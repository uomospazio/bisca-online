-- SOLO TEST: nessun account è autorizzato automaticamente.
-- Eseguire dopo 015. Prima di annunci reali sostituire la conferma client con SSV.
begin;
create table if not exists public.bisca_ad_testers (
  user_id uuid primary key references public.bisca_profiles(id) on delete cascade
);
create table if not exists public.bisca_ad_claims (
  claim_id uuid primary key,
  user_id uuid not null references public.bisca_profiles(id) on delete cascade,
  placement text not null check (placement in ('shop','solo','multi','refresh')),
  context text not null,
  amount integer not null,
  created_at timestamptz not null default now()
);
create unique index if not exists bisca_ad_match_once
  on public.bisca_ad_claims(user_id, placement, context) where placement in ('solo','multi');
create table if not exists public.bisca_personal_offers (
  user_id uuid not null references public.bisca_profiles(id) on delete cascade,
  day date not null,
  items text[] not null,
  primary key(user_id, day)
);
alter table public.bisca_ad_testers enable row level security;
alter table public.bisca_ad_claims enable row level security;
alter table public.bisca_personal_offers enable row level security;
revoke all on public.bisca_ad_testers, public.bisca_ad_claims, public.bisca_personal_offers from public, anon, authenticated;

create or replace function public.bisca_daily_shop()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  today date := (statement_timestamp() at time zone 'UTC')::date;
  selected text[];
  personal boolean := false;
  seconds integer;
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  select o.items into selected from public.bisca_personal_offers o
    where o.user_id = auth.uid() and o.day = today;
  personal := found;
  if not personal then
    perform pg_advisory_xact_lock(724019, today - date '2020-01-01');
    select o.items into selected from public.bisca_daily_offers o where o.day = today;
    if not found then
      select coalesce(array_agg(id), array[]::text[]) into selected from (
        select id from public.bisca_items where is_available and not is_default order by random() limit 3
      ) offers;
      insert into public.bisca_daily_offers(day,items) values(today,selected);
    end if;
  end if;
  seconds := greatest(1, ceil(extract(epoch from
    ((today + 1)::timestamp at time zone 'UTC') - statement_timestamp()))::integer);
  return jsonb_build_object('items', selected[1:3], 'refresh_after', seconds, 'refresh_available', not personal);
end;
$$;

create or replace function public.bisca_ad_test_eligible(p_placement text, p_context text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare u uuid := auth.uid();
begin
  if u is null then raise exception 'AUTH_REQUIRED'; end if;
  if not exists(select 1 from public.bisca_ad_testers t where t.user_id=u) then raise exception 'TESTER_REQUIRED'; end if;
  if p_placement is null or p_placement not in ('shop','solo','multi','refresh') then raise exception 'INVALID_PLACEMENT'; end if;
  if p_context is null or length(p_context)>100 then raise exception 'INVALID_CONTEXT'; end if;
  if p_placement in ('solo','multi') then
    if p_context = '' then raise exception 'INVALID_CONTEXT'; end if;
    if exists(select 1 from public.bisca_ad_claims c where c.user_id=u and c.placement=p_placement and c.context=p_context) then
      raise exception 'ALREADY_CLAIMED';
    end if;
  end if;
  if p_placement='multi' and not exists(select 1 from public.bisca_match_results m where m.user_id=u and m.match_id::text=p_context) then
    raise exception 'MATCH_NOT_RECORDED';
  end if;
  if p_placement='refresh' and exists(select 1 from public.bisca_personal_offers o
    where o.user_id=u and o.day=(statement_timestamp() at time zone 'UTC')::date) then raise exception 'DAILY_REFRESH_USED'; end if;
  return jsonb_build_object('ok',true);
end;
$$;

create or replace function public.bisca_claim_test_ad(p_claim uuid, p_placement text, p_context text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid();
  today date := (statement_timestamp() at time zone 'UTC')::date;
  previous public.bisca_ad_claims%rowtype;
  reward integer;
  balance integer;
  old_items text[];
  selected text[];
begin
  if u is null then raise exception 'AUTH_REQUIRED'; end if;
  -- Il lock sul profilo serializza doppie richieste e cambi saldo concorrenti.
  select p.credits into balance from public.bisca_profiles p where p.id=u for update;
  if not found then raise exception 'PROFILE_NOT_READY'; end if;
  select * into previous from public.bisca_ad_claims c where c.claim_id=p_claim;
  if found then
    if previous.user_id<>u or previous.placement<>p_placement or previous.context<>p_context then raise exception 'INVALID_CLAIM'; end if;
    return jsonb_build_object('ok',true,'credits',balance,'amount',previous.amount);
  end if;
  perform public.bisca_ad_test_eligible(p_placement,p_context);
  reward := case p_placement when 'shop' then 20 when 'solo' then 30 when 'multi' then 50 else 0 end;
  if p_placement='refresh' then
    select array(select jsonb_array_elements_text(public.bisca_daily_shop()->'items')) into old_items;
    select coalesce(array_agg(id),array[]::text[]) into selected from (
      select id from public.bisca_items where is_available and not is_default
      order by (id=any(old_items)), random() limit 3
    ) offers;
    insert into public.bisca_personal_offers(user_id,day,items) values(u,today,selected);
  end if;
  insert into public.bisca_ad_claims(claim_id,user_id,placement,context,amount) values(p_claim,u,p_placement,p_context,reward);
  update public.bisca_profiles set credits=credits+reward where id=u returning credits into balance;
  return jsonb_build_object('ok',true,'credits',balance,'amount',reward);
end;
$$;
revoke all on function public.bisca_daily_shop(), public.bisca_ad_test_eligible(text,text), public.bisca_claim_test_ad(uuid,text,text) from public, anon;
grant execute on function public.bisca_daily_shop(), public.bisca_ad_test_eligible(text,text), public.bisca_claim_test_ad(uuid,text,text) to authenticated;
commit;

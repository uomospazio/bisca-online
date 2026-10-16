-- Apply after 025. TEST ADS ONLY: keep tester whitelist until verified AdMob SSV.
begin;
update public.bisca_items set is_available=false where id='deck_back_13';
alter table public.bisca_items add constraint bisca_gold_wheel_exclusive
 check(id<>'deck_back_13' or not is_available);
alter table public.bisca_ad_claims drop constraint bisca_ad_claims_placement_check;
alter table public.bisca_ad_claims add constraint bisca_ad_claims_placement_check
 check(placement in ('shop','solo','multi','refresh','wheel'));
create or replace function public.bisca_ad_test_eligible(p_placement text, p_context text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare u uuid := auth.uid();
begin
  if u is null then raise exception 'AUTH_REQUIRED'; end if;
  if not exists(select 1 from public.bisca_ad_testers t where t.user_id=u) then raise exception 'TESTER_REQUIRED'; end if;
  if p_placement is null or p_placement not in ('shop','solo','multi','refresh','wheel') then raise exception 'INVALID_PLACEMENT'; end if;
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

create table public.bisca_wheel_results(
 claim_id uuid primary key references public.bisca_ad_claims(claim_id) on delete cascade,
 outcome text not null check(outcome in ('crown','coins_5000','coins_1000','coins_50','tomato','poop','tissues')),
 duplicate boolean not null default false
);
alter table public.bisca_wheel_results enable row level security;
revoke all on public.bisca_wheel_results from public,anon,authenticated;

-- 10000 equally likely values, not probabilities proportional to artwork sectors.
create function public.bisca_wheel_outcome(p_roll integer) returns text
language plpgsql immutable set search_path='' as $$
begin
 if p_roll is null or p_roll<0 or p_roll>=10000 then raise exception 'INVALID_ROLL'; end if;
 return case when p_roll<200 then 'crown' when p_roll<400 then 'coins_5000'
 when p_roll<1100 then 'coins_1000' when p_roll<2500 then 'coins_50'
 when p_roll<5000 then 'tomato' when p_roll<7500 then 'poop' else 'tissues' end;
end $$;

-- Preserve the complete old implementation and the season-locking public wrapper.
alter function public.bisca_claim_test_ad_internal(uuid,text,text) rename to bisca_claim_test_ad_before_wheel;
create function public.bisca_claim_test_ad_internal(p_claim uuid,p_placement text,p_context text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); balance integer; reward integer; choice text; owned boolean:=false;
 previous public.bisca_ad_claims%rowtype;
begin
 if p_placement is distinct from 'wheel' then
  return public.bisca_claim_test_ad_before_wheel(p_claim,p_placement,p_context);
 end if;
 if u is null then raise exception 'AUTH_REQUIRED'; end if;
 select credits into balance from public.bisca_profiles where id=u for update;
 if not found then raise exception 'PROFILE_NOT_READY'; end if;
 select * into previous from public.bisca_ad_claims where claim_id=p_claim;
 if found then
  if previous.user_id<>u or previous.placement<>p_placement or previous.context is distinct from p_context then
   raise exception 'INVALID_CLAIM';
  end if;
  select outcome,duplicate into choice,owned from public.bisca_wheel_results where claim_id=p_claim;
  if not found then raise exception 'INVALID_CLAIM'; end if;
  reward:=previous.amount;
 else
  perform public.bisca_ad_test_eligible(p_placement,p_context);
  choice:=public.bisca_wheel_outcome(floor(random()*10000)::integer);
  reward:=case choice when 'coins_5000' then 5000 when 'coins_1000' then 1000 when 'coins_50' then 50 else 0 end;
  if choice='crown' then
   select exists(select 1 from public.bisca_inventory where user_id=u and item_id='deck_back_13') into owned;
   -- A duplicate remains the same owned cosmetic; no unrequested coin conversion.
   insert into public.bisca_inventory(user_id,item_id,item_type) values(u,'deck_back_13','deck_back')
    on conflict(user_id,item_id) do nothing;
  end if;
  insert into public.bisca_ad_claims(claim_id,user_id,placement,context,amount) values(p_claim,u,p_placement,p_context,reward);
  insert into public.bisca_wheel_results(claim_id,outcome,duplicate) values(p_claim,choice,owned);
  update public.bisca_profiles set credits=credits+reward where id=u returning credits into balance;
 end if;
 return jsonb_build_object('ok',true,'credits',balance,'amount',reward,'outcome',choice,
  'item_id',case when choice='crown' then 'deck_back_13' else null end,'duplicate',owned);
end $$;
revoke all on function public.bisca_wheel_outcome(integer),public.bisca_claim_test_ad_before_wheel(uuid,text,text),
 public.bisca_claim_test_ad_internal(uuid,text,text) from public,anon,authenticated;

-- Gold uses ID 3; ID 2 remains retired. No client can select gold without owning back13.
alter table public.bisca_profiles drop constraint bisca_profiles_deck_front_check;
alter table public.bisca_profiles add constraint bisca_profiles_deck_front_check check(deck_front in (0,1,3));
create function public.bisca_guard_gold_front() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if new.deck_front=3 and not exists(
  select 1 from public.bisca_inventory where user_id=new.id and item_id='deck_back_13'
 ) then raise exception 'GOLD_DECK_REQUIRED'; end if;
 return new;
end $$;
revoke all on function public.bisca_guard_gold_front() from public,anon,authenticated;
create trigger bisca_gold_front before insert or update of deck_front on public.bisca_profiles
 for each row execute function public.bisca_guard_gold_front();
commit;


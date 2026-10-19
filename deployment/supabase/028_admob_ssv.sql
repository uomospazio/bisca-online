-- Production rewarded ads. Apply after 027; deploy admob-ssv before shipping.
begin;
create table public.bisca_ad_sessions (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.bisca_profiles(id) on delete cascade,
 placement text not null,
 context text not null,
 ad_unit text not null,
 created_at timestamptz not null default now(),
 expires_at timestamptz not null default now()+interval '2 hours',
 transaction_id text unique,
 verified_at timestamptz,
 receipt jsonb
);
create index bisca_ad_sessions_owner on public.bisca_ad_sessions(user_id,created_at);
alter table public.bisca_ad_sessions enable row level security;
revoke all on public.bisca_ad_sessions from public,anon,authenticated;

-- Kept under its historical name because the private reward functions call it.
-- All public client-side award entry points are revoked below.
create or replace function public.bisca_ad_test_eligible(p_placement text,p_context text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();
begin
 if u is null then raise exception 'AUTH_REQUIRED'; end if;
 if p_placement is null or p_placement not in ('shop','refresh','solo','multi','multi_final','wheel') then raise exception 'INVALID_PLACEMENT'; end if;
 if p_context is null or length(p_context)>100 then raise exception 'INVALID_CONTEXT'; end if;
 if p_placement in ('solo','multi','multi_final') then
  if p_context='' then raise exception 'INVALID_CONTEXT'; end if;
  if exists(select 1 from public.bisca_ad_claims where user_id=u and placement=p_placement and context=p_context) then raise exception 'ALREADY_CLAIMED'; end if;
 end if;
 if p_placement='multi' and not exists(select 1 from public.bisca_match_results where user_id=u and match_id::text=p_context) then raise exception 'MATCH_NOT_RECORDED'; end if;
 if p_placement='multi_final' and (
  not exists(select 1 from public.bisca_season_results where user_id=u and match_id::text=p_context and mode='multi' and place>=3)
  or not exists(select 1 from public.bisca_completed_reward_matches where match_id::text=p_context)
 ) then raise exception 'MATCH_NOT_RECORDED'; end if;
 if p_placement='refresh' and exists(select 1 from public.bisca_personal_offers where user_id=u and day=(now() at time zone 'UTC')::date) then raise exception 'DAILY_REFRESH_USED'; end if;
 return jsonb_build_object('ok',true);
end $$;

create function public.bisca_begin_ad(p_placement text,p_context text,p_platform text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare s public.bisca_ad_sessions; unit text;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 select * into s from public.bisca_ad_sessions where user_id=auth.uid() and verified_at is not null and receipt is null order by created_at limit 1;
 if found then return jsonb_build_object('ok',true,'session_id',s.id,'recover',true,'placement',s.placement,'context',s.context); end if;
 perform public.bisca_ad_test_eligible(p_placement,p_context);
 unit:=case p_platform when 'Android' then '7155046146' when 'iOS' then '7977173220' end;
 if unit is null then raise exception 'INVALID_PLATFORM'; end if;
 perform 1 from public.bisca_profiles where id=auth.uid() for update;
 if not found then raise exception 'PROFILE_NOT_READY'; end if;
 if exists(select 1 from public.bisca_ad_sessions where user_id=auth.uid() and created_at>now()-interval '5 seconds') then raise exception 'AD_RATE_LIMIT'; end if;
 insert into public.bisca_ad_sessions(user_id,placement,context,ad_unit)
 values(auth.uid(),p_placement,p_context,unit) returning * into s;
 return jsonb_build_object('ok',true,'session_id',s.id);
end $$;

-- ONLY the Edge Function, after verifying Google's signature, can call this.
create function public.bisca_verify_ad(p_session uuid,p_user uuid,p_unit text,p_transaction text,p_timestamp bigint) returns jsonb
language plpgsql security definer set search_path='' as $$
declare s public.bisca_ad_sessions; event_time timestamptz;
begin
 select * into s from public.bisca_ad_sessions where id=p_session for update;
 if not found then raise exception 'INVALID_SESSION'; end if;
 if s.user_id is distinct from p_user or s.ad_unit is distinct from p_unit
 or p_transaction is null or length(p_transaction) not between 1 and 256 then raise exception 'INVALID_CALLBACK'; end if;
 if s.transaction_id is not null then
  if s.transaction_id<>p_transaction then raise exception 'TRANSACTION_CONFLICT'; end if;
  return jsonb_build_object('ok',true);
 end if;
 event_time:=to_timestamp(p_timestamp/1000.0);
 if event_time is null or event_time<s.created_at-interval '5 minutes' or event_time>s.expires_at
 or event_time>now()+interval '5 minutes' then raise exception 'INVALID_TIMESTAMP'; end if;
 update public.bisca_ad_sessions set transaction_id=p_transaction,verified_at=now() where id=s.id;
 return jsonb_build_object('ok',true);
end $$;

create function public.bisca_claim_ad(p_session uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare s public.bisca_ad_sessions; result jsonb; balance integer;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 -- Same lock ordering as the existing seasonal settlement/reward code.
 perform pg_advisory_xact_lock(724020,0);
 select * into s from public.bisca_ad_sessions where id=p_session and user_id=auth.uid() for update;
 if not found then raise exception 'INVALID_SESSION'; end if;
 if s.receipt is not null then
  select credits into balance from public.bisca_profiles where id=auth.uid();
  return s.receipt||jsonb_build_object('credits',balance);
 end if;
 if s.verified_at is null then
  return jsonb_build_object('ok',false,'code','SSV_PENDING','message','Verifica video in corso. Riprova tra poco.');
 end if;
 begin
  result:=public.bisca_claim_test_ad_internal(s.id,s.placement,s.context);
 exception when raise_exception then
  if sqlerrm not in ('ALREADY_CLAIMED','DAILY_REFRESH_USED') then raise; end if;
  result:=jsonb_build_object('ok',false,'code',sqlerrm,'message','Premio gia ricevuto.');
 end;
 update public.bisca_ad_sessions set receipt=result where id=s.id;
 return result;
end $$;

revoke all on function public.bisca_ad_test_eligible(text,text),public.bisca_claim_test_ad(uuid,text,text) from public,anon,authenticated;
revoke all on function public.bisca_begin_ad(text,text,text),public.bisca_claim_ad(uuid),public.bisca_verify_ad(uuid,uuid,text,text,bigint) from public,anon,authenticated;
grant execute on function public.bisca_begin_ad(text,text,text),public.bisca_claim_ad(uuid) to authenticated;
grant execute on function public.bisca_verify_ad(uuid,uuid,text,text,bigint) to service_role;
commit;

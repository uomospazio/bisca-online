-- After 026. Separate once-per-match final video. Existing test-ad restrictions stay.
begin;
-- Server-only completion proof also covers matches won by a bot (no user receipt).
create table public.bisca_completed_reward_matches(match_id uuid primary key,finished_at timestamptz not null default now());
alter table public.bisca_completed_reward_matches enable row level security;
revoke all on public.bisca_completed_reward_matches from public,anon,authenticated;
create function public.bisca_finish_reward_match(p_match_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 insert into public.bisca_completed_reward_matches(match_id) values(p_match_id) on conflict do nothing;
 return jsonb_build_object('ok',true);
end $$;
revoke all on function public.bisca_finish_reward_match(uuid) from public,anon,authenticated;
grant execute on function public.bisca_finish_reward_match(uuid) to service_role;
alter table public.bisca_ad_claims drop constraint bisca_ad_claims_placement_check;
alter table public.bisca_ad_claims add constraint bisca_ad_claims_placement_check
 check(placement in ('shop','solo','multi','refresh','wheel','multi_final'));
create unique index bisca_ad_final_once on public.bisca_ad_claims(user_id,placement,context)
 where placement='multi_final';
alter table public.bisca_ad_claims add column season_points integer not null default 0;
alter function public.bisca_ad_test_eligible(text,text) rename to bisca_ad_eligible_before_results;
create function public.bisca_ad_test_eligible(p_placement text,p_context text) returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if p_placement is distinct from 'multi_final' then
  return public.bisca_ad_eligible_before_results(p_placement,p_context);
 end if;
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 if not exists(select 1 from public.bisca_ad_testers where user_id=auth.uid()) then raise exception 'TESTER_REQUIRED'; end if;
 if p_context is null or p_context='' or length(p_context)>100 then raise exception 'INVALID_CONTEXT'; end if;
 if exists(select 1 from public.bisca_ad_claims where user_id=auth.uid() and placement=p_placement and context=p_context)
 then raise exception 'ALREADY_CLAIMED'; end if;
 if not exists(select 1 from public.bisca_season_results where user_id=auth.uid() and match_id::text=p_context and mode='multi' and place>=3)
 or not exists(select 1 from public.bisca_completed_reward_matches where match_id::text=p_context)
 then raise exception 'MATCH_NOT_RECORDED'; end if;
 return jsonb_build_object('ok',true);
end $$;
alter function public.bisca_claim_test_ad_internal(uuid,text,text) rename to bisca_claim_ad_before_results;
create function public.bisca_claim_test_ad_internal(p_claim uuid,p_placement text,p_context text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); balance integer; previous public.bisca_ad_claims; result jsonb; xp integer;
begin
 if p_placement is distinct from 'multi_final' then
  result:=public.bisca_claim_ad_before_results(p_claim,p_placement,p_context);
  select season_points into xp from public.bisca_ad_claims where claim_id=p_claim;
  return result||jsonb_build_object('season_points',coalesce(xp,0));
 end if;
 if u is null then raise exception 'AUTH_REQUIRED'; end if;
 select credits into balance from public.bisca_profiles where id=u for update;
 if not found then raise exception 'PROFILE_NOT_READY'; end if;
 select * into previous from public.bisca_ad_claims where claim_id=p_claim;
 if found then
  if previous.user_id<>u or previous.placement<>p_placement or previous.context is distinct from p_context
  then raise exception 'INVALID_CLAIM'; end if;
 else
  perform public.bisca_ad_test_eligible(p_placement,p_context);
  insert into public.bisca_ad_claims(claim_id,user_id,placement,context,amount) values(p_claim,u,p_placement,p_context,50);
  update public.bisca_profiles set credits=credits+50 where id=u returning credits into balance;
 end if;
 return jsonb_build_object('ok',true,'credits',balance,'amount',50,'season_points',0);
end $$;
create or replace function public.bisca_season_ad_credit() returns trigger
language plpgsql security definer set search_path='' as $$
declare season integer;
begin
 if new.placement='solo' then
  select id into season from public.bisca_seasons where starts_at<=now() and ends_at>now() and settled_at is null order by starts_at desc limit 1 for update;
  if season is not null then
   insert into public.bisca_season_scores(season_id,user_id,points,reached_at)
    values(season,new.user_id,50,clock_timestamp())
   on conflict(season_id,user_id) do update set points=bisca_season_scores.points+50,reached_at=excluded.reached_at;
   update public.bisca_ad_claims set season_points=50 where claim_id=new.claim_id;
  end if;
 end if;
 return new;
end $$;
revoke all on function public.bisca_ad_eligible_before_results(text,text),public.bisca_claim_ad_before_results(uuid,text,text),
 public.bisca_claim_test_ad_internal(uuid,text,text),public.bisca_ad_test_eligible(text,text) from public,anon,authenticated;
grant execute on function public.bisca_ad_test_eligible(text,text) to authenticated;
-- A retry returns the originally credited XP for presentation, without crediting again.
alter function public.bisca_record_ranked_match(uuid,uuid,text,boolean,integer,text) rename to bisca_record_ranked_before_results;
create function public.bisca_record_ranked_match(p_match_id uuid,p_user_id uuid,p_outcome text,p_reward boolean,p_place integer,p_mode text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare receipt jsonb; xp integer;
begin
 receipt:=public.bisca_record_ranked_before_results(p_match_id,p_user_id,p_outcome,p_reward,p_place,p_mode);
 select case when credited then points else 0 end into xp from public.bisca_season_results
 where match_id=p_match_id and user_id=p_user_id;
 return receipt||jsonb_build_object('season_points',coalesce(xp,0));
end $$;
revoke all on function public.bisca_record_ranked_before_results(uuid,uuid,text,boolean,integer,text),public.bisca_record_ranked_match(uuid,uuid,text,boolean,integer,text) from public,anon,authenticated;
grant execute on function public.bisca_record_ranked_match(uuid,uuid,text,boolean,integer,text) to service_role;
commit;


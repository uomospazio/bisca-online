-- Apply after 021. Seasons use server time, not the device clock.
begin;
create table public.bisca_seasons (
 id integer primary key, name text not null,
 starts_at timestamptz not null, ends_at timestamptz not null,
 rewards integer[] not null default array[5000,2000,1000,900,800,700,600,500,400,300],
 settled_at timestamptz, check(ends_at>starts_at), check(cardinality(rewards)=10)
);
insert into public.bisca_seasons(id,name,starts_at,ends_at)
 values(0,'STAGIONE 0','2026-10-15 00:00:00 Europe/Rome','2027-01-01 00:00:00 Europe/Rome');
create table public.bisca_season_results (
 match_id uuid not null, user_id uuid not null references auth.users(id) on delete cascade,
 season_id integer references public.bisca_seasons(id),
 place integer not null check(place between 1 and 8),
 mode text not null check(mode in ('solo','multi')), eligible boolean not null,
 points integer not null check(points in (50,100,200)), credited boolean not null default false,
 created_at timestamptz not null default now(), primary key(match_id,user_id)
);
create table public.bisca_season_scores (
 season_id integer not null references public.bisca_seasons(id),
 user_id uuid not null references auth.users(id) on delete cascade,
 points bigint not null default 0 check(points>=0), reached_at timestamptz not null default now(),
 primary key(season_id,user_id)
);
create table public.bisca_season_prizes (
 season_id integer not null references public.bisca_seasons(id),
 user_id uuid not null references auth.users(id) on delete cascade,
 place integer not null, amount integer not null, created_at timestamptz not null default now(),
 primary key(season_id,user_id), unique(season_id,place)
);
alter table public.bisca_seasons enable row level security;
alter table public.bisca_season_results enable row level security;
alter table public.bisca_season_scores enable row level security;
alter table public.bisca_season_prizes enable row level security;
revoke all on public.bisca_seasons,public.bisca_season_results,public.bisca_season_scores,public.bisca_season_prizes from public,anon,authenticated;

-- Internal helper: same lock as settlement, so late ads never alter final ranks.
create function public.bisca_credit_season(p_match uuid,p_user uuid) returns integer
language plpgsql security definer set search_path='' as $$
declare r public.bisca_season_results; s public.bisca_seasons;
begin
 select * into r from public.bisca_season_results where match_id=p_match and user_id=p_user;
 if not found or r.season_id is null or not r.eligible then return 0; end if;
 select * into s from public.bisca_seasons where id=r.season_id for update;
 if s.settled_at is not null or now()>=s.ends_at or now()<s.starts_at then return 0; end if;
 update public.bisca_season_results set credited=true where match_id=p_match and user_id=p_user and not credited;
 if not found then return 0; end if;
 insert into public.bisca_season_scores(season_id,user_id,points,reached_at)
 values(r.season_id,p_user,r.points,clock_timestamp())
 on conflict(season_id,user_id) do update set points=bisca_season_scores.points+excluded.points,reached_at=excluded.reached_at;
 return r.points;
end $$;

-- Only the dedicated server supplies a verified place; old clients cannot award points.
create function public.bisca_record_ranked_match(p_match_id uuid,p_user_id uuid,p_outcome text,p_reward boolean,p_place integer,p_mode text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare receipt jsonb; season integer; saved public.bisca_season_results; earned integer:=0;
begin
 perform pg_advisory_xact_lock(724020,0);
 if p_mode is null or p_mode not in ('solo','multi') or p_place is null or p_place not between 1 and 8
 or (p_outcome='victory')<>(p_place=1) then raise exception 'INVALID_PLACEMENT'; end if;
 select id into season from public.bisca_seasons where starts_at<=now() and ends_at>now() and settled_at is null order by starts_at desc limit 1;
 if season is not null then perform 1 from public.bisca_seasons where id=season for update; end if;
 -- Solo coins, like solo points, are claimed by watching the existing ad.
 receipt := public.bisca_record_match(p_match_id,p_user_id,p_outcome,p_reward and p_mode='multi');
 insert into public.bisca_season_results(match_id,user_id,season_id,place,mode,eligible,points)
 values(p_match_id,p_user_id,season,p_place,p_mode,p_reward,case p_place when 1 then 200 when 2 then 100 else 50 end)
 on conflict do nothing;
 select * into saved from public.bisca_season_results where match_id=p_match_id and user_id=p_user_id;
 if saved.place<>p_place or saved.mode<>p_mode or saved.eligible<>p_reward then raise exception 'RESULT_CONFLICT'; end if;
 if p_mode='multi' then
  earned := public.bisca_credit_season(p_match_id,p_user_id);
 end if;
 return receipt || jsonb_build_object('season_points',earned,'place',p_place,'season_id',saved.season_id);
end $$;

-- Same confirmed ad transaction as the coins. No points for shop/extra multi ads.
create function public.bisca_season_ad_credit() returns trigger
language plpgsql security definer set search_path='' as $$
declare season integer;
begin
 if new.placement='solo' then
  select id into season from public.bisca_seasons where starts_at<=now() and ends_at>now() and settled_at is null order by starts_at desc limit 1 for update;
  if season is not null then
   -- Unique ad (user, placement, context) is the ledger: no placement from the device.
   insert into public.bisca_season_scores(season_id,user_id,points,reached_at)
   values(season,new.user_id,50,clock_timestamp())
   on conflict(season_id,user_id) do update set points=bisca_season_scores.points+50,reached_at=excluded.reached_at;
  end if;
 end if;
 return new;
end $$;
create trigger bisca_season_ad after insert on public.bisca_ad_claims for each row execute function public.bisca_season_ad_credit();

-- Acquire the seasonal lock BEFORE the underlying RPC locks a profile.
-- Keep the existing test-only authorization and ad retry semantics unchanged.
alter function public.bisca_claim_test_ad(uuid,text,text) rename to bisca_claim_test_ad_internal;
revoke all on function public.bisca_claim_test_ad_internal(uuid,text,text) from public,anon,authenticated;
create function public.bisca_claim_test_ad(p_claim uuid,p_placement text,p_context text)
returns jsonb language plpgsql security definer set search_path='' as $$
begin
 perform pg_advisory_xact_lock(724020,0);
 return public.bisca_claim_test_ad_internal(p_claim,p_placement,p_context);
end $$;
revoke all on function public.bisca_claim_test_ad(uuid,text,text) from public,anon;
grant execute on function public.bisca_claim_test_ad(uuid,text,text) to authenticated;

create function public.bisca_settle_seasons() returns jsonb
language plpgsql security definer set search_path='' as $$
declare s public.bisca_seasons; r record; total integer:=0;
begin
 perform pg_advisory_xact_lock(724020,0);
 for s in select * from public.bisca_seasons where ends_at<=now() and settled_at is null order by id for update loop
  for r in select user_id,row_number() over(order by points desc,reached_at,user_id)::integer as place
   from public.bisca_season_scores where season_id=s.id and points>0 order by points desc,reached_at,user_id limit 10 loop
   insert into public.bisca_season_prizes(season_id,user_id,place,amount) values(s.id,r.user_id,r.place,s.rewards[r.place]) on conflict do nothing;
   if found then
    update public.bisca_profiles set credits=credits+s.rewards[r.place],updated_at=now() where id=r.user_id;
    total := total+1;
   end if;
  end loop;
  update public.bisca_seasons set settled_at=now() where id=s.id;
 end loop;
 return jsonb_build_object('awarded',total);
end $$;

create function public.bisca_season_board() returns jsonb
language plpgsql security definer set search_path='' as $$
declare s public.bisca_seasons; entries jsonb; own jsonb; stats jsonb;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 select * into s from public.bisca_seasons where starts_at<=now() order by starts_at desc limit 1;
 select jsonb_build_object('games_played',coalesce(games_played,0),'wins',coalesce(wins,0)) into stats from public.bisca_profiles where id=auth.uid();
 if s.id is null then return jsonb_build_object('season',null,'entries','[]'::jsonb,'stats',stats); end if;
 with ranked as (
  select user_id,points,row_number() over(order by points desc,reached_at,user_id) as place from public.bisca_season_scores where season_id=s.id and points>0
 ) select coalesce(jsonb_agg(jsonb_build_object('rank',r.place,'points',r.points,'username',p.username,'public_id',p.public_id,'avatar',coalesce(a.avatar,'')) order by r.place),'[]'::jsonb)
 into entries from ranked r join public.bisca_profiles p on p.id=r.user_id left join public.bisca_profile_avatars a on a.user_id=r.user_id where r.place<=100;
 with ranked as (
  select user_id,points,row_number() over(order by points desc,reached_at,user_id) as place from public.bisca_season_scores where season_id=s.id and points>0
 ) select jsonb_build_object('rank',place,'points',points) into own from ranked where user_id=auth.uid();
 return jsonb_build_object('season',jsonb_build_object('id',s.id,'name',s.name,'ends_at',extract(epoch from s.ends_at),'remaining',greatest(0,extract(epoch from s.ends_at-now())),'settled',s.settled_at is not null,'rewards',s.rewards),'entries',entries,'own',own,'stats',stats);
end $$;
revoke all on function public.bisca_credit_season(uuid,uuid),public.bisca_season_ad_credit(),public.bisca_record_ranked_match(uuid,uuid,text,boolean,integer,text),public.bisca_settle_seasons(),public.bisca_season_board() from public,anon,authenticated;
grant execute on function public.bisca_record_ranked_match(uuid,uuid,text,boolean,integer,text),public.bisca_settle_seasons() to service_role;
grant execute on function public.bisca_season_board() to authenticated;
commit;

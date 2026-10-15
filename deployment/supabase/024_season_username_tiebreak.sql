-- Apply after 023. Username breaks ties only after points and time.
begin;
create or replace function public.bisca_season_board() returns jsonb
language plpgsql security definer set search_path='' as $$
declare s public.bisca_seasons; entries jsonb; own jsonb; stats jsonb;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 select * into s from public.bisca_seasons where starts_at<=now() order by starts_at desc limit 1;
 select jsonb_build_object('games_played',coalesce(games_played,0),'wins',coalesce(wins,0)) into stats from public.bisca_profiles where id=auth.uid();
 if s.id is null then return jsonb_build_object('season',null,'entries','[]'::jsonb,'stats',stats); end if;
 with ranked as (
  select p.id as user_id,coalesce(score.points,0) as points,
   row_number() over(order by coalesce(score.points,0) desc,
    case when score.points>0 then score.reached_at end nulls last,
    (nullif(btrim(p.username),'') is not null) desc,p.id) as place
  from public.bisca_profiles p
  left join public.bisca_season_scores score on score.user_id=p.id and score.season_id=s.id
 ) select coalesce(jsonb_agg(jsonb_build_object('rank',r.place,'points',r.points,'username',p.username,'public_id',p.public_id,'avatar',coalesce(a.avatar,'')) order by r.place),'[]'::jsonb)
 into entries from ranked r join public.bisca_profiles p on p.id=r.user_id left join public.bisca_profile_avatars a on a.user_id=r.user_id where r.place<=100;
 with ranked as (
  select p.id as user_id,coalesce(score.points,0) as points,
   row_number() over(order by coalesce(score.points,0) desc,
    case when score.points>0 then score.reached_at end nulls last,
    (nullif(btrim(p.username),'') is not null) desc,p.id) as place
  from public.bisca_profiles p
  left join public.bisca_season_scores score on score.user_id=p.id and score.season_id=s.id
 ) select jsonb_build_object('rank',place,'points',points) into own from ranked where user_id=auth.uid();
 return jsonb_build_object('season',jsonb_build_object('id',s.id,'name',s.name,'ends_at',extract(epoch from s.ends_at),'remaining',greatest(0,extract(epoch from s.ends_at-now())),'settled',s.settled_at is not null,'rewards',s.rewards),'entries',entries,'own',own,'stats',stats);
end $$;

create or replace function public.bisca_settle_seasons() returns jsonb
language plpgsql security definer set search_path='' as $$
declare s public.bisca_seasons; r record; total integer:=0;
begin
 perform pg_advisory_xact_lock(724020,0);
 for s in select * from public.bisca_seasons where ends_at<=now() and settled_at is null order by id for update loop
  for r in select score.user_id,row_number() over(order by score.points desc,score.reached_at,
    (nullif(btrim(p.username),'') is not null) desc,score.user_id)::integer as place
   from public.bisca_season_scores score join public.bisca_profiles p on p.id=score.user_id
   where score.season_id=s.id and score.points>0
   order by score.points desc,score.reached_at,(nullif(btrim(p.username),'') is not null) desc,score.user_id limit 10 loop
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

revoke all on function public.bisca_season_board(),public.bisca_settle_seasons() from public,anon,authenticated;
grant execute on function public.bisca_season_board() to authenticated;
grant execute on function public.bisca_settle_seasons() to service_role;
commit;


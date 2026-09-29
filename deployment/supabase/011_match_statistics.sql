-- Richiede 010_match_rewards.sql. Solo nuove partite, nessun backfill storico.
begin;
create table if not exists public.bisca_match_results (
  match_id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  outcome text not null check (outcome in ('elimination','victory')),
  created_at timestamptz not null default now(),
  primary key(match_id,user_id)
);
alter table public.bisca_match_results enable row level security;
revoke all on public.bisca_match_results from public, anon, authenticated;

create or replace function public.bisca_record_match(
  p_match_id uuid, p_user_id uuid, p_outcome text, p_reward boolean
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  inserted integer;
  saved_outcome text;
  result jsonb;
begin
  if p_outcome is null or p_outcome not in ('elimination','victory') then
    raise exception 'Invalid outcome';
  end if;
  perform 1 from public.bisca_profiles where id=p_user_id for update;
  if not found then raise exception 'Profile not ready'; end if;
  insert into public.bisca_match_results(match_id,user_id,outcome)
    values(p_match_id,p_user_id,p_outcome) on conflict do nothing;
  get diagnostics inserted = row_count;
  if inserted=1 then
    update public.bisca_profiles set
      games_played=coalesce(games_played,0)+1,
      wins=coalesce(wins,0)+case when p_outcome='victory' then 1 else 0 end,
      updated_at=now() where id=p_user_id;
  end if;
  select outcome into saved_outcome from public.bisca_match_results
    where match_id=p_match_id and user_id=p_user_id;
  if p_reward then
    result := public.bisca_award_match(p_match_id,p_user_id,saved_outcome);
  else
    result := jsonb_build_object('match_id',p_match_id,'user_id',p_user_id,'outcome',saved_outcome,'amount',0);
  end if;
  return result;
end $$;
revoke all on function public.bisca_record_match(uuid,uuid,text,boolean) from public, anon, authenticated;
grant execute on function public.bisca_record_match(uuid,uuid,text,boolean) to service_role;
commit;

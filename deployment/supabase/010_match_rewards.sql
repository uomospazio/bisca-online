-- Eseguire nel SQL Editor. Nessun cambiamento ai prezzi del catalogo.
begin;
create table if not exists public.bisca_match_rewards (
  match_id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  outcome text not null check (outcome in ('elimination', 'victory')),
  amount integer not null check (amount in (30, 50)),
  created_at timestamptz not null default now(),
  primary key (match_id, user_id)
);
alter table public.bisca_match_rewards enable row level security;
revoke all on public.bisca_match_rewards from public, anon, authenticated;

-- Solo il server fidato puo' chiamarla. L'importo non arriva dal client.
create or replace function public.bisca_award_match(p_match_id uuid, p_user_id uuid, p_outcome text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  reward integer;
  inserted integer;
  balance bigint;
  saved public.bisca_match_rewards;
begin
  if p_outcome not in ('elimination', 'victory') or p_outcome is null then
    raise exception 'Invalid outcome';
  end if;
  reward := case when p_outcome = 'victory' then 50 else 30 end;
  select credits into balance from public.bisca_profiles where id = p_user_id for update;
  if not found then raise exception 'Profile not ready'; end if;
  insert into public.bisca_match_rewards(match_id,user_id,outcome,amount)
    values(p_match_id,p_user_id,p_outcome,reward) on conflict do nothing;
  get diagnostics inserted = row_count;
  if inserted = 1 then
    update public.bisca_profiles set credits = credits + reward, updated_at = now()
      where id = p_user_id returning credits into balance;
  end if;
  select * into saved from public.bisca_match_rewards where match_id=p_match_id and user_id=p_user_id;
  return jsonb_build_object('match_id',p_match_id,'user_id',p_user_id,
    'amount',saved.amount,'outcome',saved.outcome,'credits',balance::text);
end $$;
revoke all on function public.bisca_award_match(uuid,uuid,text) from public, anon, authenticated;
grant execute on function public.bisca_award_match(uuid,uuid,text) to service_role;
commit;

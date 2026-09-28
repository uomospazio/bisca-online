-- Eseguire una volta nel SQL Editor del progetto Supabase BISCA.
-- Solo profilo e preferenze: nessun credito, premio o dato della lobby.
begin;
create table public.bisca_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text check (username is null or char_length(username) between 3 and 24),
  deck_back integer not null default 1 check (deck_back between 1 and 12),
  deck_front integer not null default 0 check (deck_front between 0 and 2),
  created_at timestamptz not null default now()
);
alter table public.bisca_profiles enable row level security;
revoke all on public.bisca_profiles from anon, authenticated;
grant select on public.bisca_profiles to authenticated;
grant insert (id, deck_back, deck_front) on public.bisca_profiles to authenticated;
grant update (deck_back, deck_front) on public.bisca_profiles to authenticated;
create policy own_profile_read on public.bisca_profiles for select to authenticated
  using ((select auth.uid()) = id);
create policy own_profile_create on public.bisca_profiles for insert to authenticated
  with check ((select auth.uid()) = id);
create policy own_profile_update on public.bisca_profiles for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
commit;

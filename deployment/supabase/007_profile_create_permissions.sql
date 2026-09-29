-- Ripristino mirato per errore 42501 nella POST bisca_profiles.
-- Non concede INSERT/UPDATE su crediti, XP, statistiche o public_id.
begin;
alter table public.bisca_profiles enable row level security;
grant usage on schema public to authenticated;
grant select on public.bisca_profiles to authenticated;
grant insert (id, deck_back, deck_front) on public.bisca_profiles to authenticated;
grant update (deck_back, deck_front, username) on public.bisca_profiles to authenticated;
drop policy if exists bisca_shop_profile_allow on public.bisca_profiles;
create policy bisca_shop_profile_allow on public.bisca_profiles for all to authenticated
using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
drop policy if exists bisca_shop_profile_guard on public.bisca_profiles;
create policy bisca_shop_profile_guard on public.bisca_profiles as restrictive for all to authenticated
using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
commit;

-- Tutti questi permessi devono risultare true.
select has_column_privilege('authenticated','public.bisca_profiles','id','INSERT') as insert_id,
has_column_privilege('authenticated','public.bisca_profiles','deck_back','INSERT') as insert_back,
has_column_privilege('authenticated','public.bisca_profiles','deck_front','INSERT') as insert_front;

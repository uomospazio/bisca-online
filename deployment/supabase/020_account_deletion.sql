-- No accounts are deleted by this migration.
begin;
alter table public.bisca_inventory drop constraint bisca_inventory_user_id_fkey;
alter table public.bisca_inventory add constraint bisca_inventory_user_id_fkey
  foreign key(user_id) references auth.users(id) on delete cascade;
alter table public.bisca_season_progress drop constraint bisca_season_progress_user_id_fkey;
alter table public.bisca_season_progress add constraint bisca_season_progress_user_id_fkey
  foreign key(user_id) references auth.users(id) on delete cascade;
commit;

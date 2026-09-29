-- Eseguire manualmente dopo 002_shop_readonly.sql.
-- Permette solo l'username del proprio profilo, tramite le policy RLS esistenti.
begin;
grant update (username) on public.bisca_profiles to authenticated;
alter table public.bisca_profiles drop constraint if exists bisca_username_format;
alter table public.bisca_profiles add constraint bisca_username_format
check (username is null or username ~ '^[A-Za-z0-9_.]{3,24}$') not valid;
-- Non richiede unicita': l'identificatore univoco rimane public_id.
-- Nessun permesso aggiunto per crediti, XP, vittorie o inventario.
commit;

-- ESEGUIRE MANUALMENTE nel SQL Editor come postgres. NON applicato dal gioco.
-- Richiede le tabelle ESISTENTI descritte in SHOP.md. Non ricrea nessuna tabella.
-- Rivedere prima eventuali grant/policy personalizzati. Gli altri trigger restano.
begin;

-- Fallisce prima di installare un trigger che potrebbe bloccare nuovi signup.
do $$
begin
  if not exists (select 1 from public.bisca_items where id = 'deck_back_1' and item_type is not null) then
    raise exception 'Manca deck_back_1 nel catalogo: aggiungerlo prima di questa migrazione';
  end if;
end $$;
update public.bisca_items set price = 0, is_default = true, asset_id = 1
where id = 'deck_back_1';

-- Revoca anche eventuali privilegi A LIVELLO COLONNA: revocare solo quelli
-- di tabella non basta. Non tocca service_role, usato esclusivamente sul server.
do $$
declare t text; c record;
begin
  foreach t in array array['bisca_profiles','bisca_items','bisca_inventory','bisca_season_progress'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all privileges on table public.%I from public, anon, authenticated', t);
    for c in select column_name from information_schema.columns
      where table_schema = 'public' and table_name = t loop
      execute format('revoke all privileges (%I) on table public.%I from public, anon, authenticated', c.column_name, t);
    end loop;
    execute format('grant select on table public.%I to authenticated', t);
  end loop;
end $$;

-- AccountProfile puo' ancora creare la propria riga e aggiornare SOLO il mazzo.
grant insert (id, deck_back, deck_front) on public.bisca_profiles to authenticated;
grant update (deck_back, deck_front) on public.bisca_profiles to authenticated;
drop policy if exists bisca_shop_profile_allow on public.bisca_profiles;
create policy bisca_shop_profile_allow on public.bisca_profiles for all to authenticated
using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
drop policy if exists bisca_shop_profile_guard on public.bisca_profiles;
create policy bisca_shop_profile_guard on public.bisca_profiles as restrictive for all to authenticated
using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

-- Catalogo leggibile dagli utenti autenticati, inclusi gli ospiti Supabase.
drop policy if exists bisca_shop_catalog_read on public.bisca_items;
create policy bisca_shop_catalog_read on public.bisca_items for select to authenticated using (true);

-- Policy restrittive: eventuali vecchie policy permissive non aprono dati altrui.
drop policy if exists bisca_shop_inventory_read on public.bisca_inventory;
create policy bisca_shop_inventory_read on public.bisca_inventory for select to authenticated
using ((select auth.uid()) = user_id);
drop policy if exists bisca_shop_inventory_guard on public.bisca_inventory;
create policy bisca_shop_inventory_guard on public.bisca_inventory as restrictive for select to authenticated
using ((select auth.uid()) = user_id);
drop policy if exists bisca_shop_season_read on public.bisca_season_progress;
create policy bisca_shop_season_read on public.bisca_season_progress for select to authenticated
using ((select auth.uid()) = user_id);
drop policy if exists bisca_shop_season_guard on public.bisca_season_progress;
create policy bisca_shop_season_guard on public.bisca_season_progress as restrictive for select to authenticated
using ((select auth.uid()) = user_id);

-- Assegnazione SERVER-SIDE. Nessuna RPC di grant esposta al client.
create or replace function public.bisca_grant_default_back_on_signup()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.bisca_inventory (user_id, item_id, item_type)
  select new.id, id, item_type from public.bisca_items where id = 'deck_back_1'
  on conflict (user_id, item_id) do nothing;
  return new;
end;
$$;
revoke all on function public.bisca_grant_default_back_on_signup() from public, anon, authenticated;
drop trigger if exists bisca_shop_default_back on auth.users;
create trigger bisca_shop_default_back after insert on auth.users
for each row execute function public.bisca_grant_default_back_on_signup();

-- Backfill una volta per UID, anche per i guest gia' presenti. Ripetibile.
insert into public.bisca_inventory (user_id, item_id, item_type)
select u.id, i.id, i.item_type from auth.users u
cross join public.bisca_items i where i.id = 'deck_back_1'
on conflict (user_id, item_id) do nothing;
commit;

-- Non rimuovere il default dal catalogo/inventario tramite operazioni amministrative.
-- La conversione email modifica auth.users, NON crea un nuovo UID: nessun duplicato.
-- Non protegge da vecchie RPC SECURITY DEFINER insicure: revisionarle separatamente.

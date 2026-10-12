-- Catalogo completo: 12 dorsi, 32 avatar (incluso Special), 9 lanciabili.
-- Indici lanciabili ZERO-based: non riordinare throw_catalog.gd.
-- Ripetibile; non revoca acquisti e non modifica saldi o statistiche.
begin;
insert into public.bisca_items(id,name,item_type,asset_id,price,rarity,is_available,is_default)
select 'deck_back_' || n, 'Dorso ' || n, 'deck_back', n,
       case when n=1 then 0 else 500 end, 'common', true, n=1
from generate_series(1,12) n
on conflict(id) do update set item_type=excluded.item_type,asset_id=excluded.asset_id,
  price=excluded.price,is_default=excluded.is_default,is_available=true;

insert into public.bisca_items(id,name,item_type,asset_id,price,rarity,is_available,is_default)
select 'avatar_' || n, case when n=32 then 'Avatar Special' else 'Avatar ' || n end,
       'avatar', n, case when n=1 then 0 else 100 end, 'common', true, n=1
from generate_series(1,32) n
on conflict(id) do update set item_type=excluded.item_type,asset_id=excluded.asset_id,
  price=excluded.price,is_default=excluded.is_default,is_available=true;

insert into public.bisca_items(id,name,item_type,asset_id,price,rarity,is_available,is_default)
select 'throw_' || filename, initcap(filename), 'throwable', asset,
       case when filename='pomodoro' then 0 else 200 end, 'common', true, filename='pomodoro'
from (values (0,'poop'),(1,'gay'),(2,'fazzoletti'),(3,'cry'),(4,'sorry'),
             (5,'clown'),(6,'angry'),(7,'pollo'),(8,'pomodoro')) as objects(asset,filename)
on conflict(id) do update set item_type=excluded.item_type,asset_id=excluded.asset_id,
  price=excluded.price,is_default=excluded.is_default,is_available=true;

-- Mantiene il trigger esistente; cambia la dotazione da un dorso a tre oggetti.
create or replace function public.bisca_grant_default_back_on_signup()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.bisca_inventory(user_id,item_id,item_type)
  select new.id,id,item_type from public.bisca_items
  where id in ('deck_back_1','avatar_1','throw_pomodoro')
  on conflict(user_id,item_id) do nothing;
  return new;
end;
$$;
revoke all on function public.bisca_grant_default_back_on_signup() from public,anon,authenticated;
drop trigger if exists bisca_shop_default_back on auth.users;
create trigger bisca_shop_default_back after insert on auth.users
for each row execute function public.bisca_grant_default_back_on_signup();

insert into public.bisca_inventory(user_id,item_id,item_type)
select u.id,i.id,i.item_type from auth.users u cross join public.bisca_items i
where i.id in ('deck_back_1','avatar_1','throw_pomodoro')
on conflict(user_id,item_id) do nothing;

-- Terzo front ritirato: converti al secondo front, anche per vecchi client
-- che conservano una preferenza offline non ancora sincronizzata.
update public.bisca_profiles set deck_front=1 where deck_front=2;
create or replace function public.bisca_normalize_retired_front()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.deck_front=2 then new.deck_front:=1; end if;
  return new;
end;
$$;
revoke all on function public.bisca_normalize_retired_front() from public,anon,authenticated;
drop trigger if exists bisca_retired_front on public.bisca_profiles;
create trigger bisca_retired_front before insert or update of deck_front on public.bisca_profiles
for each row execute function public.bisca_normalize_retired_front();
alter table public.bisca_profiles drop constraint if exists bisca_profiles_deck_front_check;
alter table public.bisca_profiles add constraint bisca_profiles_deck_front_check check(deck_front between 0 and 1);
commit;

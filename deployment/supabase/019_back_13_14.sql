-- Estende il catalogo senza modificare inventari, saldi o dorsi esistenti.
begin;
insert into public.bisca_items(id,name,item_type,asset_id,price,rarity,is_available,is_default)
values ('deck_back_13','Dorso 13','deck_back',13,500,'common',true,false),
       ('deck_back_14','Dorso 14','deck_back',14,500,'common',true,false)
on conflict(id) do update set item_type=excluded.item_type,asset_id=excluded.asset_id,
  price=excluded.price,is_available=true,is_default=false;
alter table public.bisca_profiles drop constraint if exists bisca_profiles_deck_back_check;
alter table public.bisca_profiles add constraint bisca_profiles_deck_back_check
  check(deck_back between 1 and 14);
commit;

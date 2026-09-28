-- Eseguire nel SQL Editor dopo 002. Nessun credito di test viene assegnato.
begin;
create or replace function public.bisca_purchase_item(p_item_id text, p_expected_price bigint)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  buyer uuid := auth.uid();
  balance bigint;
  product public.bisca_items%rowtype;
  inserted_count integer;
begin
  if buyer is null then raise exception 'AUTH_REQUIRED'; end if;
  -- Serializza tutti gli acquisti dello stesso account, anche da dispositivi diversi.
  select credits into balance from public.bisca_profiles where id = buyer for update;
  if not found or balance is null then raise exception 'PROFILE_NOT_READY'; end if;
  select * into product from public.bisca_items where id = p_item_id for share;
  if not found then raise exception 'ITEM_NOT_FOUND'; end if;
  if exists (select 1 from public.bisca_inventory where user_id = buyer and item_id = p_item_id) then
    return jsonb_build_object('user_id', buyer, 'credits', balance::text, 'already_owned', true);
  end if;
  if product.is_available is distinct from true or product.price is null or product.price < 0 then
    raise exception 'ITEM_UNAVAILABLE';
  end if;
  if p_expected_price is distinct from product.price then raise exception 'PRICE_CHANGED'; end if;
  if balance < product.price then raise exception 'INSUFFICIENT_CREDITS'; end if;
  insert into public.bisca_inventory(user_id, item_id, item_type)
  values (buyer, product.id, product.item_type)
  on conflict (user_id, item_id) do nothing;
  get diagnostics inserted_count = row_count;
  if inserted_count = 1 then
    update public.bisca_profiles set credits = credits - product.price where id = buyer
    returning credits into balance;
  end if;
  return jsonb_build_object('user_id', buyer, 'credits', balance::text, 'already_owned', inserted_count = 0);
end;
$$;
revoke all on function public.bisca_purchase_item(text, bigint) from public, anon;
grant execute on function public.bisca_purchase_item(text, bigint) to authenticated;
commit;

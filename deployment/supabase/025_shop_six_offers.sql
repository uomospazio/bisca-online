-- Apply after 024. Six offers, 2 per category, and +50 coins for shop ads.
-- Existing inventories/prices are unchanged. Test-ad restrictions remain in place.
begin;
create function public.bisca_pick_shop(p_previous text[] default array[]::text[])
returns text[] language plpgsql security definer set search_path='' as $$
declare category text; picked text[]; result text[]:=array[]::text[];
begin
 foreach category in array array['deck_back','avatar','throwable'] loop
  select array_agg(id) into picked from (
   select id from public.bisca_items where item_type=category and is_available and not is_default
   order by (id=any(p_previous)),random() limit 2
  ) choices;
  if coalesce(cardinality(picked),0)<>2 then raise exception 'SHOP_CATEGORY_INCOMPLETE: %',category; end if;
  result:=result||picked;
 end loop;
 return result;
end $$;
create function public.bisca_valid_shop(p_items text[]) returns boolean
language sql security definer set search_path='' as $$
 select coalesce(cardinality(p_items)=6 and
  (select count(*)=6 from public.bisca_items where id=any(p_items) and is_available and not is_default) and
  (select count(*)=3 from (
   select item_type from public.bisca_items where id=any(p_items) and item_type in ('deck_back','avatar','throwable')
   group by item_type having count(*)=2
  ) groups),false);
$$;
create or replace function public.bisca_daily_shop() returns jsonb
language plpgsql security definer set search_path='' as $$
declare today date := (statement_timestamp() at time zone 'UTC')::date;
 selected text[]; personal boolean; seconds integer;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 perform pg_advisory_xact_lock(724019,today-date '2020-01-01');
 select items into selected from public.bisca_personal_offers where user_id=auth.uid() and day=today;
 personal:=found;
 if personal then
  if not public.bisca_valid_shop(selected) then
   selected:=public.bisca_pick_shop();
   update public.bisca_personal_offers set items=selected where user_id=auth.uid() and day=today;
  end if;
 else
  select items into selected from public.bisca_daily_offers where day=today;
  if not public.bisca_valid_shop(selected) then
   selected:=public.bisca_pick_shop();
   insert into public.bisca_daily_offers(day,items) values(today,selected)
   on conflict(day) do update set items=excluded.items;
  end if;
 end if;
 seconds:=greatest(1,ceil(extract(epoch from ((today+1)::timestamp at time zone 'UTC')-statement_timestamp()))::integer);
 return jsonb_build_object('items',selected,'refresh_after',seconds,'refresh_available',not personal);
end $$;
create or replace function public.bisca_claim_test_ad_internal(p_claim uuid, p_placement text, p_context text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid();
  today date := (statement_timestamp() at time zone 'UTC')::date;
  previous public.bisca_ad_claims%rowtype;
  reward integer;
  balance integer;
  old_items text[];
  selected text[];
begin
  if u is null then raise exception 'AUTH_REQUIRED'; end if;
  -- Il lock sul profilo serializza doppie richieste e cambi saldo concorrenti.
  select p.credits into balance from public.bisca_profiles p where p.id=u for update;
  if not found then raise exception 'PROFILE_NOT_READY'; end if;
  select * into previous from public.bisca_ad_claims c where c.claim_id=p_claim;
  if found then
    if previous.user_id<>u or previous.placement<>p_placement or previous.context<>p_context then raise exception 'INVALID_CLAIM'; end if;
    return jsonb_build_object('ok',true,'credits',balance,'amount',previous.amount);
  end if;
  perform public.bisca_ad_test_eligible(p_placement,p_context);
  reward := case p_placement when 'shop' then 50 when 'solo' then 30 when 'multi' then 50 else 0 end;
  if p_placement='refresh' then
    select array(select jsonb_array_elements_text(public.bisca_daily_shop()->'items')) into old_items;
    selected := public.bisca_pick_shop(old_items);
    insert into public.bisca_personal_offers(user_id,day,items) values(u,today,selected);
  end if;
  insert into public.bisca_ad_claims(claim_id,user_id,placement,context,amount) values(p_claim,u,p_placement,p_context,reward);
  update public.bisca_profiles set credits=credits+reward where id=u returning credits into balance;
  return jsonb_build_object('ok',true,'credits',balance,'amount',reward);
end;
$$;

-- Keep 022's public wrapper: it takes the seasonal lock before the profile lock.
revoke all on function public.bisca_pick_shop(text[]),public.bisca_valid_shop(text[]),public.bisca_claim_test_ad_internal(uuid,text,text) from public,anon,authenticated;
revoke all on function public.bisca_daily_shop() from public,anon;
grant execute on function public.bisca_daily_shop() to authenticated;
commit;


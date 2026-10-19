-- Shop days run from 19:00 Europe/Rome to the following local 19:00.
begin;
create function public.bisca_shop_day(p_at timestamptz) returns date
language sql stable set search_path='' as $$
 select ((p_at at time zone 'Europe/Rome')-interval '19 hours')::date;
$$;
create function public.bisca_shop_next_reset(p_at timestamptz) returns timestamptz
language sql stable set search_path='' as $$
 select ((public.bisca_shop_day(p_at)+1)+time '19:00') at time zone 'Europe/Rome';
$$;
revoke all on function public.bisca_shop_day(timestamptz),public.bisca_shop_next_reset(timestamptz) from public,anon,authenticated;

-- Preserve the reward/offer algorithms and ACLs; change only the time boundary.
do $$
declare signature text; definition text; updated text;
begin
 foreach signature in array array[
  'public.bisca_daily_shop()',
  'public.bisca_claim_test_ad_before_wheel(uuid,text,text)',
  'public.bisca_ad_test_eligible(text,text)'
 ] loop
  definition:=pg_get_functiondef(signature::regprocedure);
  updated:=replace(definition,'(statement_timestamp() at time zone ''UTC'')::date','public.bisca_shop_day(statement_timestamp())');
  updated:=replace(updated,'(now() at time zone ''UTC'')::date','public.bisca_shop_day(statement_timestamp())');
  updated:=replace(updated,'((today+1)::timestamp at time zone ''UTC'')','public.bisca_shop_next_reset(statement_timestamp())');
  if updated=definition and position('bisca_shop_day' in definition)=0 then
   raise exception 'Unexpected shop function: %',signature;
  end if;
  execute updated;
 end loop;
end $$;
commit;

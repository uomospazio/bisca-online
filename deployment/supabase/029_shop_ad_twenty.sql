-- After 028. Only new shop-video rewards change; existing receipts are preserved.
begin;
do $$
declare definition text;
begin
 definition:=pg_get_functiondef('public.bisca_claim_test_ad_before_wheel(uuid,text,text)'::regprocedure);
 if position('when ''shop'' then 50' in definition)>0 then
  execute replace(definition,'when ''shop'' then 50','when ''shop'' then 20');
 elsif position('when ''shop'' then 20' in definition)=0 then
  raise exception 'Unexpected shop reward function: migration not applied';
 end if;
end $$;
commit;

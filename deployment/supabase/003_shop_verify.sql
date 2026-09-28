-- Eseguire DOPO 002 nel SQL Editor. Tutte le prove sono annullate con ROLLBACK.
-- Richiede almeno due utenti Auth gia' esistenti (nessun utente creato dal test).
begin;
do $$
declare a uuid; b uuid; n bigint;
begin
  select id into a from auth.users order by id limit 1;
  select id into b from auth.users where id <> a order by id limit 1;
  if a is null or b is null then raise exception 'Servono almeno due utenti Auth per il test'; end if;
  if exists (select 1 from auth.users u where not exists
    (select 1 from public.bisca_inventory i where i.user_id=u.id and i.item_id='deck_back_1')) then
    raise exception 'Backfill default incompleto';
  end if;
  perform set_config('request.jwt.claims', json_build_object('sub',a,'role','authenticated')::text, true);
  set local role authenticated;
  select count(*) into n from public.bisca_inventory where item_id='deck_back_1';
  if n <> 1 then raise exception 'Default non visibile o inventari altrui visibili'; end if;
  if exists(select 1 from public.bisca_inventory where user_id <> a) then raise exception 'RLS inventory'; end if;
  if exists(select 1 from public.bisca_profiles where id <> a) then raise exception 'RLS profiles'; end if;
  if exists(select 1 from public.bisca_season_progress where user_id <> a) then raise exception 'RLS season'; end if;
  if not exists(select 1 from public.bisca_items where id='deck_back_1' and price=0 and is_default) then raise exception 'Catalogo default'; end if;
  -- SQLSTATE 42501 e' l'unico fallimento accettato per queste scritture vietate.
  begin
    insert into public.bisca_inventory(user_id,item_id,item_type) values(a,'deck_back_2','deck_back');
    raise exception 'INSERT inventario consentito!';
  exception when insufficient_privilege then null; end;
  begin
    update public.bisca_profiles set credits=999,xp=999,games_played=999,wins=999 where id=a;
    raise exception 'UPDATE premi consentito!';
  exception when insufficient_privilege then null; end;
  begin
    update public.bisca_season_progress set xp=999,level=999,wins=999 where user_id=a;
    raise exception 'UPDATE stagione consentito!';
  exception when insufficient_privilege then null; end;
  begin
    update public.bisca_items set price=0 where id='deck_back_2';
    raise exception 'UPDATE catalogo consentito!';
  exception when insufficient_privilege then null; end;
  update public.bisca_profiles set deck_back=1 where id=b;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'Modifica profilo altrui consentita!'; end if;
  -- Percorso legittimo di AccountProfile: crea se manca, poi modifica il mazzo.
  insert into public.bisca_profiles(id,deck_back,deck_front) values(a,1,0) on conflict(id) do nothing;
  update public.bisca_profiles set deck_back=1,deck_front=0 where id=a;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'Aggiornamento preferenze proprie bloccato'; end if;
  set local role postgres;
  perform set_config('request.jwt.claims', json_build_object('sub',b,'role','authenticated')::text, true);
  set local role authenticated;
  if exists(select 1 from public.bisca_inventory where user_id <> b) then raise exception 'RLS secondo utente'; end if;
  set local role postgres;
  set local role anon;
  begin
    perform 1 from public.bisca_inventory;
    raise exception 'Lettura non autenticata consentita!';
  exception when insufficient_privilege then null; end;
  set local role postgres;
  raise notice 'PASS: lettura, isolamento account, default, scritture vietate e preferenze';
end $$;
rollback;

-- Audit READ-ONLY delle RPC potenzialmente esposte. Rivedere eventuali funzioni
-- che assegnano crediti/inventario; i grant sulle tabelle non limitano i definer.
select p.oid::regprocedure as function_name
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.prosecdef
and (has_function_privilege('authenticated',p.oid,'EXECUTE')
  or has_function_privilege('anon',p.oid,'EXECUTE'));

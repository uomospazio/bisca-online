-- Eseguire una volta nel SQL Editor. Nessuna modifica a prezzi, inventario o saldo.
-- Sei offerte condivise, congelate alla prima apertura del giorno (UTC).
begin;
create table if not exists public.bisca_daily_offers (
  day date primary key,
  items text[] not null,
  created_at timestamptz not null default now()
);
alter table public.bisca_daily_offers enable row level security;
revoke all on table public.bisca_daily_offers from public, anon, authenticated;

create or replace function public.bisca_daily_shop()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  today date := (statement_timestamp() at time zone 'UTC')::date;
  selected text[];
  seconds integer;
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  -- Lock comune: due utenti simultanei non creano estrazioni diverse.
  perform pg_advisory_xact_lock(724019, today - date '2020-01-01');
  select items into selected from public.bisca_daily_offers where day = today;
  if not found then
    select coalesce(array_agg(id), array[]::text[]) into selected
    from (
      select id from public.bisca_items
      where is_available is true and is_default is false
      order by random() limit 6
    ) offers;
    insert into public.bisca_daily_offers(day, items) values (today, selected);
  end if;
  seconds := greatest(1, ceil(extract(epoch from
    ((today + 1)::timestamp at time zone 'UTC') - statement_timestamp()))::integer);
  return jsonb_build_object('items', selected, 'refresh_after', seconds);
end;
$$;
revoke all on function public.bisca_daily_shop() from public, anon;
grant execute on function public.bisca_daily_shop() to authenticated;
commit;

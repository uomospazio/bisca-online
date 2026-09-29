-- Eseguire manualmente nel SQL Editor. Non espone email, saldo o token.
begin;
create table if not exists public.bisca_friendships (
  user_a uuid references auth.users(id) on delete cascade not null,
  user_b uuid references auth.users(id) on delete cascade not null,
  requester uuid references auth.users(id) on delete cascade not null,
  status text not null default 'pending' check (status in ('pending','accepted')),
  created_at timestamptz not null default now(),
  primary key(user_a,user_b),
  check(user_a < user_b), check(requester in (user_a,user_b))
);
alter table public.bisca_friendships enable row level security;
revoke all on public.bisca_friendships from public, anon, authenticated;

create or replace function public.bisca_search_friends(query text)
returns table(id uuid, username text, public_id text)
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  if length(trim(query)) < 3 then return; end if;
  return query select p.id,p.username,p.public_id from public.bisca_profiles p
  where p.id <> auth.uid() and
  (lower(p.username) = lower(trim(query)) or upper(p.public_id) = upper(ltrim(trim(query),'#')))
  order by p.id limit 20;
end; $$;

create or replace function public.bisca_list_friends()
returns table(id uuid, username text, public_id text, status text, incoming boolean)
language sql security definer set search_path = '' as $$
  select p.id,p.username,p.public_id,f.status,f.requester <> auth.uid()
  from public.bisca_friendships f join public.bisca_profiles p
  on p.id = case when f.user_a = auth.uid() then f.user_b else f.user_a end
  where auth.uid() in (f.user_a,f.user_b) order by f.created_at desc;
$$;

create or replace function public.bisca_friend_action(target uuid, action text)
returns void language plpgsql security definer set search_path = '' as $$
declare me uuid := auth.uid(); a uuid; b uuid;
begin
  if me is null or target = me or target is null then raise exception 'INVALID_TARGET'; end if;
  a := least(me,target); b := greatest(me,target);
  -- Serializza le azioni della stessa coppia, anche quando la riga non esiste ancora.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(a::text || b::text,0));
  if action = 'request' then
    if not exists(select 1 from public.bisca_profiles where id=target) then raise exception 'NOT_FOUND'; end if;
    if (select count(*) from public.bisca_friendships where requester=me and status='pending') >= 50 then
      raise exception 'TOO_MANY_REQUESTS';
    end if;
    insert into public.bisca_friendships(user_a,user_b,requester) values(a,b,me)
    on conflict do nothing;
  elsif action = 'accept' then
    update public.bisca_friendships set status='accepted'
    where user_a=a and user_b=b and requester=target and status='pending';
  elsif action = 'decline' then
    delete from public.bisca_friendships where user_a=a and user_b=b and requester=target and status='pending';
  elsif action = 'cancel' then
    delete from public.bisca_friendships where user_a=a and user_b=b and requester=me and status='pending';
  else raise exception 'INVALID_ACTION';
  end if;
end; $$;
revoke all on function public.bisca_search_friends(text), public.bisca_list_friends(), public.bisca_friend_action(uuid,text) from public,anon;
grant execute on function public.bisca_search_friends(text), public.bisca_list_friends(), public.bisca_friend_action(uuid,text) to authenticated;
commit;

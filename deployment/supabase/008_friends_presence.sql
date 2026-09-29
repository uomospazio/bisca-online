-- Eseguire dopo 006. Presenza leggibile solo dai propri contatti.
begin;
create table if not exists public.bisca_presence (
 user_id uuid primary key references auth.users(id) on delete cascade,
 last_seen timestamptz not null default now()
);
alter table public.bisca_presence enable row level security;
revoke all on public.bisca_presence from public,anon,authenticated;
create or replace function public.bisca_friends_presence()
returns table(id uuid,username text,public_id text,status text,incoming boolean,online boolean)
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 insert into public.bisca_presence(user_id,last_seen) values(auth.uid(),now())
 on conflict(user_id) do update set last_seen=excluded.last_seen;
 return query select p.id,p.username,p.public_id,f.status,f.requester<>auth.uid(),
 coalesce(pr.last_seen > now()-interval '90 seconds',false)
 from public.bisca_friendships f join public.bisca_profiles p
 on p.id=case when f.user_a=auth.uid() then f.user_b else f.user_a end
 left join public.bisca_presence pr on pr.user_id=p.id
 where auth.uid() in(f.user_a,f.user_b)
 order by (f.status='pending' and f.requester<>auth.uid()) desc,f.created_at desc;
end; $$;
revoke all on function public.bisca_friends_presence() from public,anon;
grant execute on function public.bisca_friends_presence() to authenticated;
commit;

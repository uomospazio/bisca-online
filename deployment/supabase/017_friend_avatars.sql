-- Eseguire nel SQL Editor di Supabase dopo 013_friends_prefix_search.sql.
-- Foto JPEG piccole, accessibili solo attraverso le RPC dei contatti/ricerca.
begin;
create table if not exists public.bisca_profile_avatars (
 user_id uuid primary key references auth.users(id) on delete cascade,
 avatar text not null,
 updated_at timestamptz not null default now()
);
alter table public.bisca_profile_avatars enable row level security;
revoke all on public.bisca_profile_avatars from public, anon, authenticated;

create or replace function public.bisca_set_profile_avatar(photo text)
returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 if photo is null or length(photo) > 32768 then raise exception 'INVALID_AVATAR'; end if;
 if photo <> '' and (
   length(photo) % 4 <> 0 or photo !~ '^[A-Za-z0-9+/]+={0,2}$'
 ) then raise exception 'INVALID_AVATAR'; end if;
 if photo <> '' and substring(decode(photo,'base64') from 1 for 2) <> decode('ffd8','hex')
 then raise exception 'INVALID_AVATAR'; end if;
 insert into public.bisca_profile_avatars(user_id,avatar) values(auth.uid(),photo)
 on conflict(user_id) do update set avatar=excluded.avatar,updated_at=now();
end; $$;

-- Wrapper: mantiene filtri, autorizzazioni e aggiornamento presenza originali.
create or replace function public.bisca_friends_presence_with_avatars()
returns table(id uuid,username text,public_id text,status text,incoming boolean,online boolean,avatar text)
language sql security definer set search_path='' as $$
 select f.*, coalesce(a.avatar,'')
 from public.bisca_friends_presence() f
 left join public.bisca_profile_avatars a on a.user_id=f.id;
$$;
create or replace function public.bisca_search_friends_with_avatars(query text)
returns table(id uuid,username text,public_id text,avatar text)
language sql security definer set search_path='' as $$
 select f.*, coalesce(a.avatar,'')
 from public.bisca_search_friends(query) f
 left join public.bisca_profile_avatars a on a.user_id=f.id;
$$;
revoke all on function public.bisca_set_profile_avatar(text), public.bisca_friends_presence_with_avatars(), public.bisca_search_friends_with_avatars(text) from public,anon;
grant execute on function public.bisca_set_profile_avatar(text), public.bisca_friends_presence_with_avatars(), public.bisca_search_friends_with_avatars(text) to authenticated;
commit;

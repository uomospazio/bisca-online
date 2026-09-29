-- Eseguire dopo 006 e 008. Inviti tra amici, scadenza 10 minuti.
begin;
create table if not exists public.bisca_lobby_invites (
 sender uuid references auth.users(id) on delete cascade,
 recipient uuid references auth.users(id) on delete cascade,
 room_code text not null check(room_code ~ '^[A-Z0-9]{6}$'),
 expires_at timestamptz not null,
 primary key(sender,recipient), check(sender<>recipient)
);
alter table public.bisca_lobby_invites enable row level security;
revoke all on public.bisca_lobby_invites from public,anon,authenticated;
create or replace function public.bisca_invite_friend(target uuid, code text)
returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not exists(select 1 from public.bisca_friendships
 where user_a=least(auth.uid(),target) and user_b=greatest(auth.uid(),target) and status='accepted') then
 raise exception 'FRIENDS_ONLY'; end if;
 insert into public.bisca_lobby_invites values(auth.uid(),target,upper(trim(code)),now()+interval '10 minutes')
 on conflict(sender,recipient) do update set room_code=excluded.room_code,expires_at=excluded.expires_at;
end; $$;
create or replace function public.bisca_list_invites()
returns table(sender uuid, room_code text) language sql security definer set search_path='' as $$
 select i.sender,i.room_code from public.bisca_lobby_invites i
 where i.recipient=auth.uid() and i.expires_at>now();
$$;
create or replace function public.bisca_answer_invite(from_user uuid, accept boolean)
returns text language plpgsql security definer set search_path='' as $$
declare code text;
begin
 delete from public.bisca_lobby_invites where recipient=auth.uid() and sender=from_user
 and expires_at>now() returning room_code into code;
 if code is null then raise exception 'INVITE_EXPIRED'; end if;
 return case when accept then code else null end;
end; $$;
revoke all on function public.bisca_invite_friend(uuid,text),public.bisca_list_invites(),public.bisca_answer_invite(uuid,boolean) from public,anon;
grant execute on function public.bisca_invite_friend(uuid,text),public.bisca_list_invites(),public.bisca_answer_invite(uuid,boolean) to authenticated;
commit;

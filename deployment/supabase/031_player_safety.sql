begin;
create table public.bisca_player_reports (
 id uuid primary key default gen_random_uuid(), reporter uuid references auth.users on delete set null,
 target uuid references auth.users on delete set null, category text not null check(category in ('voice','profile','other')),
 displayed_name text not null, room_code text not null, created_at timestamptz not null default now(),
 reviewed_at timestamptz
);
create table public.bisca_player_blocks (
 owner_id uuid references auth.users on delete cascade, target_id uuid references auth.users on delete cascade,
 primary key(owner_id,target_id), check(owner_id<>target_id)
);
alter table public.bisca_player_reports enable row level security;
alter table public.bisca_player_blocks enable row level security;
revoke all on public.bisca_player_reports,public.bisca_player_blocks from public,anon,authenticated;
create function public.bisca_report_player(target uuid, category text, displayed_name text, room_code text) returns void
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or auth.uid()=target or target is null then raise exception 'INVALID_TARGET'; end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,31));
 if (select count(*) from public.bisca_player_reports r where r.reporter=auth.uid() and r.created_at>now()-interval '1 hour')>=15 then raise exception 'REPORT_LIMIT'; end if;
 insert into public.bisca_player_reports(reporter,target,category,displayed_name,room_code)
 values(auth.uid(),target,category,left(displayed_name,32),left(room_code,12));
end $$;
create function public.bisca_block_player(target uuid) returns void
language plpgsql security definer set search_path='' as $$
declare a uuid:=least(auth.uid(),target); b uuid:=greatest(auth.uid(),target);
begin
 if auth.uid() is null or auth.uid()=target or target is null then raise exception 'INVALID_TARGET'; end if;
 perform pg_advisory_xact_lock(hashtextextended(a::text||b::text,0));
 insert into public.bisca_player_blocks values(auth.uid(),target) on conflict do nothing;
 delete from public.bisca_friendships where user_a=a and user_b=b;
 delete from public.bisca_lobby_invites where least(sender,recipient)=a and greatest(sender,recipient)=b;
end $$;
create function public.bisca_list_blocks() returns table(id uuid)
language sql security definer set search_path='' as $$
 select target_id from public.bisca_player_blocks where owner_id=auth.uid()
$$;
create function public.bisca_guard_blocked_pair() returns trigger language plpgsql security definer set search_path='' as $$
declare a uuid; b uuid;
begin
 if tg_table_name='bisca_friendships' then a:=new.user_a; b:=new.user_b;
 else a:=least(new.sender,new.recipient); b:=greatest(new.sender,new.recipient); end if;
 perform pg_advisory_xact_lock(hashtextextended(a::text||b::text,0));
 if exists(select 1 from public.bisca_player_blocks where (owner_id=a and target_id=b) or (owner_id=b and target_id=a)) then raise exception 'CONTACT_UNAVAILABLE'; end if;
 return new;
end $$;
create trigger bisca_guard_friend before insert or update on public.bisca_friendships for each row execute function public.bisca_guard_blocked_pair();
create trigger bisca_guard_invite before insert or update on public.bisca_lobby_invites for each row execute function public.bisca_guard_blocked_pair();
revoke all on function public.bisca_guard_blocked_pair(),public.bisca_report_player(uuid,text,text,text),public.bisca_block_player(uuid),public.bisca_list_blocks() from public,anon,authenticated;
grant execute on function public.bisca_report_player(uuid,text,text,text),public.bisca_block_player(uuid),public.bisca_list_blocks() to authenticated;
commit;

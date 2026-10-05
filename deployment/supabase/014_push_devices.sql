-- Push token registry. Run manually in Supabase SQL Editor after 009_lobby_invites.sql.
-- Clients can register only their own auth.uid(); tokens are never readable directly.
begin;

create table if not exists public.bisca_push_devices (
  device_token text primary key check (length(device_token) between 20 and 4096),
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('android', 'ios')),
  updated_at timestamptz not null default now()
);

alter table public.bisca_push_devices enable row level security;
revoke all on public.bisca_push_devices from public, anon, authenticated;
grant select, delete on public.bisca_push_devices to service_role;

create or replace function public.bisca_register_push_device(device_token text, device_platform text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  if device_token is null or length(device_token) < 20 or length(device_token) > 4096 then
    raise exception 'INVALID_DEVICE_TOKEN';
  end if;
  if device_platform not in ('android', 'ios') then raise exception 'INVALID_PLATFORM'; end if;

  -- A token's owner is taken from the signed-in session, never a client-supplied user id.
  insert into public.bisca_push_devices as current_device (device_token, user_id, platform)
  values ($1, auth.uid(), $2)
  on conflict (device_token) do update set
    user_id = excluded.user_id,
    platform = excluded.platform,
    updated_at = now();
end;
$$;

create or replace function public.bisca_unregister_push_device(device_token text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  delete from public.bisca_push_devices where device_token = $1 and user_id = auth.uid();
end;
$$;

revoke all on function public.bisca_register_push_device(text, text), public.bisca_unregister_push_device(text) from public, anon;
grant execute on function public.bisca_register_push_device(text, text), public.bisca_unregister_push_device(text) to authenticated;

commit;

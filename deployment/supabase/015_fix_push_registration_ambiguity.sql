-- Fix HTTP 400 / PostgreSQL 42702 when registering an FCM token.
-- Run in Supabase SQL Editor after 014_push_devices.sql.
begin;

create or replace function public.bisca_register_push_device(device_token text, device_platform text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  if device_token is null or length(device_token) < 20 or length(device_token) > 4096 then
    raise exception 'INVALID_DEVICE_TOKEN';
  end if;
  if device_platform not in ('android', 'ios') then raise exception 'INVALID_PLATFORM'; end if;

  insert into public.bisca_push_devices as current_device (device_token, user_id, platform)
  values ($1, auth.uid(), $2)
  on conflict on constraint bisca_push_devices_pkey do update set
    user_id = excluded.user_id,
    platform = excluded.platform,
    updated_at = now();
end;
$$;

revoke all on function public.bisca_register_push_device(text, text) from public, anon;
grant execute on function public.bisca_register_push_device(text, text) to authenticated;

notify pgrst, 'reload schema';

commit;

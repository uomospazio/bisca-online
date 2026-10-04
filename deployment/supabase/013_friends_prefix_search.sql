-- Apply in the Supabase SQL editor after 006_friends.sql.
-- Prefix matching treats %, _ and other characters literally.
begin;
create or replace function public.bisca_search_friends(query text)
returns table(id uuid, username text, public_id text)
language plpgsql security definer set search_path = '' as $$
declare
  term text := lower(trim(query));
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  if length(term) < 2 or length(term) > 64 then return; end if;
  return query
    select p.id, p.username, p.public_id
    from public.bisca_profiles p
    where p.id <> auth.uid() and (
      (left(term, 1) <> '#' and left(lower(p.username), length(term)) = term)
      or upper(p.public_id) = upper(ltrim(term, '#'))
    )
    order by (lower(p.username) = term) desc, lower(p.username), p.id
    limit 20;
end; $$;
revoke all on function public.bisca_search_friends(text) from public, anon;
grant execute on function public.bisca_search_friends(text) to authenticated;
commit;

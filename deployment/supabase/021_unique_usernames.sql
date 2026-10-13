-- Keep GAM on the oldest account. Only the two newer usernames are cleared.
-- Any other duplicate causes the whole transaction to roll back for review.
begin;
lock table public.bisca_profiles in share row exclusive mode;
with ranked as (
  select p.id, row_number() over (order by u.created_at, p.created_at, p.id) as position
  from public.bisca_profiles p
  join auth.users u on u.id = p.id
  where lower(btrim(p.username)) = 'gam'
)
update public.bisca_profiles p set username = null
from ranked r where p.id = r.id and r.position > 1;

create unique index bisca_profiles_username_unique
  on public.bisca_profiles (lower(btrim(username)))
  where username is not null;
commit;

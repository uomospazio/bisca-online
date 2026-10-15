// node deployment/tests/seasons_sql.mjs /path/to/@electric-sql/pglite/dist/index.js
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
const {PGlite} = await import(pathToFileURL(process.argv[2]).href);
const db = new PGlite();
const id = n => `00000000-0000-0000-0000-${String(n).padStart(12,'0')}`;
await db.exec(`
create role anon; create role authenticated; create role service_role;
create schema auth; create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql as $$select '${id(1)}'::uuid$$;
create table public.bisca_profiles(id uuid primary key references auth.users,credits integer default 0,updated_at timestamptz,games_played integer default 0,wins integer default 0,username text,public_id text);
create table public.bisca_profile_avatars(user_id uuid primary key,avatar text);
create table public.bisca_items(id text primary key,is_available boolean,is_default boolean);
create table public.bisca_daily_offers(day date primary key,items text[]);
insert into auth.users values('${id(1)}'),('${id(2)}'),('${id(3)}');
insert into public.bisca_profiles(id,username,public_id) select id,'Player','ABC123' from auth.users;
`);
for (const file of ['010_match_rewards.sql','011_match_statistics.sql','016_rewarded_ads_test.sql','022_seasons.sql'])
  await db.exec(await readFile(new URL('../supabase/'+file,import.meta.url),'utf8'));
await db.exec(`update public.bisca_seasons set starts_at=now()-interval '1 day',ends_at=now()+interval '1 day'`);
async function rpc(name,args=[]) {
  return (await db.query(`select public.${name}(${args.map((_,i)=>'$'+(i+1)).join(',')}) result`,args)).rows[0].result;
}
async function points(user=1) {
  return Number((await db.query('select points from bisca_season_scores where user_id=$1',[id(user)])).rows[0]?.points ?? 0);
}
await assert.rejects(rpc('bisca_claim_test_ad',[id(10),'solo',id(20)]),/TESTER_REQUIRED/);
await db.exec(`insert into bisca_ad_testers values('${id(1)}')`);
let r = await rpc('bisca_claim_test_ad',[id(10),'solo',id(20)]);
assert.equal(r.credits,30); assert.equal(await points(),50,'offline solo needs no recorded result');
await rpc('bisca_claim_test_ad',[id(10),'solo',id(20)]);
assert.equal(await points(),50,'same claim retry is idempotent');
await assert.rejects(rpc('bisca_claim_test_ad',[id(11),'solo',id(20)]),/ALREADY_CLAIMED/);
await rpc('bisca_claim_test_ad',[id(12),'shop','']);
assert.equal(await points(),50,'shop ads do not award seasonal points');
r = await rpc('bisca_record_ranked_match',[id(21),id(1),'victory',true,1,'multi']);
assert.equal(r.season_points,200); assert.equal(await points(),250);
r = await rpc('bisca_record_ranked_match',[id(21),id(1),'victory',true,1,'multi']);
assert.equal(r.season_points,0); assert.equal(await points(),250);
await assert.rejects(rpc('bisca_record_ranked_match',[id(21),id(1),'elimination',true,2,'multi']),/RESULT_CONFLICT/);
await rpc('bisca_record_ranked_match',[id(21),id(2),'elimination',true,2,'multi']);
await rpc('bisca_record_ranked_match',[id(21),id(3),'elimination',true,3,'multi']);
assert.equal(await points(2),100); assert.equal(await points(3),50);
await rpc('bisca_claim_test_ad',[id(13),'multi',id(21)]);
assert.equal(await points(),250,'extra multi ad must not double match points');
await rpc('bisca_record_ranked_match',[id(22),id(1),'victory',false,1,'multi']);
assert.equal(await points(),250,'ineligible match still records stats, not points');
const board = await rpc('bisca_season_board');
assert.equal(board.entries.length,3); assert.equal(board.own.rank,1);
assert.equal(board.stats.games_played,2); assert.equal(board.stats.wins,2);
await db.exec('set role authenticated');
await assert.rejects(rpc('bisca_record_ranked_match',[id(23),id(1),'victory',true,1,'multi']),/permission denied/);
await assert.rejects(rpc('bisca_claim_test_ad_internal',[id(14),'solo',id(24)]),/permission denied/);
await assert.rejects(db.exec('update bisca_season_scores set points=99999'),/permission denied/);
await db.exec('reset role');
await db.exec(`update bisca_seasons set ends_at=now()-interval '1 second'`);
await rpc('bisca_claim_test_ad',[id(15),'solo',id(25)]);
assert.equal(await points(),250,'ended season earns no additional points');
const before = (await db.query('select credits from bisca_profiles where id=$1',[id(1)])).rows[0].credits;
r = await rpc('bisca_settle_seasons'); assert.equal(r.awarded,3);
r = await rpc('bisca_settle_seasons'); assert.equal(r.awarded,0);
assert.equal((await db.query('select credits from bisca_profiles where id=$1',[id(1)])).rows[0].credits,before+5000);
assert.equal((await db.query('select amount from bisca_season_prizes where user_id=$1',[id(2)])).rows[0].amount,2000);
await db.close();
console.log('PASS: seasonal points, offline ad, retries, permissions, stats, deadline, settlement');

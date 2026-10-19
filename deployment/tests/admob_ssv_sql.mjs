import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
const {PGlite}=await import(pathToFileURL(process.argv[2]).href);
const db=new PGlite();
const uid='11111111-1111-1111-1111-111111111111';
await db.exec(`
create role anon; create role authenticated; create role service_role;
create schema auth; create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql as $$select '${uid}'::uuid$$;
create table bisca_profiles(id uuid primary key,credits integer default 0,updated_at timestamptz,games_played integer default 0,wins integer default 0,username text,public_id text,deck_front integer default 0 constraint bisca_profiles_deck_front_check check(deck_front between 0 and 1));
create table bisca_items(id text primary key,item_type text,is_available boolean,is_default boolean);
create table bisca_inventory(user_id uuid references bisca_profiles(id),item_id text references bisca_items(id),item_type text,primary key(user_id,item_id));
create table bisca_daily_offers(day date primary key,items text[]);
create table bisca_profile_avatars(user_id uuid,avatar text);
insert into auth.users values('${uid}'); insert into bisca_profiles(id) values('${uid}');
insert into bisca_items select category||'_'||n,category,true,false from unnest(array['deck_back','avatar','throwable']) category cross join generate_series(1,4) n;
insert into bisca_items values('deck_back_13','deck_back',true,false);
`);
for(const file of ['010_match_rewards.sql','011_match_statistics.sql','016_rewarded_ads_test.sql','022_seasons.sql','025_shop_six_offers.sql','026_fortune_wheel.sql','027_match_result_ads.sql','028_admob_ssv.sql'])
 await db.exec(await readFile(new URL('../supabase/'+file,import.meta.url),'utf8'));
await db.exec("update bisca_seasons set starts_at=now()-interval '1 day',ends_at=now()+interval '1 day'");
async function rpc(name,args=[]) {return (await db.query(`select public.${name}(${args.map((_,i)=>'$'+(i+1)).join(',')}) r`,args)).rows[0].r;}
async function begin(placement,context='') {
 await db.exec("update bisca_ad_sessions set created_at=now()-interval '10 seconds'");
 return (await rpc('bisca_begin_ad',[placement,context,'iOS'])).session_id;
}
let n=0;
async function verify(id,unit='7977173220',transaction='tx'+(++n)) {return rpc('bisca_verify_ad',[id,uid,unit,transaction,Date.now()]);}
const s=await begin('shop');
assert.equal((await rpc('bisca_claim_ad',[s])).code,'SSV_PENDING');
await assert.rejects(verify(s,'7155046146'),/INVALID_CALLBACK/);
await verify(s,'7977173220','transaction1');
await verify(s,'7977173220','transaction1');
await assert.rejects(verify(s),/TRANSACTION_CONFLICT/);
assert.equal((await rpc('bisca_begin_ad',['wheel','','iOS'])).recover,true);
let r=await rpc('bisca_claim_ad',[s]);assert.equal(r.amount,50);assert.equal(r.credits,50);
assert.deepEqual(await rpc('bisca_claim_ad',[s]),r);
await db.exec(await readFile(new URL('../supabase/029_shop_ad_twenty.sql',import.meta.url),'utf8'));
await db.exec(await readFile(new URL('../supabase/030_shop_rome_reset.sql',import.meta.url),'utf8'));
for(const [at,day,next] of [
 ['2026-01-10T17:59:59Z','2026-01-09','2026-01-10T18:00:00Z'],
 ['2026-01-10T18:00:00Z','2026-01-10','2026-01-11T18:00:00Z'],
 ['2026-07-10T16:59:59Z','2026-07-09','2026-07-10T17:00:00Z'],
 ['2026-07-10T17:00:00Z','2026-07-10','2026-07-11T17:00:00Z'],
 ['2026-03-28T18:00:00Z','2026-03-28','2026-03-29T17:00:00Z'],
 ['2026-10-24T17:00:00Z','2026-10-24','2026-10-25T18:00:00Z']
]) {
 const row=(await db.query('select bisca_shop_day($1)::text as day, extract(epoch from bisca_shop_next_reset($1)) as seconds',[at])).rows[0];
 assert.equal(row.day,day);assert.equal(Number(row.seconds),Date.parse(next)/1000);
}
const offers=await rpc('bisca_daily_shop');
const expectedSeconds=Number((await db.query('select ceil(extract(epoch from bisca_shop_next_reset(statement_timestamp())-statement_timestamp())) seconds')).rows[0].seconds);
assert.ok(Math.abs(offers.refresh_after-expectedSeconds)<=1,'Countdown matches Rome reset');
assert.deepEqual(await rpc('bisca_claim_ad',[s]),r,'Already granted 50-coin receipts stay unchanged');
const newShop=await begin('shop');await verify(newShop);
r=await rpc('bisca_claim_ad',[newShop]);assert.equal(r.amount,20);assert.equal(r.credits,70);
assert.deepEqual(await rpc('bisca_claim_ad',[newShop]),r,'20-coin reward is idempotent');
const solo=await begin('solo','offline-match');await verify(solo);
r=await rpc('bisca_claim_ad',[solo]);assert.equal(r.amount,30);assert.equal(r.season_points,50);
await assert.rejects(begin('solo','offline-match'),/ALREADY_CLAIMED/);
const refresh=await begin('refresh');await verify(refresh);assert.equal((await rpc('bisca_claim_ad',[refresh])).amount,0);
assert.equal((await db.query('select day=bisca_shop_day(statement_timestamp()) correct from bisca_personal_offers')).rows[0].correct,true);
await assert.rejects(begin('refresh'),/DAILY_REFRESH_USED/);
await assert.rejects(begin('multi','fake-match'),/MATCH_NOT_RECORDED/);
await assert.rejects(begin('multi_final','fake-match'),/MATCH_NOT_RECORDED/);
const wheel=await begin('wheel');
await assert.rejects(verify(wheel,'7977173220','transaction1'),/unique/);
await verify(wheel);r=await rpc('bisca_claim_ad',[wheel]);assert.ok(r.outcome);assert.deepEqual(await rpc('bisca_claim_ad',[wheel]),r);
const expired=await begin('shop');
await db.exec(`update bisca_ad_sessions set expires_at=now()-interval '1 second' where id='${expired}'`);
await assert.rejects(verify(expired),/INVALID_TIMESTAMP/);
await db.exec('set role authenticated');
for(const fn of ['bisca_claim_test_ad','bisca_claim_test_ad_internal','bisca_claim_ad_before_results','bisca_claim_test_ad_before_wheel'])
 await assert.rejects(rpc(fn,[s,'shop','']),/permission denied/);
await assert.rejects(verify(expired),/permission denied/);
await assert.rejects(db.exec('update bisca_ad_sessions set verified_at=now()'),/permission denied/);
await db.exec('reset role');
await db.exec("create or replace function auth.uid() returns uuid language sql as $$select '22222222-2222-2222-2222-222222222222'::uuid$$");
await assert.rejects(rpc('bisca_claim_ad',[s]),/INVALID_SESSION/);
await db.close();
console.log('PASS: signed-only rewards, ownership, replay, expiry, rates, recovery, coins, XP, wheel, permissions');

// node deployment/tests/shop_rotation_sql.mjs /path/to/pglite/dist/index.js
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
const {PGlite}=await import(pathToFileURL(process.argv[2]).href);
const db=new PGlite();
const uid='11111111-1111-1111-1111-111111111111';
const id=n=>`00000000-0000-0000-0000-${String(n).padStart(12,'0')}`;
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
 insert into bisca_items values('default','avatar',true,true),('disabled','deck_back',false,false);
`);

for(const file of ['010_match_rewards.sql','011_match_statistics.sql','016_rewarded_ads_test.sql','022_seasons.sql','025_shop_six_offers.sql','026_fortune_wheel.sql'])
 await db.exec(await readFile(new URL('../supabase/'+file,import.meta.url),'utf8'));
async function rpc(name,args=[]){return (await db.query(`select public.${name}(${args.map((_,i)=>'$'+(i+1)).join(',')}) r`,args)).rows[0].r;}
const counts=(await db.query("select bisca_wheel_outcome(n) outcome,count(*)::int n from generate_series(0,9999)n group by 1")).rows;
assert.deepEqual(Object.fromEntries(counts.map(x=>[x.outcome,x.n])),{crown:200,coins_5000:200,coins_1000:700,coins_50:1400,tomato:2500,poop:2500,tissues:2500});
await assert.rejects(rpc('bisca_wheel_outcome',[-1]),/INVALID_ROLL/);
await assert.rejects(rpc('bisca_claim_test_ad',[id(1),'wheel','']),/TESTER_REQUIRED/);
await assert.rejects(db.exec("update bisca_profiles set deck_front=3"),/GOLD_DECK_REQUIRED/);
await assert.rejects(db.exec("update bisca_items set is_available=true where id='deck_back_13'"),/bisca_gold_wheel_exclusive/);
await db.exec(`insert into bisca_ad_testers values('${uid}')`);
let total=0,serial=1;
for(const [outcome,amount] of [['crown',0],['coins_5000',5000],['coins_1000',1000],['coins_50',50],['tomato',0],['poop',0],['tissues',0],['crown',5000]]){
 // Deterministic DB-only injection, not exposed to any client or deployed.
 await db.exec(`create or replace function public.bisca_wheel_outcome(p_roll integer) returns text language sql immutable as $$select '${outcome}'::text$$`);
 const result=await rpc('bisca_claim_test_ad',[id(serial),'wheel','']); total+=amount;
 assert.equal(result.outcome,outcome);assert.equal(result.amount,amount);assert.equal(result.credits,total);
 assert.equal(result.duplicate,serial===8);
 assert.deepEqual(await rpc('bisca_claim_test_ad',[id(serial),'wheel','']),result,'retry is the SAME result, no reroll or extra credit');
 await assert.rejects(rpc('bisca_claim_test_ad',[id(serial),'shop','']),/INVALID_CLAIM/);
 assert.equal((await db.query('select count(*)::int n from bisca_inventory')).rows[0].n,1,'losing objects grant nothing, gold duplicates once');
 serial++;
}
await db.exec("update bisca_profiles set deck_front=3");
for(let i=0;i<30;i++) assert.ok(!(await rpc('bisca_daily_shop')).items.includes('deck_back_13'));
await db.exec('set role authenticated');
await assert.rejects(rpc('bisca_wheel_outcome',[1]),/permission denied/);
await assert.rejects(rpc('bisca_claim_test_ad_internal',[id(20),'wheel','']),/permission denied/);
await assert.rejects(db.query('select * from bisca_wheel_results'),/permission denied/);
await db.exec('reset role');
await db.close();
console.log('PASS: exact 2/2/7/14/25/25/25 probabilities, atomic rewards, retries, gold access, exclusivity, unlimited spins, tester and RPC permissions');


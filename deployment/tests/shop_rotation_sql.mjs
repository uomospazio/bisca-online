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
 create table bisca_profiles(id uuid primary key,credits integer default 0,updated_at timestamptz,games_played integer default 0,wins integer default 0,username text,public_id text);
 create table bisca_items(id text primary key,item_type text,is_available boolean,is_default boolean);
 create table bisca_daily_offers(day date primary key,items text[]);
 create table bisca_profile_avatars(user_id uuid,avatar text);
 insert into auth.users values('${uid}'); insert into bisca_profiles(id) values('${uid}');
 insert into bisca_items select category||'_'||n,category,true,false from unnest(array['deck_back','avatar','throwable']) category cross join generate_series(1,4) n;
 insert into bisca_items values('default','avatar',true,true),('disabled','deck_back',false,false);
`);
for(const file of ['010_match_rewards.sql','011_match_statistics.sql','016_rewarded_ads_test.sql','022_seasons.sql','025_shop_six_offers.sql'])
 await db.exec(await readFile(new URL('../supabase/'+file,import.meta.url),'utf8'));
async function rpc(name,args=[]){return (await db.query(`select public.${name}(${args.map((_,i)=>'$'+(i+1)).join(',')}) r`,args)).rows[0].r;}
function balanced(items){
 assert.equal(items.length,6);assert.equal(new Set(items).size,6);
 for(const type of ['deck_back','avatar','throwable']) assert.equal(items.filter(x=>x.startsWith(type+'_')).length,2);
 assert.ok(!items.includes('default')&&!items.includes('disabled'));
}
await db.exec(`insert into bisca_daily_offers values((now() at time zone 'UTC')::date,array['avatar_1','avatar_2','avatar_3'])`);
const before=await rpc('bisca_daily_shop');balanced(before.items);
assert.deepEqual((await rpc('bisca_daily_shop')).items,before.items,'global rotation remains stable');
await assert.rejects(rpc('bisca_claim_test_ad',[id(1),'shop','']),/TESTER_REQUIRED/);
await db.exec(`insert into bisca_ad_testers values('${uid}')`);
let result=await rpc('bisca_claim_test_ad',[id(1),'shop','']);assert.equal(result.amount,50);assert.equal(result.credits,50);
result=await rpc('bisca_claim_test_ad',[id(1),'shop','']);assert.equal(result.credits,50);
await rpc('bisca_claim_test_ad',[id(2),'refresh','']);
const after=await rpc('bisca_daily_shop');balanced(after.items);assert.equal(after.refresh_available,false);
assert.ok(after.items.every(x=>!before.items.includes(x)),'reroll favors new items in every category');
await assert.rejects(rpc('bisca_claim_test_ad',[id(3),'refresh','']),/DAILY_REFRESH_USED/);
await rpc('bisca_claim_test_ad',[id(2),'refresh','']);assert.deepEqual((await rpc('bisca_daily_shop')).items,after.items);
await db.exec(`update bisca_personal_offers set items=array['avatar_1','avatar_2','avatar_3']`);
const repaired=await rpc('bisca_daily_shop');balanced(repaired.items);assert.equal(repaired.refresh_available,false,'repair cannot reset daily ad allowance');
await db.exec(`update bisca_items set is_available=false where item_type='throwable'`);
await assert.rejects(rpc('bisca_daily_shop'),/SHOP_CATEGORY_INCOMPLETE/);
await db.exec('set role authenticated');
await assert.rejects(rpc('bisca_pick_shop'),/permission denied/);
await assert.rejects(rpc('bisca_claim_test_ad_internal',[id(4),'shop','']),/permission denied/);
await db.exec('reset role');
await db.close();console.log('PASS: 2/2/2 daily + reroll, legacy cache repair, +50 once, tester restrictions, RLS');

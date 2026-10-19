import { verifyCallback } from './verify.mjs';

let keys = new Map<string, string>();
let fetchedAt = 0;
async function refreshKeys() {
  const response = await fetch('https://www.gstatic.com/admob/reward/verifier-keys.json', {signal: AbortSignal.timeout(10000)});
  if (!response.ok) throw new Error('Key server unavailable');
  const data = await response.json();
  const next = new Map<string, string>();
  for (const key of data.keys ?? []) if (typeof key.pem === 'string') next.set(String(key.keyId), key.pem);
  if (!next.size) throw new Error('No keys');
  keys = next;
  fetchedAt = Date.now();
}
Deno.serve(async (request: Request) => {
  if (request.method !== 'GET') return new Response('Method not allowed', {status:405});
  try {
    // Refresh at least hourly, also on rotation (at most once per minute).
    const key = new URL(request.url).searchParams.get('key_id') ?? '';
    if (Date.now()-fetchedAt>3600000 || (!keys.has(key) && Date.now()-fetchedAt>60000)) await refreshKeys();
  } catch { return new Response('Verification temporarily unavailable', {status:503}); }
  let payload;
  try { payload = verifyCallback(request.url, keys); }
  catch (error) {
    console.warn('SSV rejected:', error instanceof Error ? error.message : 'Invalid callback');
    return new Response('Invalid callback', {status:400});
  }
  if (payload === null) return new Response('OK: configuration verified, no reward granted');
  try {
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const response = await fetch(Deno.env.get('SUPABASE_URL')+'/rest/v1/rpc/bisca_verify_ad', {
      method:'POST', headers:{'Content-Type':'application/json', apikey:serviceKey, Authorization:'Bearer '+serviceKey},
      body:JSON.stringify(payload), signal:AbortSignal.timeout(15000)
    });
    if (!response.ok) return new Response('Callback not recorded', {status:503});
    return new Response('OK');
  } catch { return new Response('Callback temporarily unavailable', {status:503}); }
});

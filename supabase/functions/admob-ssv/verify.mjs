import { verify } from 'node:crypto';
import { Buffer } from 'node:buffer';

// Verify the ORIGINAL encoded query, never a re-serialized URLSearchParams.
export function verifyCallback(url, keys) {
  const query = new URL(url).search.slice(1);
  const match = query.match(/^(.*)&signature=([^&]+)&key_id=(\d+)$/);
  if (!match || query.length > 8192) throw new Error('Invalid signed query');
  const [, content, signature, keyId] = match;
  const params = new URLSearchParams(query);
  const names = [...params.keys()];
  if (new Set(names).size !== names.length) throw new Error('Duplicate parameter');
  const pem = keys.get(keyId);
  if (!pem) throw new Error('Unknown signing key');
  const sig = decodeURIComponent(signature);
  if (!/^[A-Za-z0-9_\-]+=*$/.test(sig) || !verify('sha256', Buffer.from(content), pem, Buffer.from(sig, 'base64url')))
    throw new Error('Invalid signature');
  // AdMob's URL verification tool can omit BOTH optional identity fields.
  // Acknowledge only after signature verification; never call the reward RPC.
  if (!params.get('user_id') && !params.get('custom_data')) return null;
  const unit = params.get('ad_unit')?.replace('ca-app-pub-4798197645196973/', '');
  if (!['7155046146', '7977173220'].includes(unit)) throw new Error('Invalid unit');
  if (params.get('reward_amount') !== '1' || params.get('reward_item') !== 'bisca_reward') throw new Error('Invalid reward');
  const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuid.test(params.get('custom_data') ?? '') || !uuid.test(params.get('user_id') ?? '')) throw new Error('Invalid identity');
  const timestamp = params.get('timestamp') ?? '';
  if (!/^\d{13}$/.test(timestamp)) throw new Error('Invalid timestamp');
  const transaction = params.get('transaction_id') ?? '';
  if (!/^[A-Za-z0-9_-]{1,256}$/.test(transaction)) throw new Error('Invalid transaction');
  return {p_session: params.get('custom_data'), p_user: params.get('user_id'), p_unit: unit,
    p_transaction: transaction, p_timestamp: Number(timestamp)};
}

import { createClient } from "npm:@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const webhookSecret = Deno.env.get("BISCA_PUSH_WEBHOOK_SECRET") ?? "";
const firebaseServiceAccountJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") ?? "";

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

let accessToken = "";
let accessTokenExpiresAt = 0;

function base64Url(value: string | Uint8Array): string {
  const bytes = typeof value === "string" ? new TextEncoder().encode(value) : value;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

async function getFcmAccessToken(serviceAccount: Record<string, string>): Promise<string> {
  if (accessToken && Date.now() < accessTokenExpiresAt - 60_000) return accessToken;

  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64Url(JSON.stringify({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${claims}`;
  const pem = serviceAccount.private_key.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, "");
  const keyBytes = Uint8Array.from(atob(pem), (character) => character.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  ));
  const assertion = `${unsigned}.${base64Url(signature)}`;
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const result = await response.json();
  if (!response.ok || typeof result.access_token !== "string") {
    throw new Error(`FCM OAuth token request failed (${response.status})`);
  }
  accessToken = result.access_token;
  accessTokenExpiresAt = Date.now() + Number(result.expires_in ?? 3600) * 1000;
  return accessToken;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return new Response("Method not allowed", { status: 405 });
  if (!webhookSecret || request.headers.get("x-bisca-webhook-secret") !== webhookSecret) {
    return new Response("Unauthorized", { status: 401 });
  }

  try {
    const event = await request.json();
    const record = event.record ?? {};
    let recipient = "";
    let kind = "";

    if (event.schema === "public" && event.table === "bisca_friendships" && event.type === "INSERT" && record.status === "pending") {
      recipient = record.requester === record.user_a ? record.user_b : record.user_a;
      kind = "friend_request";
    } else if (event.schema === "public" && event.table === "bisca_lobby_invites" && ["INSERT", "UPDATE"].includes(event.type)) {
      if (Date.parse(record.expires_at ?? "") <= Date.now()) return Response.json({ skipped: "expired" });
      recipient = record.recipient ?? "";
      kind = "lobby_invite";
    } else {
      return Response.json({ skipped: "unsupported event" });
    }

    if (!recipient) return new Response("Invalid event", { status: 400 });
    const { data: devices, error } = await supabase
      .from("bisca_push_devices")
      .select("device_token")
      .eq("user_id", recipient);
    if (error) throw error;
    const tokens = (devices ?? []).map((row) => row.device_token as string).filter(Boolean);
    if (tokens.length === 0) return Response.json({ sent: 0 });

    if (!firebaseServiceAccountJson) throw new Error("FCM_SERVICE_ACCOUNT_JSON is not configured");
    const serviceAccount = JSON.parse(firebaseServiceAccountJson);
    const projectId = serviceAccount.project_id;
    if (typeof projectId !== "string" || !projectId) throw new Error("Firebase service account has no project_id");
    const bearer = await getFcmAccessToken(serviceAccount);

    const title = kind === "friend_request" ? "Nuova richiesta di amicizia" : "Invito a una partita";
    const body = kind === "friend_request" ? "Apri BISCA per vedere la richiesta." : "Apri BISCA per vedere l'invito alla lobby.";
    let sent = 0;
    let hadDeliveryFailure = false;
    const invalidTokens: string[] = [];
    for (const token of tokens) {
      const result = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
        method: "POST",
        headers: {
          authorization: `Bearer ${bearer}`,
          "content-type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            data: { kind },
            android: { priority: "HIGH" },
            apns: { payload: { aps: { sound: "default" } } },
          },
        }),
      });
      if (result.ok) {
        sent++;
        continue;
      }
      const responseBody = await result.json().catch(() => ({}));
      if (responseBody?.error?.status === "UNREGISTERED") invalidTokens.push(token);
      else {
        hadDeliveryFailure = true;
        console.error(`FCM send failed (${result.status}, ${responseBody?.error?.status ?? "unknown"})`);
      }
    }
    if (invalidTokens.length) {
      await supabase.from("bisca_push_devices").delete().in("device_token", invalidTokens);
    }
    if (hadDeliveryFailure) return new Response("One or more push deliveries failed", { status: 502 });
    return Response.json({ sent });
  } catch (error) {
    console.error("Push dispatch failed", error);
    return new Response("Push dispatch failed", { status: 500 });
  }
});

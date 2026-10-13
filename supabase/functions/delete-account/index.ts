import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const reply = (status: number, data: object) => new Response(JSON.stringify(data), {
  status, headers: { ...cors, "Content-Type": "application/json", "Cache-Control": "no-store" },
});

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response(null, { headers: cors });
  if (request.method !== "POST") return reply(405, { error: "METHOD_NOT_ALLOWED" });
  const token = request.headers.get("Authorization")?.match(/^Bearer (.+)$/i)?.[1];
  if (!token) return reply(401, { error: "AUTH_REQUIRED" });
  try {
    const body = await request.json();
    // Never accept a target UID from the caller.
    if (body?.confirmation !== "DELETE_MY_ACCOUNT" || Object.keys(body).some(k => k !== "confirmation")) {
      return reply(400, { error: "CONFIRMATION_REQUIRED" });
    }
    const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    // Validate with Auth, not just a decoded or locally cached JWT.
    const { data, error } = await admin.auth.getUser(token);
    if (error || !data.user) return reply(401, { error: "INVALID_SESSION" });
    // Hard delete. Personal tables cascade via migration 020 and existing FKs.
    // Bisca stores profile photos in bisca_profile_avatars, not Storage.
    const deleted = await admin.auth.admin.deleteUser(data.user.id, false);
    if (deleted.error) return reply(500, { error: "DELETE_FAILED" });
    return reply(200, { deleted: true });
  } catch {
    return reply(400, { error: "INVALID_REQUEST" });
  }
});

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Creates a Supabase admin client using the service role key.
 * This client bypasses Row Level Security and should only be used
 * in trusted server-side contexts (Edge Functions).
 */
export function createAdminClient(): SupabaseClient {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  }

  return createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}

/**
 * Creates a Supabase client scoped to the requesting user's JWT.
 * Used when operations should respect Row Level Security.
 */
export function createUserClient(req: Request): SupabaseClient {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (!supabaseUrl || !anonKey) {
    throw new Error("Missing SUPABASE_URL or SUPABASE_ANON_KEY");
  }

  const authHeader = req.headers.get("Authorization");

  return createClient(supabaseUrl, anonKey, {
    global: {
      headers: authHeader ? { Authorization: authHeader } : {},
    },
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}

/**
 * Extracts the authenticated user ID from the request's JWT.
 * Returns null if the user is not authenticated.
 */
export async function getUserId(req: Request): Promise<string | null> {
  const client = createUserClient(req);
  const {
    data: { user },
    error,
  } = await client.auth.getUser();

  if (error || !user) return null;
  return user.id;
}

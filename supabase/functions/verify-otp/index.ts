import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { createAdminClient } from "../_shared/supabase.ts";

serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    if (req.method !== "POST") {
      return errorResponse("Method not allowed", 405);
    }

    const body = await req.json();
    const { phone, otp } = body;

    if (!phone || typeof phone !== "string") {
      return errorResponse("Phone number is required");
    }

    if (!otp || typeof otp !== "string") {
      return errorResponse("OTP is required");
    }

    const supabase = createAdminClient();

    // Look up the OTP record
    const { data: otpRecord, error: lookupError } = await supabase
      .from("otp_codes")
      .select("*")
      .eq("phone", phone)
      .maybeSingle();

    if (lookupError) {
      console.error("OTP lookup error:", lookupError);
      return errorResponse("Failed to verify OTP", 500);
    }

    if (!otpRecord) {
      return errorResponse("Invalid OTP");
    }

    // Check if OTP matches
    if (otpRecord.otp !== otp) {
      return errorResponse("Invalid OTP");
    }

    // Check if OTP is expired
    const expiresAt = new Date(otpRecord.expires_at);
    if (expiresAt < new Date()) {
      // Clean up expired OTP
      await supabase.from("otp_codes").delete().eq("phone", phone);
      return errorResponse("OTP has expired. Please request a new one.");
    }

    // OTP is valid -- sign in or sign up the user via admin auth.
    // First, check if a user with this phone already exists.
    const { data: existingUsers, error: listError } =
      await supabase.auth.admin.listUsers();

    let userId: string | undefined;
    if (!listError && existingUsers?.users) {
      const existing = existingUsers.users.find((u) => u.phone === phone);
      if (existing) {
        userId = existing.id;
      }
    }

    if (!userId) {
      // Create a new user with this phone number
      const { data: newUser, error: createError } =
        await supabase.auth.admin.createUser({
          phone,
          phone_confirm: true,
        });

      if (createError) {
        console.error("User creation error:", createError);
        return errorResponse("Failed to create user account", 500);
      }

      userId = newUser.user.id;

      // Initialize user_stats for the new user
      await supabase.from("user_stats").insert({
        user_id: userId,
        current_streak: 0,
        longest_streak: 0,
        total_editions_completed: 0,
        total_cards_read: 0,
        total_time_seconds: 0,
        total_cards_saved: 0,
        cards_this_week: 0,
        cards_this_month: 0,
        xp_points: 0,
        level: 1,
      });
    }

    // Generate a session for the user
    const { data: sessionData, error: sessionError } =
      await supabase.auth.admin.generateLink({
        type: "magiclink",
        email: `${phone.replace("+", "")}@phone.glintup.app`,
      });

    // Use a different approach: generate tokens directly
    // Since we're using phone auth, we can use the admin API to
    // create a session by updating the user and using signInWithPassword
    // or we can return a custom token.

    // The simplest approach for phone OTP: use Supabase's built-in
    // phone OTP verification which creates a session automatically.
    // But since we're managing OTP ourselves, we'll generate a link.

    // Alternative: Use admin.generateLink won't work for phone.
    // Let's use the admin API to create a session token pair.
    const { data: tokenData, error: tokenError } =
      // deno-lint-ignore no-explicit-any
      await (supabase.auth.admin as any).generateLink({
        type: "magiclink",
        email: `phone_${phone.replace("+", "")}@glintup.app`,
      });

    // Fallback: Sign the user in by generating an invite/recovery link
    // and extracting the token. For a production app, consider using
    // Supabase's native phone auth or a custom JWT.

    // For now, let's use the Supabase admin to directly sign in the user
    // by creating a custom session. This requires the service role key.
    // We'll use the createUser approach with a password-based session.

    // Clean approach: set a temporary password and sign in
    const tempPassword = crypto.randomUUID();

    const { error: updateError } = await supabase.auth.admin.updateUserById(
      userId,
      { password: tempPassword },
    );

    if (updateError) {
      console.error("Password update error:", updateError);
      return errorResponse("Failed to create session", 500);
    }

    // Now sign in with the temporary password to get a session
    const { data: signInData, error: signInError } =
      await supabase.auth.signInWithPassword({
        phone,
        password: tempPassword,
      });

    if (signInError || !signInData.session) {
      console.error("Sign-in error:", signInError);
      return errorResponse("Failed to create session", 500);
    }

    // Delete the used OTP
    await supabase.from("otp_codes").delete().eq("phone", phone);

    return jsonResponse({
      success: true,
      session: {
        access_token: signInData.session.access_token,
        refresh_token: signInData.session.refresh_token,
        expires_in: signInData.session.expires_in,
        token_type: signInData.session.token_type,
        user: {
          id: signInData.session.user.id,
          phone: signInData.session.user.phone,
          created_at: signInData.session.user.created_at,
        },
      },
    });
  } catch (err) {
    console.error("verify-otp error:", err);
    return errorResponse("Internal server error", 500);
  }
});

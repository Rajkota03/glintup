import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { handleCors, jsonResponse, errorResponse } from "../_shared/cors.ts";
import { createAdminClient } from "../_shared/supabase.ts";

const OTP_LENGTH = 6;
const OTP_EXPIRY_MINUTES = 10;

function generateOtp(): string {
  const digits = "0123456789";
  let otp = "";
  for (let i = 0; i < OTP_LENGTH; i++) {
    otp += digits[Math.floor(Math.random() * digits.length)];
  }
  return otp;
}

serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    if (req.method !== "POST") {
      return errorResponse("Method not allowed", 405);
    }

    const body = await req.json();
    const { phone } = body;

    if (!phone || typeof phone !== "string") {
      return errorResponse("Phone number is required");
    }

    // Basic phone validation: must start with + and have at least 10 digits
    const phoneRegex = /^\+\d{10,15}$/;
    if (!phoneRegex.test(phone)) {
      return errorResponse(
        "Invalid phone number. Must include country code, e.g. +919876543210",
      );
    }

    const otp = generateOtp();
    const now = new Date();
    const expiresAt = new Date(now.getTime() + OTP_EXPIRY_MINUTES * 60 * 1000);

    const supabase = createAdminClient();

    // Upsert OTP record keyed by phone number
    const { error: upsertError } = await supabase
      .from("otp_codes")
      .upsert(
        {
          phone,
          otp,
          expires_at: expiresAt.toISOString(),
          created_at: now.toISOString(),
        },
        { onConflict: "phone" },
      );

    if (upsertError) {
      console.error("OTP upsert error:", upsertError);
      return errorResponse("Failed to generate OTP", 500);
    }

    // TODO: Integrate actual SMS provider (Twilio, MSG91, etc.)

    const isDev = Deno.env.get("ENVIRONMENT") !== "production";
    const responseBody: Record<string, unknown> = {
      success: true,
      message: "OTP sent",
    };

    // In development, include the OTP for testing
    if (isDev) {
      responseBody.otp = otp;
    }

    return jsonResponse(responseBody);
  } catch (err) {
    console.error("send-otp error:", err);
    return errorResponse("Internal server error", 500);
  }
});

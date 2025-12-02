// Supabase Edge Function: send-notification
// Sends FCM push notifications when messages are created
// Deploy: supabase functions deploy send-notification
// Set secret: supabase secrets set FCM_SERVICE_ACCOUNT='<json-content>'

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// CORS headers for browser requests
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Get Google OAuth2 access token using service account
async function getAccessToken(serviceAccount: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const expiry = now + 3600; // 1 hour

  // Create JWT header and payload
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: expiry,
  };

  // Base64URL encode
  const encoder = new TextEncoder();
  const toBase64Url = (data: string) =>
    btoa(data).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  const headerB64 = toBase64Url(JSON.stringify(header));
  const payloadB64 = toBase64Url(JSON.stringify(payload));
  const unsignedToken = `${headerB64}.${payloadB64}`;

  // Import private key and sign
  const pemContents = serviceAccount.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");

  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(unsignedToken)
  );

  const signatureB64 = toBase64Url(
    String.fromCharCode(...new Uint8Array(signature))
  );
  const jwt = `${unsignedToken}.${signatureB64}`;

  // Exchange JWT for access token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenData = await tokenResponse.json();
  if (!tokenData.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`);
  }

  return tokenData.access_token;
}

// Send FCM notification
async function sendFcmNotification(
  accessToken: string,
  projectId: string,
  fcmToken: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<boolean> {
  const message = {
    message: {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: data || {},
      android: {
        priority: "high",
        notification: {
          sound: "default",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      webpush: {
        notification: {
          icon: "/icons/icon-192.png",
        },
      },
    },
  };

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(message),
    }
  );

  if (!response.ok) {
    const error = await response.text();
    console.error("FCM send error:", error);
    return false;
  }

  return true;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get service account from secrets
    const serviceAccountJson = Deno.env.get("FCM_SERVICE_ACCOUNT");
    if (!serviceAccountJson) {
      throw new Error("FCM_SERVICE_ACCOUNT secret not configured");
    }
    const serviceAccount = JSON.parse(serviceAccountJson);

    // Get Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse request body
    const { record, type } = await req.json();

    // Only process INSERT events
    if (type !== "INSERT") {
      return new Response(JSON.stringify({ message: "Ignored non-INSERT event" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const message = record;
    console.log("Processing message:", message.id);

    // Determine recipients
    let recipientIds: string[] = [];

    if (message.targetUserId) {
      // Targeted message - send to specific user
      recipientIds = [message.targetUserId];
    } else {
      // Broadcast message - send to all users except sender
      const { data: users, error } = await supabase
        .from("users")
        .select("id")
        .neq("id", message.userId);

      if (error) {
        throw new Error(`Failed to fetch users: ${error.message}`);
      }
      recipientIds = users?.map((u) => u.id) || [];
    }

    if (recipientIds.length === 0) {
      return new Response(JSON.stringify({ message: "No recipients" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get FCM tokens for recipients
    const { data: recipients, error: tokenError } = await supabase
      .from("users")
      .select("id, name, \"fcmToken\"")
      .in("id", recipientIds)
      .not("fcmToken", "is", null);

    if (tokenError) {
      throw new Error(`Failed to fetch FCM tokens: ${tokenError.message}`);
    }

    if (!recipients || recipients.length === 0) {
      return new Response(
        JSON.stringify({ message: "No recipients with FCM tokens" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get access token for FCM
    const accessToken = await getAccessToken(serviceAccount);
    const projectId = serviceAccount.project_id;

    // Build notification content
    const title = message.targetUserId
      ? `Besked fra ${message.userName}`
      : `Ny besked i sag`;
    const body =
      message.text.length > 100
        ? message.text.substring(0, 100) + "..."
        : message.text;

    // Send notifications
    const results = await Promise.allSettled(
      recipients.map((recipient) =>
        sendFcmNotification(accessToken, projectId, recipient.fcmToken, title, body, {
          messageId: message.id,
          sagId: message.sagId || "",
          senderId: message.userId,
        })
      )
    );

    const succeeded = results.filter((r) => r.status === "fulfilled" && r.value).length;
    const failed = results.length - succeeded;

    console.log(`Notifications sent: ${succeeded} succeeded, ${failed} failed`);

    return new Response(
      JSON.stringify({
        success: true,
        sent: succeeded,
        failed: failed,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

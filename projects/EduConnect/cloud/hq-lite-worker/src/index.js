// F:\EduConnect\cloud\hq-lite-worker\src\index.js

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

function jsonResponse(data, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...CORS_HEADERS,
      ...extraHeaders,
    },
  });
}

export default {
  async fetch(request, env, ctx) {
    // --- CORS preflight ------------------------------------------------------
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: CORS_HEADERS,
      });
    }

    const url = new URL(request.url);
    const pathname = url.pathname;

    try {
      // Simple health check
      if (pathname === "/health") {
        return jsonResponse({ ok: true, service: "educonnect-hq-lite" }, 200);
      }

      // ================== ENROLL ENDPOINT ===================================
      if (pathname === "/enroll" && request.method === "POST") {
        let payload;
        try {
          payload = await request.json();
        } catch (e) {
          return jsonResponse(
            { ok: false, error: "Invalid JSON body" },
            400
          );
        }

        const full_name = (payload.full_name || "").toString().trim();
        const email = (payload.email || "").toString().trim();
        const phone = (payload.phone || "").toString().trim();
        const course = (payload.course || "").toString().trim();
        const source = (payload.source || "web").toString().trim();
        const notes = (payload.notes || "").toString().trim();

        // Basic validation
        if (!full_name || !course || (!email && !phone)) {
          return jsonResponse(
            {
              ok: false,
              error: "Missing required fields (full_name, course, email/phone).",
            },
            400
          );
        }

        // ------------- Insert enrollment into Supabase ----------------------
        const enrollmentBody = {
          full_name,
          email,
          phone,
          course,
          source,
          notes,
          status: "new",
        };

        const enrollRes = await fetch(
          `${env.SUPABASE_URL}/rest/v1/enrollments`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              apikey: env.SUPABASE_SERVICE_ROLE_KEY,
              Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
              Prefer: "return=representation",
            },
            body: JSON.stringify(enrollmentBody),
          }
        );

        const enrollText = await enrollRes.text();
        let enrollment = null;

        if (!enrollRes.ok) {
          return jsonResponse(
            {
              ok: false,
              error: "Supabase insert failed for enrollments",
              status: enrollRes.status,
              body: enrollText,
            },
            500
          );
        }

        try {
          const parsed = JSON.parse(enrollText);
          enrollment = Array.isArray(parsed) ? parsed[0] : parsed;
        } catch (e) {
          enrollment = enrollText;
        }

        // ------------- Queue confirmation email (if email exists) ----------
        let emailLogResult = { queued: false, data: [] };

        if (email) {
          const subject = "AI Workshop enrollment received";
          const body =
            `Hi ${full_name},\n\n` +
            `We have received your interest in "${course}".\n` +
            `We will contact you soon with the final details and confirmation.\n\n` +
            `Thank you,\nEduConnect Team`;

          const emailPayload = {
            enrollment_id: enrollment && enrollment.id ? enrollment.id : null,
            to_email: email,
            subject,
            body,
            status: "queued",
            error: null,
          };

          const emailRes = await fetch(
            `${env.SUPABASE_URL}/rest/v1/email_log`,
            {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                apikey: env.SUPABASE_SERVICE_ROLE_KEY,
                Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
                Prefer: "return=representation",
              },
              body: JSON.stringify(emailPayload),
            }
          );

          const emailText = await emailRes.text();

          if (emailRes.ok) {
            let emailData;
            try {
              const parsed = JSON.parse(emailText);
              emailData = parsed;
            } catch (e) {
              emailData = emailText;
            }

            emailLogResult = {
              queued: true,
              data: emailData,
            };
          } else {
            emailLogResult = {
              queued: false,
              error: {
                status: emailRes.status,
                body: emailText,
              },
            };
          }
        }

        // Final response (matches PS test shape)
        return jsonResponse(
          {
            ok: true,
            enrollment,
            email_log: emailLogResult,
          },
          200
        );
      }

      // Fallback 404
      return new Response("Not found", {
        status: 404,
        headers: CORS_HEADERS,
      });
    } catch (err) {
      return jsonResponse(
        {
          ok: false,
          error: "Unexpected error in Worker",
          detail: err && err.message ? err.message : String(err),
        },
        500
      );
    }
  },
};


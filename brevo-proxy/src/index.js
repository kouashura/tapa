export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    try {
      const { email, code } = await request.json();

      if (!email || !code) {
        return new Response(JSON.stringify({ error: "email et code requis" }), {
          status: 400,
          headers: { "Content-Type": "application/json" },
        });
      }

      const brevoResponse = await fetch("https://api.brevo.com/v3/smtp/email", {
        method: "POST",
        headers: {
          "api-key": env.BREVO_API_KEY,
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: JSON.stringify({
          sender: { name: "TAPA Budget", email: "infosservices2015@gmail.com" },
          to: [{ email }],
          subject: "Votre code de vérification TAPA Budget",
          htmlContent: `
            <div style="font-family: sans-serif; padding: 20px;">
              <h2>TAPA Budget</h2>
              <p>Votre code de vérification est :</p>
              <h1 style="letter-spacing: 4px;">${code}</h1>
              <p>Ce code expire dans 15 minutes.</p>
            </div>
          `,
        }),
      });

      const result = await brevoResponse.text();

      return new Response(result, {
        status: brevoResponse.status,
        headers: { "Content-Type": "application/json" },
      });
    } catch (e) {
      return new Response(JSON.stringify({ error: e.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }
  },
};

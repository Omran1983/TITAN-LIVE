function isoNow() { return new Date().toISOString(); }
function minsDiff(a, b) { return (new Date(b) - new Date(a)) / 60000; }

async function tgSend(env, chatId, text) {
  if (!env?.TELEGRAM_BOT_TOKEN || !chatId) return;
  const api = `https://api.telegram.org/bot${env.TELEGRAM_BOT_TOKEN}/sendMessage`;
  await fetch(api, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ chat_id: chatId, text })
  });
}

async function runCron(env) {
  const now = isoNow();
  const prev = await env.STATUS.get('last_heartbeat', { type: 'text' });
  // Alert if we had a gap > 10 minutes
  if (prev) {
    const gap = minsDiff(prev, now);
    if (gap > 10 && env.OWNER_CHAT_ID) {
      await tgSend(env, env.OWNER_CHAT_ID, `HQ-Lite ALERT: cron gap ~${gap.toFixed(1)} min (prev=${prev})`);
      await env.AUDIT.put(`cron_alert:${Date.now()}`, JSON.stringify({ prev, now, gap }), { expirationTtl: 2592000 });
    }
  }
  // Write heartbeat + last_cron (with TTL)
  await env.STATUS.put('last_heartbeat', now);
  await env.AUDIT.put('last_cron', now, { expirationTtl: 2592000 });
  return { ok: true, prev, now };
}

async function dailyPing(env) {
  const hb = await env.STATUS.get('last_heartbeat', { type: 'text' });
  if (env.OWNER_CHAT_ID) {
    await tgSend(env, env.OWNER_CHAT_ID, `HQ-Lite OK (daily)\nlast_heartbeat: ${hb ?? 'n/a'}`);
  }
  await env.AUDIT.put(`daily_ping:${Date.now()}`, isoNow(), { expirationTtl: 2592000 });
  return { ok: true, last_heartbeat: hb ?? null };
}

async function versionInfo(env) {
  const hb = await env.STATUS.get('last_heartbeat', { type: 'text' });
  return {
    ok: true,
    deploy_id: env.DEPLOY_ID ?? null,
    wrangler: env.WRANGLER_VERSION ?? null,
    last_heartbeat: hb ?? null
  };
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Telegram webhook
    if (url.pathname === '/tg/webhook' && request.method === 'POST') {
      const update = await request.json().catch(() => ({}));
      const msg = update?.message || update?.edited_message;
      const chatId = msg?.chat?.id;
      const text = (msg?.text || '').trim();

      if (text?.startsWith('/status')) {
        const hb = await env.STATUS.get('last_heartbeat', { type: 'text' });
        await tgSend(env, chatId, `HQ-Lite OK\nlast_heartbeat: ${hb ?? 'n/a'}`);
      }
      if (text?.startsWith('/ping')) {
        const now = isoNow();
        await env.AUDIT.put(`ping:${Date.now()}`, now, { expirationTtl: 2592000 });
        await tgSend(env, chatId, 'pong');
      }
      if (text?.startsWith('/version')) {
        const v = await versionInfo(env);
        await tgSend(env, chatId, `DEPLOY=${v.deploy_id ?? 'n/a'}\n${v.wrangler ?? ''}\nlast_heartbeat: ${v.last_heartbeat ?? 'n/a'}`);
      }
      return new Response('ok', { status: 200 });
    }

    // Health
    if (url.pathname === '/health') {
      const hb = await env.STATUS.get('last_heartbeat', { type: 'text' });
      return new Response(JSON.stringify({ ok: true, last_heartbeat: hb ?? null }), {
        headers: { 'content-type': 'application/json' },
      });
    }

    // Manual cron runner (for testing)
    if (url.pathname === '/cron/run') {
      const res = await runCron(env);
      return new Response(JSON.stringify(res), { headers: { 'content-type': 'application/json' } });
    }

    // Manual daily ping (for testing)
    if (url.pathname === '/cron/ping') {
      const res = await dailyPing(env);
      return new Response(JSON.stringify(res), { headers: { 'content-type': 'application/json' } });
    }

    // Version endpoint (HTTP)
    if (url.pathname === '/version') {
      const v = await versionInfo(env);
      return new Response(JSON.stringify(v), { headers: { 'content-type': 'application/json' } });
    }

    return new Response('OK', { status: 200 });
  },

  // Real cron schedules
  async scheduled(event, env, ctx) {
    // Always run the 5-minute heartbeat
    ctx.waitUntil(runCron(env));

    // If it's the 09:00 MUR / 05:00 UTC daily schedule, send the daily ping
    if (event?.cron === '0 5 * * *') {
      ctx.waitUntil(dailyPing(env));
    }
  }
};

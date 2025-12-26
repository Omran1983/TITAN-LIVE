export async function handleStatusRequest(env) {
  const now = new Date().toISOString();
  const supabaseUrl = env.SUPABASE_URL || 'missing';

  const body = {
    service: 'educonnect-hq-lite',
    time: now,
    supabaseUrlConfigured: supabaseUrl !== 'missing',
    supabaseUrl,
  };

  return new Response(JSON.stringify(body, null, 2), {
    status: 200,
    headers: {
      'content-type': 'application/json; charset=utf-8',
    },
  });
}

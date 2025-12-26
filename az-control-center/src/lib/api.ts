// src/lib/api.ts
type ApiOptions = {
  token?: string; // OPERATOR | ADMIN etc
};

const API_BASE =
  (import.meta as any).env?.VITE_TITAN_API_BASE ||
  "http://127.0.0.1:5000";

function headers(opts?: ApiOptions): HeadersInit {
  const h: Record<string, string> = {
    "Content-Type": "application/json",
  };
  if (opts?.token) h["Authorization"] = `Bearer ${opts.token}`;
  return h;
}

export async function apiGet<T>(path: string, opts?: ApiOptions): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "GET",
    headers: headers(opts),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`GET ${path} failed (${res.status}): ${text}`);
  }
  return (await res.json()) as T;
}

export async function apiPost<T>(
  path: string,
  body: any,
  opts?: ApiOptions
): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: headers(opts),
    body: JSON.stringify(body ?? {}),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`POST ${path} failed (${res.status}): ${text}`);
  }
  return (await res.json()) as T;
}

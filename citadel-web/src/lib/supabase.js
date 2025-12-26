import { createClient } from "@supabase/supabase-js";

const url = import.meta.env.VITE_SUPABASE_URL;
const anon = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!url || !anon) {
    // Fail fast: avoids “silent empty data” headaches.
    // UI still loads, but dev console will show the issue immediately.
    console.warn("Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY in .env.local");
}

export const supabase = createClient(url ?? "", anon ?? "");

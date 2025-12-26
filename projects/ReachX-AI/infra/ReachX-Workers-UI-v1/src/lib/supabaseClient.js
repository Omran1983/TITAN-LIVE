// src/lib/supabaseClient.js
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

console.log('[ReachX ENV]', {
  VITE_SUPABASE_URL: supabaseUrl,
  hasAnonKey: !!supabaseAnonKey,
});

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn(
    '[ReachX] Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY. Check your .env.local in ReachX-Workers-UI-v1.'
  );
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

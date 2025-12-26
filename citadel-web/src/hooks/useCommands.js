import { useEffect, useState } from "react";
import { supabase } from "../lib/supabase";

/**
 * Phase 1.1: Contract-only hook.
 * Phase 1.2: Wire to az_commands (history table).
 */
export function useCommands() {
    const [commands, setCommands] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState(null);

    useEffect(() => {
        let cancelled = false;

        async function load() {
            setIsLoading(true);
            setError(null);

            try {
                const { data, error: qErr } = await supabase
                    .from("az_commands")
                    .select("*")
                    .order("created_at", { ascending: false })
                    .limit(50);

                if (qErr) throw qErr;
                if (!cancelled) setCommands(data ?? []);
            } catch (e) {
                if (!cancelled) setError(e);
            } finally {
                if (!cancelled) setIsLoading(false);
            }
        }

        load();
        return () => {
            cancelled = true;
        };
    }, []);

    return { commands, isLoading, error };
}

import { useEffect, useState } from "react";
import { supabase } from "../lib/supabase";

/**
 * Phase 1.1: Contract-only hook.
 * Phase 1.2: Wire to az_agents + az_health_snapshots.
 */
export function useAgents() {
    const [agents, setAgents] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState(null);

    useEffect(() => {
        let cancelled = false;

        async function load() {
            setIsLoading(true);
            setError(null);

            try {
                // Placeholder query (safe even if table missing; will surface error)
                const { data, error: qErr } = await supabase
                    .from("az_agents")
                    .select("*")
                    .limit(50);

                if (qErr) throw qErr;
                if (!cancelled) setAgents(data ?? []);
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

    return { agents, isLoading, error };
}

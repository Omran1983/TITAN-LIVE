import { useEffect, useState } from "react";
import { supabase } from "../lib/supabase";

/**
 * Phase 1.1: Contract-only hook.
 * Phase 1.2: Wire to these views:
 * - az_finance_kpi_today
 * - az_finance_kpi_month
 * - az_finance_cashflow_30d
 */
export function useFinanceKpis() {
    const [today, setToday] = useState(null);
    const [month, setMonth] = useState(null);
    const [cashflow30d, setCashflow30d] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState(null);

    useEffect(() => {
        let cancelled = false;

        async function load() {
            setIsLoading(true);
            setError(null);

            try {
                const [{ data: t, error: tErr }, { data: m, error: mErr }, { data: c, error: cErr }] =
                    await Promise.all([
                        supabase.from("az_finance_kpi_today").select("*").limit(1).maybeSingle(),
                        supabase.from("az_finance_kpi_month").select("*").limit(1).maybeSingle(),
                        supabase.from("az_finance_cashflow_30d").select("*").order("date", { ascending: true }),
                    ]);

                if (tErr) throw tErr;
                if (mErr) throw mErr;
                if (cErr) throw cErr;

                if (!cancelled) {
                    setToday(t ?? null);
                    setMonth(m ?? null);
                    setCashflow30d(c ?? []);
                }
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

    return { today, month, cashflow30d, isLoading, error };
}

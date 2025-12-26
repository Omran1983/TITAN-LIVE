-- TITAN V2 FINANCE SCHEMA (CANONICAL)
-- As defined in Master UI Phase 1.1 Specification

-- 1. CORE TABLES -----------------------------------------------------------

-- ACCOUNTS (Where money lives)
CREATE TABLE IF NOT EXISTS public.az_finance_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,         -- e.g. "MCB Main", "Cash Hand"
    type TEXT NOT NULL,         -- 'bank', 'cash', 'wallet'
    currency TEXT DEFAULT 'MUR',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    meta JSONB DEFAULT '{}'::jsonb
);

-- CATEGORIES (Classification)
CREATE TABLE IF NOT EXISTS public.az_finance_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,         -- e.g. "Delivery Fuel", "Sales"
    direction TEXT NOT NULL,    -- 'income', 'expense'
    "group" TEXT DEFAULT 'general', -- 'ops', 'marketing', 'personal'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- TRANSACTIONS (The Ledger)
CREATE TABLE IF NOT EXISTS public.az_finance_tx (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tx_date DATE NOT NULL DEFAULT CURRENT_DATE,
    posted_at TIMESTAMPTZ DEFAULT now(),
    amount NUMERIC NOT NULL DEFAULT 0, -- + for Income, - for Expense
    currency TEXT DEFAULT 'MUR',
    account_id UUID REFERENCES public.az_finance_accounts(id),
    category_id UUID REFERENCES public.az_finance_categories(id),
    project TEXT DEFAULT 'general', -- 'deliveries', 'okasina', 'educonnect'
    source TEXT DEFAULT 'manual',   -- 'manual', 'jarvis', 'csv'
    description TEXT,
    meta JSONB DEFAULT '{}'::jsonb
);

-- 2. VIEWS (THE MONEY MATH) ------------------------------------------------

-- KPI: TODAY
CREATE OR REPLACE VIEW public.az_finance_kpi_today AS
SELECT
    CURRENT_DATE as date,
    COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0) as income_today,
    COALESCE(SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END), 0) as expense_today,
    COALESCE(SUM(amount), 0) as net_today,
    COUNT(*) as transactions_count
FROM public.az_finance_tx
WHERE tx_date = CURRENT_DATE;

-- KPI: MONTH
CREATE OR REPLACE VIEW public.az_finance_kpi_month AS
WITH current_month AS (
    SELECT
        date_trunc('month', CURRENT_DATE)::date as month_start,
        COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0) as income,
        COALESCE(SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END), 0) as expense,
        COALESCE(SUM(amount), 0) as net
    FROM public.az_finance_tx
    WHERE date_trunc('month', tx_date) = date_trunc('month', CURRENT_DATE)
),
prev_month AS (
    SELECT
        COALESCE(SUM(amount), 0) as net
    FROM public.az_finance_tx
    WHERE date_trunc('month', tx_date) = date_trunc('month', CURRENT_DATE - INTERVAL '1 month')
)
SELECT
    cm.month_start,
    cm.income as income_month,
    cm.expense as expense_month,
    cm.net as net_month,
    pm.net as prev_month_net,
    CASE 
        WHEN pm.net = 0 THEN 0 
        ELSE ROUND(((cm.net - pm.net) / ABS(pm.net)) * 100, 1) 
    END as net_change_pct
FROM current_month cm, prev_month pm;

-- CHART: CASHFLOW 30 DAYS
CREATE OR REPLACE VIEW public.az_finance_cashflow_30d AS
SELECT
    tx_date as date,
    COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0) as income,
    COALESCE(SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END), 0) as expense,
    COALESCE(SUM(amount), 0) as net
FROM public.az_finance_tx
WHERE tx_date >= CURRENT_DATE - 30
GROUP BY tx_date
ORDER BY tx_date ASC;

-- CHART: BY PROJECT
CREATE OR REPLACE VIEW public.az_finance_by_project AS
SELECT
    project,
    COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0) as income_30d,
    COALESCE(SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END), 0) as expense_30d,
    COALESCE(SUM(amount), 0) as net_30d
FROM public.az_finance_tx
WHERE tx_date >= CURRENT_DATE - 30
GROUP BY project
ORDER BY net_30d DESC;

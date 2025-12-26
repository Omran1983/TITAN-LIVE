-- QUERY TO FIND YOUR IMPORTED TABLES
-- Run this in Supabase SQL Editor to see the real table names.

SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name NOT LIKE 'pg_%' 
AND table_name NOT LIKE 'sql_%'
AND table_name NOT LIKE 'az_%' -- Exclude our new system tables
ORDER BY table_name;

-- After running this, look for names like 'master_sheet', 'daily_expenses', etc.

-- SEED DATA FOR TITAN V2 (AOGRL DELIVERIES)
-- Populates the new az_* tables to verify the dashboard.

DO $$
DECLARE
    biz_id bigint;
    today_str text := to_char(now(), 'YYYY-MM-DD');
BEGIN
    -- 1. Get Business ID
    SELECT id INTO biz_id FROM public.az_businesses WHERE slug = 'aogrl_deliveries';
    
    IF biz_id IS NULL THEN
        RAISE EXCEPTION 'Business aogrl_deliveries not found! Run migration_titan_v2_core.sql first.';
    END IF;

    -- 2. Clear old V2 demo data for today to avoid duplicates
    DELETE FROM public.az_sales_events WHERE business_id = biz_id AND date >= now()::date;
    DELETE FROM public.az_expense_events WHERE business_id = biz_id AND date >= now()::date;
    DELETE FROM public.az_deliveries WHERE business_id = biz_id AND created_at >= now()::date;
    DELETE FROM public.az_ops_tickets WHERE business_id = biz_id AND created_at >= now()::date;

    -- 3. Log Sales (Manual Input Simulation)
    INSERT INTO public.az_sales_events (business_id, amount, type, source, customer_name, notes, created_at) VALUES
    (biz_id, 2500.00, 'service_invoice', 'manual', 'Grand Baie Resort', 'Logistics Contract #101', now() - interval '4 hours'),
    (biz_id, 1200.00, 'service_invoice', 'manual', 'Cybercity Office', 'Express Document Run', now() - interval '2 hours'),
    (biz_id, 4500.00, 'service_invoice', 'manual', 'Event Planner Ltd', 'Van Hire Full Day', now() - interval '30 minutes');

    -- 4. Log Expenses
    INSERT INTO public.az_expense_events (business_id, amount, category, notes, created_at) VALUES
    (biz_id, 850.00, 'fuel', 'Diesel for Van 1', now() - interval '5 hours'),
    (biz_id, 200.00, 'meals', 'Driver Lunch', now() - interval '1 hour');

    -- 5. Log Deliveries
    INSERT INTO public.az_deliveries (business_id, ref_code, client_name, address, status, created_at) VALUES
    (biz_id, 'JOB-101', 'Grand Baie Resort', 'Coastal Road, Grand Baie', 'delivered', now() - interval '3 hours'),
    (biz_id, 'JOB-102', 'Cybercity Office', 'Ebene Cybercity', 'delivered', now() - interval '1 hour'),
    (biz_id, 'JOB-103', 'Private Client', 'Flic en Flac', 'pending', now() - interval '15 minutes');

    -- 6. Log Tickets/Notes
    INSERT INTO public.az_ops_tickets (business_id, title, type, status, created_at) VALUES
    (biz_id, 'Van 2 needs service', 'maintenance', 'open', now() - interval '6 hours'),
    (biz_id, 'Client complained about delay on Job 101', 'complaint', 'resolved', now() - interval '2 hours');

END $$;

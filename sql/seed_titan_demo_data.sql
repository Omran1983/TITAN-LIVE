-- SEED DATA FOR TITAN COMMAND (AOGRL DELIVERIES)
-- Fixes: Uses REAL Order IDs (bigint) captured from inserts to satisfy FK constraints.

DO $$
DECLARE
    biz_id bigint;
    today_date timestamptz := now();
    o1 bigint;
    o2 bigint;
    o3 bigint;
BEGIN
    -- 1. Get the Business ID for 'aogrl_deliveries'
    SELECT id INTO biz_id FROM public.businesses WHERE slug = 'aogrl_deliveries';

    IF biz_id IS NULL THEN
        RAISE EXCEPTION 'Business aogrl_deliveries not found! Run migration_multibusiness.sql first.';
    END IF;

    -- 2. Clean up "Today's" test data to avoid duplicates if re-run
    DELETE FROM public.orders WHERE business_id = biz_id AND created_at > (today_date - interval '1 day');
    DELETE FROM public.expenses WHERE business_id = biz_id AND incurred_at > (today_date - interval '1 day');
    DELETE FROM public.deliveries WHERE business_id = biz_id AND created_at > (today_date - interval '1 day');
    DELETE FROM public.customer_feedback WHERE business_id = biz_id AND created_at > (today_date - interval '1 day');

    -- 3. Insert Orders & Capture IDs (for Deliveries linkage)
    INSERT INTO public.orders (business_id, total_amount, status, created_at) 
    VALUES (biz_id, 2500.00, 'completed', today_date - interval '4 hours')
    RETURNING id INTO o1;

    INSERT INTO public.orders (business_id, total_amount, status, created_at) 
    VALUES (biz_id, 1200.50, 'completed', today_date - interval '2 hours')
    RETURNING id INTO o2;

    INSERT INTO public.orders (business_id, total_amount, status, created_at) 
    VALUES (biz_id, 4500.00, 'processing', today_date - interval '30 minutes')
    RETURNING id INTO o3;

    -- 4. Insert Expenses
    INSERT INTO public.expenses (business_id, amount, description, category, incurred_at) VALUES
    (biz_id, 850.00, 'Fuel for Van 1', 'Transport', today_date - interval '5 hours'),
    (biz_id, 300.00, 'Facebook Ad Spend', 'Marketing', today_date - interval '1 hour');

    -- 5. Insert Operations (Deliveries) using captured Order IDs
    INSERT INTO public.deliveries (business_id, order_id, client_name, status, delay_minutes, created_at) VALUES
    (biz_id, o1, 'Grand Baie Resort', 'delivered', 0, today_date - interval '3 hours'),
    (biz_id, o2, 'Cybercity Office', 'dispatched', 0, today_date - interval '1 hour'),
    (biz_id, o3, 'Private Client', 'delivered', 15, today_date - interval '45 minutes');

    -- 6. Insert Customer Feedback
    INSERT INTO public.customer_feedback (business_id, customer_name, message, sentiment, source, created_at) VALUES
    (biz_id, 'Sarah L.', 'Extremely fast delivery, very impressed!', 'positive', 'whatsapp', today_date - interval '2 hours'),
    (biz_id, 'John D.', 'Driver was polite but arrived slightly late.', 'neutral', 'email', today_date - interval '4 hours'),
    (biz_id, 'Tech Corp', 'Professional service as always.', 'positive', 'portal', today_date - interval '30 minutes');

END $$;

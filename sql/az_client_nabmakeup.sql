-- TITAN CLIENT SCHEMA: NAB MAKEUP
-- Purpose: Backend for AI Sales Assistant (Leads, Offers, Tracking)

-- 1. LEADS (The Funnel)
create table if not exists public.nab_leads (
    id              bigserial primary key,
    created_at      timestamptz default now(),
    source          text,                       -- 'quiz', 'whatsapp_optin', 'website_form'
    customer_name   text,
    contact_info    text,                       -- Phone or Email
    interest        text,                       -- 'acne', 'pigmentation', 'bridal', 'general'
    stage           text default 'new',         -- 'new', 'engaged', 'won', 'lost'
    notes           text
);

-- 2. OFFERS (The Brain / Scripts)
create table if not exists public.nab_offers (
    id              bigserial primary key,
    name            text not null,              -- 'Acne Reset Kit'
    price_mur       int,
    description     text,
    email_template  text,
    whatsapp_template text,
    is_active       boolean default true
);

-- 3. SEED OFFERS (As defined in strategy)
insert into public.nab_offers (name, price_mur, description, email_template, whatsapp_template) values 
(
    'Acne Reset Kit', 
    2500, 
    'Complete routine for clearing breakouts.',
    'Hi {name}, saw you were asking about acne. Our Reset Kit clears 80% of breakouts in 2 weeks...',
    'Hey {name} 👋 Nabila here. For acne, I always start creating a base with the Reset Kit. Want to see a before/after?'
),
(
    'Glow Starter Kit', 
    1800, 
    'Vitamin C + Hydration for dull skin.',
    'Hi {name}, ready for that glow? The Starter Kit is our best seller...',
    'Hey {name} ✨ The Glow Kit is exactly what you need for hydration. Shall I send the link?'
),
(
    'Bridal Trial Package', 
    5000, 
    'Full trial + Consultation + Day-of booking.',
    'Hi {name}, congrats! For brides, we do a full trial first...',
    'Hi {name} 👰 Congrats! Let''s book your trial. Are you free this weekend?'
)
on conflict do nothing;

-- =====================================================
-- ReachX Demo Seed – Employers, Requests, Assignments, Invoices
-- Idempotent: safe to run many times
-- =====================================================

-- 1) Ensure at least 1 worker exists
insert into reachx_workers (
    full_name,
    nationality,
    status
)
select
    'Demo Worker 1',
    'Mauritian',
    'available'
where not exists (
    select 1
    from reachx_workers
    where full_name = 'Demo Worker 1'
)
returning id;

-- 2) Ensure Acclime employer exists (it already does in your case, but keep it safe)
insert into reachx_employers (id, name, country, status)
select
    '03aab99a-8dae-4d42-ab0a-e280f06808b6'::uuid,
    'Acclime Mauritius Limited',
    'Mauritius',
    'active'
where not exists (
    select 1 from reachx_employers
    where id = '03aab99a-8dae-4d42-ab0a-e280f06808b6'::uuid
);

-- 3) Create / reuse demo request for Acclime
with emp as (
    select id as employer_id
    from reachx_employers
    where name = 'Acclime Mauritius Limited'
    limit 1
),
existing_req as (
    select id, employer_id
    from reachx_requests
    where title = '10 Fund Administrators – Corporate & Funds (DEMO)'
      and employer_id in (select employer_id from emp)
),
new_req as (
    insert into reachx_requests (
        employer_id,
        title,
        country,
        location,
        role,
        quantity,
        status,
        notes
    )
    select
        e.employer_id,
        '10 Fund Administrators – Corporate & Funds (DEMO)',
        'Mauritius',
        'Ebène',
        'Fund Administrator',
        10,
        'open',
        'Demo request for dashboard'
    from emp e
    where not exists (
        select 1 from existing_req
    )
    returning id, employer_id
),
reqs as (
    select id, employer_id from new_req
    union all
    select id, employer_id from existing_req
),
worker as (
    select id as worker_id
    from reachx_workers
    order by created_at asc nulls last
    limit 1
),
existing_assigns as (
    select distinct request_id
    from reachx_assignments
    where request_id in (select id from reqs)
)

insert into reachx_assignments (
    request_id,
    worker_id,
    employer_id,
    status,
    start_date,
    end_date
)
select
    r.id as request_id,
    w.worker_id,
    r.employer_id,
    'active' as status,
    current_date - interval '7 days' as start_date,
    null::date as end_date
from reqs r
cross join worker w
left join existing_assigns ea
    on ea.request_id = r.id
where ea.request_id is null;

-- 4) Demo invoice for Acclime

with emp as (
  select id as employer_id
  from reachx_employers
  where name = 'Acclime Mauritius Limited'
  limit 1
),
ass as (
  select a.id as assignment_id, a.employer_id
  from reachx_assignments a
  join emp e on e.employer_id = a.employer_id
  order by a.start_date asc nulls last
  limit 1
),
existing as (
  select 1 as exists_flag
  from reachx_employer_invoices i
  join ass a on a.assignment_id = i.assignment_id
  where i.invoice_no = 'RX-DEMO-ACCLIME-001'
)

insert into reachx_employer_invoices (
  employer_id,
  assignment_id,
  invoice_no,
  amount,
  currency,
  status,
  issued_at,
  due_at
)
select
  a.employer_id,
  a.assignment_id,
  'RX-DEMO-ACCLIME-001',
  250000,
  'MUR',
  'unpaid',
  current_date - interval '2 days',
  current_date + interval '28 days'
from ass a
where not exists (select 1 from existing);

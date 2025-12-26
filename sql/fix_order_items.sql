-- FIX: Drop and Recreate order_items
-- PROBABLY: The table 'order_items' already existed from an old experiment, 
-- causing 'create table if not exists' to skip, but then the index failed.

drop table if exists public.order_items cascade;

create table public.order_items (
  id            bigserial primary key,
  business_id   bigint references public.businesses(id),
  order_id      bigint references public.orders(id) on delete cascade,
  product_id    text, 
  sku           text,
  name          text,
  category      text,
  subcategory   text,
  tags          text[],
  unit_price    numeric(10,2) default 0,
  qty           integer default 1,
  line_total    numeric(10,2) default 0,
  created_at    timestamptz not null default now()
);

create index idx_order_items_business on public.order_items(business_id);
create index idx_order_items_product on public.order_items(product_id);
create index idx_order_items_category on public.order_items(category);

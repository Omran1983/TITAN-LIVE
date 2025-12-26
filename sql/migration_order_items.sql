-- Create order_items table for itemized order details
create table if not exists public.order_items (
  id            bigserial primary key,
  business_id   bigint references public.businesses(id),
  order_id      bigint references public.orders(id) on delete cascade,
  product_id    text, -- uuid string often
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

-- Optional: index for faster analytics later
create index if not exists idx_order_items_business on public.order_items(business_id);
create index if not exists idx_order_items_product on public.order_items(product_id);
create index if not exists idx_order_items_category on public.order_items(category);

-- Main products table for AOGRL-DS
create table if not exists aogrl_ds_products (
  id                  uuid primary key default gen_random_uuid(),
  supplier            text not null,           -- e.g. 'Goli'
  supplier_product_id text,                    -- if we find a product handle/ID
  name                text not null,
  description         text,
  price_cents         integer,                 -- normalised price in cents
  currency            text default 'USD',
  image_url           text,
  source_url          text,                    -- page we scraped from
  extra               jsonb,                   -- extra attributes (flavour, size, bundle info, etc.)
  is_active           boolean default true,
  created_at          timestamptz default now(),
  updated_at          timestamptz default now()
);

-- Make sure we don't duplicate the same supplier+product combination
create unique index if not exists idx_aogrl_ds_products_supplier_unique
  on aogrl_ds_products (supplier, supplier_product_id);

-- Simple trigger to auto-update updated_at
create or replace function set_aogrl_ds_products_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_aogrl_ds_products_updated_at on aogrl_ds_products;

create trigger trg_aogrl_ds_products_updated_at
before update on aogrl_ds_products
for each row
execute procedure set_aogrl_ds_products_updated_at();

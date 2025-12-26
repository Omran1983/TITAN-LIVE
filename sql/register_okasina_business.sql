-- 1) Register OKASINA Trading as a business
insert into public.businesses (slug, name)
values ('okasina', 'OKASINA Trading')
on conflict (slug) do nothing;

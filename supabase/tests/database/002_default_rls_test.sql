begin;

set local role postgres;
set local search_path = public, extensions;

create extension if not exists pgtap with schema extensions;
grant usage on schema extensions to anon, authenticated;

select extensions.plan(8);

insert into auth.users (id, email)
values
  ('11000000-0000-4000-8000-000000000001', 'household-a-owner@example.invalid'),
  ('11000000-0000-4000-8000-000000000002', 'household-b-owner@example.invalid');

insert into public.households (id, owner_id, name)
values
  (
    '22000000-0000-4000-8000-000000000001',
    '11000000-0000-4000-8000-000000000001',
    'Domácnost A'
  ),
  (
    '22000000-0000-4000-8000-000000000002',
    '11000000-0000-4000-8000-000000000002',
    'Domácnost B'
  );

insert into public.household_members (household_id, user_id, role)
values
  (
    '22000000-0000-4000-8000-000000000001',
    '11000000-0000-4000-8000-000000000001',
    'owner'
  ),
  (
    '22000000-0000-4000-8000-000000000002',
    '11000000-0000-4000-8000-000000000002',
    'owner'
  );

insert into public.shopping_lists (id, household_id, name, created_by)
values
  (
    '77000000-0000-4000-8000-000000000001',
    '22000000-0000-4000-8000-000000000001',
    'Seznam A',
    '11000000-0000-4000-8000-000000000001'
  ),
  (
    '77000000-0000-4000-8000-000000000002',
    '22000000-0000-4000-8000-000000000002',
    'Seznam B',
    '11000000-0000-4000-8000-000000000002'
  );

insert into public.shopping_items (id, list_id, original_label, normalized_label)
values
  (
    '88000000-0000-4000-8000-000000000001',
    '77000000-0000-4000-8000-000000000001',
    'Položka A',
    'polozka-a'
  ),
  (
    '88000000-0000-4000-8000-000000000002',
    '77000000-0000-4000-8000-000000000002',
    'Položka B',
    'polozka-b'
  );

select extensions.results_eq(
  $$
    select count(*)
    from pg_catalog.pg_class as relation
    join pg_catalog.pg_namespace as namespace
      on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relkind = 'r'
      and relation.relrowsecurity
  $$,
  array[17::bigint],
  'RLS je zapnuté na všech 17 veřejných tabulkách'
);

select extensions.results_eq(
  $$select count(*) from pg_catalog.pg_policies where schemaname = 'public'$$,
  array[0::bigint],
  'Ve výchozí fázi neexistuje žádná povolující RLS politika'
);

set local role anon;

select extensions.throws_ok(
  $$
    select id from public.households
    where id = '22000000-0000-4000-8000-000000000002'
  $$,
  '42501',
  'permission denied for table households',
  'Anonymní uživatel nemůže číst domácnost'
);

select extensions.throws_ok(
  $$
    select id from public.shopping_items
    where id = '88000000-0000-4000-8000-000000000002'
  $$,
  '42501',
  'permission denied for table shopping_items',
  'Anonymní uživatel nemůže číst položku nákupního seznamu'
);

set local role postgres;
set local role authenticated;
set local request.jwt.claim.sub = '11000000-0000-4000-8000-000000000001';

select extensions.is_empty(
  $$
    select id from public.households
    where id = '22000000-0000-4000-8000-000000000002'
  $$,
  'Uživatel domácnosti A nevidí domácnost B'
);

select extensions.is_empty(
  $$
    select id from public.shopping_items
    where id = '88000000-0000-4000-8000-000000000002'
  $$,
  'Uživatel domácnosti A nevidí položky domácnosti B'
);

select extensions.is_empty(
  $$
    update public.shopping_items
    set note = 'Cizí změna'
    where id = '88000000-0000-4000-8000-000000000002'
    returning id
  $$,
  'Uživatel domácnosti A nemůže změnit položku domácnosti B'
);

select extensions.is_empty(
  $$
    delete from public.shopping_lists
    where id = '77000000-0000-4000-8000-000000000002'
    returning id
  $$,
  'Uživatel domácnosti A nemůže smazat seznam domácnosti B'
);

set local role postgres;

select * from extensions.finish();

rollback;

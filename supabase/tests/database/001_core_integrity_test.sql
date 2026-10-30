begin;

set local role postgres;
set local search_path = public, extensions;

create extension if not exists pgtap with schema extensions;

select extensions.plan(7);

insert into auth.users (id, email)
values ('10000000-0000-4000-8000-000000000001', 'integrity-owner@example.invalid');

insert into public.households (id, owner_id, name)
values (
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001',
  'Testovací domácnost'
);

insert into public.household_members (household_id, user_id, role)
values (
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001',
  'owner'
);

insert into public.product_categories (id, name, normalized_name)
values (
  '30000000-0000-4000-8000-000000000001',
  'Testovací kategorie',
  'testovaci-kategorie'
);

insert into public.products (id, category_id, label, normalized_label)
values (
  '40000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000001',
  'Testovací produkt',
  'testovaci-produkt'
);

insert into public.store_chains (id, name, slug)
values (
  '50000000-0000-4000-8000-000000000001',
  'Testovací řetězec',
  'testovaci-retezec'
);

insert into public.stores (id, chain_id, name, address_line, city, location)
values
  (
    '60000000-0000-4000-8000-000000000001',
    '50000000-0000-4000-8000-000000000001',
    'Pobočka A',
    'Testovací 1',
    'Praha',
    extensions.st_geogfromtext('SRID=4326;POINT(14.42076 50.08804)')
  ),
  (
    '60000000-0000-4000-8000-000000000002',
    '50000000-0000-4000-8000-000000000001',
    'Pobočka B',
    'Testovací 2',
    'Praha',
    extensions.st_geogfromtext('SRID=4326;POINT(14.43076 50.07804)')
  );

insert into public.shopping_lists (id, household_id, name, created_by)
values (
  '70000000-0000-4000-8000-000000000001',
  '20000000-0000-4000-8000-000000000001',
  'Testovací seznam',
  '10000000-0000-4000-8000-000000000001'
);

select extensions.throws_ok(
  $$
    insert into public.shopping_items (
      list_id, original_label, normalized_label, quantity
    ) values (
      '70000000-0000-4000-8000-000000000001',
      'Neplatné množství', 'neplatne-mnozstvi', 0
    )
  $$,
  '23514',
  'new row for relation "shopping_items" violates check constraint "shopping_items_quantity_valid"',
  'Položka musí mít kladné množství'
);

select extensions.throws_ok(
  $$
    insert into public.shopping_items (
      list_id, product_id, category_id, original_label, normalized_label
    ) values (
      '70000000-0000-4000-8000-000000000001',
      '40000000-0000-4000-8000-000000000001',
      '30000000-0000-4000-8000-000000000001',
      'Dvojí klasifikace', 'dvoji-klasifikace'
    )
  $$,
  '23514',
  'new row for relation "shopping_items" violates check constraint "shopping_items_product_or_category"',
  'Položka nemůže současně odkazovat na produkt i kategorii'
);

select extensions.throws_ok(
  $$
    insert into public.shopping_items (
      list_id, original_label, normalized_label, status
    ) values (
      '70000000-0000-4000-8000-000000000001',
      'Nekonzistentní nákup', 'nekonzistentni-nakup', 'purchased'
    )
  $$,
  '23514',
  'new row for relation "shopping_items" violates check constraint "shopping_items_purchase_consistent"',
  'Zakoupená položka musí uvést kupujícího a čas nákupu'
);

select extensions.throws_ok(
  $$
    insert into public.shopping_sessions (
      user_id, list_id, store_id, selection_source,
      device_installation_id, started_at, ended_at
    ) values (
      '10000000-0000-4000-8000-000000000001',
      '70000000-0000-4000-8000-000000000001',
      '60000000-0000-4000-8000-000000000001',
      'manual',
      '80000000-0000-4000-8000-000000000001',
      '2026-01-02 10:00:00+00',
      '2026-01-02 09:59:59+00'
    )
  $$,
  '23514',
  'new row for relation "shopping_sessions" violates check constraint "shopping_sessions_end_after_start"',
  'Nákupní relace nemůže skončit před začátkem'
);

insert into public.shopping_sessions (
  id, user_id, list_id, store_id, selection_source, device_installation_id
)
values (
  '90000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001',
  '70000000-0000-4000-8000-000000000001',
  '60000000-0000-4000-8000-000000000001',
  'manual',
  '80000000-0000-4000-8000-000000000001'
);

insert into public.client_operations (
  operation_id, user_id, device_installation_id, operation_type, target_type
)
values (
  'a0000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001',
  '80000000-0000-4000-8000-000000000001',
  'confirm_purchase',
  'shopping_item'
);

select extensions.throws_ok(
  $$
    insert into public.purchase_observations (
      session_id, operation_id, store_id, product_id,
      sequence_number, observed_at_bucket, source
    ) values (
      '90000000-0000-4000-8000-000000000001',
      'a0000000-0000-4000-8000-000000000001',
      '60000000-0000-4000-8000-000000000002',
      '40000000-0000-4000-8000-000000000001',
      0, '2026-01-02 10:00:00+00', 'purchase_confirmation'
    )
  $$,
  '23503',
  'insert or update on table "purchase_observations" violates foreign key constraint "purchase_observations_session_same_store"',
  'Pozorování musí patřit do stejné pobočky jako relace'
);

select extensions.throws_ok(
  $$
    insert into public.purchase_observations (
      session_id, operation_id, store_id, product_id, category_id,
      sequence_number, observed_at_bucket, source
    ) values (
      '90000000-0000-4000-8000-000000000001',
      'a0000000-0000-4000-8000-000000000001',
      '60000000-0000-4000-8000-000000000001',
      '40000000-0000-4000-8000-000000000001',
      '30000000-0000-4000-8000-000000000001',
      0, '2026-01-02 10:00:00+00', 'purchase_confirmation'
    )
  $$,
  '23514',
  'new row for relation "purchase_observations" violates check constraint "purchase_observations_product_xor_category"',
  'Pozorování musí odkazovat právě na produkt, nebo kategorii'
);

insert into public.privacy_consents (user_id, purpose, policy_version)
values (
  '10000000-0000-4000-8000-000000000001',
  'crowdsourcing',
  '2026-01'
);

select extensions.throws_ok(
  $$
    insert into public.privacy_consents (user_id, purpose, policy_version)
    values (
      '10000000-0000-4000-8000-000000000001',
      'crowdsourcing',
      '2026-02'
    )
  $$,
  '23505',
  'duplicate key value violates unique constraint "privacy_consents_one_active_per_purpose_idx"',
  'Uživatel může mít pro jeden účel jen jeden aktivní souhlas'
);

select * from extensions.finish();

rollback;

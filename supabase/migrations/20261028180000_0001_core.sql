begin;

create schema if not exists extensions;
create schema if not exists private;

revoke all on schema private from public;
grant usage on schema private to postgres, service_role;

create extension if not exists pgcrypto with schema extensions;
create extension if not exists postgis with schema extensions;

create type public.household_role as enum ('owner', 'member');
create type public.item_status as enum (
  'active',
  'claimed',
  'purchased',
  'removed'
);
create type public.store_selection_source as enum (
  'manual',
  'last_used',
  'location_suggestion'
);
create type public.observation_source as enum (
  'purchase_confirmation',
  'manual_zone_confirmation'
);
create type public.quality_bucket as enum (
  'unknown',
  'low',
  'medium',
  'high'
);
create type public.observation_processing_state as enum (
  'pending',
  'accepted',
  'rejected',
  'aggregated'
);

create function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = statement_timestamp();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name varchar(100) not null,
  locale varchar(16) not null default 'cs-CZ',
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint profiles_display_name_not_blank
    check (length(btrim(display_name)) between 1 and 100),
  constraint profiles_locale_format
    check (locale ~ '^[a-z]{2,3}(-[A-Z]{2})?$')
);

create table public.households (
  id uuid primary key default extensions.gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete restrict,
  name varchar(120) not null,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint households_name_not_blank
    check (length(btrim(name)) between 1 and 120)
);

create table public.household_members (
  household_id uuid not null references public.households (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role public.household_role not null default 'member',
  joined_at timestamptz not null default statement_timestamp(),
  primary key (household_id, user_id)
);

create index household_members_user_id_idx
  on public.household_members (user_id, household_id);

create table public.household_invites (
  id uuid primary key default extensions.gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  token_hash bytea not null unique,
  created_by uuid not null references auth.users (id) on delete restrict,
  expires_at timestamptz not null,
  max_uses smallint not null default 1,
  use_count smallint not null default 0,
  revoked_at timestamptz,
  created_at timestamptz not null default statement_timestamp(),
  constraint household_invites_use_counts_valid
    check (max_uses between 1 and 20 and use_count between 0 and max_uses),
  constraint household_invites_expiry_after_creation
    check (expires_at > created_at)
);

create index household_invites_household_id_idx
  on public.household_invites (household_id, expires_at);

create table public.product_categories (
  id uuid primary key default extensions.gen_random_uuid(),
  name varchar(100) not null,
  normalized_name varchar(100) not null unique,
  typical_order integer,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint product_categories_name_not_blank
    check (length(btrim(name)) between 1 and 100),
  constraint product_categories_normalized_name_not_blank
    check (length(btrim(normalized_name)) between 1 and 100),
  constraint product_categories_typical_order_nonnegative
    check (typical_order is null or typical_order >= 0)
);

create table public.products (
  id uuid primary key default extensions.gen_random_uuid(),
  category_id uuid references public.product_categories (id) on delete set null,
  label varchar(160) not null,
  normalized_label varchar(160) not null,
  ean varchar(14) unique,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint products_label_not_blank
    check (length(btrim(label)) between 1 and 160),
  constraint products_normalized_label_not_blank
    check (length(btrim(normalized_label)) between 1 and 160),
  constraint products_ean_format
    check (ean is null or ean ~ '^[0-9]{8,14}$')
);

create index products_category_id_idx on public.products (category_id);
create index products_normalized_label_idx on public.products (normalized_label);

create table public.store_chains (
  id uuid primary key default extensions.gen_random_uuid(),
  name varchar(120) not null,
  slug varchar(80) not null unique,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint store_chains_name_not_blank
    check (length(btrim(name)) between 1 and 120),
  constraint store_chains_slug_format
    check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$')
);

create table public.stores (
  id uuid primary key default extensions.gen_random_uuid(),
  chain_id uuid not null references public.store_chains (id) on delete restrict,
  name varchar(160) not null,
  address_line varchar(200) not null,
  city varchar(120) not null,
  postal_code varchar(20),
  country_code char(2) not null default 'CZ',
  location extensions.geography(point, 4326) not null,
  is_active boolean not null default true,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint stores_name_not_blank
    check (length(btrim(name)) between 1 and 160),
  constraint stores_address_not_blank
    check (length(btrim(address_line)) between 1 and 200),
  constraint stores_city_not_blank
    check (length(btrim(city)) between 1 and 120),
  constraint stores_country_code_format
    check (country_code ~ '^[A-Z]{2}$')
);

create index stores_chain_id_idx on public.stores (chain_id);
create index stores_location_gix on public.stores using gist (location);

create table public.store_zones (
  id uuid primary key default extensions.gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  name varchar(120) not null,
  sort_order integer not null,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint store_zones_name_not_blank
    check (length(btrim(name)) between 1 and 120),
  constraint store_zones_sort_order_nonnegative check (sort_order >= 0),
  constraint store_zones_store_name_unique unique (store_id, name),
  constraint store_zones_store_order_unique unique (store_id, sort_order),
  constraint store_zones_id_store_unique unique (id, store_id)
);

create table public.store_product_estimates (
  id uuid primary key default extensions.gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  zone_id uuid,
  sort_position numeric(10, 4),
  confidence public.quality_bucket not null default 'unknown',
  independent_session_count integer not null default 0,
  independent_installation_count integer not null default 0,
  model_version varchar(40) not null,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint store_product_estimates_store_product_unique
    unique (store_id, product_id),
  constraint store_product_estimates_zone_same_store
    foreign key (zone_id, store_id)
    references public.store_zones (id, store_id) on delete set null (zone_id),
  constraint store_product_estimates_sort_position_nonnegative
    check (sort_position is null or sort_position >= 0),
  constraint store_product_estimates_counts_nonnegative
    check (
      independent_session_count >= 0
      and independent_installation_count >= 0
    ),
  constraint store_product_estimates_model_version_not_blank
    check (length(btrim(model_version)) between 1 and 40)
);

create index store_product_estimates_product_id_idx
  on public.store_product_estimates (product_id);

create table public.shopping_lists (
  id uuid primary key default extensions.gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  name varchar(120) not null,
  created_by uuid not null references auth.users (id) on delete restrict,
  version bigint not null default 1,
  archived_at timestamptz,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint shopping_lists_name_not_blank
    check (length(btrim(name)) between 1 and 120),
  constraint shopping_lists_version_positive check (version > 0)
);

create index shopping_lists_household_id_idx
  on public.shopping_lists (household_id, archived_at);

create table public.shopping_items (
  id uuid primary key default extensions.gen_random_uuid(),
  list_id uuid not null references public.shopping_lists (id) on delete cascade,
  product_id uuid references public.products (id) on delete set null,
  category_id uuid references public.product_categories (id) on delete set null,
  original_label varchar(160) not null,
  normalized_label varchar(160) not null,
  quantity numeric(12, 3) not null default 1,
  unit varchar(32),
  note varchar(500),
  status public.item_status not null default 'active',
  claimed_by uuid references auth.users (id) on delete set null,
  claimed_until timestamptz,
  purchased_by uuid references auth.users (id) on delete set null,
  purchased_at timestamptz,
  removed_at timestamptz,
  manual_sort_order integer,
  version bigint not null default 1,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint shopping_items_product_or_category
    check (product_id is null or category_id is null),
  constraint shopping_items_label_not_blank
    check (length(btrim(original_label)) between 1 and 160),
  constraint shopping_items_normalized_label_not_blank
    check (length(btrim(normalized_label)) between 1 and 160),
  constraint shopping_items_quantity_valid
    check (quantity > 0 and quantity <= 100000),
  constraint shopping_items_unit_length
    check (unit is null or length(btrim(unit)) between 1 and 32),
  constraint shopping_items_claim_consistent
    check (
      status <> 'claimed'
      or (claimed_by is not null and claimed_until is not null)
    ),
  constraint shopping_items_purchase_consistent
    check (
      status <> 'purchased'
      or (purchased_by is not null and purchased_at is not null)
    ),
  constraint shopping_items_removal_consistent
    check (status <> 'removed' or removed_at is not null),
  constraint shopping_items_manual_sort_order_nonnegative
    check (manual_sort_order is null or manual_sort_order >= 0),
  constraint shopping_items_version_positive check (version > 0),
  constraint shopping_items_id_list_unique unique (id, list_id)
);

create index shopping_items_list_status_idx
  on public.shopping_items (list_id, status, created_at);

create table public.client_operations (
  operation_id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  device_installation_id uuid not null,
  operation_type varchar(64) not null,
  target_type varchar(64) not null,
  target_id uuid,
  result_version bigint,
  created_at timestamptz not null default statement_timestamp(),
  constraint client_operations_operation_type_not_blank
    check (length(btrim(operation_type)) between 1 and 64),
  constraint client_operations_target_type_not_blank
    check (length(btrim(target_type)) between 1 and 64),
  constraint client_operations_result_version_positive
    check (result_version is null or result_version > 0)
);

create index client_operations_user_created_idx
  on public.client_operations (user_id, created_at desc);

create table public.list_revisions (
  list_id uuid not null references public.shopping_lists (id) on delete cascade,
  revision bigint not null,
  operation_id uuid references public.client_operations (operation_id) on delete set null,
  entity_type varchar(64) not null,
  entity_id uuid not null,
  changed_at timestamptz not null default statement_timestamp(),
  primary key (list_id, revision),
  constraint list_revisions_revision_positive check (revision > 0),
  constraint list_revisions_entity_type_not_blank
    check (length(btrim(entity_type)) between 1 and 64)
);

create index list_revisions_changed_at_idx
  on public.list_revisions (list_id, changed_at);

create table public.privacy_consents (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  purpose varchar(64) not null,
  policy_version varchar(40) not null,
  granted_at timestamptz not null default statement_timestamp(),
  revoked_at timestamptz,
  constraint privacy_consents_purpose_not_blank
    check (length(btrim(purpose)) between 1 and 64),
  constraint privacy_consents_policy_version_not_blank
    check (length(btrim(policy_version)) between 1 and 40),
  constraint privacy_consents_revocation_after_grant
    check (revoked_at is null or revoked_at >= granted_at)
);

create unique index privacy_consents_one_active_per_purpose_idx
  on public.privacy_consents (user_id, purpose)
  where revoked_at is null;

create table public.shopping_sessions (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  list_id uuid not null references public.shopping_lists (id) on delete cascade,
  store_id uuid not null references public.stores (id) on delete restrict,
  selection_source public.store_selection_source not null,
  device_installation_id uuid not null,
  consent_id uuid references public.privacy_consents (id) on delete set null,
  capabilities varchar(40)[] not null default '{}',
  started_at timestamptz not null default statement_timestamp(),
  ended_at timestamptz,
  constraint shopping_sessions_end_after_start
    check (ended_at is null or ended_at >= started_at),
  constraint shopping_sessions_id_store_unique unique (id, store_id)
);

create unique index shopping_sessions_one_active_per_user_list_idx
  on public.shopping_sessions (user_id, list_id)
  where ended_at is null;
create index shopping_sessions_store_started_idx
  on public.shopping_sessions (store_id, started_at desc);

create table public.purchase_observations (
  id uuid primary key default extensions.gen_random_uuid(),
  session_id uuid not null,
  operation_id uuid not null references public.client_operations (operation_id) on delete restrict,
  store_id uuid not null references public.stores (id) on delete restrict,
  product_id uuid references public.products (id) on delete set null,
  category_id uuid references public.product_categories (id) on delete set null,
  zone_id uuid,
  sequence_number integer not null,
  observed_at_bucket timestamptz not null,
  position_quality public.quality_bucket not null default 'unknown',
  motion_quality public.quality_bucket not null default 'unknown',
  source public.observation_source not null,
  processing_state public.observation_processing_state not null default 'pending',
  created_at timestamptz not null default statement_timestamp(),
  constraint purchase_observations_session_same_store
    foreign key (session_id, store_id)
    references public.shopping_sessions (id, store_id) on delete cascade,
  constraint purchase_observations_zone_same_store
    foreign key (zone_id, store_id)
    references public.store_zones (id, store_id) on delete set null (zone_id),
  constraint purchase_observations_product_xor_category
    check ((product_id is not null) <> (category_id is not null)),
  constraint purchase_observations_sequence_nonnegative
    check (sequence_number >= 0),
  constraint purchase_observations_operation_unique unique (operation_id)
);

create index purchase_observations_pending_idx
  on public.purchase_observations (processing_state, created_at)
  where processing_state = 'pending';
create index purchase_observations_store_product_idx
  on public.purchase_observations (store_id, product_id, observed_at_bucket desc);

create table private.audit_events (
  id bigint generated always as identity primary key,
  actor_user_id uuid references auth.users (id) on delete set null,
  event_type varchar(80) not null,
  subject_type varchar(64) not null,
  subject_id uuid,
  correlation_id uuid,
  occurred_at timestamptz not null default statement_timestamp(),
  constraint audit_events_event_type_not_blank
    check (length(btrim(event_type)) between 1 and 80),
  constraint audit_events_subject_type_not_blank
    check (length(btrim(subject_type)) between 1 and 64)
);

revoke all on table private.audit_events from public, anon, authenticated;
grant select, insert on table private.audit_events to service_role;
grant usage, select on sequence private.audit_events_id_seq to service_role;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function private.set_updated_at();
create trigger households_set_updated_at
before update on public.households
for each row execute function private.set_updated_at();
create trigger product_categories_set_updated_at
before update on public.product_categories
for each row execute function private.set_updated_at();
create trigger products_set_updated_at
before update on public.products
for each row execute function private.set_updated_at();
create trigger store_chains_set_updated_at
before update on public.store_chains
for each row execute function private.set_updated_at();
create trigger stores_set_updated_at
before update on public.stores
for each row execute function private.set_updated_at();
create trigger store_zones_set_updated_at
before update on public.store_zones
for each row execute function private.set_updated_at();
create trigger store_product_estimates_set_updated_at
before update on public.store_product_estimates
for each row execute function private.set_updated_at();
create trigger shopping_lists_set_updated_at
before update on public.shopping_lists
for each row execute function private.set_updated_at();
create trigger shopping_items_set_updated_at
before update on public.shopping_items
for each row execute function private.set_updated_at();

alter table public.profiles enable row level security;
alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.household_invites enable row level security;
alter table public.product_categories enable row level security;
alter table public.products enable row level security;
alter table public.store_chains enable row level security;
alter table public.stores enable row level security;
alter table public.store_zones enable row level security;
alter table public.store_product_estimates enable row level security;
alter table public.shopping_lists enable row level security;
alter table public.shopping_items enable row level security;
alter table public.client_operations enable row level security;
alter table public.list_revisions enable row level security;
alter table public.privacy_consents enable row level security;
alter table public.shopping_sessions enable row level security;
alter table public.purchase_observations enable row level security;

revoke all on all tables in schema public from anon, authenticated;

grant select, insert, update on table public.profiles to authenticated;
grant select, insert, update, delete on table
  public.households,
  public.household_members,
  public.household_invites,
  public.shopping_lists,
  public.shopping_items,
  public.privacy_consents,
  public.shopping_sessions
to authenticated;
grant select on table
  public.product_categories,
  public.products,
  public.store_chains,
  public.stores,
  public.store_zones,
  public.store_product_estimates,
  public.list_revisions
to authenticated;
grant select, insert on table public.client_operations to authenticated;

alter default privileges for role postgres in schema public
  revoke all on tables from anon, authenticated;

commit;

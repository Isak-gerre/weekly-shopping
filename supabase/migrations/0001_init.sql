-- Enable pgcrypto for UUID generation if needed
create extension if not exists pgcrypto;

-- Helper: update updated_at to now() on UPDATE
create or replace function public.set_current_timestamp_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Profiles map to Supabase auth.users
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_profiles_updated_at
before update on public.profiles
for each row execute procedure public.set_current_timestamp_updated_at();

-- Families and membership
create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.family_members (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member', -- owner | admin | member
  created_at timestamptz not null default now(),
  primary key (family_id, user_id)
);

-- Groups and membership (user-centric recipe sharing)
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.group_members (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member', -- owner | admin | member
  created_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

-- Recipes and subrecipes
create table if not exists public.recipes (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  instructions text[],
  servings int not null check (servings > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_recipes_updated_at
before update on public.recipes
for each row execute procedure public.set_current_timestamp_updated_at();

-- Subrecipe relations (parent imports child ingredients/instructions)
create table if not exists public.recipe_subrecipes (
  parent_recipe_id uuid not null references public.recipes(id) on delete cascade,
  child_recipe_id uuid not null references public.recipes(id) on delete restrict,
  primary key (parent_recipe_id, child_recipe_id),
  check (parent_recipe_id <> child_recipe_id)
);

-- Ingredients per recipe
create table if not exists public.ingredients (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  name text not null,
  quantity numeric not null default 0,
  unit text not null default 'unit',
  notes text
);

-- Tags and recipe->tag mapping
create table if not exists public.tags (
  id uuid primary key default gen_random_uuid(),
  label text not null unique,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.recipe_tags (
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  primary key (recipe_id, tag_id)
);

-- Link recipes to groups for sharing
create table if not exists public.group_recipes (
  group_id uuid not null references public.groups(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  primary key (group_id, recipe_id)
);

-- Meal plans (family-visible)
create table if not exists public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  name text not null,
  week_of date not null,
  created_at timestamptz not null default now()
);

create table if not exists public.meal_plan_entries (
  meal_plan_id uuid not null references public.meal_plans(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id) on delete restrict,
  planned_servings int not null check (planned_servings > 0),
  day_of_week int check (day_of_week between 0 and 6),
  primary key (meal_plan_id, recipe_id, day_of_week)
);

-- Shopping lists (family-visible), optionally derived from meal plan
create table if not exists public.shopping_lists (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  meal_plan_id uuid references public.meal_plans(id) on delete set null,
  name text not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.shopping_list_items (
  id uuid primary key default gen_random_uuid(),
  shopping_list_id uuid not null references public.shopping_lists(id) on delete cascade,
  name text not null,
  quantity numeric not null default 0,
  unit text not null default 'unit',
  checked boolean not null default false,
  source_recipe_id uuid references public.recipes(id) on delete set null
);

-- Row Level Security policies (baseline; refine per app needs)
alter table public.profiles enable row level security;
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_subrecipes enable row level security;
alter table public.ingredients enable row level security;
alter table public.tags enable row level security;
alter table public.recipe_tags enable row level security;
alter table public.group_recipes enable row level security;
alter table public.meal_plans enable row level security;
alter table public.meal_plan_entries enable row level security;
alter table public.shopping_lists enable row level security;
alter table public.shopping_list_items enable row level security;

-- Simple permissive policies for development (restrict later)
do $$ begin
  perform 1;
  exception when others then null;
end $$;

create policy "Allow all for authenticated" on public.recipes
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');



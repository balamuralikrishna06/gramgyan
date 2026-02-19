-- Migration: Knowledge Verification Layer
-- 1. Create knowledge_submissions (Pending Layer)
-- 2. Update knowledge_posts (Verified Layer)
-- 3. Add roles to profiles
-- 4. RLS & Functions

-- 🟢 1. Create knowledge_submissions table
create table if not exists knowledge_submissions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade,

  original_text text not null,
  english_text text not null,
  language text not null,

  audio_url text,

  latitude double precision,
  longitude double precision,

  embedding vector(3072), -- Matches verified dimension

  ai_flagged boolean default false,
  ai_reason text, -- Reason for flagging if any
  moderation_status text default 'pending' check (moderation_status in ('pending', 'approved', 'rejected')),

  created_at timestamp with time zone default now()
);

-- Enable RLS
alter table knowledge_submissions enable row level security;

-- 🟢 2. Update knowledge_posts table with verification details
alter table knowledge_posts
add column if not exists submission_id uuid references knowledge_submissions(id),
add column if not exists is_verified boolean default false, -- Default true for admin inserts, but structure suggests explicit
add column if not exists verified_by uuid references auth.users(id),
add column if not exists verified_at timestamp with time zone,
add column if not exists likes_count integer default 0;

-- Backfill existing posts as verified (assuming legacy data is safe)
update knowledge_posts 
set is_verified = true, verified_at = now() 
where is_verified is null;

-- 🟢 3. Add Role to Profiles
-- Check if profiles table exists, if not create based on auth.users (common pattern)
-- Assuming 'profiles' exists or we use 'users' table if custom. 
-- Implementation Plan assumes 'profiles' table exists.
-- Safe add:
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  role text default 'farmer'
);

-- If it already existed, just add the column
do $$
begin
    if not exists (select 1 from information_schema.columns where table_name = 'profiles' and column_name = 'role') then
        alter table profiles add column role text default 'farmer';
    end if;
end $$;

-- 🛡️ 4. RLS Policies

-- A. knowledge_submissions
-- Users can insert their own
create policy "Users can upload submissions"
  on knowledge_submissions for insert
  with check ( auth.uid() = user_id );

-- Users can view their own
create policy "Users can view own submissions"
  on knowledge_submissions for select
  using ( auth.uid() = user_id );

-- Admins/Experts can view ALL (This requires a helper function or claim check)
-- For simplicity in this migration, using a simple check on profiles table if possible, 
-- but RLS recursive checks can be heavy. 
-- Optimization: Use app_metadata or functions. 
-- Here we'll use a direct lookup for simplicity, considering scale.

create or replace function public.is_admin_or_expert()
returns boolean as $$
declare
  _role text;
begin
  select role into _role from profiles where id = auth.uid();
  return _role in ('admin', 'expert');
end;
$$ language plpgsql security definer;

create policy "Admins can view and update submissions"
  on knowledge_submissions
  using ( is_admin_or_expert() );

-- B. knowledge_posts
-- Public can view verified ONLY
drop policy if exists "Enable read access for all users" on knowledge_posts;

create policy "Public can view verified posts"
  on knowledge_posts for select
  using ( is_verified = true );

-- Admins can insert/update
create policy "Admins can manage posts"
  on knowledge_posts
  using ( is_admin_or_expert() )
  with check ( is_admin_or_expert() );

-- 🔍 5. Update Search Function (match_knowledge)
-- Ensure it ONLY matches verified posts
-- Drop first to avoid "cannot change return type" error
drop function if exists match_knowledge(vector, double precision, integer);

create or replace function match_knowledge (
  query_embedding vector(3072),
  match_threshold float,
  match_count int
)
returns table (
  id uuid,
  user_id uuid,
  original_text text,
  english_text text,
  audio_url text,
  similarity float
)
language plpgsql
as $$
begin
  return query
  select
    knowledge_posts.id,
    knowledge_posts.user_id,
    knowledge_posts.original_text,
    knowledge_posts.english_text,
    knowledge_posts.audio_url,
    (1 - (knowledge_posts.embedding <=> query_embedding)) as similarity
  from knowledge_posts
  where 1 - (knowledge_posts.embedding <=> query_embedding) > match_threshold
  and knowledge_posts.is_verified = true -- 🔒 CRITICAL SECURITY CHECK
  order by similarity desc
  limit match_count;
end;
$$;

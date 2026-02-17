-- Enable the pgvector extension to work with embedding vectors
create extension if not exists vector;

-- Update reports table with new columns for AI/Backend flow
alter table "reports" 
add column if not exists "type" text default 'question' check (type in ('question', 'knowledge')),
add column if not exists "status" text default 'open' check (status in ('open', 'solved', 'verified')),
add column if not exists "english_text" text,
add column if not exists "embedding" vector(768); -- Gemini embeddings are usually 768 dimensions

-- Create solutions table for AI or Community answers
create table if not exists "solutions" (
  "id" uuid primary key default gen_random_uuid(),
  "report_id" uuid references "reports" ("id") on delete cascade not null,
  "user_id" uuid references "auth"."users" ("id") on delete set null,
  "solution_text" text not null,
  "ai_generated" boolean default false,
  "upvotes" integer default 0,
  "created_at" timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on solutions
alter table "solutions" enable row level security;

-- Policies for solutions
create policy "Public solutions are viewable by everyone"
  on "solutions" for select
  using ( true );

create policy "Users can insert their own solutions"
  on "solutions" for insert
  with check ( auth.uid() = user_id );

-- ── Semantic Search Function ──
-- Matches reports based on vector similarity of the 'embedding' column
create or replace function match_reports (
  query_embedding vector(768),
  match_threshold float,
  match_count int
)
returns table (
  id uuid,
  original_text text,
  solution_text text,
  similarity float
)
language plpgsql
as $$
begin
  return query(
    select
      r.id,
      r.original_text,
      s.solution_text,
      1 - (r.embedding <=> query_embedding) as similarity -- Cosine similarity
    from reports r
    join solutions s on r.id = s.report_id
    where 1 - (r.embedding <=> query_embedding) > match_threshold
    order by r.embedding <=> query_embedding
    limit match_count
  );
end;
$$;

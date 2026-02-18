-- 1. Create the 'questions' table
create table if not exists questions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id),
  original_text text,
  english_text text,
  embedding vector(768),
  latitude double precision,
  longitude double precision,
  status text default 'open',
  created_at timestamp default now()
);

-- 2. Create the 'match_knowledge' RPC function
create or replace function match_knowledge(
  query_embedding vector(768),
  match_threshold float,
  match_count int
)
returns table (
  id uuid,
  original_text text,
  english_text text,
  similarity float
)
language sql stable
as $$
  select
    id,
    original_text,
    english_text,
    1 - (embedding <=> query_embedding) as similarity
  from knowledge_posts
  where 1 - (embedding <=> query_embedding) > match_threshold
  order by embedding <=> query_embedding
  limit match_count;
$$;

-- 3. Create 'answers' table for community responses (Future proofing for notifications)
create table if not exists answers (
  id uuid primary key default uuid_generate_v4(),
  question_id uuid references questions(id),
  user_id uuid references auth.users(id),
  answer_text text,
  audio_url text,
  created_at timestamp default now()
);

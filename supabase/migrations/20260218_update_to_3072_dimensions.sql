-- Migration to update embedding dimensions to 3072 for gemini-embedding-001

-- 1. Drop the existing function that depends on the vector size
DROP FUNCTION IF EXISTS match_knowledge;

-- 2. Alter tables to change vector dimension
-- Using CASCADE to handle foreign key constraints (e.g. answers table)
TRUNCATE TABLE knowledge_posts CASCADE;
TRUNCATE TABLE questions CASCADE;

ALTER TABLE knowledge_posts 
ALTER COLUMN embedding TYPE vector(3072);

ALTER TABLE questions 
ALTER COLUMN embedding TYPE vector(3072);

-- 3. Recreate the match_knowledge function with 3072 dimensions
create or replace function match_knowledge (
  query_embedding vector(3072),
  match_threshold float,
  match_count int
)
returns setof knowledge_posts
language plpgsql
as $$
begin
  return query
  select *
  from knowledge_posts
  where 1 - (knowledge_posts.embedding <=> query_embedding) > match_threshold
  order by knowledge_posts.embedding <=> query_embedding
  limit match_count;
end;
$$;

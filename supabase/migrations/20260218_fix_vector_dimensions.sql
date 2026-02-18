-- Fix: gemini-embedding-001 produces 3072-dimensional vectors, not 768

-- 1. Update knowledge_posts embedding column
ALTER TABLE knowledge_posts
  ALTER COLUMN embedding TYPE vector(3072);

-- 2. Update questions embedding column
ALTER TABLE questions
  ALTER COLUMN embedding TYPE vector(3072);

-- 3. Recreate match_knowledge function with correct dimensions
CREATE OR REPLACE FUNCTION match_knowledge(
  query_embedding vector(3072),
  match_threshold float,
  match_count int
)
RETURNS TABLE (
  id uuid,
  original_text text,
  english_text text,
  similarity float
)
LANGUAGE sql STABLE
AS $$
  SELECT
    id,
    original_text,
    english_text,
    1 - (embedding <=> query_embedding) AS similarity
  FROM knowledge_posts
  WHERE 1 - (embedding <=> query_embedding) > match_threshold
  ORDER BY embedding <=> query_embedding
  LIMIT match_count;
$$;

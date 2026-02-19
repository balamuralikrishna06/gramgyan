-- Fix match_knowledge to return similarity score
DROP FUNCTION IF EXISTS match_knowledge;

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
  order by similarity desc
  limit match_count;
end;
$$;

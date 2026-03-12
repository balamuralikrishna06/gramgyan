-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL,
  question_id uuid REFERENCES public.questions(id) ON DELETE CASCADE,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can see their own notifications
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can update their own notifications (e.g., mark as read)
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: System/Auth can insert notifications (backend usually bypasses RLS using service key, 
-- but if using anon key, we'd need an insert policy, typically we don't want clients inserting these)

-- Create the RPC function to find recent similar questions based on vector, time, and distance
CREATE OR REPLACE FUNCTION match_recent_questions(
  query_embedding vector(3072),
  query_lat float,
  query_lng float,
  match_threshold float DEFAULT 0.85,
  max_distance_km float DEFAULT 5.0,
  days_ago int DEFAULT 30
)
RETURNS TABLE (
  match_count bigint,
  nearby_user_ids uuid[]
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_count bigint;
  v_user_ids uuid[];
BEGIN
  -- We use the Haversine formula for distance. Earth radius is approx 6371 km.
  -- 1 - (embedding <=> query_embedding) gives cosine similarity.

  SELECT 
    COUNT(id), 
    ARRAY_AGG(user_id) FILTER (WHERE user_id IS NOT NULL)
  INTO 
    v_count, 
    v_user_ids
  FROM public.questions
  WHERE 
    -- 1. Time filter
    created_at >= (now() - (days_ago || ' days')::interval)
    
    -- 2. Embedding similarity filter
    AND 1 - (embedding <=> query_embedding) > match_threshold
    
    -- 3. Distance filter (Haversine formula)
    AND latitude IS NOT NULL 
    AND longitude IS NOT NULL
    AND query_lat IS NOT NULL 
    AND query_lng IS NOT NULL
    AND (
      6371 * acos(
        cos(radians(query_lat)) * cos(radians(latitude)) *
        cos(radians(longitude) - radians(query_lng)) +
        sin(radians(query_lat)) * sin(radians(latitude))
      )
    ) <= max_distance_km;

  -- Return the single row with count and array of user_ids
  RETURN QUERY SELECT v_count, COALESCE(v_user_ids, '{}'::uuid[]);
END;
$$;

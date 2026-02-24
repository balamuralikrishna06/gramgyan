-- Add firebase_uid and phone columns to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS firebase_uid TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS phone TEXT;

-- Create index for faster lookups by firebase_uid
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON public.users(firebase_uid);

-- Comment on columns
COMMENT ON COLUMN public.users.firebase_uid IS 'Firebase Authentication User ID';
COMMENT ON COLUMN public.users.phone IS 'User phone number linked to Firebase Auth';

-- Create user_mappings table
CREATE TABLE public.user_mappings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    firebase_id TEXT NOT NULL UNIQUE,
    uuid UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX idx_user_mappings_firebase_id ON public.user_mappings(firebase_id);

-- Enable Row Level Security
ALTER TABLE public.user_mappings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own mapping"
    ON public.user_mappings
    FOR SELECT
    USING (auth.uid()::text = firebase_id);

CREATE POLICY "Service role can manage all mappings"
    ON public.user_mappings
    FOR ALL
    USING (auth.role() = 'service_role');

-- Grant access to authenticated users
GRANT SELECT ON public.user_mappings TO authenticated;
GRANT INSERT ON public.user_mappings TO authenticated; 
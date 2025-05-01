-- Create enum type for submission status
CREATE TYPE submission_status AS ENUM ('pending', 'approved', 'rejected');

-- Create local_submissions table
CREATE TABLE public.local_submissions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    name TEXT NOT NULL,
    location TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('food', 'experience', 'attraction')),
    description TEXT NOT NULL,
    photo_url TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status submission_status DEFAULT 'pending',
    rejection_reason TEXT,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_local_submissions_user_id ON public.local_submissions(user_id);
CREATE INDEX idx_local_submissions_status ON public.local_submissions(status);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_local_submissions_updated_at
    BEFORE UPDATE ON public.local_submissions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE public.local_submissions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Allow users to view their own submissions
CREATE POLICY "Users can view their own submissions"
    ON public.local_submissions
    FOR SELECT
    USING (auth.uid() = user_id);

-- Allow users to create their own submissions
CREATE POLICY "Users can create their own submissions"
    ON public.local_submissions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own pending submissions
CREATE POLICY "Users can update their own pending submissions"
    ON public.local_submissions
    FOR UPDATE
    USING (auth.uid() = user_id AND status = 'pending');

-- Allow users to delete their own pending submissions
CREATE POLICY "Users can delete their own pending submissions"
    ON public.local_submissions
    FOR DELETE
    USING (auth.uid() = user_id AND status = 'pending');

-- Create storage bucket for submission photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('submission_photos', 'submission_photos', true);

-- Create storage policy for submission photos
CREATE POLICY "Users can upload their own submission photos"
    ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'submission_photos' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Anyone can view submission photos"
    ON storage.objects
    FOR SELECT
    USING (bucket_id = 'submission_photos'); 
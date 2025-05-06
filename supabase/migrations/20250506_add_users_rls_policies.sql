-- Add RLS policies for users table
-- First, make sure RLS is enabled on the users table
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows staff members to view all users
CREATE POLICY "Staff can view all users"
    ON auth.users
    FOR SELECT
    USING (
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'stb_staff' OR
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
    );

-- Create a policy that allows users to view only their own data
CREATE POLICY "Users can view their own user data"
    ON auth.users
    FOR SELECT
    USING (auth.uid() = id);

-- Grant permissions to the authenticated role to select from users table
GRANT SELECT ON auth.users TO authenticated;
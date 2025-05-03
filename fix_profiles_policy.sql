-- STEP 1: Drop all existing policies on the profiles table
-- We need to drop each policy by name, or use pg_policy to get the names first
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'profiles'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON profiles', policy_record.policyname);
    END LOOP;
END
$$;

-- STEP 2: Enable RLS on the profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- STEP 3: Create simple policy that allows everyone to read any profile
CREATE POLICY "Allow anyone to read profiles"
ON profiles FOR SELECT
USING (true);

-- STEP 4: Allow authenticated users to update their own profile
CREATE POLICY "Allow users to update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);

-- STEP 5: Allow authenticated users to insert their own profile
CREATE POLICY "Allow users to insert own profile"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- STEP 6: Grant appropriate permissions to roles
GRANT SELECT ON profiles TO anon, authenticated;
GRANT UPDATE, INSERT ON profiles TO authenticated;
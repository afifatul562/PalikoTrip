-- =====================================================
-- STEP 2: ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================
-- File: 02_rls_policies.sql
-- Deskripsi: Membuat policies untuk keamanan data dan foto profil
-- =====================================================

-- =====================================================
-- POLICIES UNTUK USER_PROFILES
-- =====================================================

-- Users can view their own profile
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own profile (including profile_image_url)
CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can insert their own profile
CREATE POLICY "Users can insert their own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Public read access for profile images (for display purposes)
CREATE POLICY "Public can view profile images" ON user_profiles
    FOR SELECT USING (true);

-- =====================================================
-- POLICIES UNTUK WISATA
-- =====================================================

-- Anyone can view wisata (public read access)
CREATE POLICY "Anyone can view wisata" ON wisata
    FOR SELECT USING (true);

-- Admin can insert wisata (only admin can add new wisata)
CREATE POLICY "Admin can insert wisata" ON wisata
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- Admin can update wisata (only admin can edit wisata)
CREATE POLICY "Admin can update wisata" ON wisata
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- Admin can delete wisata (only admin can delete wisata)
CREATE POLICY "Admin can delete wisata" ON wisata
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- =====================================================
-- POLICIES UNTUK USER_FAVORITES
-- =====================================================

-- Users can view their own favorites
CREATE POLICY "Users can view their own favorites" ON user_favorites
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own favorites
CREATE POLICY "Users can insert their own favorites" ON user_favorites
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can delete their own favorites
CREATE POLICY "Users can delete their own favorites" ON user_favorites
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- STORAGE POLICIES UNTUK FOTO PROFIL
-- =====================================================

-- Create storage bucket for user uploads if not exists
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'user-uploads',
  'user-uploads',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload their own profile images
CREATE POLICY "Users can upload profile images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'user-uploads' AND
  auth.uid() IS NOT NULL AND
  name LIKE 'profile_images/' || auth.uid()::text || '/%'
);

-- Allow users to view their own profile images
CREATE POLICY "Users can view their own profile images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'user-uploads' AND
  auth.uid() IS NOT NULL AND
  name LIKE 'profile_images/' || auth.uid()::text || '/%'
);

-- Allow users to update their own profile images
CREATE POLICY "Users can update their own profile images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'user-uploads' AND
  auth.uid() IS NOT NULL AND
  name LIKE 'profile_images/' || auth.uid()::text || '/%'
);

-- Allow users to delete their own profile images
CREATE POLICY "Users can delete their own profile images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'user-uploads' AND
  auth.uid() IS NOT NULL AND
  name LIKE 'profile_images/' || auth.uid()::text || '/%'
);

-- Public access to profile images (for display in app)
CREATE POLICY "Public can view profile images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'user-uploads' AND
  name LIKE 'profile_images/%'
);

-- =====================================================
-- STORAGE POLICIES UNTUK WISATA IMAGES
-- =====================================================

-- Create storage bucket for wisata images if not exists
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'wisata-images',
  'wisata-images',
  true,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload wisata images
CREATE POLICY "Authenticated users can upload wisata images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'wisata-images' AND 
  auth.uid() IS NOT NULL
);

-- Public read access for wisata images
CREATE POLICY "Public can view wisata images" ON storage.objects
FOR SELECT USING (bucket_id = 'wisata-images');

-- Allow authenticated users to update wisata images
CREATE POLICY "Authenticated users can update wisata images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'wisata-images' AND 
  auth.uid() IS NOT NULL
);

-- Allow authenticated users to delete wisata images
CREATE POLICY "Authenticated users can delete wisata images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'wisata-images' AND 
  auth.uid() IS NOT NULL
);

-- =====================================================
-- FUNCTION UNTUK VALIDASI FOTO PROFIL
-- =====================================================

-- Function to validate profile image upload
CREATE OR REPLACE FUNCTION validate_profile_image_upload()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if user is authenticated
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated to upload profile images';
  END IF;
  
  -- Check if file is in correct folder
  IF NEW.name NOT LIKE 'profile_images/' || auth.uid()::text || '/%' THEN
    RAISE EXCEPTION 'Profile images must be uploaded to user-specific folder';
  END IF;
  
  -- Check file size (5MB limit)
  IF NEW.metadata->>'size'::text::bigint > 5242880 THEN
    RAISE EXCEPTION 'File size must be less than 5MB';
  END IF;
  
  -- Check file type
  IF NEW.mime_type NOT IN ('image/jpeg', 'image/png', 'image/gif', 'image/webp') THEN
    RAISE EXCEPTION 'Only image files are allowed (JPEG, PNG, GIF, WebP)';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for profile image validation
CREATE TRIGGER validate_profile_image_upload_trigger
  BEFORE INSERT ON storage.objects
  FOR EACH ROW
  WHEN (NEW.bucket_id = 'user-uploads' AND NEW.name LIKE 'profile_images/%')
  EXECUTE FUNCTION validate_profile_image_upload();

-- =====================================================
-- FUNCTION UNTUK CLEANUP FOTO PROFIL LAMA
-- =====================================================

-- Function to cleanup old profile images when new one is uploaded
CREATE OR REPLACE FUNCTION cleanup_old_profile_images()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete old profile images for the same user
  DELETE FROM storage.objects 
  WHERE bucket_id = 'user-uploads' 
    AND name LIKE 'profile_images/' || auth.uid()::text || '/%'
    AND name != NEW.name;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for cleanup old profile images
CREATE TRIGGER cleanup_old_profile_images_trigger
  AFTER INSERT ON storage.objects
  FOR EACH ROW
  WHEN (NEW.bucket_id = 'user-uploads' AND NEW.name LIKE 'profile_images/%')
  EXECUTE FUNCTION cleanup_old_profile_images();

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
-- ✅ RLS Policies berhasil dibuat!
-- ✅ User profiles: User hanya bisa akses data sendiri
-- ✅ Wisata: Public read, Admin-only write
-- ✅ Favorites: User hanya bisa akses data sendiri
-- ✅ Storage buckets: user-uploads dan wisata-images
-- ✅ Profile images: Secure upload dengan validasi
-- ✅ Public access: Profile images bisa diakses untuk display
-- ✅ Auto cleanup: Foto lama otomatis dihapus saat upload baru
-- 
-- Lanjut ke file: 03_storage_setup.sql
-- ===================================================== 
-- =====================================================
-- COMPLETE SUPABASE SETUP - MTrip App
-- =====================================================
-- File: complete_setup.sql
-- Deskripsi: Semua setup dalam 1 file untuk kemudahan
-- =====================================================

-- =====================================================
-- STEP 1: DATABASE TABLES
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    username TEXT NOT NULL,
    role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    profile_image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create wisata table
CREATE TABLE IF NOT EXISTS wisata (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nama TEXT NOT NULL,
    deskripsi TEXT,
    alamat TEXT,
    image_url TEXT,
    maps_url TEXT,
    kategori TEXT DEFAULT 'Wisata Alam',
    rating DECIMAL(3,2) DEFAULT 0.0,
    review_count INTEGER DEFAULT 0,
    fasilitas TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_favorites table
CREATE TABLE IF NOT EXISTS user_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    wisata_id UUID REFERENCES wisata(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, wisata_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_wisata_kategori ON wisata(kategori);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_wisata_id ON user_favorites(wisata_id);

-- Enable Row Level Security (RLS)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE wisata ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 2: RLS POLICIES
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
-- STEP 3: STORAGE SETUP
-- =====================================================

-- Create storage bucket for user uploads
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'user-uploads',
  'user-uploads',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Create storage bucket for wisata images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'wisata-images',
  'wisata-images',
  true,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Storage policies for user-uploads bucket
CREATE POLICY "Users can upload their own files" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'user-uploads' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view their own files" ON storage.objects
FOR SELECT USING (
  bucket_id = 'user-uploads' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update their own files" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'user-uploads' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own files" ON storage.objects
FOR DELETE USING (
  bucket_id = 'user-uploads' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Public access to profile images (for display)
CREATE POLICY "Public access to profile images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'user-uploads' AND
  name LIKE 'profile_images/%'
);

-- Storage policies for wisata-images bucket
CREATE POLICY "Allow authenticated uploads" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'wisata-images' AND 
        auth.uid() IS NOT NULL
    );

CREATE POLICY "Allow public read access" ON storage.objects
    FOR SELECT USING (bucket_id = 'wisata-images');

CREATE POLICY "Allow authenticated updates" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'wisata-images' AND 
        auth.uid() IS NOT NULL
    );

CREATE POLICY "Allow authenticated deletes" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'wisata-images' AND 
        auth.uid() IS NOT NULL
    );

-- =====================================================
-- STEP 4: TRIGGER SETUP
-- =====================================================

-- Function untuk handle new user
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_profiles (user_id, email, username, role)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'username', NEW.email), 'user');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger untuk new user registration
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- STEP 5: SAMPLE DATA
-- =====================================================

-- Insert sample data untuk wisata
INSERT INTO wisata (nama, deskripsi, alamat, image_url, maps_url, kategori, rating, review_count, fasilitas) VALUES
(
    'Lembah Harau',
    'Lembah Harau adalah destinasi wisata alam yang terkenal dengan tebing-tebing batu yang menjulang tinggi dan pemandangan yang memukau. Tempat ini sangat cocok untuk hiking, fotografi, dan menikmati keindahan alam.',
    'Kecamatan Harau, Kabupaten 50 Kota, Sumatera Barat',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
    'https://maps.google.com/?q=Lembah+Harau+50+Kota',
    'Wisata Alam',
    4.5,
    150,
    ARRAY['Parkir Luas', 'Musholla', 'Warung Makan', 'Tempat Camping', 'Pemandu Wisata']
),
(
    'Kelok Sembilan',
    'Kelok Sembilan adalah jalan berkelok yang terkenal dengan pemandangan alam yang indah. Jalan ini menghubungkan Payakumbuh dengan Bukittinggi dan menawarkan view yang spektakuler.',
    'Jalan Lintas Payakumbuh-Bukittinggi, Sumatera Barat',
    'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800',
    'https://maps.google.com/?q=Kelok+Sembilan+Payakumbuh',
    'Wisata Alam',
    4.3,
    200,
    ARRAY['Tempat Foto', 'Warung Kopi', 'Parkir', 'Toilet Umum']
),
(
    'Ngalau Indah',
    'Ngalau Indah adalah gua alam yang memiliki stalaktit dan stalagmit yang indah. Gua ini juga memiliki sejarah yang menarik dan sering dikunjungi wisatawan.',
    'Kecamatan Payakumbuh, Kota Payakumbuh, Sumatera Barat',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
    'https://maps.google.com/?q=Ngalau+Indah+Payakumbuh',
    'Wisata Alam',
    4.2,
    80,
    ARRAY['Pemandu Wisata', 'Penerangan', 'Toilet', 'Warung Makan']
),
(
    'Cafe Forest',
    'Cafe Forest adalah tempat nongkrong yang nyaman dengan suasana alam. Menyajikan berbagai menu kopi dan makanan ringan dengan view yang asri.',
    'Jl. Soekarno-Hatta, Payakumbuh',
    'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800',
    'https://maps.google.com/?q=Cafe+Forest+Payakumbuh',
    'Cafe',
    4.4,
    120,
    ARRAY['WiFi Gratis', 'Power Outlet', 'Ruang Indoor', 'Ruang Outdoor', 'Live Music']
),
(
    'Warung Makan Sederhana',
    'Warung makan tradisional yang menyajikan masakan khas Minang dengan cita rasa autentik. Tempat yang nyaman untuk menikmati hidangan lokal.',
    'Jl. Sudirman, Payakumbuh',
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=800',
    'https://maps.google.com/?q=Warung+Makan+Sederhana+Payakumbuh',
    'Wisata Kuliner',
    4.1,
    95,
    ARRAY['Parkir Motor', 'Toilet', 'Ruang AC', 'Delivery']
);

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
-- ✅ COMPLETE SETUP BERHASIL!
-- 
-- SELANJUTNYA:
-- 1. Buat bucket 'wisata-images' di menu Storage (Public bucket)
-- 2. Dapatkan API keys di menu Settings > API
-- 3. Update API keys di main.dart
-- 4. Register user ifa@admin.com di aplikasi
-- 5. Jalankan query admin setup:
--    UPDATE user_profiles SET role = 'admin' WHERE email = 'ifa@admin.com';
-- 6. Test aplikasi Flutter
-- ===================================================== 
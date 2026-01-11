-- =====================================================
-- STEP 3: STORAGE SETUP
-- =====================================================
-- File: 03_storage_setup.sql
-- Deskripsi: Setup Supabase Storage untuk upload file
-- =====================================================

-- =====================================================
-- CATATAN: BUCKET HARUS DIBUAT MANUAL
-- =====================================================
-- 1. Buka menu "Storage" di sidebar Supabase
-- 2. Klik "New bucket"
-- 3. Beri nama: wisata-images
-- 4. Pilih "Public bucket"
-- 5. Klik "Create bucket"
-- =====================================================

-- =====================================================
-- STORAGE POLICIES UNTUK BUCKET 'wisata-images'
-- =====================================================

-- Policy untuk upload gambar (hanya user yang login)
CREATE POLICY "Allow authenticated uploads" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'wisata-images' AND 
        auth.uid() IS NOT NULL
    );

-- Policy untuk membaca gambar (semua user bisa akses)
CREATE POLICY "Allow public read access" ON storage.objects
    FOR SELECT USING (bucket_id = 'wisata-images');

-- Policy untuk update gambar (hanya user yang login)
CREATE POLICY "Allow authenticated updates" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'wisata-images' AND 
        auth.uid() IS NOT NULL
    );

-- Policy untuk delete gambar (hanya user yang login)
CREATE POLICY "Allow authenticated deletes" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'wisata-images' AND 
        auth.uid() IS NOT NULL
    );

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
-- ✅ Storage policies berhasil dibuat!
-- 
-- JANGAN LUPA:
-- 1. Buat bucket 'wisata-images' secara manual di menu Storage
-- 2. Pilih "Public bucket" agar gambar bisa diakses publik
-- 
-- Lanjut ke file: 04_sample_data.sql
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

-- Create storage policies for user-uploads bucket
-- Allow authenticated users to upload their own files
CREATE POLICY "Users can upload their own files" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'user-uploads' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to view their own files
CREATE POLICY "Users can view their own files" ON storage.objects
FOR SELECT USING (
  bucket_id = 'user-uploads' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to update their own files
CREATE POLICY "Users can update their own files" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'user-uploads' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to delete their own files
CREATE POLICY "Users can delete their own files" ON storage.objects
FOR DELETE USING (
  bucket_id = 'user-uploads' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow public access to profile images (for display)
CREATE POLICY "Public access to profile images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'user-uploads' AND
  name LIKE 'profile_images/%'
);

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
-- ✅ Storage bucket 'user-uploads' berhasil dibuat!
-- ✅ Storage policies sudah dikonfigurasi
-- ✅ File size limit: 5MB
-- ✅ Allowed file types: JPEG, PNG, GIF, WebP
-- ✅ Public access untuk profile images
-- 
-- Lanjut ke file: complete_setup.sql
-- ===================================================== 
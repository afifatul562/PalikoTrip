-- Create tables for Paliko Trip application

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    username TEXT NOT NULL,
    role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
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

-- Create RLS policies for user_profiles
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create RLS policies for wisata (public read, admin write)
CREATE POLICY "Anyone can view wisata" ON wisata
    FOR SELECT USING (true);

CREATE POLICY "Admin can insert wisata" ON wisata
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admin can update wisata" ON wisata
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admin can delete wisata" ON wisata
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- Create RLS policies for user_favorites
CREATE POLICY "Users can view their own favorites" ON user_favorites
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own favorites" ON user_favorites
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own favorites" ON user_favorites
    FOR DELETE USING (auth.uid() = user_id);

-- Create function to handle user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_profiles (user_id, email, username, role)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'username', NEW.email), 'user');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user registration
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Insert sample data for wisata (dummy awal)
INSERT INTO wisata (nama, deskripsi, alamat, image_url, maps_url, kategori, rating, review_count, fasilitas) VALUES
(
    'Lembah Harau',
    'Lembah Harau adalah destinasi wisata alam yang terkenal dengan tebing-tebing batu yang menjulang tinggi dan pemandangan yang memukau. Tempat ini sangat cocok untuk hiking, fotografi, dan menikmati keindahan alam.',
    'Kecamatan Harau, Kabupaten 50 Kota, Sumatera Barat',
    'https://example.com/lembah_harau.jpg',
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
    'https://example.com/kelok_sembilan.jpg',
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
    'https://example.com/ngalau_indah.jpg',
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
    'https://example.com/cafe_forest.jpg',
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
    'https://example.com/warung_makan.jpg',
    'https://maps.google.com/?q=Warung+Makan+Sederhana+Payakumbuh',
    'Wisata Kuliner',
    4.1,
    95,
    ARRAY['Parkir Motor', 'Toilet', 'Ruang AC', 'Delivery']
);

-- Create admin user (you need to create this user in Supabase Auth first)
-- Then run this query to make them admin:
-- UPDATE user_profiles SET role = 'admin' WHERE email = 'admin@palikotrip.com'; 
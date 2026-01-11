# Supabase Setup untuk MTrip App

Folder ini berisi semua file setup untuk project Supabase baru.

## 📁 Struktur Folder:
```
supabase_setup/
├── README.md                    # File ini
├── 01_database_tables.sql       # Setup tabel database
├── 02_rls_policies.sql          # Setup Row Level Security
├── 03_storage_setup.sql         # Setup storage bucket & policies
├── 04_sample_data.sql           # Data sample wisata
├── 05_admin_setup.sql           # Setup admin user
└── complete_setup.sql           # Semua query dalam 1 file
```

## 🚀 Cara Penggunaan:

### Opsi 1: Setup Step by Step (Recommended)
1. Jalankan `01_database_tables.sql`
2. Jalankan `02_rls_policies.sql`
3. Jalankan `03_storage_setup.sql`
4. Jalankan `04_sample_data.sql`
5. Register user `ifa@admin.com` di app
6. Jalankan `05_admin_setup.sql`

### Opsi 2: Setup Sekaligus
- Jalankan `complete_setup.sql` (semua dalam 1 file)

## 📋 Checklist Setup:
- [ ] Project Supabase baru dibuat
- [ ] Database tables terbuat
- [ ] RLS policies aktif
- [ ] Storage bucket terbuat
- [ ] Sample data ter-insert
- [ ] Admin user ter-setup
- [ ] API keys diupdate di main.dart
- [ ] App berjalan tanpa error

## 🔧 Troubleshooting:
- Jika ada error, cek log di SQL Editor
- Pastikan query dijalankan secara berurutan
- Cek policies di menu Authentication > Policies 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtrip/services/user_service.dart';
import 'package:mtrip/pages/login_screen.dart';
import 'package:mtrip/pages/register_screen.dart';

class AkunPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;
  final String username;
  final VoidCallback onLogout;
  final VoidCallback onAdminDashboard;

  const AkunPage({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
    required this.username,
    required this.onLogout,
    required this.onAdminDashboard,
  });

  @override
  State<AkunPage> createState() => _AkunPageState();
}

class _AkunPageState extends State<AkunPage> {
  final UserService _userService = UserService();
  bool _loadingRole = true;
  String? _username;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _fetchUsername();
  }

  Future<void> _fetchUserRole() async {
    try {
      setState(() {
        _loadingRole = false;
      });
    } catch (e) {
      setState(() {
        _loadingRole = false;
      });
      debugPrint('Error fetch role: $e');
    }
  }

  Future<void> _fetchUsername() async {
    final user = _userService.getCurrentUser();
    if (user != null) {
      final profile = await _userService.getUserProfile();
      setState(() {
        _username = profile?['username'] ?? user.email;
      });
    } else {
      setState(() {
        _username = null;
      });
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Konfirmasi Keluar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Apakah Anda yakin ingin keluar dari aplikasi?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onLogout();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Keluar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _userService.getCurrentUser();
    if (user == null) {
      // Belum login: tampilkan tombol Login & Register
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => LoginScreen(
                            onLoginSuccess: (username) async {
                              await _fetchUsername();
                              setState(() {});
                              Navigator.pop(
                                context,
                              ); // Tutup LoginScreen setelah login sukses
                            },
                          ),
                    ),
                  );
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                  // Setelah register, bisa langsung fetch username jika auto-login
                  await _fetchUsername();
                  setState(() {});
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      );
    }
    // Sudah login: tampilkan isi profil seperti sebelumnya
    final userEmail = user.email;
    final isIfaAdmin = userEmail == 'ifa@admin.com';
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    (_username ?? userEmail) ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isIfaAdmin ? 'Administrator' : 'Pengguna Aktif',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Menu Items
            if (_loadingRole)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Admin Dashboard (only for ifa@admin.com)
              if (isIfaAdmin)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    'Admin Dashboard',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Kelola data wisata',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: widget.onAdminDashboard,
                ),

              // Theme Toggle
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  'Mode ${widget.isDarkMode ? 'Terang' : 'Gelap'}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Ubah tema aplikasi',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                trailing: Switch(
                  value: widget.isDarkMode,
                  onChanged: widget.toggleTheme,
                ),
              ),

              // Help & Support
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  'Bantuan & Dukungan',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Pusat bantuan aplikasi',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(
                            'Bantuan & Dukungan',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Jika Anda mengalami kendala atau membutuhkan bantuan, silakan hubungi kami melalui:',
                                  style: GoogleFonts.poppins(),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.email,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'afifatulmawaddah562@gmail.com',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '+62 831-9115-8446',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'FAQ:',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Q: Bagaimana cara menambahkan destinasi ke favorit?\nA: Buka detail destinasi, lalu klik ikon hati di pojok kanan atas.',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Q: Bagaimana jika lupa password?\nA: Silakan gunakan fitur "Lupa Password" di halaman login.',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Q: Bagaimana menghubungi admin?\nA: Hubungi kontak di atas atau email.',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Tutup'),
                            ),
                          ],
                        ),
                  );
                },
              ),

              // About
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  'Tentang Aplikasi',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Informasi aplikasi',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(
                            'Tentang Paliko Trip',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paliko Trip adalah aplikasi mobile yang membantu Anda menemukan, menjelajahi, dan menikmati destinasi wisata terbaik di Kota Payakumbuh dan Kabupaten 50 Kota. Dilengkapi dengan fitur pencarian, kategori, favorit, dan informasi lengkap setiap destinasi.',
                                style: GoogleFonts.poppins(),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Dikembangkan oleh:',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Afifatul Mawaddah (221013001) - 2025',
                                style: GoogleFonts.poppins(),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Tutup'),
                            ),
                          ],
                        ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(
                    'Keluar',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

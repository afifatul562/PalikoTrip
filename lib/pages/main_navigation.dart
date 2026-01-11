import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtrip/pages/wisata_list_page.dart';
import 'package:mtrip/pages/favorit_page.dart';
import 'package:mtrip/pages/akun_page.dart';
import 'package:mtrip/pages/kategori_page.dart';
import 'package:mtrip/pages/admin/admin_dashboard.dart';
import 'package:mtrip/services/wisata_service.dart';
import 'package:mtrip/services/user_service.dart';
import 'package:mtrip/services/auth_service.dart';
import 'dart:async';
import 'package:mtrip/main.dart';

class MainNavigation extends StatefulWidget {
  final String username;
  final Function(bool)? onThemeChanged;
  final VoidCallback? onLogout;
  final int initialIndex;

  const MainNavigation({
    super.key,
    required this.username,
    this.onThemeChanged,
    this.onLogout,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;
  bool _isDarkMode = false;
  List<Map<String, dynamic>> _wisataList = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _loadingRole = true;
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  StreamSubscription<List<Map<String, dynamic>>>? _wisataSubscription;

  final List<IconData> _icons = [
    Icons.home,
    Icons.favorite,
    Icons.category,
    Icons.person,
  ];
  final List<String> _titles = ['Beranda', 'Favorit', 'Kategori', 'Akun'];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _fetchUserRole();
    _loadWisataData();
    _listenToWisataUpdates();
  }

  @override
  void dispose() {
    _wisataSubscription?.cancel();
    super.dispose();
  }

  void _listenToWisataUpdates() {
    _wisataSubscription = WisataService.wisataStream.listen((data) {
      if (mounted) {
        setState(() {
          _wisataList = data;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _fetchUserRole() async {
    try {
      final isAdmin = await _userService.isAdmin();
      setState(() {
        _isAdmin = isAdmin;
        _loadingRole = false;
      });
    } catch (e) {
      setState(() {
        _loadingRole = false;
      });
      debugPrint('Error fetch role: $e');
    }
  }

  Future<void> _loadWisataData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final wisataService = WisataService();
      final data = await wisataService.getAllWisata();
      setState(() {
        _wisataList = data;
        _isLoading = false;
      });
      // Emit initial data through stream
      wisataService.emitInitialData();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    widget.onThemeChanged?.call(value);
  }

  Future<void> _navigateToAdminDashboard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboard()),
    );
    if (result == true) {
      _loadWisataData();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _authService.logout(context);
      widget.onLogout?.call();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WisataApp()),
        (route) => false,
      );
    }
  }

  List<Widget> get _pages => [
    WisataListPage(wisataList: _wisataList, onRefresh: _loadWisataData),
    const FavoritPage(),
    KategoriPage(),
    AkunPage(
      isDarkMode: _isDarkMode,
      toggleTheme: _toggleTheme,
      username: widget.username,
      onLogout: _logout,
      onAdminDashboard: _navigateToAdminDashboard,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          if (!_loadingRole && _isAdmin && _selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: _navigateToAdminDashboard,
              tooltip: 'Admin Dashboard',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items:
              _icons
                  .asMap()
                  .entries
                  .map(
                    (entry) => BottomNavigationBarItem(
                      icon: Icon(entry.value),
                      label: _titles[entry.key],
                    ),
                  )
                  .toList(),
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }
}

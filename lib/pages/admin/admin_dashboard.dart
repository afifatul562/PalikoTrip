import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtrip/pages/admin/add_wisata_page.dart';
import 'package:mtrip/pages/admin/edit_wisata_page.dart';
import 'package:mtrip/pages/admin/user_management_page.dart';
import 'package:mtrip/services/wisata_service.dart';
import 'package:mtrip/services/user_service.dart';
import 'dart:async';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> _wisataList = [];
  bool _isLoading = true;
  final WisataService _wisataService = WisataService();
  final UserService _userService = UserService();
  StreamSubscription<List<Map<String, dynamic>>>? _wisataSubscription;

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadWisataData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _wisataService.getAllWisata();
      setState(() {
        _wisataList = data;
        _isLoading = false;
      });
      // Emit updated data through stream
      _wisataService.emitInitialData();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _navigateToAddWisata() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddWisataPage()),
    );
    if (result == true) {
      _loadWisataData();
    }
  }

  Future<void> _navigateToEditWisata(Map<String, dynamic> wisata) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditWisataPage(wisata: wisata)),
    );
    if (result == true) {
      _loadWisataData();
    }
  }

  void _navigateToUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserManagementPage()),
    );
  }

  Future<void> _deleteWisata(String id, String nama) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text('Apakah Anda yakin ingin menghapus wisata "$nama"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _wisataService.deleteWisata(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wisata berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadWisataData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _userService.getCurrentUser()?.email;
    final isIfaAdmin = userEmail == 'ifa@admin.com';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat Datang, Admin!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Kelola data wisata dengan mudah',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${_wisataList.length}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Total Wisata',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _navigateToUserManagement,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.people,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Kelola User',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content Section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daftar Wisata',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isIfaAdmin)
                                ElevatedButton.icon(
                                  onPressed: _navigateToAddWisata,
                                  icon: const Icon(Icons.add),
                                  label: Text(
                                    'Tambah Wisata',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _loadWisataData,
                              child:
                                  _wisataList.isEmpty
                                      ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.location_off,
                                              size: 80,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Belum ada data wisata',
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Mulai dengan menambahkan wisata baru',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      : ListView.builder(
                                        itemCount: _wisataList.length,
                                        itemBuilder: (context, index) {
                                          final wisata = _wisataList[index];
                                          final nama =
                                              wisata['nama']?.toString() ?? '';
                                          final imageUrl =
                                              wisata['image_url']?.toString() ??
                                              '';

                                          return Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: ListTile(
                                              leading: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  imageUrl,
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              title: Text(
                                                nama,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                wisata['alamat']?.toString() ??
                                                    '',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              trailing:
                                                  isIfaAdmin
                                                      ? Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            onPressed:
                                                                () =>
                                                                    _navigateToEditWisata(
                                                                      wisata,
                                                                    ),
                                                            icon: const Icon(
                                                              Icons.edit,
                                                            ),
                                                            color: Colors.blue,
                                                          ),
                                                          IconButton(
                                                            onPressed:
                                                                () => _deleteWisata(
                                                                  wisata['id']
                                                                          ?.toString() ??
                                                                      '',
                                                                  nama,
                                                                ),
                                                            icon: const Icon(
                                                              Icons.delete,
                                                            ),
                                                            color: Colors.red,
                                                          ),
                                                        ],
                                                      )
                                                      : null,
                                            ),
                                          );
                                        },
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      floatingActionButton:
          isIfaAdmin
              ? FloatingActionButton(
                onPressed: _navigateToAddWisata,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}

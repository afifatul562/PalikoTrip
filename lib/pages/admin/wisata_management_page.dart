import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtrip/services/wisata_service.dart';
import 'package:mtrip/pages/admin/edit_wisata_page.dart';

class WisataManagementPage extends StatefulWidget {
  const WisataManagementPage({super.key});

  @override
  State<WisataManagementPage> createState() => _WisataManagementPageState();
}

class _WisataManagementPageState extends State<WisataManagementPage> {
  final WisataService _wisataService = WisataService();
  List<Map<String, dynamic>> _wisataList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWisataData();
  }

  Future<void> _loadWisataData() async {
    setState(() {
      _isLoading = true;
    });

    final data = await _wisataService.getAllWisata();
    setState(() {
      _wisataList = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteWisata(String id, String nama) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Konfirmasi Hapus'),
            content: Text('Apakah Anda yakin ingin menghapus wisata "$nama"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      final success = await _wisataService.deleteWisata(id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wisata "$nama" berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadWisataData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus wisata'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredWisataList {
    if (_searchQuery.isEmpty) {
      return _wisataList;
    }
    return _wisataList.where((wisata) {
      final nama = wisata['nama']?.toString().toLowerCase() ?? '';
      final kategori = wisata['kategori']?.toString().toLowerCase() ?? '';
      final alamat = wisata['alamat']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return nama.contains(query) ||
          kategori.contains(query) ||
          alamat.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelola Wisata',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari wisata...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Wisata List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredWisataList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                      onRefresh: _loadWisataData,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredWisataList.length,
                        itemBuilder: (context, index) {
                          final wisata = _filteredWisataList[index];
                          return _buildWisataCard(wisata);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildWisataCard(Map<String, dynamic> wisata) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image and basic info
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              image: DecorationImage(
                image: NetworkImage(wisata['image_url'] ?? ''),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  // Handle image error
                },
              ),
            ),
            child: Stack(
              children: [
                // Category badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      wisata['kategori'] ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Rating badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${wisata['rating']?.toStringAsFixed(1) ?? '0.0'}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wisata['nama'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  wisata['alamat'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (wisata['deskripsi']?.toString() ?? '').length > 100
                      ? '${wisata['deskripsi'].toString().substring(0, 100)}...'
                      : wisata['deskripsi']?.toString() ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editWisata(wisata),
                        icon: Icon(Icons.edit, size: 16),
                        label: Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            () => _deleteWisata(
                              wisata['id'].toString(),
                              wisata['nama'] ?? '',
                            ),
                        icon: Icon(Icons.delete, size: 16),
                        label: Text('Hapus'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Belum ada data wisata'
                : 'Tidak ada hasil ditemukan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Tambahkan wisata pertama Anda'
                : 'Coba kata kunci lain',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _editWisata(Map<String, dynamic> wisata) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditWisataPage(wisata: wisata)),
    ).then((result) {
      if (result == true) {
        _loadWisataData();
      }
    });
  }
}

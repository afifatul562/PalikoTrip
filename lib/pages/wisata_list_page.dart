import 'package:flutter/material.dart';
import 'package:mtrip/pages/detail_wisata_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mtrip/services/favorit_service.dart';
import 'package:mtrip/services/wisata_service.dart';
import 'package:mtrip/services/user_service.dart';
import 'package:mtrip/pages/main_navigation.dart';

class WisataListPage extends StatefulWidget {
  final List<Map<String, dynamic>> wisataList;
  final Future<void> Function()? onRefresh;

  const WisataListPage({super.key, required this.wisataList, this.onRefresh});

  @override
  WisataListPageState createState() => WisataListPageState();
}

class WisataListPageState extends State<WisataListPage> {
  List<Map<String, dynamic>> _filteredWisataList = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final FavoritService _favoritService = FavoritService();
  final Map<String, bool> _favoriteStatus = {};

  @override
  void initState() {
    super.initState();
    _filteredWisataList = widget.wisataList;
    _searchController.addListener(_searchWisata);
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    for (final wisata in widget.wisataList) {
      final id = wisata['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        final isFavorited = await _favoritService.isFavorited(id);
        setState(() {
          _favoriteStatus[id] = isFavorited;
        });
      }
    }
  }

  Future<void> _toggleFavorite(String id, String nama) async {
    try {
      final isCurrentlyFavorited = _favoriteStatus[id] ?? false;

      if (isCurrentlyFavorited) {
        final success = await _favoritService.removeFavorite(id);
        if (success) {
          setState(() {
            _favoriteStatus[id] = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$nama dihapus dari favorit'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        final success = await _favoritService.addFavorite(id);
        if (success) {
          setState(() {
            _favoriteStatus[id] = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$nama ditambahkan ke favorit'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _searchWisata() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      _filteredWisataList =
          widget.wisataList.where((wisata) {
            final nama = wisata['nama']?.toString().toLowerCase() ?? '';
            final deskripsi =
                wisata['deskripsi']?.toString().toLowerCase() ?? '';
            return nama.contains(query) || deskripsi.contains(query);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari destinasi wisata...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.primary,
              ),
              suffixIcon:
                  _isSearching
                      ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _isSearching = false;
                            _filteredWisataList = widget.wisataList;
                          });
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),

        // Results Count
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_filteredWisataList.length} hasil ditemukan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Wisata List
        Expanded(
          child:
              _filteredWisataList.isEmpty
                  ? _buildEmptyState()
                  : AnimationLimiter(
                    child: RefreshIndicator(
                      onRefresh: widget.onRefresh ?? () async {},
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredWisataList.length,
                        itemBuilder: (context, index) {
                          final wisata = _filteredWisataList[index];
                          final nama = wisata['nama']?.toString() ?? '';
                          final imageUrl =
                              wisata['image_url']?.toString() ?? '';
                          final id = wisata['id']?.toString() ?? '';
                          final isFavorit = _favoriteStatus[id] ?? false;

                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 600),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: _buildWisataCard(
                                    wisata: wisata,
                                    nama: nama,
                                    imageUrl: imageUrl,
                                    isFavorit: isFavorit,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildWisataCard({
    required Map<String, dynamic> wisata,
    required String nama,
    required String imageUrl,
    required bool isFavorit,
  }) {
    final id = wisata['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => DetailWisataPage(
                  id: id,
                  nama: nama,
                  deskripsi: wisata['deskripsi']?.toString() ?? '',
                  alamat: wisata['alamat']?.toString() ?? '',
                  imageUrl: imageUrl,
                  mapsUrl: wisata['maps_url']?.toString() ?? '',
                  rating: wisata['rating']?.toDouble() ?? 0.0,
                  reviewCount: wisata['review_count']?.toInt() ?? 0,
                  fasilitas: WisataService.parseFasilitas(wisata['fasilitas']),
                  kategori: wisata['kategori']?.toString() ?? 'Wisata Alam',
                ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
                // Favorite Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorit ? Icons.favorite : Icons.favorite_border,
                        color: isFavorit ? Colors.red : Colors.grey[600],
                        size: 24,
                      ),
                      onPressed: () {
                        final user = UserService().getCurrentUser();
                        if (user == null) {
                          // Belum login, arahkan ke halaman akun (index 3)
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder:
                                  (context) => MainNavigation(
                                    username: '',
                                    initialIndex: 3,
                                  ),
                            ),
                            (route) => false,
                          );
                        } else {
                          _toggleFavorite(id, nama);
                        }
                      },
                    ),
                  ),
                ),
                // Location Badge
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          wisata['kategori']?.toString() ?? 'Wisata Alam',
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

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    wisata['alamat']?.toString() ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (wisata['deskripsi']?.toString() ?? '').length > 100
                        ? '${wisata['deskripsi'].toString().substring(0, 100)}...'
                        : wisata['deskripsi']?.toString() ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fasilitas Section
                  if (WisataService.parseFasilitas(
                    wisata['fasilitas'],
                  ).isNotEmpty) ...[
                    Text(
                      'Fasilitas:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          WisataService.parseFasilitas(wisata['fasilitas'])
                              .take(3) // Tampilkan maksimal 3 fasilitas
                              .map(
                                (fasilitas) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    fasilitas,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    if (WisataService.parseFasilitas(
                          wisata['fasilitas'],
                        ).length >
                        3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+${WisataService.parseFasilitas(wisata['fasilitas']).length - 3} fasilitas lainnya',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${wisata['rating']?.toStringAsFixed(1) ?? '0.0'}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${wisata['review_count']?.toString() ?? '0'} ulasan)',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Lihat Detail',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
            'Tidak ada hasil ditemukan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba kata kunci lain atau hapus filter pencarian',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

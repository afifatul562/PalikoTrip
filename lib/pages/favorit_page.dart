import 'package:flutter/material.dart';
import 'package:mtrip/pages/detail_wisata_page.dart';
import 'package:mtrip/services/favorit_service.dart';
import 'package:mtrip/services/wisata_service.dart';
import 'package:google_fonts/google_fonts.dart';

class FavoritPage extends StatefulWidget {
  const FavoritPage({super.key});

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {
  final FavoritService _favoritService = FavoritService();
  List<Map<String, dynamic>> _favoriteWisata = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await _favoritService.getFavoriteWisataDetails();
      setState(() {
        _favoriteWisata = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteWisata.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada wisata favorit',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan wisata ke favorit untuk melihatnya di sini',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        itemCount: _favoriteWisata.length,
        itemBuilder: (context, index) {
          final wisata = _favoriteWisata[index];
          final nama = wisata['nama']?.toString() ?? '';
          final imageUrl = wisata['image_url']?.toString() ?? '';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => DetailWisataPage(
                        id: wisata['id']?.toString() ?? '',
                        nama: nama,
                        deskripsi: wisata['deskripsi']?.toString() ?? '',
                        alamat: wisata['alamat']?.toString() ?? '',
                        imageUrl: imageUrl,
                        mapsUrl: wisata['maps_url']?.toString() ?? '',
                        rating: wisata['rating']?.toDouble() ?? 0.0,
                        reviewCount: wisata['review_count']?.toInt() ?? 0,
                        fasilitas: WisataService.parseFasilitas(
                          wisata['fasilitas'],
                        ),
                        kategori:
                            wisata['kategori']?.toString() ?? 'Wisata Alam',
                      ),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.all(10),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
                title: Text(
                  nama,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wisata['alamat']?.toString() ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${wisata['rating']?.toString() ?? '0.0'} (${wisata['review_count']?.toString() ?? '0'} ulasan)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Fasilitas Section
                    if (WisataService.parseFasilitas(
                      wisata['fasilitas'],
                    ).isNotEmpty) ...[
                      Text(
                        'Fasilitas:',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children:
                            WisataService.parseFasilitas(wisata['fasilitas'])
                                .take(2) // Tampilkan maksimal 2 fasilitas
                                .map(
                                  (fasilitas) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
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
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      if (WisataService.parseFasilitas(
                            wisata['fasilitas'],
                          ).length >
                          2)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '+${WisataService.parseFasilitas(wisata['fasilitas']).length - 2} lainnya',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
                trailing: Icon(Icons.favorite, color: Colors.red, size: 24),
              ),
            ),
          );
        },
      ),
    );
  }
}

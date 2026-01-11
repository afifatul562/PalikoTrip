import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtrip/pages/wisata_list_page.dart';
import 'package:mtrip/services/wisata_service.dart';

class KategoriPage extends StatefulWidget {
  const KategoriPage({super.key});

  @override
  State<KategoriPage> createState() => _KategoriPageState();
}

class _KategoriPageState extends State<KategoriPage> {
  final WisataService _wisataService = WisataService();
  List<Map<String, dynamic>> _allWisata = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Wisata Alam',
      'icon': Icons.landscape,
      'color': Colors.green,
      'description': 'Wisata alam dan pegunungan',
      'image': 'assets/forest.png',
    },
    {
      'name': 'Wisata Kuliner',
      'icon': Icons.restaurant,
      'color': Colors.orange,
      'description': 'Wisata kuliner dan makanan',
      'image': 'assets/lembah_harau.jpg',
    },
    {
      'name': 'Cafe',
      'icon': Icons.coffee,
      'color': Colors.brown,
      'description': 'Tempat nongkrong dan cafe',
      'image': 'assets/kelok_sembilan.jpg',
    },
    {
      'name': 'Semua',
      'icon': Icons.all_inclusive,
      'color': Colors.teal,
      'description': 'Semua jenis wisata',
      'image': 'assets/background.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadWisataData();
  }

  Future<void> _loadWisataData() async {
    try {
      final data = await _wisataService.getAllWisata();
      setState(() {
        _allWisata = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<Map<String, dynamic>> _getWisataByCategory(String kategori) {
    if (kategori == 'Semua') {
      return _allWisata;
    }
    return _allWisata
        .where((wisata) => wisata['kategori'] == kategori)
        .toList();
  }

  void _navigateToCategory(String kategori) {
    final filteredWisata = _getWisataByCategory(kategori);

    // Show loading if no data
    if (filteredWisata.isEmpty && kategori != 'Semua') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Belum ada wisata dalam kategori "$kategori"'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(title: Text(kategori), centerTitle: true),
              body: WisataListPage(wisataList: filteredWisata),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kategori Wisata',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih kategori wisata yang ingin Anda jelajahi',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final wisataCount =
                            _getWisataByCategory(category['name']).length;

                        return GestureDetector(
                          onTap: () {
                            // Add haptic feedback
                            SystemSound.play(SystemSoundType.click);
                            _navigateToCategory(category['name']);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  // Background Image
                                  Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(category['image']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // Gradient Overlay
                                  Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Content
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Icon
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: category['color']
                                                .withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            category['icon'],
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const Spacer(),
                                        // Category Name
                                        Text(
                                          category['name'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Description
                                        Text(
                                          category['description'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        // Count
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '$wisataCount tempat',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Statistics Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statistik Wisata',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Total Wisata',
                                _allWisata.length.toString(),
                                Icons.location_on,
                                Colors.blue,
                              ),
                              _buildStatItem(
                                'Kategori',
                                '3',
                                Icons.category,
                                Colors.green,
                              ),
                              _buildStatItem(
                                'Rating Tertinggi',
                                _getHighestRating(),
                                Icons.star,
                                Colors.orange,
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

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _getHighestRating() {
    if (_allWisata.isEmpty) return '0.0';
    double maxRating = 0;
    for (var wisata in _allWisata) {
      if (wisata['rating'] > maxRating) {
        maxRating = wisata['rating'].toDouble();
      }
    }
    return maxRating.toStringAsFixed(1);
  }
}

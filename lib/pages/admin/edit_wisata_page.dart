import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtrip/services/wisata_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mtrip/services/user_service.dart';

class EditWisataPage extends StatefulWidget {
  final Map<String, dynamic> wisata;

  const EditWisataPage({super.key, required this.wisata});

  @override
  State<EditWisataPage> createState() => _EditWisataPageState();
}

class _EditWisataPageState extends State<EditWisataPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _alamatController = TextEditingController();
  final _mapsUrlController = TextEditingController();
  final _ratingController = TextEditingController();
  final _reviewCountController = TextEditingController();

  String? _selectedImagePath;
  String? _currentImageUrl;
  List<String> _selectedFasilitas = [];
  bool _isLoading = false;
  String _selectedKategori = 'Wisata Alam';

  final List<String> _kategoriList = ['Wisata Alam', 'Wisata Kuliner', 'Cafe'];

  final List<String> _availableFasilitas = [
    'Tempat Parkir',
    'WiFi',
    'Musholla',
    'Warung Makan',
    'Toilet Umum',
    'Spot Foto',
    'Keamanan 24 Jam',
    'Pemandu Wisata',
    'Tempat Istirahat',
    'Souvenir Shop',
  ];

  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final wisata = widget.wisata;
    _namaController.text = wisata['nama']?.toString() ?? '';
    _deskripsiController.text = wisata['deskripsi']?.toString() ?? '';
    _alamatController.text = wisata['alamat']?.toString() ?? '';
    _mapsUrlController.text = wisata['maps_url']?.toString() ?? '';
    _ratingController.text = (wisata['rating']?.toDouble() ?? 0.0).toString();
    _reviewCountController.text =
        (wisata['review_count']?.toInt() ?? 0).toString();
    _selectedKategori = wisata['kategori']?.toString() ?? 'Wisata Alam';
    _currentImageUrl = wisata['image_url']?.toString();

    // Initialize fasilitas
    var fasilitas = wisata['fasilitas'];
    _selectedFasilitas = WisataService.parseFasilitas(fasilitas);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _alamatController.dispose();
    _mapsUrlController.dispose();
    _ratingController.dispose();
    _reviewCountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final wisataService = WisataService();
      String imageUrl = _currentImageUrl ?? '';

      // Upload new image if selected
      if (_selectedImagePath != null) {
        final file = File(_selectedImagePath!);
        final fileName = 'wisata_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadedUrl = await wisataService.uploadImage(file, fileName);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      // Update wisata data
      final success = await wisataService.updateWisata(
        id: widget.wisata['id'].toString(),
        nama: _namaController.text,
        deskripsi: _deskripsiController.text,
        alamat: _alamatController.text,
        imageUrl: imageUrl,
        mapsUrl: _mapsUrlController.text,
        kategori: _selectedKategori,
        rating: double.tryParse(_ratingController.text) ?? 0.0,
        reviewCount: int.tryParse(_reviewCountController.text) ?? 0,
        fasilitas: _selectedFasilitas,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wisata berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui wisata'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          'Edit Wisata',
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
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child:
                                    _selectedImagePath != null
                                        ? Image.file(
                                          File(_selectedImagePath!),
                                          fit: BoxFit.cover,
                                        )
                                        : _currentImageUrl != null
                                        ? Image.network(
                                          _currentImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        )
                                        : Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.add_photo_alternate,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_camera),
                              label: Text(
                                'Pilih Gambar',
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
                      ),

                      const SizedBox(height: 32),

                      // Form Fields
                      Text(
                        'Informasi Wisata',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nama
                      TextFormField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Wisata',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama wisata harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Deskripsi
                      TextFormField(
                        controller: _deskripsiController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Deskripsi harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Alamat
                      TextFormField(
                        controller: _alamatController,
                        decoration: InputDecoration(
                          labelText: 'Alamat',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.home),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Alamat harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Maps URL
                      TextFormField(
                        controller: _mapsUrlController,
                        decoration: InputDecoration(
                          labelText: 'URL Google Maps',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.map),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Kategori
                      DropdownButtonFormField<String>(
                        value: _selectedKategori,
                        items:
                            _kategoriList.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedKategori = newValue!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.category),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rating & Review Count
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ratingController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Rating',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.star),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Rating harus diisi';
                                }
                                final rating = double.tryParse(value);
                                if (rating == null ||
                                    rating < 0 ||
                                    rating > 5) {
                                  return 'Rating harus antara 0-5';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _reviewCountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Jumlah Review',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.rate_review),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Jumlah review harus diisi';
                                }
                                final count = int.tryParse(value);
                                if (count == null || count < 0) {
                                  return 'Jumlah review harus positif';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Fasilitas Section
                      Text(
                        'Fasilitas',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _availableFasilitas.map((fasilitas) {
                                final isSelected = _selectedFasilitas.contains(
                                  fasilitas,
                                );
                                return FilterChip(
                                  label: Text(fasilitas),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedFasilitas.add(fasilitas);
                                      } else {
                                        _selectedFasilitas.remove(fasilitas);
                                      }
                                    });
                                  },
                                  selectedColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.2),
                                  checkmarkColor:
                                      Theme.of(context).colorScheme.primary,
                                  backgroundColor: Colors.grey[100],
                                  side: BorderSide(
                                    color:
                                        isSelected
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                    color:
                                        isSelected
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Colors.grey[700],
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isIfaAdmin ? _submitForm : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Update Wisata',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (!isIfaAdmin)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            'Hanya ifa@admin.com yang dapat mengedit data wisata.',
                            style: GoogleFonts.poppins(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}

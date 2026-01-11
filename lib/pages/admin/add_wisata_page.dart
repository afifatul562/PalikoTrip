import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtrip/services/wisata_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mtrip/services/user_service.dart';

class AddWisataPage extends StatefulWidget {
  const AddWisataPage({super.key});

  @override
  State<AddWisataPage> createState() => _AddWisataPageState();
}

class _AddWisataPageState extends State<AddWisataPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _alamatController = TextEditingController();
  final _mapsUrlController = TextEditingController();
  final _ratingController = TextEditingController();
  final _reviewCountController = TextEditingController();

  String _selectedKategori = 'Wisata Alam';
  final List<String> _selectedFasilitas = [];
  File? _selectedImage;

  final List<String> _kategoriList = ['Wisata Alam', 'Wisata Kuliner', 'Cafe'];

  final List<String> _fasilitasList = [
    'Tempat Parkir',
    'Warung Makan',
    'Toilet Umum',
    'Spot Foto',
    'Keamanan 24 Jam',
    'WiFi',
    'Musholla',
    'Tempat Istirahat',
    'Pemandu Wisata',
    'Souvenir Shop',
  ];

  final UserService _userService = UserService();

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
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih gambar terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final WisataService wisataService = WisataService();

      // Upload image
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageUrl = await wisataService.uploadImage(
        _selectedImage!,
        fileName,
      );

      if (imageUrl == null) {
        throw Exception('Gagal mengupload gambar');
      }

      // Create wisata
      final success = await wisataService.createWisata(
        nama: _namaController.text,
        deskripsi: _deskripsiController.text,
        alamat: _alamatController.text,
        imageUrl: imageUrl,
        mapsUrl: _mapsUrlController.text,
        kategori: _selectedKategori,
        rating: double.parse(_ratingController.text),
        reviewCount: int.parse(_reviewCountController.text),
        fasilitas: _selectedFasilitas,
      );

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wisata berhasil ditambahkan'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Gagal menambahkan wisata');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
          'Tambah Wisata',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child:
                        _selectedImage != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                            : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pilih Gambar',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Nama Wisata
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Wisata',
                  hintText: 'Masukkan nama wisata',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama wisata tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Kategori
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category),
                ),
                items:
                    _kategoriList.map((String kategori) {
                      return DropdownMenuItem<String>(
                        value: kategori,
                        child: Text(kategori),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedKategori = newValue!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Alamat
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  hintText: 'Masukkan alamat wisata',
                  prefixIcon: Icon(Icons.place),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alamat tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Maps URL
              TextFormField(
                controller: _mapsUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL Google Maps',
                  hintText: 'https://maps.app.goo.gl/...',
                  prefixIcon: Icon(Icons.map),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'URL Maps tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Rating
              TextFormField(
                controller: _ratingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rating',
                  hintText: '4.5',
                  prefixIcon: Icon(Icons.star),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Rating tidak boleh kosong';
                  }
                  final rating = double.tryParse(value);
                  if (rating == null || rating < 0 || rating > 5) {
                    return 'Rating harus antara 0-5';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Review Count
              TextFormField(
                controller: _reviewCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Review',
                  hintText: '120',
                  prefixIcon: Icon(Icons.rate_review),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah review tidak boleh kosong';
                  }
                  final count = int.tryParse(value);
                  if (count == null || count < 0) {
                    return 'Jumlah review harus positif';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Deskripsi
              TextFormField(
                controller: _deskripsiController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Masukkan deskripsi wisata',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Fasilitas
              Text(
                'Fasilitas',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

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
                      _fasilitasList.map((fasilitas) {
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
                          checkmarkColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Colors.grey[100],
                          side: BorderSide(
                            color:
                                isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[300]!,
                            width: 1,
                          ),
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color:
                                isSelected
                                    ? Theme.of(context).colorScheme.primary
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Tambah Wisata',
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
                    'Hanya ifa@admin.com yang dapat menambah data wisata.',
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

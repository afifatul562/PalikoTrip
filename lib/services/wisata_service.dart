import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

class WisataService {
  final supabase = Supabase.instance.client;

  static final StreamController<List<Map<String, dynamic>>>
  _wisataStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  static Stream<List<Map<String, dynamic>>> get wisataStream =>
      _wisataStreamController.stream;

  // Utility function to parse fasilitas from any format
  static List<String> parseFasilitas(dynamic fasilitas) {
    if (fasilitas == null) return [];

    if (fasilitas is List) {
      return fasilitas
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }

    if (fasilitas is String) {
      String str = fasilitas.trim();

      // Remove JSON array brackets if present
      if (str.startsWith('[') && str.endsWith(']')) {
        str = str.substring(1, str.length - 1);
      }

      // Remove JSON object braces if present
      if (str.startsWith('{') && str.endsWith('}')) {
        str = str.substring(1, str.length - 1);
      }

      // Split by comma and clean each item
      return str
          .split(',')
          .map(
            (e) =>
                e
                    .replaceAll('"', '')
                    .replaceAll("'", '')
                    .replaceAll('[', '')
                    .replaceAll(']', '')
                    .replaceAll('{', '')
                    .replaceAll('}', '')
                    .replaceAll('\\', '')
                    .trim(),
          )
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }

    return [];
  }

  // Get all wisata data
  Future<List<Map<String, dynamic>>> getAllWisata() async {
    try {
      final response = await supabase
          .from('wisata')
          .select()
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching wisata: $e');
      return [];
    }
  }

  // Get wisata by ID
  Future<Map<String, dynamic>?> getWisataById(String id) async {
    try {
      final response =
          await supabase.from('wisata').select().eq('id', id).single();

      return response;
    } catch (e) {
      debugPrint('Error fetching wisata by ID: $e');
      return null;
    }
  }

  // Create new wisata
  Future<bool> createWisata({
    required String nama,
    required String deskripsi,
    required String alamat,
    required String imageUrl,
    required String mapsUrl,
    required String kategori,
    required double rating,
    required int reviewCount,
    required List<String> fasilitas,
  }) async {
    try {
      await supabase.from('wisata').insert({
        'nama': nama,
        'deskripsi': deskripsi,
        'alamat': alamat,
        'image_url': imageUrl,
        'maps_url': mapsUrl,
        'kategori': kategori,
        'rating': rating,
        'review_count': reviewCount,
        'fasilitas': fasilitas,
      });

      // Emit updated data through stream
      final updatedData = await getAllWisata();
      _wisataStreamController.add(updatedData);

      return true;
    } catch (e) {
      debugPrint('Error creating wisata: ' + e.toString());
      return false;
    }
  }

  // Update wisata
  Future<bool> updateWisata({
    required String id,
    required String nama,
    required String deskripsi,
    required String alamat,
    required String imageUrl,
    required String mapsUrl,
    required String kategori,
    required double rating,
    required int reviewCount,
    required List<String> fasilitas,
  }) async {
    try {
      await supabase
          .from('wisata')
          .update({
            'nama': nama,
            'deskripsi': deskripsi,
            'alamat': alamat,
            'image_url': imageUrl,
            'maps_url': mapsUrl,
            'kategori': kategori,
            'rating': rating,
            'review_count': reviewCount,
            'fasilitas': fasilitas,
          })
          .eq('id', id);

      // Emit updated data through stream
      final updatedData = await getAllWisata();
      _wisataStreamController.add(updatedData);

      return true;
    } catch (e) {
      debugPrint('Error updating wisata: $e');
      return false;
    }
  }

  // Delete wisata
  Future<bool> deleteWisata(String id) async {
    try {
      await supabase.from('wisata').delete().eq('id', id);

      // Emit updated data through stream
      final updatedData = await getAllWisata();
      _wisataStreamController.add(updatedData);

      return true;
    } catch (e) {
      debugPrint('Error deleting wisata: $e');
      return false;
    }
  }

  // Upload image to Supabase Storage
  Future<String?> uploadImage(File file, String fileName) async {
    try {
      final response = await supabase.storage
          .from('wisata-images')
          .upload(fileName, file);

      if (response.isNotEmpty) {
        final imageUrl = supabase.storage
            .from('wisata-images')
            .getPublicUrl(fileName);
        return imageUrl;
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Upload image to Supabase Storage (Web)
  Future<String?> uploadImageWeb(Uint8List bytes, String fileName) async {
    try {
      final response = await supabase.storage
          .from('wisata-images')
          .uploadBinary(fileName, bytes);
      if (response.isNotEmpty) {
        final imageUrl = supabase.storage
            .from('wisata-images')
            .getPublicUrl(fileName);
        return imageUrl;
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading image (web): $e');
      return null;
    }
  }

  // Get wisata by category
  Future<List<Map<String, dynamic>>> getWisataByCategory(
    String kategori,
  ) async {
    try {
      final response = await supabase
          .from('wisata')
          .select()
          .eq('kategori', kategori)
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching wisata by category: $e');
      return [];
    }
  }

  // Search wisata
  Future<List<Map<String, dynamic>>> searchWisata(String query) async {
    try {
      final response = await supabase
          .from('wisata')
          .select()
          .or(
            'nama.ilike.%$query%,deskripsi.ilike.%$query%,alamat.ilike.%$query%',
          )
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error searching wisata: $e');
      return [];
    }
  }

  // Emit initial data through stream
  Future<void> emitInitialData() async {
    final data = await getAllWisata();
    _wisataStreamController.add(data);
  }

  // Dispose stream controller
  static void dispose() {
    _wisataStreamController.close();
  }
}

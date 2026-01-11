import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class FavoritService {
  final supabase = Supabase.instance.client;

  // Get user favorites
  Future<List<String>> getUserFavorites() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final response = await supabase
          .from('user_favorites')
          .select('wisata_id')
          .eq('user_id', user.id);

      return response
          .map<String>((item) => item['wisata_id'].toString())
          .toList();
    } catch (e) {
      debugPrint('Error fetching user favorites: $e');
      return [];
    }
  }

  // Add favorite
  Future<bool> addFavorite(String wisataId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase.from('user_favorites').insert({
        'user_id': user.id,
        'wisata_id': wisataId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error adding favorite: $e');
      return false;
    }
  }

  // Remove favorite
  Future<bool> removeFavorite(String wisataId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('wisata_id', wisataId);

      return true;
    } catch (e) {
      debugPrint('Error removing favorite: $e');
      return false;
    }
  }

  // Check if wisata is favorited
  Future<bool> isFavorited(String wisataId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final response =
          await supabase
              .from('user_favorites')
              .select()
              .eq('user_id', user.id)
              .eq('wisata_id', wisataId)
              .single();

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get favorite wisata with details
  Future<List<Map<String, dynamic>>> getFavoriteWisataDetails() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final response = await supabase
          .from('user_favorites')
          .select('''
            wisata_id,
            wisata:wisata_id (
              id,
              nama,
              deskripsi,
              alamat,
              image_url,
              maps_url,
              kategori,
              rating,
              review_count,
              fasilitas
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return response.map<Map<String, dynamic>>((item) {
        final wisata = item['wisata'] as Map<String, dynamic>;
        return {
          'id': wisata['id'],
          'nama': wisata['nama'],
          'deskripsi': wisata['deskripsi'],
          'alamat': wisata['alamat'],
          'image_url': wisata['image_url'],
          'maps_url': wisata['maps_url'],
          'kategori': wisata['kategori'],
          'rating': wisata['rating'],
          'review_count': wisata['review_count'],
          'fasilitas': wisata['fasilitas'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching favorite wisata details: $e');
      return [];
    }
  }
}

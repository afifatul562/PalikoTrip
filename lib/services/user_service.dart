import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class UserService {
  final supabase = Supabase.instance.client;

  // Get current user
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      final response =
          await supabase
              .from('user_profiles')
              .select()
              .eq('user_id', user.id)
              .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // Create user profile
  Future<bool> createUserProfile({
    required String username,
    required String role,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase.from('user_profiles').upsert({
        'user_id': user.id,
        'email': user.email,
        'username': username,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      return true;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      return false;
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    try {
      final profile = await getUserProfile();
      return profile?['role'] == 'admin';
    } catch (e) {
      debugPrint('Error checking admin role: $e');
      return false;
    }
  }

  // Create admin user (for testing purposes)
  Future<bool> createAdminUser({required String username}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase.from('user_profiles').upsert({
        'user_id': user.id,
        'email': user.email,
        'username': username,
        'role': 'admin',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      return true;
    } catch (e) {
      debugPrint('Error creating admin user: $e');
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({required String username}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase
          .from('user_profiles')
          .update({
            'username': username,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Ensure user profile exists (create if not exists)
  Future<bool> ensureUserProfile({required String username}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      // Check if profile exists
      final existingProfile = await getUserProfile();
      if (existingProfile != null) {
        return true;
      }

      // Create profile if it doesn't exist
      return await createUserProfile(username: username, role: 'user');
    } catch (e) {
      debugPrint('Error ensuring user profile: $e');
      return false;
    }
  }

  // Get all users (admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await supabase
          .from('user_profiles')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return [];
    }
  }

  // Delete user (admin only)
  Future<bool> deleteUser(String userId) async {
    try {
      // Delete user profile
      await supabase.from('user_profiles').delete().eq('user_id', userId);

      // Delete user favorites
      await supabase.from('user_favorites').delete().eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  // Get user count
  Future<int> getUserCount() async {
    try {
      final response = await supabase.from('user_profiles').select();

      return response.length;
    } catch (e) {
      debugPrint('Error getting user count: $e');
      return 0;
    }
  }
}

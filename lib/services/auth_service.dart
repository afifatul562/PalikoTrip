import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:mtrip/services/user_service.dart';

class AuthService {
  final supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  Future<Map<String, dynamic>?> login(
    String? email,
    String password,
    BuildContext context,
  ) async {
    try {
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final User? user = res.user;
      if (user != null) {
        // Get user profile
        final profile = await _userService.getUserProfile();
        return {'success': true, 'user': user, 'profile': profile};
      } else {
        return {'success': false, 'message': 'Login gagal'};
      }
    } on AuthApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              e.message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
      return {'success': false, 'message': e.message};
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              e.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String username,
    BuildContext context,
  ) async {
    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final User? user = res.user;
      if (user != null) {
        // Create user profile
        final profileCreated = await _userService.createUserProfile(
          username: username,
          role: 'user', // Default role is user
        );

        if (profileCreated) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.green,
                content: Text("Registrasi berhasil. Silakan login."),
              ),
            );
          }
          return {'success': true, 'message': 'Registrasi berhasil'};
        } else {
          return {'success': false, 'message': 'Gagal membuat profil user'};
        }
      } else {
        return {'success': false, 'message': 'Registrasi gagal'};
      }
    } on AuthApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              e.message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
      return {'success': false, 'message': e.message};
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              e.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await _userService.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Logout berhasil"),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Error logout: $e"),
          ),
        );
      }
    }
  }
}

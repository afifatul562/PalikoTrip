import 'package:flutter/material.dart';
import 'package:mtrip/pages/main_navigation.dart';
import 'package:mtrip/pages/home_screen.dart';
import 'package:mtrip/pages/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://cyoswjisdjroesaxkumx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN5b3N3amlzZGpyb2VzYXhrdW14Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExMDAxMDYsImV4cCI6MjA2NjY3NjEwNn0.UqWhjgWh5hll45E-MEQElmvZGsoF-oDp0Wa6EiRbLEE',
  );
  runApp(const WisataApp());
}

class WisataApp extends StatefulWidget {
  const WisataApp({super.key});

  @override
  State<WisataApp> createState() => _WisataAppState();
}

class _WisataAppState extends State<WisataApp> {
  bool _isDarkMode = false;
  String? _currentUsername;
  bool _hasSeenSplash = false;
  bool _hasSeenHome = false;

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  void _handleLogout() {
    setState(() {
      _currentUsername = null;
      _hasSeenHome = false;
    });
  }

  void _handleStart() {
    setState(() {
      _hasSeenHome = true;
    });
  }

  void _finishSplash() {
    setState(() {
      _hasSeenSplash = true;
    });
  }

  ThemeData _buildTheme(bool isDark) {
    final colorScheme =
        isDark
            ? const ColorScheme.dark(
              primary: Color(0xFF4CAF50),
              secondary: Color(0xFF81C784),
              surface: Color(0xFF000000),
              onPrimary: Colors.white,
              onSecondary: Colors.black,
              onSurface: Colors.white,
            )
            : const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              secondary: Color(0xFF4CAF50),
              surface: Color(0xFFF5F5F5),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Colors.black,
            );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.poppinsTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget homeWidget;

    if (!_hasSeenSplash) {
      homeWidget = SplashScreen(onFinish: _finishSplash);
    } else if (!_hasSeenHome) {
      homeWidget = HomeScreen(onStart: _handleStart);
    } else {
      homeWidget = MainNavigation(
        username: _currentUsername ?? '',
        onThemeChanged: _toggleTheme,
        onLogout: _handleLogout,
      );
    }

    return MaterialApp(
      title: 'Paliko Trip',
      theme: _buildTheme(_isDarkMode),
      home: homeWidget,
      debugShowCheckedModeBanner: false,
    );
  }
}

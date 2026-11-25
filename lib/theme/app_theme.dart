import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

class AppTheme {
  static const forest = Color(0xFF004D40);
  static const teal = Color(0xFF00695C);
  static const accent = Color(0xFF26A69A);
  static const gold = Color(0xFFC6A15B);
  static const mist = Color(0xFFF5F7FA);
  static const line = Color(0xFFE3E8EE);

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: teal,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: forest,
      error: Color(0xFFB42318),
      onError: Colors.white,
      surface: mist,
      onSurface: Color(0xFF1B2424),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: mist,
    );
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: const Color(0xFF1B2424),
      displayColor: forest,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 32,
          letterSpacing: -0.8,
          color: forest,
        ),
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: -0.3,
          color: forest,
        ),
        titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: forest,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: forest,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: forest,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        prefixIconColor: teal,
        labelStyle: GoogleFonts.inter(color: const Color(0xFF667085)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: teal, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFB42318)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: teal,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        extendedSizeConstraints: const BoxConstraints(minHeight: 56, minWidth: 132),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: forest,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(color: line, space: 1),
    );
  }
}

class AppPage {
  static Route<T> route<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 460),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.04, 0.03), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

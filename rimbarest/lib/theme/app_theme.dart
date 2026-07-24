import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgPage     = Color(0xFFF7F9FF);
  static const Color bgCard     = Color(0xFFFFFFFF);
  static const Color bgSurface  = Color(0xFFEEF2FF);
  static const Color bgInput    = Color(0xFFF1F5F9);

  static const Color borderSoft   = Color(0xFFE2E8F0);
  static const Color borderMedium = Color(0xFFC7D2FE);
  static const Color borderStrong = Color(0xFFA5B4FC);

  static const Color primary   = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFF2563EB);
  static const Color success   = Color(0xFF059669);
  static const Color warning   = Color(0xFFD97706);
  static const Color danger    = Color(0xFFDC2626);

  static const Color bgPrimary   = Color(0xFFEDE9FE);
  static const Color bgSecondary = Color(0xFFDBEAFE);
  static const Color bgSuccess   = Color(0xFFF0FDF4);
  static const Color bgWarning   = Color(0xFFFFFBEB);
  static const Color bgDanger    = Color(0xFFFEF2F2);

  static const Color bdrPrimary  = Color(0xFFC4B5FD);
  static const Color bdrSuccess  = Color(0xFFBBF7D0);
  static const Color bdrWarning  = Color(0xFFFDE68A);
  static const Color bdrDanger   = Color(0xFFFECDD3);

  static const Color textPrimary   = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted     = Color(0xFF94A3B8);
  static const Color textLight     = Color(0xFFCBD5E1);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: bgPage,
        fontFamily: 'Outfit',
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: secondary,
          surface: bgCard,
          error: danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: textPrimary,
          titleTextStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: bgCard,
          elevation: 0,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: borderSoft),
          ),
        ),
      );
}

class LightGradients {
  static const LinearGradient primaryGrad = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGrad = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient cardHeaderGrad = LinearGradient(
    colors: [
      const Color(0xFF7C3AED).withValues(alpha: 0.06),
      const Color(0xFF2563EB).withValues(alpha: 0.02),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient statusGrad = LinearGradient(
    colors: [
      const Color(0xFF7C3AED).withValues(alpha: 0.06),
      const Color(0xFF2563EB).withValues(alpha: 0.03),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

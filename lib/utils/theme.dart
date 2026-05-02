import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const first = Color(0xFF6366F1);      // Indigo
  static const firstDark = Color(0xFF4F46E5);
  static const second = Color(0xFF8B5CF6);    // Purple
  static const accent = Color(0xFF06B6D4);       // Cyan
  static const success = Color(0xFF10B981);      // Green
  static const warning = Color(0xFFF59E0B);      // Amber
  static const danger = Color(0xFFEF4444);       // Red
  static const surface = Color(0xFF1E1E2E);
  static const surfaceLight = Color(0xFF2A2A3E);
  static const background = Color(0xFF13131F);
  static const onSurface = Color(0xFFE2E8F0);
  static const onSurfaceMuted = Color(0xFF94A3B8);

  
  static Color priorityColor(String priority) {
    switch (priority) {
      case 'urgent': return danger;
      case 'high': return warning;
      case 'medium': return first;
      case 'low': return success;
      default: return onSurfaceMuted;
    }
  }

  
  static Color statusColor(String status) {
    switch (status) {
      case 'todo': return onSurfaceMuted;
      case 'in_progress': return accent;
      case 'review': return warning;
      case 'done': return success;
      default: return onSurfaceMuted;
    }
  }

  
  static const projectColors = [
    '#6366F1', '#8B5CF6', '#EC4899', '#EF4444',
    '#F59E0B', '#10B981', '#06B6D4', '#3B82F6',
  ];

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: first,
        secondary: second,
        surface: surface,
        background: background,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: onSurface,
        error: danger,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(color: onSurface, fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.plusJakartaSans(color: onSurface, fontWeight: FontWeight.w700),
        headlineLarge: GoogleFonts.plusJakartaSans(color: onSurface, fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.plusJakartaSans(color: onSurface, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.plusJakartaSans(color: onSurface, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.plusJakartaSans(color: onSurface),
        bodyMedium: GoogleFonts.plusJakartaSans(color: onSurfaceMuted),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: first, width: 2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: onSurfaceMuted),
        hintStyle: GoogleFonts.plusJakartaSans(color: onSurfaceMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: first,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: onSurface),
      ),
    );
  }
}


Color hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

String formatDate(DateTime? date) {
  if (date == null) return 'No date';
  final now = DateTime.now();
  final diff = date.difference(now);
  if (diff.inDays == 0) return 'Today';
  if (diff.inDays == 1) return 'Tomorrow';
  if (diff.inDays == -1) return 'Yesterday';
  return '${date.day}/${date.month}/${date.year}';
}
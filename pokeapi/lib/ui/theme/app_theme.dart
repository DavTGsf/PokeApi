import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const red = Color(0xFFDC3030);
  static const redDark = Color(0xFF8F2020);
  static const cream = Color(0xFFF5EBD5);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF252525);
  static const grey = Color(0xFF777777);
}

const kRadius = 16.0;
const kFast = Duration(milliseconds: 120);
const kMedium = Duration(milliseconds: 250);

const _typeColors = {
  'normal': Color(0xFFA8A878),
  'fire': Color(0xFFF08030),
  'water': Color(0xFF6890F0),
  'electric': Color(0xFFF8D030),
  'grass': Color(0xFF78C850),
  'ice': Color(0xFF7FD3E8),
  'fighting': Color(0xFFC03028),
  'poison': Color(0xFFA040A0),
  'ground': Color(0xFFD2A95A),
  'flying': Color(0xFFA890F0),
  'psychic': Color(0xFFF85888),
  'bug': Color(0xFFA8B820),
  'rock': Color(0xFFB8A038),
  'ghost': Color(0xFF705898),
  'dragon': Color(0xFF3F4FB5),
  'dark': Color(0xFF705848),
  'steel': Color(0xFF9EA6BC),
  'fairy': Color(0xFFEE99AC),
};

const _typeLabels = {
  'normal': 'Normal', 'fire': 'Fuego', 'water': 'Agua', 'electric': 'Eléctrico',
  'grass': 'Planta', 'ice': 'Hielo', 'fighting': 'Lucha', 'poison': 'Veneno',
  'ground': 'Tierra', 'flying': 'Volador', 'psychic': 'Psíquico', 'bug': 'Bicho',
  'rock': 'Roca', 'ghost': 'Fantasma', 'dragon': 'Dragón', 'dark': 'Siniestro',
  'steel': 'Acero', 'fairy': 'Hada',
};

Color typeColor(String t) => _typeColors[t] ?? AppColors.grey;
String typeLabel(String t) => _typeLabels[t] ?? t;
String dex(int id) => '#${id.toString().padLeft(4, '0')}';
String cap(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).replaceAll('-', ' ');

class AppText {
  /// Pixelada: identificadores, etiquetas, detalles retro.
  static TextStyle pixel({double size = 11, Color color = AppColors.ink}) =>
      GoogleFonts.pixelifySans(fontSize: size, color: color, fontWeight: FontWeight.w600);

  /// Moderna: nombres, datos, descripciones.
  static TextStyle title({double size = 20, Color color = AppColors.ink}) =>
      GoogleFonts.nunito(fontSize: size, color: color, fontWeight: FontWeight.w800);

  static TextStyle body({double size = 14, Color color = AppColors.ink, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.nunito(fontSize: size, color: color, fontWeight: weight);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.red,
    primary: AppColors.red,
    surface: AppColors.cream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: ThemeData(brightness: Brightness.light).textTheme.apply(
      fontFamily: GoogleFonts.nunito().fontFamily,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.red,
      foregroundColor: AppColors.white,
      titleTextStyle: AppText.pixel(size: 18, color: AppColors.white),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.red),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.red,
      foregroundColor: AppColors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppText.pixel(size: 13, color: AppColors.white),
      ),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.cream),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.cream),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: AppText.body(color: AppColors.white),
    ),
  );
}

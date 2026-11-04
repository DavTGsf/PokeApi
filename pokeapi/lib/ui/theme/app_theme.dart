import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models.dart';

class AppColors {
  static const red = Color(0xFFD7262B);
  static const redDark = Color(0xFF9E1A1E);
  static const cream = Color(0xFFE9DEC4); // fondo de la pantalla
  static const paper = Color(0xFFF7F0DE); // tarjetas
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2B2622);
  static const grey = Color(0xFF7A7166);
  static const male = Color(0xFF2F80D1);
  static const female = Color(0xFFEF4F78);
}

const kRadius = 16.0;
const kFast = Duration(milliseconds: 120);
const kMedium = Duration(milliseconds: 250);

const kMegaGradient = LinearGradient(colors: [Color(0xFF7B2FF7), Color(0xFFE6338F)]);

/// Caja retro: borde grueso y sombra sólida desplazada.
BoxDecoration retroBox({Color color = AppColors.paper, double radius = kRadius, bool shadow = true}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.ink, width: 2.5),
      boxShadow: shadow ? const [BoxShadow(color: AppColors.ink, offset: Offset(0, 3))] : null,
    );

/// Fondo de "escenario" según el tipo.
Gradient typeGradient(Color c) => RadialGradient(
      center: const Alignment(0, -0.2),
      radius: 0.95,
      colors: [Color.lerp(c, Colors.white, 0.45)!, c, Color.lerp(c, Colors.black, 0.35)!],
      stops: const [0, 0.55, 1],
    );

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

const _typeIcons = {
  'normal': Icons.circle_outlined,
  'fire': Icons.local_fire_department,
  'water': Icons.water_drop,
  'electric': Icons.bolt,
  'grass': Icons.eco,
  'ice': Icons.ac_unit,
  'fighting': Icons.sports_mma,
  'poison': Icons.science,
  'ground': Icons.terrain,
  'flying': Icons.air,
  'psychic': Icons.psychology,
  'bug': Icons.bug_report,
  'rock': Icons.landscape,
  'ghost': Icons.nights_stay,
  'dragon': Icons.whatshot,
  'dark': Icons.dark_mode,
  'steel': Icons.shield,
  'fairy': Icons.star,
};

Color typeColor(String t) => _typeColors[t] ?? AppColors.grey;
String typeLabel(String t) => _typeLabels[t] ?? t;
IconData typeIcon(String t) => _typeIcons[t] ?? Icons.help_outline;
String dex(int id) => '#${id.toString().padLeft(4, '0')}';
String cap(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).replaceAll('-', ' ');

/// "Charizard", "Mega Charizard X", "Groudon Primigenio".
String pokeName(String n) {
  final label = formLabel(n);
  if (label == 'Normal') return cap(n);
  final base = cap(baseName(n));
  if (label == 'Primigenia') return '$base Primigenio';
  return label.replaceFirst('Mega', 'Mega $base');
}

class AppText {
  /// Pixelada: etiquetas, identificadores.
  static TextStyle pixel({double size = 11, Color color = AppColors.ink}) =>
      GoogleFonts.pixelifySans(fontSize: size, color: color, fontWeight: FontWeight.w600);

  /// Títulos pixelados gruesos (nombre del Pokémon).
  static TextStyle title({double size = 20, Color color = AppColors.ink}) =>
      GoogleFonts.pixelifySans(fontSize: size, color: color, fontWeight: FontWeight.w700);

  /// Monoespaciada retro: datos y descripciones (Space Mono solo trae 400/700).
  static TextStyle body({double size = 14, Color color = AppColors.ink, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        color: color,
        fontWeight: weight.value >= 600 ? FontWeight.w700 : FontWeight.w400,
      );
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
      fontFamily: GoogleFonts.spaceMono().fontFamily,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: AppColors.ink, width: 2.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.ink, width: 2.5),
        ),
        textStyle: AppText.pixel(size: 13, color: AppColors.white),
      ),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.paper),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.paper),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: AppText.body(color: AppColors.white),
    ),
  );
}

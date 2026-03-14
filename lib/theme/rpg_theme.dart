import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════
//  RPG THEME — modifie ici pour changer toute
//  l'apparence de l'app d'un seul endroit
// ═══════════════════════════════════════════════

// ── Couleurs principales ─────────────────────
const kBg        = Color(0xFFF5F0E8);   // fond parchemin
const kBgCard    = Color(0xFFEDE5D0);   // card légère
const kBgCard2   = Color(0xFFE8E0CC);   // card plus sombre
const kPrimary   = Color(0xFFC9820A);   // ambre / or brûlé
const kPrimaryLt = Color(0xFFE8A020);   // ambre clair
const kAccent    = Color(0xFFD4A017);   // accent doré
const kText      = Color(0xFF2C3E50);   // texte principal encre
const kTextMid   = Color(0xFF5D6D7E);   // texte secondaire
const kTextDim   = Color(0xFF8E9BAA);   // texte désactivé
const kBorder    = Color(0xFFD4C5A0);   // bordure subtile
const kSuccess   = Color(0xFF27AE60);   // succès vert
const kError     = Color(0xFFE74C3C);   // erreur rouge

// ── Aliases sémantiques ──────────────────────
// (gardés pour compatibilité avec les fichiers existants)
const kEmerald = kPrimary;
const kCyan    = kPrimaryLt;
const kGlow    = kAccent;

// ── ThemeData Flutter ────────────────────────
// Utilisé dans main.dart : theme: RpgTheme.light
class RpgTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: kPrimary,
      secondary: kPrimaryLt,
      surface: kBg,
      background: kBg,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: kText,
      onBackground: kText,
      error: kError,
    ),
    scaffoldBackgroundColor: kBg,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: kBg,
      foregroundColor: kText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: kText,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
      iconTheme: IconThemeData(color: kText),
    ),

    // NavigationBar (bottom nav)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kBgCard2,
      indicatorColor: kPrimary,
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: Colors.white, size: 22);
        }
        return const IconThemeData(color: kTextMid, size: 22);
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(
            color: kPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          );
        }
        return const TextStyle(color: kTextMid, fontSize: 12);
      }),
      surfaceTintColor: Colors.transparent,
      elevation: 8,
    ),

    // Cartes
    cardTheme: CardThemeData(
      color: kBgCard,
      elevation: 4,
      shadowColor: kText.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: kBorder),
      ),
    ),

    // Champs texte
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBgCard,
      hintStyle: TextStyle(color: kTextDim),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError, width: 1.5),
      ),
    ),

    // Boutons elevés
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: kPrimary.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: kBgCard2,
      selectedColor: kPrimary.withOpacity(0.15),
      labelStyle: const TextStyle(color: kText, fontSize: 12),
      side: BorderSide(color: kBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: kBorder,
      thickness: 1,
    ),

    // Texte global
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: kText, fontWeight: FontWeight.w900, fontSize: 28),
      headlineMedium: TextStyle(color: kText, fontWeight: FontWeight.w800, fontSize: 22),
      titleLarge: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 18),
      titleMedium: TextStyle(color: kText, fontWeight: FontWeight.w600, fontSize: 15),
      bodyLarge: TextStyle(color: kText, fontSize: 15),
      bodyMedium: TextStyle(color: kTextMid, fontSize: 13),
      labelSmall: TextStyle(color: kTextDim, fontSize: 11, letterSpacing: 0.5),
    ),

    // CircularProgressIndicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: kPrimary,
    ),
  );
}
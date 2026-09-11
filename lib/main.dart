import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'ui/home_screen.dart';
import 'ui/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final appState = AppState(prefs)..load();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const FlashcardApp(),
    ),
  );
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcard Memory',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const _RootRouter(),
    );
  }
}

/// V2 chantier C — Identité visuelle.
///
/// Seed violet énergique (au lieu du bleu générique de la V1) : plus de
/// caractère pour une app de révision, tout en restant Material 3 pur (pas de
/// police externe, pour ne pas ajouter de dépendance ni de risque réseau au
/// build). Les thèmes de composants (cartes, boutons, AppBar) sont posés une
/// fois ici et se propagent à tous les écrans, plutôt que d'habiller chaque
/// écran séparément.
ThemeData _buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF6C4DE6));
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: scheme.surfaceTint,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.secondaryContainer,
      labelStyle: TextStyle(color: scheme.onSecondaryContainer),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
    ),
  );
}

/// Aiguille vers l'écran d'accueil pédagogique au tout premier lancement
/// (V2 chantier D), sinon directement vers l'Accueil.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final showOnboarding = context.watch<AppState>().showOnboarding;
    return showOnboarding ? const OnboardingScreen() : const HomeScreen();
  }
}

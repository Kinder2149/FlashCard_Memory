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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F6FB0)),
        useMaterial3: true,
      ),
      home: const _RootRouter(),
    );
  }
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

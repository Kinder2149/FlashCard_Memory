import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

/// V2 D — Écran d'accueil pédagogique, montré une seule fois au tout premier
/// lancement. Reprend les mêmes idées que la page d'aide (U7), sous une forme
/// visuelle courte plutôt qu'un mur de texte — pas de contenu dupliqué à
/// maintenir : chaque diapositive tient en une phrase.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  final IconData icon;
  final String title;
  final String text;
  const _Slide(this.icon, this.title, this.text);
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      Icons.edit_note,
      'Vos mots, votre liste',
      'Écrivez vos mots et leurs traductions dans l\'app, ou dans un fichier '
          'Excel / Google Sheet. Flashcard fabrique une carte par correspondance.',
    ),
    _Slide(
      Icons.play_circle_outline,
      'Une session de révision',
      'Choisissez une paire de langues, un thème et un sens, puis jouez : '
          'saisie libre ou QCM, à votre rythme, même hors connexion.',
    ),
    _Slide(
      Icons.bar_chart,
      'Votre progression suivie',
      'Chaque réponse met à jour votre taux de réussite, par carte et par sens. '
          'Retrouvez tout ça dans les statistiques, à tout moment.',
    ),
  ];

  void _finish() => context.read<AppState>().completeOnboarding();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Passer'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLast
                      ? _finish
                      : () => _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isLast ? 'Commencer' : 'Suivant'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 56, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            slide.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

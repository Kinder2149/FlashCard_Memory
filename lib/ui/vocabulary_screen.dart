import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';

/// U — Consultation du vocabulaire.
///
/// Liste, en lecture seule, toutes les paires importées (Français — Anglais)
/// groupées par thème (catégorie). Permet de parcourir l'ensemble du vocabulaire
/// d'un coup d'œil. Un thème vide est regroupé sous « Sans thème ».
class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  static const _noTheme = 'Sans thème';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    // Regroupement des cartes par thème.
    final byTheme = <String, List<Flashcard>>{};
    for (final c in app.cards) {
      final key = c.theme.isEmpty ? _noTheme : c.theme;
      byTheme.putIfAbsent(key, () => []).add(c);
    }
    final themeNames = byTheme.keys.toList()
      ..sort((a, b) {
        if (a == _noTheme) return 1; // « Sans thème » en dernier
        if (b == _noTheme) return -1;
        return a.compareTo(b);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Vocabulaire')),
      body: SafeArea(
        child: app.cards.isEmpty
            ? const Center(child: Text('Aucune carte en mémoire.'))
            : Column(
                children: [
                  _Summary(
                    words: app.cards.length,
                    themes: themeNames.length,
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final theme in themeNames)
                          _ThemeSection(
                            title: theme,
                            cards: byTheme[theme]!
                              ..sort((a, b) => a.fr.toLowerCase().compareTo(
                                    b.fr.toLowerCase(),
                                  )),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Bandeau récapitulatif : nombre de mots et de thèmes.
class _Summary extends StatelessWidget {
  final int words;
  final int themes;
  const _Summary({required this.words, required this.themes});

  @override
  Widget build(BuildContext context) {
    final w = '$words ${words <= 1 ? "mot" : "mots"}';
    final t = '$themes ${themes <= 1 ? "thème" : "thèmes"}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text('$w · $t',
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
    );
  }
}

/// Une catégorie : un en-tête de thème puis ses paires (Français — Anglais).
class _ThemeSection extends StatelessWidget {
  final String title;
  final List<Flashcard> cards;
  const _ThemeSection({required this.title, required this.cards});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: scheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            '$title  (${cards.length})',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ),
        for (final c in cards) _PairRow(card: c),
      ],
    );
  }
}

/// Une paire : Français à gauche, Anglais à droite.
class _PairRow extends StatelessWidget {
  final Flashcard card;
  const _PairRow({required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(card.fr,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(card.en)),
        ],
      ),
    );
  }
}

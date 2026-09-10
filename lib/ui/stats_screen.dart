import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';

/// U6 — Consultation des statistiques.
///
/// Liste, par thème, chaque carte avec ses taux de réussite cumulatifs. Deux
/// blocs distincts par carte : « Saisie » et « QCM » — comptabilisés séparément
/// car la réussite est objective en QCM (bon choix) mais auto-déclarée en
/// saisie. Chaque bloc détaille les deux sens (FR → EN, EN → FR). Un thème vide
/// est regroupé sous « Sans thème ».
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

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
      appBar: AppBar(title: const Text('Statistiques')),
      body: SafeArea(
        child: app.cards.isEmpty
            ? const Center(child: Text('Aucune carte en mémoire.'))
            : ListView(
                children: themeNames.map((theme) {
                  final cards = byTheme[theme]!
                    ..sort((a, b) => a.fr.toLowerCase().compareTo(
                          b.fr.toLowerCase(),
                        ));
                  return ExpansionTile(
                    title: Text('$theme  (${cards.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    initiallyExpanded: themeNames.length <= 3,
                    children:
                        cards.map((c) => _CardRow(card: c, app: app)).toList(),
                  );
                }).toList(),
              ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final Flashcard card;
  final AppState app;
  const _CardRow({required this.card, required this.app});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${card.fr}  —  ${card.en}',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _modeBlock(context, 'Saisie', qcm: false),
          const SizedBox(height: 8),
          _modeBlock(context, 'QCM', qcm: true),
          const Divider(height: 20),
        ],
      ),
    );
  }

  /// Un bloc de mode (Saisie ou QCM) : son étiquette + les deux sens.
  Widget _modeBlock(BuildContext context, String label, {required bool qcm}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _rate(context, Direction.frToEn, qcm: qcm)),
            const SizedBox(width: 8),
            Expanded(child: _rate(context, Direction.enToFr, qcm: qcm)),
          ],
        ),
      ],
    );
  }

  Widget _rate(BuildContext context, Direction dir, {required bool qcm}) {
    final rate = qcm ? app.qcmRateOf(card.id, dir) : app.rateOf(card.id, dir);
    final attempts =
        qcm ? app.qcmAttemptsOf(card.id, dir) : app.attemptsOf(card.id, dir);
    final label = dir == Direction.frToEn ? 'FR → EN' : 'EN → FR';

    final String value;
    final Color color;
    if (rate == null) {
      value = 'jamais joué';
      color = Colors.grey;
    } else {
      value = '${(rate * 100).round()}%  ($attempts)';
      color = rate >= 0.5 ? Colors.green.shade700 : Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

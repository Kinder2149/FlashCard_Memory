import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'import_screen.dart';
import 'setup_screen.dart';
import 'stats_screen.dart';
import 'vocabulary_screen.dart';
import 'help_screen.dart';

/// U1 — Accueil.
///
/// Affiche l'état de la mémoire (cartes intégrées) et, quand un lien est
/// mémorisé et que l'appareil est en ligne, la comparaison avec le Sheet
/// (« X en mémoire / Y dans le Sheet — Z à intégrer »). Propose les actions :
/// Jouer, Importer / mettre à jour, Consulter le vocabulaire, Consulter les
/// statistiques.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Vérification silencieuse Accueil ↔ Sheet, après le premier rendu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshHomeComparison();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard'),
        actions: [
          IconButton(
            tooltip: 'Comment ça marche ?',
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _MemoryStatusCard(app: app),
              const Spacer(),
              FilledButton.icon(
                onPressed: app.hasCards
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SetupScreen()),
                        );
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                label: const Text('Jouer'),
              ),
              if (!app.hasCards)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Ajoutez des cartes en important votre Sheet pour pouvoir jouer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ImportScreen()),
                  );
                },
                icon: const Icon(Icons.sync),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                label: Text(app.hasLink
                    ? 'Importer / mettre à jour'
                    : 'Importer mes cartes'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: app.hasCards
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const VocabularyScreen()),
                        );
                      }
                    : null,
                icon: const Icon(Icons.menu_book),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                label: const Text('Consulter le vocabulaire'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: app.hasCards
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const StatsScreen()),
                        );
                      }
                    : null,
                icon: const Icon(Icons.bar_chart),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                label: const Text('Consulter les statistiques'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryStatusCard extends StatelessWidget {
  final AppState app;
  const _MemoryStatusCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('État de la mémoire',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              '${app.memoryCount} '
              '${app.memoryCount <= 1 ? "carte en mémoire" : "cartes en mémoire"}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            _comparisonLine(context),
          ],
        ),
      ),
    );
  }

  Widget _comparisonLine(BuildContext context) {
    if (!app.hasLink) {
      return const Text('Aucun lien mémorisé pour le moment.',
          style: TextStyle(color: Colors.grey));
    }
    switch (app.homeCheck) {
      case HomeCheck.checking:
        return const Text('Vérification du Sheet…',
            style: TextStyle(color: Colors.grey));
      case HomeCheck.offline:
        return const Text('Hors ligne — dernier état connu affiché.',
            style: TextStyle(color: Colors.grey));
      case HomeCheck.idle:
        return const SizedBox.shrink();
      case HomeCheck.done:
        final sheet = app.sheetValidCountLive;
        final toInt = app.toIntegrateLive;
        if (sheet == null) return const SizedBox.shrink();
        final base = '${app.memoryCount} en mémoire / $sheet dans le Sheet';
        if (toInt != null && toInt > 0) {
          return Text('$base — $toInt à intégrer',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600));
        }
        return Text('$base — à jour',
            style: const TextStyle(color: Colors.green));
    }
  }
}

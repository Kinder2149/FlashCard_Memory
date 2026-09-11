import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'import_choice_screen.dart';
import 'manage_cards_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';
import 'stats_screen.dart';
import 'help_screen.dart';

/// U1 — Accueil.
///
/// Affiche l'état de la mémoire et propose : Jouer (mis en avant), puis Mes
/// cartes / Statistiques / Paramètres sous forme de tuiles d'action colorées.
/// Import direct proposé en priorité tant qu'aucune carte n'est en mémoire.
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style_rounded, color: scheme.primary),
            const SizedBox(width: 8),
            const Text('Flashcard'),
          ],
        ),
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _MemoryStatusCard(app: app),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: app.hasCards
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SetupScreen()),
                      );
                    }
                  : null,
              icon: const Icon(Icons.play_arrow),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              label: const Text('Jouer'),
            ),
            if (!app.hasCards) ...[
              const SizedBox(height: 14),
              _ActionTile(
                icon: Icons.rocket_launch_outlined,
                color: scheme.primaryContainer,
                title: 'Importer mes cartes',
                subtitle: 'Depuis un modèle, un fichier Excel ou un Google Sheet',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImportChoiceScreen()),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _ActionTile(
              icon: Icons.style_outlined,
              color: scheme.secondaryContainer,
              title: 'Mes cartes',
              subtitle: '${app.memoryCount} carte(s) — voir, ajouter, modifier',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageCardsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.bar_chart,
              color: scheme.tertiaryContainer,
              title: 'Statistiques',
              subtitle: 'Vos taux de réussite par carte et par sens',
              enabled: app.hasCards,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.settings_outlined,
              color: scheme.surfaceContainerHighest,
              title: 'Paramètres',
              subtitle: 'Importations, langue, réinitialisation',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tuile d'action colorée de l'Accueil : icône dans un badge, titre, sous-titre.
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: color, child: Icon(icon)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.outline),
              ],
            ),
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('État de la mémoire',
                style: TextStyle(fontSize: 13, color: scheme.onPrimaryContainer)),
            const SizedBox(height: 8),
            Text(
              '${app.memoryCount} '
              '${app.memoryCount <= 1 ? "carte en mémoire" : "cartes en mémoire"}',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 6),
            _comparisonLine(context),
          ],
        ),
      ),
    );
  }

  Widget _comparisonLine(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onPrimaryContainer.withValues(alpha: 0.75);
    if (!app.hasLink) {
      return Text('Aucun lien mémorisé pour le moment.',
          style: TextStyle(color: muted));
    }
    switch (app.homeCheck) {
      case HomeCheck.checking:
        return Text('Vérification du Sheet…', style: TextStyle(color: muted));
      case HomeCheck.offline:
        return Text('Hors ligne — dernier état connu affiché.',
            style: TextStyle(color: muted));
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
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700));
        }
        return Text('$base — à jour', style: TextStyle(color: muted));
    }
  }
}

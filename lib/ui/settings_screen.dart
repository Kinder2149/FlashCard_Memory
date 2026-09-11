import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import 'import_choice_screen.dart';

/// Paramètres — 3 blocs distincts (retour utilisateur : un onglet Paramètres
/// avec un bloc Importations, un bloc Langue, un bloc Réinitialiser, plutôt
/// qu'un mur de sections empilées).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- Bloc Importations ---
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ImportChoiceScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: const Icon(Icons.cloud_sync_outlined),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Importations',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              app.hasLink
                                  ? 'Modèle, fichier Excel ou lien Google Sheet — mettre à jour'
                                  : 'Modèle, fichier Excel ou lien Google Sheet',
                              style:
                                  const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // --- Bloc Langue ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: scheme.secondaryContainer,
                          child: const Icon(Icons.translate),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text('Ma langue',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'La langue dans laquelle vous écrivez vos traductions. '
                      'Elle sert à afficher les bons libellés partout dans l\'app.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: app.motherLang,
                      items: Languages.codes
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(Languages.nameOf(c))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) app.setMotherLang(v);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // --- Bloc Réinitialiser ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: scheme.errorContainer,
                          child: Icon(Icons.delete_outline,
                              color: scheme.onErrorContainer),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text('Réinitialiser',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Efface toutes les cartes et leurs statistiques de la '
                      'mémoire du téléphone. Votre Sheet ou fichier n\'est pas '
                      'touché : vous pourrez tout réimporter. Le lien mémorisé '
                      'est conservé.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: app.hasCards ? () => _confirmClear(context) : null,
                      icon: Icon(Icons.delete_outline, color: scheme.error),
                      style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                      label: const Text('Vider la mémoire'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider la mémoire ?'),
        content: Text(
            'Les ${app.memoryCount} cartes et toutes leurs statistiques seront '
            'effacées du téléphone. Cette action est définitive. Vous pourrez '
            'réimporter depuis votre Sheet ou votre fichier.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
    if (ok == true) await app.clearMemory();
  }
}

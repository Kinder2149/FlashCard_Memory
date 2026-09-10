import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../logic/session_runner.dart';

/// U5 — Récap de session.
///
/// Affiche le score (bonnes réponses / cartes réellement jouées) et la liste
/// des cartes jouées avec leur résultat. « Retour à l'Accueil » clôt la session.
class RecapScreen extends StatelessWidget {
  const RecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<AppState>().session;
    final played = session?.playedCards ?? const <SessionCard>[];
    final correct = session?.correctCount ?? 0;
    final isQcm = session?.mode == GameMode.qcm;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Récap de session'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('Score',
                            style:
                                TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                          '$correct / ${played.length}',
                          style: const TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          played.isEmpty
                              ? 'Aucune carte jouée.'
                              : 'bonnes réponses / cartes jouées',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (played.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: played.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final sc = played[i];
                      final knew = sc.knew == true;
                      final String subtitle;
                      if (isQcm) {
                        subtitle = knew ? 'Bonne réponse' : 'Mauvaise réponse';
                      } else {
                        subtitle = knew ? 'Je savais' : 'Je savais pas';
                      }
                      return ListTile(
                        leading: Icon(
                          knew ? Icons.check_circle : Icons.cancel,
                          color: knew ? Colors.green : Colors.red,
                        ),
                        title: Text('${sc.card.fr}  —  ${sc.card.en}'),
                        subtitle: Text(subtitle),
                      );
                    },
                  ),
                )
              else
                const Expanded(child: SizedBox.shrink()),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      context.read<AppState>().endSession();
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Retour à l\'Accueil'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

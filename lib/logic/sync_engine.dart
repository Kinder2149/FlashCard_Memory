import '../models.dart';

/// Résultat d'une synchronisation : le nouvel état mémoire + le décompte.
class SyncOutcome {
  final List<Flashcard> cards; // nouvel état des cartes en mémoire
  final Map<String, Map<Direction, DirectionStat>> stats; // stats mises à jour
  final int added;
  final int updated;
  final int unchanged;
  final int deleted;

  const SyncOutcome({
    required this.cards,
    required this.stats,
    required this.added,
    required this.updated,
    required this.unchanged,
    required this.deleted,
  });
}

/// L1 — Moteur de synchronisation (diff Sheet ↔ mémoire).
///
/// Prend l'état exact des cartes valides du Sheet et cale la mémoire dessus,
/// ID par ID (spec) :
/// - ID valide absent de la mémoire      → carte intégrée (ajout)
/// - ID des deux côtés, contenu identique → inchangé
/// - ID des deux côtés, contenu différent → texte mis à jour, stats conservées
/// - ID en mémoire, absent du Sheet valide → carte supprimée + stats supprimées
///
/// Après synchronisation, la mémoire reflète exactement les cartes valides du
/// Sheet. Les statistiques ne sont jamais perdues lors d'une simple correction
/// de texte (même ID).
class SyncEngine {
  SyncOutcome synchronize({
    required List<Flashcard> memory,
    required Map<String, Map<Direction, DirectionStat>> stats,
    required List<Flashcard> validSheetCards,
  }) {
    final memoryById = {for (final c in memory) c.id: c};
    final sheetById = {for (final c in validSheetCards) c.id: c};

    final resultCards = <Flashcard>[];
    final resultStats = <String, Map<Direction, DirectionStat>>{};

    var added = 0, updated = 0, unchanged = 0, deleted = 0;

    // Parcours de l'état cible (le Sheet valide).
    for (final entry in sheetById.entries) {
      final id = entry.key;
      final sheetCard = entry.value;
      final existing = memoryById[id];

      if (existing == null) {
        added++;
        resultCards.add(sheetCard);
        // pas de stats initiales : elles naîtront au premier jeu
      } else if (existing.sameContentAs(sheetCard)) {
        unchanged++;
        resultCards.add(existing);
        if (stats.containsKey(id)) resultStats[id] = stats[id]!;
      } else {
        updated++;
        resultCards.add(sheetCard); // texte corrigé
        if (stats.containsKey(id)) resultStats[id] = stats[id]!; // stats gardées
      }
    }

    // Cartes en mémoire absentes du Sheet valide → supprimées (stats comprises).
    for (final id in memoryById.keys) {
      if (!sheetById.containsKey(id)) deleted++;
    }

    return SyncOutcome(
      cards: resultCards,
      stats: resultStats,
      added: added,
      updated: updated,
      unchanged: unchanged,
      deleted: deleted,
    );
  }
}

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

/// L1 — Moteur de synchronisation (diff fichier importé ↔ mémoire).
///
/// Prend l'état exact des cartes valides du fichier importé (Sheet ou Excel)
/// et cale la mémoire dessus, ID par ID (spec V1) :
/// - ID valide absent de la mémoire      → carte intégrée (ajout)
/// - ID des deux côtés, contenu identique → inchangé
/// - ID des deux côtés, contenu différent → texte mis à jour, stats conservées
/// - ID en mémoire, absent du fichier     → carte supprimée + stats supprimées
///
/// **V2 (A4)** : depuis que l'app permet de créer des cartes directement
/// ([manualIdPrefix]), la dernière règle ne s'applique plus à elles — aucun
/// fichier ne contiendra jamais leur ID, donc les supprimer au premier import
/// effacerait systématiquement tout ajout manuel. Une carte manuelle n'est
/// donc jamais supprimée par une synchronisation ; sa suppression reste un
/// geste volontaire (écran « Mes cartes »). Les cartes venant d'un import
/// précédent gardent le comportement V1 inchangé : le fichier réimporté fait
/// toujours foi sur son propre espace d'ID.
class SyncEngine {
  /// Préfixe des ID des cartes créées manuellement dans l'app (V2 A2).
  static const manualIdPrefix = 'APP-';

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

    // Parcours de l'état cible (le fichier importé valide).
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

    // Cartes en mémoire absentes du fichier importé :
    // - créées manuellement (APP-n) → conservées, jamais supprimées par un import.
    // - venant d'un import précédent → supprimées avec leurs stats (comportement V1).
    for (final entry in memoryById.entries) {
      final id = entry.key;
      if (sheetById.containsKey(id)) continue;
      if (id.startsWith(manualIdPrefix)) {
        resultCards.add(entry.value);
        if (stats.containsKey(id)) resultStats[id] = stats[id]!;
      } else {
        deleted++;
      }
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

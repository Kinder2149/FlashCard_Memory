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
/// ([Flashcard.id] préfixé `APP-`) ou de les importer en fusion additive
/// depuis un fichier local (préfixé `IMP-`, voir [AdditiveMerge]), la dernière
/// règle ne s'applique plus à elles — aucun lien Google Sheet ne contiendra
/// jamais leur ID, donc les supprimer à la prochaine synchronisation
/// effacerait tout ajout manuel ou fichier. Ces cartes ne sont donc jamais
/// supprimées par une synchronisation ; leur suppression reste un geste
/// volontaire (écran « Mes cartes » ou « Réinitialiser »). Les cartes venant
/// du lien Sheet lui-même gardent le comportement V1 inchangé : ce lien fait
/// toujours foi sur son propre espace d'ID (document unique et continu, à la
/// différence d'un fichier local qui peut être un nouveau modèle re-téléchargé).
class SyncEngine {
  /// Préfixes des ID « possédés par l'app », jamais supprimés par une
  /// synchronisation avec le lien Sheet : créés à la main (`APP-`, V2 A2) ou
  /// ajoutés par fusion additive de fichier (`IMP-`, V2 A5).
  static bool isAppOwnedId(String id) =>
      id.startsWith('APP-') || id.startsWith('IMP-');

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
    // - possédées par l'app (APP-/IMP-) → conservées, jamais supprimées.
    // - venant du lien Sheet lui-même → supprimées avec leurs stats (comportement V1).
    for (final entry in memoryById.entries) {
      final id = entry.key;
      if (sheetById.containsKey(id)) continue;
      if (isAppOwnedId(id)) {
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

import '../models.dart';

/// Résultat d'une fusion additive.
class MergeOutcome {
  final List<Flashcard> cards; // nouvel état mémoire (mémoire + ajouts)
  final int added;
  final int skipped; // contenu déjà présent, ignoré (jamais écrasé)

  const MergeOutcome({
    required this.cards,
    required this.added,
    required this.skipped,
  });
}

/// L — Fusion additive d'un import fichier local dans la base mère de l'app
/// (V2 A5, corrige un bug de perte de données signalé après test).
///
/// Contrairement à [SyncEngine] (réservé au lien Google Sheet, document
/// unique et continu où l'ID fait foi), un fichier local peut être une
/// nouvelle copie du modèle re-téléchargée : ses ID (`EN-1`, `EN-2`…)
/// recommencent alors à zéro et n'ont plus aucun rapport fiable avec ceux
/// déjà en mémoire. Comparer par ID importerait un mot différent sous un ID
/// déjà pris pour un « mot corrigé » (écrasement silencieux), ou effacerait
/// tout ce qui n'est pas dans CE fichier précis (perte de données observée).
///
/// La fusion se fait donc par **contenu** (mot langue mère + mot langue
/// étrangère + langue, insensible à la casse), jamais par ID : une carte de
/// contenu déjà présent est ignorée (jamais écrasée), les autres sont
/// ajoutées avec un nouvel ID réservé (`IMP-n`, jamais fourni par le
/// fichier). Aucune carte existante n'est jamais supprimée par cette fusion.
class AdditiveMerge {
  static const newIdPrefix = 'IMP-';

  MergeOutcome merge({
    required List<Flashcard> memory,
    required List<Flashcard> importedValidCards,
  }) {
    final existingContent = memory.map(_key).toSet();
    final resultCards = List<Flashcard>.of(memory);
    var added = 0, skipped = 0;
    var nextId = _nextId(memory);

    for (final c in importedValidCards) {
      final key = _key(c);
      if (existingContent.contains(key)) {
        skipped++;
        continue;
      }
      existingContent.add(key);
      resultCards.add(Flashcard(
        id: '$newIdPrefix$nextId',
        motherWord: c.motherWord,
        foreignWord: c.foreignWord,
        foreignLang: c.foreignLang,
        theme: c.theme,
      ));
      nextId++;
      added++;
    }

    return MergeOutcome(cards: resultCards, added: added, skipped: skipped);
  }

  String _key(Flashcard c) => '${c.motherWord.toLowerCase()}'
      '|${c.foreignWord.toLowerCase()}|${c.foreignLang.toUpperCase()}';

  int _nextId(List<Flashcard> memory) {
    var max = 0;
    for (final c in memory) {
      if (c.id.startsWith(newIdPrefix)) {
        final n = int.tryParse(c.id.substring(newIdPrefix.length));
        if (n != null && n > max) max = n;
      }
    }
    return max + 1;
  }
}

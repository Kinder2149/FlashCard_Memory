import 'dart:math';
import '../models.dart';

/// Les 4 options d'une carte QCM : la liste déjà mélangée + l'indice de la
/// bonne réponse dans cette liste.
class QcmOptions {
  final List<String> options;
  final int correctIndex;

  const QcmOptions(this.options, this.correctIndex);

  String get correct => options[correctIndex];
}

/// L — Construction des options QCM et disponibilité du mode.
///
/// Les distracteurs proviennent **uniquement** des cartes déjà importées, dans
/// la même langue cible que la bonne réponse (jamais de mot externe). Priorité
/// de choix (préférence, pas filtre) : d'abord les mots du même thème, sinon en
/// complément les mots orthographiquement proches de la bonne réponse, sinon
/// n'importe quel autre mot de la paire. Les 4 options sont toujours distinctes
/// entre elles : deux cartes au même texte cible ne comptent que pour une option.
class QcmBuilder {
  /// Nombre total d'options affichées (1 bonne réponse + 3 distracteurs).
  static const int optionCount = 4;
  static const int _distractorCount = optionCount - 1;

  /// Texte cible (langue de la réponse) d'une carte selon le sens.
  String _target(Flashcard c, Direction d) =>
      d == Direction.motherToForeign ? c.foreignWord : c.motherWord;

  /// Nombre de textes cibles distincts dans toute la paire, pour ce sens.
  int distinctTargetCount(List<Flashcard> cards, Direction d) => cards
      .map((c) => _target(c, d))
      .where((t) => t.isNotEmpty)
      .toSet()
      .length;

  /// Le QCM est jouable si la paire entière compte au moins 4 mots cibles
  /// distincts pour ce sens (sinon une carte ne peut pas réunir 3 distracteurs).
  bool isAvailable(List<Flashcard> cards, Direction d) =>
      distinctTargetCount(cards, d) >= optionCount;

  /// Construit les 4 options pour [card]. [cards] = toute la paire (source des
  /// distracteurs). [rng] injectable pour rendre les tests déterministes.
  ///
  /// Suppose le mode disponible : s'il manque des distracteurs (paire trop
  /// pauvre), renvoie moins de 4 options sans planter — la disponibilité est
  /// vérifiée en amont au paramétrage.
  QcmOptions build({
    required Flashcard card,
    required List<Flashcard> cards,
    required Direction direction,
    Random? rng,
  }) {
    final random = rng ?? Random();
    final correct = _target(card, direction);

    // Textes cibles distincts (≠ bonne réponse), classés selon qu'ils
    // apparaissent ou non dans le thème de la carte. Un même texte présent dans
    // le thème y reste rattaché en priorité, quel que soit l'ordre de parcours.
    final inTheme = <String>{};
    final elsewhere = <String>{};
    for (final c in cards) {
      final t = _target(c, direction);
      if (t.isEmpty || t == correct) continue;
      final sameTheme = card.theme.isNotEmpty && c.theme == card.theme;
      if (sameTheme) {
        inTheme.add(t);
        elsewhere.remove(t); // le thème prime sur « ailleurs »
      } else if (!inTheme.contains(t)) {
        elsewhere.add(t);
      }
    }

    final distractors = <String>[];
    // 1. Même thème, dans un ordre aléatoire (varie les distracteurs d'une
    //    partie à l'autre).
    final themePool = inTheme.toList()..shuffle(random);
    distractors.addAll(themePool.take(_distractorCount));
    // 2. Complément : les plus proches orthographiquement d'abord, puis les
    //    autres (la liste triée par distance couvre les deux priorités).
    if (distractors.length < _distractorCount) {
      final rest = elsewhere.toList()
        ..sort((a, b) =>
            _distance(a, correct).compareTo(_distance(b, correct)));
      for (final t in rest) {
        if (distractors.length >= _distractorCount) break;
        distractors.add(t);
      }
    }

    final options = [correct, ...distractors]..shuffle(random);
    return QcmOptions(options, options.indexOf(correct));
  }

  /// Distance d'édition (Levenshtein), insensible à la casse. Sert à mesurer la
  /// proximité orthographique entre deux mots — aucune donnée externe.
  int _distance(String a, String b) {
    final s = a.toLowerCase();
    final t = b.toLowerCase();
    final m = s.length, n = t.length;
    if (m == 0) return n;
    if (n == 0) return m;
    var prev = List<int>.generate(n + 1, (j) => j);
    var cur = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      cur[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        final del = prev[j] + 1;
        final ins = cur[j - 1] + 1;
        final sub = prev[j - 1] + cost;
        cur[j] = min(sub, min(del, ins));
      }
      final tmp = prev;
      prev = cur;
      cur = tmp;
    }
    return prev[n];
  }
}

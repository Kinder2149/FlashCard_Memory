import 'dart:math';
import '../models.dart';

/// L3 — Constitution de session (filtre paire de langues + thème + ordre
/// aléatoire).
///
/// Sélectionne les cartes du périmètre choisi (une paire de langues, un thème
/// précis ou tous) et les mélange. Chaque carte apparaît une seule fois. Le
/// sens de jeu n'influe pas sur la sélection : il est porté par la session au
/// moment du jeu.
class SessionBuilder {
  /// [foreignLang] = la paire choisie (code de la langue étrangère). [theme]
  /// null = « tout ». [rng] injectable pour les tests.
  List<Flashcard> build({
    required List<Flashcard> cards,
    required String foreignLang,
    required String? theme,
    Random? rng,
  }) {
    final pool = cards
        .where((c) => c.foreignLang.toUpperCase() == foreignLang.toUpperCase())
        .where((c) => theme == null || c.theme == theme)
        .toList();
    pool.shuffle(rng);
    return pool;
  }
}

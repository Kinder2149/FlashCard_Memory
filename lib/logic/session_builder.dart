import 'dart:math';
import '../models.dart';

/// L3 — Constitution de session (filtre thème + ordre aléatoire).
///
/// Sélectionne les cartes du périmètre choisi (un thème précis, ou toutes) et
/// les mélange. Chaque carte apparaît une seule fois. Le sens de jeu n'influe
/// pas sur la sélection : il est porté par la session au moment du jeu.
class SessionBuilder {
  /// [theme] null = « tout ». [rng] injectable pour les tests.
  List<Flashcard> build({
    required List<Flashcard> cards,
    required String? theme,
    Random? rng,
  }) {
    final pool = theme == null
        ? List<Flashcard>.of(cards)
        : cards.where((c) => c.theme == theme).toList();
    pool.shuffle(rng);
    return pool;
  }
}

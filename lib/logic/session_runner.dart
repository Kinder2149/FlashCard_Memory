import '../models.dart';

/// Une carte au sein d'une session, avec son résultat éventuel.
class SessionCard {
  final Flashcard card;
  bool? knew; // null = pas encore jouée

  SessionCard(this.card);
}

/// L4 — Déroulé de session (carte courante, validation, auto-évaluation, clôture).
///
/// Présente les cartes une par une dans l'ordre fourni. Pour chaque carte :
/// afficher le mot source (selon le sens), puis dévoiler la réponse attendue,
/// puis enregistrer « je savais » / « je savais pas ». La session peut être
/// clôturée à tout moment : seules les cartes jouées comptent.
class GameSession {
  final Direction direction;
  final GameMode mode;
  final List<SessionCard> cards;
  int _index = 0;
  bool closed = false;

  GameSession({
    required this.direction,
    this.mode = GameMode.typing,
    required List<Flashcard> pool,
  }) : cards = pool.map(SessionCard.new).toList();

  int get total => cards.length;
  int get position => _index; // nombre de cartes déjà passées

  SessionCard? get current => _index < cards.length ? cards[_index] : null;

  /// Terminée quand toutes les cartes sont passées, ou clôturée manuellement.
  bool get isFinished => closed || _index >= cards.length;

  /// Mot affiché (langue source, selon le sens).
  String prompt(Flashcard c) =>
      direction == Direction.frToEn ? c.fr : c.en;

  /// Réponse attendue (langue cible, selon le sens).
  String answer(Flashcard c) =>
      direction == Direction.frToEn ? c.en : c.fr;

  /// Enregistre le résultat de la carte courante et avance.
  void answerCurrent(bool knew) {
    final cur = current;
    if (cur == null) return;
    cur.knew = knew;
    _index++;
  }

  /// Clôture anticipée : les cartes non jouées ne comptent pas.
  void close() => closed = true;

  List<SessionCard> get playedCards =>
      cards.where((c) => c.knew != null).toList();

  int get playedCount => playedCards.length;
  int get correctCount => cards.where((c) => c.knew == true).length;
}

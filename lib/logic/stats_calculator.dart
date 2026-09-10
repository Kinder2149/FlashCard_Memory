import '../models.dart';

/// L5 — Calcul des statistiques (taux cumulatif, score de session).
///
/// Le taux cumulatif d'une carte pour un sens = nombre de « je savais » /
/// nombre de tentatives, depuis toujours. Le score de session = bonnes
/// réponses / cartes réellement jouées (calculé par la session elle-même).
class StatsCalculator {
  /// Enregistre une tentative dans la carte du bon sens (crée l'entrée si
  /// besoin). Appelé immédiatement à chaque « je savais / je savais pas ».
  void registerAttempt(
    Map<String, Map<Direction, DirectionStat>> stats,
    String cardId,
    Direction direction,
    bool knew,
  ) {
    final byDir = stats.putIfAbsent(cardId, () => {});
    final stat = byDir.putIfAbsent(direction, () => DirectionStat());
    stat.register(knew);
  }

  /// Taux cumulatif (0..1) d'une carte pour un sens, ou null si jamais tentée.
  double? rateOf(
    Map<String, Map<Direction, DirectionStat>> stats,
    String cardId,
    Direction direction,
  ) =>
      stats[cardId]?[direction]?.rate;
}

/// Structures de données partagées par les trois couches.
///
/// Ce fichier ne contient que des données (pas de logique métier ni d'écran).
/// Il fait partie de la couche Données au sens conceptuel.
library;

/// Mode de jeu d'une session.
///
/// [typing] = saisie (écrit sa réponse puis auto-évaluation « je savais »).
/// [qcm] = choix multiple (choisit une option parmi quatre, évaluation
/// automatique). Les deux modes tiennent des statistiques séparées.
enum GameMode { typing, qcm }

extension GameModeInfo on GameMode {
  /// Libellé affiché à l'utilisateur.
  String get label =>
      this == GameMode.typing ? 'Saisie' : 'QCM (choix multiple)';

  /// Code stable utilisé pour le stockage (ne pas traduire / renommer).
  String get code => this == GameMode.typing ? 'TYPING' : 'QCM';
}

/// Sens de jeu d'une carte.
enum Direction { frToEn, enToFr }

extension DirectionInfo on Direction {
  /// Libellé affiché à l'utilisateur.
  String get label =>
      this == Direction.frToEn ? 'Français → Anglais' : 'Anglais → Français';

  /// Code stable utilisé pour le stockage (ne pas traduire / renommer).
  String get code => this == Direction.frToEn ? 'FR_EN' : 'EN_FR';

  static Direction fromCode(String code) =>
      code == 'EN_FR' ? Direction.enToFr : Direction.frToEn;
}

/// Une flashcard : identité figée (id) + contenu (fr, en, thème).
class Flashcard {
  final String id;
  final String fr;
  final String en;
  final String theme; // '' si aucun thème

  const Flashcard({
    required this.id,
    required this.fr,
    required this.en,
    required this.theme,
  });

  /// Deux cartes ont le même contenu si texte FR, EN et thème sont identiques.
  bool sameContentAs(Flashcard other) =>
      fr == other.fr && en == other.en && theme == other.theme;

  Map<String, dynamic> toJson() => {'id': id, 'fr': fr, 'en': en, 'theme': theme};

  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
        id: j['id'] as String,
        fr: j['fr'] as String,
        en: j['en'] as String,
        theme: (j['theme'] as String?) ?? '',
      );
}

/// Statistique cumulative d'une carte pour UN sens donné.
class DirectionStat {
  int attempts; // nombre de tentatives
  int knew; // nombre de « je savais »

  DirectionStat({this.attempts = 0, this.knew = 0});

  /// Taux cumulatif (0..1), ou null si jamais tentée.
  double? get rate => attempts == 0 ? null : knew / attempts;

  void register(bool knewIt) {
    attempts += 1;
    if (knewIt) knew += 1;
  }

  Map<String, dynamic> toJson() => {'attempts': attempts, 'knew': knew};

  factory DirectionStat.fromJson(Map<String, dynamic> j) => DirectionStat(
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
        knew: (j['knew'] as num?)?.toInt() ?? 0,
      );
}

/// Ligne brute issue du CSV, colonnes déjà séparées et nettoyées (trim).
class RawRow {
  final String id;
  final String fr;
  final String en;
  final String theme;

  const RawRow({
    required this.id,
    required this.fr,
    required this.en,
    required this.theme,
  });
}

/// Résultat d'un import : ce qui sera montré dans le rapport d'import.
class ImportReport {
  final int added;
  final int updated;
  final int deleted;
  final int unchanged;
  final List<String> incompleteIds; // lignes commencées mais incomplètes
  final List<String> duplicateIds; // même correspondance sous 2 ID
  final int sheetValidCount; // nombre d'entrées valides trouvées dans le Sheet

  const ImportReport({
    required this.added,
    required this.updated,
    required this.deleted,
    required this.unchanged,
    required this.incompleteIds,
    required this.duplicateIds,
    required this.sheetValidCount,
  });
}

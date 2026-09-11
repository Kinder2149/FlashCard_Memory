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
///
/// V2 : ces deux valeurs signifient génériquement « langue mère → langue
/// étrangère » ([motherToForeign]) et l'inverse ([foreignToMother]) — les noms
/// FR/EN sont restés pour ne pas casser les codes déjà stockés (voir [code]),
/// mais ne présument plus que la langue étrangère est l'anglais. Le libellé
/// affiché se construit dynamiquement à partir des langues réelles de la
/// carte/session (voir [directionLabel]).
enum Direction { motherToForeign, foreignToMother }

extension DirectionInfo on Direction {
  /// Code stable utilisé pour le stockage (ne pas changer : des statistiques
  /// existantes en dépendent, y compris celles de la V1 mono-paire FR/EN).
  String get code => this == Direction.motherToForeign ? 'FR_EN' : 'EN_FR';

  static Direction fromCode(String code) =>
      code == 'EN_FR' ? Direction.foreignToMother : Direction.motherToForeign;
}

/// Libellé d'un sens de jeu à partir des langues réelles concernées.
String directionLabel(Direction d, String motherLang, String foreignLang) {
  final m = Languages.nameOf(motherLang);
  final f = Languages.nameOf(foreignLang);
  return d == Direction.motherToForeign ? '$m → $f' : '$f → $m';
}

/// Table de langues courantes (code ISO → nom affiché en français). Un code
/// absent de la table est affiché tel quel (majuscules) plutôt que de planter
/// — une langue non répertoriée reste utilisable, juste moins joliment nommée.
class Languages {
  static const Map<String, String> _names = {
    'FR': 'Français',
    'EN': 'Anglais',
    'ES': 'Espagnol',
    'DE': 'Allemand',
    'IT': 'Italien',
    'PT': 'Portugais',
    'NL': 'Néerlandais',
  };

  static String nameOf(String code) =>
      _names[code.toUpperCase()] ?? code.toUpperCase();

  /// Codes proposés dans les sélecteurs (langue mère, ajout manuel d'une carte).
  static List<String> get codes => _names.keys.toList();
}

/// Une flashcard : identité figée (id) + contenu (mot en langue mère, mot en
/// langue étrangère, code de la langue étrangère, thème).
///
/// V2 : [foreignLang] remplace l'hypothèse V1 « toujours de l'anglais » —
/// plusieurs langues étrangères peuvent coexister en mémoire ; la langue mère,
/// elle, est un réglage unique de l'app (voir [AppState.motherLang]), pas un
/// champ par carte : on suppose un seul apprenant, donc une seule langue mère.
class Flashcard {
  final String id;
  final String motherWord;
  final String foreignWord;
  final String foreignLang; // code ISO (ex. 'EN', 'ES')
  final String theme; // '' si aucun thème

  const Flashcard({
    required this.id,
    required this.motherWord,
    required this.foreignWord,
    required this.foreignLang,
    required this.theme,
  });

  /// Deux cartes ont le même contenu si les deux mots, la langue étrangère et
  /// le thème sont identiques.
  bool sameContentAs(Flashcard other) =>
      motherWord == other.motherWord &&
      foreignWord == other.foreignWord &&
      foreignLang == other.foreignLang &&
      theme == other.theme;

  Map<String, dynamic> toJson() => {
        'id': id,
        'motherWord': motherWord,
        'foreignWord': foreignWord,
        'foreignLang': foreignLang,
        'theme': theme,
      };

  /// Lit aussi l'ancien format V1 (clés `fr`/`en`, toujours anglais) pour ne
  /// pas perdre les cartes déjà en mémoire chez les utilisateurs existants.
  factory Flashcard.fromJson(Map<String, dynamic> j) {
    final isLegacy = j.containsKey('fr');
    return Flashcard(
      id: j['id'] as String,
      motherWord: (isLegacy ? j['fr'] : j['motherWord']) as String,
      foreignWord: (isLegacy ? j['en'] : j['foreignWord']) as String,
      foreignLang: (j['foreignLang'] as String?) ?? 'EN',
      theme: (j['theme'] as String?) ?? '',
    );
  }
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

/// Ligne brute issue du fichier importé, colonnes déjà séparées et nettoyées
/// (trim). [foreignLang] vaut 'EN' par défaut quand la colonne Langue est
/// absente ou vide (rétro-compatibilité avec le template V1, mono-paire FR/EN).
class RawRow {
  final String id;
  final String motherWord;
  final String foreignWord;
  final String foreignLang;
  final String theme;

  const RawRow({
    required this.id,
    required this.motherWord,
    required this.foreignWord,
    required this.foreignLang,
    required this.theme,
  });
}

/// Aperçu d'un fichier lu et validé, avant toute décision de l'utilisateur
/// (V2 A6) : ne modifie pas la mémoire. Permet d'afficher ce que contient le
/// fichier et de choisir ensuite entre ajouter à la base ou la remplacer.
class ImportPreview {
  final List<Flashcard> validCards;
  final List<String> incompleteIds;
  final List<String> duplicateIds;

  const ImportPreview({
    required this.validCards,
    required this.incompleteIds,
    required this.duplicateIds,
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

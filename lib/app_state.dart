import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'data/cards_store.dart';
import 'data/stats_store.dart';
import 'data/link_store.dart';
import 'data/settings_store.dart';
import 'data/csv_source.dart';
import 'data/csv_parser.dart';
import 'data/local_file_source.dart';
import 'logic/validation.dart';
import 'logic/sync_engine.dart';
import 'logic/additive_merge.dart';
import 'logic/session_builder.dart';
import 'logic/session_runner.dart';
import 'logic/stats_calculator.dart';
import 'logic/qcm_builder.dart';

/// État de l'affichage (Provider, imposé par STACK_STANDARD).
///
/// Fait le lien entre la couche Données (stockages, CSV) et la couche Logique
/// (validation, synchronisation), et expose aux écrans un état simple à lire.
/// Ne contient aucune règle métier : il orchestre, il ne décide pas.
class AppState extends ChangeNotifier {
  // Couche Données
  final CardsStore _cardsStore;
  final StatsStore _statsStore; // stats du mode saisie
  final StatsStore _qcmStatsStore; // stats du mode QCM (clé de stockage séparée)
  final LinkStore _linkStore;
  final SettingsStore _settingsStore;
  final CsvSource _csvSource;
  final CsvParser _parser;
  final LocalFileSource _fileSource;
  // Couche Logique
  final Validator _validator;
  final SyncEngine _sync;
  final AdditiveMerge _merge;
  final SessionBuilder _sessionBuilder;
  final StatsCalculator _statsCalc;
  final QcmBuilder _qcmBuilder;

  AppState(SharedPreferences prefs)
      : _cardsStore = CardsStore(prefs),
        _statsStore = StatsStore(prefs),
        _qcmStatsStore = StatsStore(prefs, key: 'stats_qcm'),
        _linkStore = LinkStore(prefs),
        _settingsStore = SettingsStore(prefs),
        _csvSource = CsvSource(),
        _parser = CsvParser(),
        _fileSource = LocalFileSource(),
        _validator = Validator(),
        _sync = SyncEngine(),
        _merge = AdditiveMerge(),
        _sessionBuilder = SessionBuilder(),
        _statsCalc = StatsCalculator(),
        _qcmBuilder = QcmBuilder();

  // --- État en mémoire ---
  List<Flashcard> _cards = [];
  Map<String, Map<Direction, DirectionStat>> _stats = {}; // saisie
  Map<String, Map<Direction, DirectionStat>> _qcmStats = {}; // QCM
  String? _csvLink;
  ImportReport? _lastReport;
  GameSession? _session;
  String _motherLang = SettingsStore.defaultLang;
  bool _showOnboarding = false;

  // Comparaison Accueil (meilleur effort, sans modifier la mémoire).
  HomeCheck _homeCheck = HomeCheck.idle;
  int? _sheetValidCountLive;
  int? _toIntegrateLive;

  // --- Lecture pour les écrans ---
  List<Flashcard> get cards => List.unmodifiable(_cards);
  int get memoryCount => _cards.length;
  bool get hasCards => _cards.isNotEmpty;
  String? get csvLink => _csvLink;
  bool get hasLink => _csvLink != null;
  ImportReport? get lastReport => _lastReport;
  GameSession? get session => _session;

  /// Thèmes distincts présents en mémoire (hors thème vide), triés.
  List<String> get themes {
    final set = _cards
        .map((c) => c.theme)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    set.sort();
    return set;
  }

  /// L'écran d'accueil pédagogique doit-il être montré (V2 chantier D) ?
  /// Vrai uniquement avant le tout premier passage dessus.
  bool get showOnboarding => _showOnboarding;

  /// Marque l'écran d'accueil pédagogique comme vu : ne réapparaît plus.
  Future<void> completeOnboarding() async {
    _showOnboarding = false;
    await _settingsStore.markOnboardingSeen();
    notifyListeners();
  }

  /// Langue mère (réglage unique de l'app, V2 chantier B).
  String get motherLang => _motherLang;

  /// Change la langue mère. N'affecte que l'affichage : le texte déjà tapé
  /// dans les cartes n'est jamais retraduit.
  Future<void> setMotherLang(String code) async {
    _motherLang = code.toUpperCase();
    await _settingsStore.save(_motherLang);
    notifyListeners();
  }

  /// Paires de langues disponibles (codes de langue étrangère distincts
  /// présents en mémoire), triées. Le jeu ne propose que celles-ci.
  List<String> get availablePairs {
    final set = _cards.map((c) => c.foreignLang.toUpperCase()).toSet().toList();
    set.sort();
    return set;
  }

  HomeCheck get homeCheck => _homeCheck;
  int? get sheetValidCountLive => _sheetValidCountLive;
  int? get toIntegrateLive => _toIntegrateLive;

  /// Charge l'état persistant au démarrage.
  void load() {
    _cards = _cardsStore.load();
    _stats = _statsStore.load();
    _qcmStats = _qcmStatsStore.load();
    _csvLink = _linkStore.load();
    _motherLang = _settingsStore.load();
    _showOnboarding = !_settingsStore.hasSeenOnboarding();
    notifyListeners();
  }

  /// Import / mise à jour : télécharge le CSV, synchronise la mémoire, persiste,
  /// et produit le rapport d'import. [pastedLink] est fourni au premier import ;
  /// ensuite « mettre à jour » appelle sans argument (lien mémorisé).
  Future<ImportReport> importFromLink({String? pastedLink}) async {
    final link = (pastedLink != null && pastedLink.trim().isNotEmpty)
        ? pastedLink.trim()
        : _csvLink;
    if (link == null) {
      throw const CsvSourceException('Aucun lien à utiliser : colle d\'abord un lien.');
    }

    final content = await _csvSource.fetch(link); // D1
    final rows = _parser.parse(content); // D2

    if (link != _csvLink) {
      _csvLink = link;
      await _linkStore.save(link); // D5
    }
    return _applyRows(rows);
  }

  /// Lit et valide un fichier Excel (.xlsx) choisi sur l'appareil, **sans
  /// toucher à la mémoire** (V2 A6). Permet d'afficher un aperçu — ce que le
  /// fichier contient — avant de laisser l'utilisateur choisir entre ajouter
  /// à la base ou la remplacer entièrement (voir [commitXlsxPreview]).
  ImportPreview previewXlsxFile(Uint8List bytes) {
    final rows = _fileSource.readRows(bytes); // D6
    final validation = _validator.validate(rows); // L2
    return ImportPreview(
      validCards: validation.validCards,
      incompleteIds: validation.incompleteIds,
      duplicateIds: validation.duplicateIds,
    );
  }

  /// Intègre un aperçu déjà validé (V2 A6), selon le choix de l'utilisateur :
  /// - [replace] = false (« Ajouter ») : fusion additive dans la base
  ///   actuelle (comportement A5) — rien n'est jamais écrasé ni supprimé.
  /// - [replace] = true (« Remplacer ») : la base actuelle (cartes + stats,
  ///   toutes origines confondues) est effacée avant d'intégrer le fichier —
  ///   geste explicite et volontaire de l'utilisateur, jamais un effet de
  ///   bord automatique d'un import.
  Future<ImportReport> commitXlsxPreview(
    ImportPreview preview, {
    required bool replace,
  }) async {
    final previousCount = _cards.length;
    if (replace) {
      _cards = [];
      _stats = {};
      _qcmStats = {};
    }
    final outcome = _merge.merge(
      memory: _cards,
      importedValidCards: preview.validCards,
    ); // L (fusion additive)

    _cards = outcome.cards;
    await _cardsStore.save(_cards); // D3
    if (replace) {
      await _statsStore.save(_stats); // D4
      await _qcmStatsStore.save(_qcmStats); // D4 (QCM)
    }

    _lastReport = ImportReport(
      added: outcome.added,
      updated: 0,
      deleted: replace ? previousCount : 0,
      unchanged: outcome.skipped,
      incompleteIds: preview.incompleteIds,
      duplicateIds: preview.duplicateIds,
      sheetValidCount: preview.validCards.length,
    );

    notifyListeners();
    return _lastReport!;
  }

  /// Tronc commun à l'import par lien Google Sheet : validation (L2),
  /// synchronisation par ID (L1), persistance (D3/D4) et rapport. Document
  /// unique et continu : contrairement au fichier local, l'ID y fait foi
  /// (voir la documentation de [SyncEngine]).
  Future<ImportReport> _applyRows(List<RawRow> rows) async {
    final validation = _validator.validate(rows); // L2
    final outcome = _sync.synchronize(
      memory: _cards,
      stats: _stats,
      validSheetCards: validation.validCards,
    ); // L1

    _cards = outcome.cards;
    _stats = outcome.stats;
    // Les stats QCM suivent la même règle : on ne garde que les cartes
    // survivantes (une carte disparue du Sheet perd ses stats des deux modes).
    final survivingIds = {for (final c in outcome.cards) c.id};
    _qcmStats.removeWhere((id, _) => !survivingIds.contains(id));
    await _cardsStore.save(_cards); // D3
    await _statsStore.save(_stats); // D4
    await _qcmStatsStore.save(_qcmStats); // D4 (QCM)

    _lastReport = ImportReport(
      added: outcome.added,
      updated: outcome.updated,
      deleted: outcome.deleted,
      unchanged: outcome.unchanged,
      incompleteIds: validation.incompleteIds,
      duplicateIds: validation.duplicateIds,
      sheetValidCount: validation.validCards.length,
    );

    // Après un import, la mémoire reflète exactement la source.
    _sheetValidCountLive = validation.validCards.length;
    _toIntegrateLive = 0;
    _homeCheck = HomeCheck.done;

    notifyListeners();
    return _lastReport!;
  }

  // --- Gestion manuelle des cartes (A2) ---

  /// Génère un ID pour une carte créée dans l'app : espace réservé « APP-n »,
  /// distinct de l'espace des ID importés (ex. EN-42), pour ne jamais entrer
  /// en collision avec un futur import.
  String _nextManualId() {
    const prefix = 'APP-';
    var max = 0;
    for (final c in _cards) {
      if (c.id.startsWith(prefix)) {
        final n = int.tryParse(c.id.substring(prefix.length));
        if (n != null && n > max) max = n;
      }
    }
    return '$prefix${max + 1}';
  }

  /// Crée une carte directement dans l'app, hors import.
  Future<void> addCard({
    required String motherWord,
    required String foreignWord,
    required String foreignLang,
    required String theme,
  }) async {
    final card = Flashcard(
      id: _nextManualId(),
      motherWord: motherWord.trim(),
      foreignWord: foreignWord.trim(),
      foreignLang: foreignLang.trim().toUpperCase(),
      theme: theme.trim(),
    );
    _cards = [..._cards, card];
    await _cardsStore.save(_cards); // D3
    notifyListeners();
  }

  /// Modifie le texte d'une carte existante. Les statistiques sont conservées,
  /// comme pour une correction via import.
  Future<void> updateCard(
    String id, {
    required String motherWord,
    required String foreignWord,
    required String foreignLang,
    required String theme,
  }) async {
    _cards = _cards
        .map((c) => c.id == id
            ? Flashcard(
                id: id,
                motherWord: motherWord.trim(),
                foreignWord: foreignWord.trim(),
                foreignLang: foreignLang.trim().toUpperCase(),
                theme: theme.trim(),
              )
            : c)
        .toList();
    await _cardsStore.save(_cards); // D3
    notifyListeners();
  }

  /// Supprime une carte et ses statistiques (saisie + QCM).
  Future<void> deleteCard(String id) async {
    _cards = _cards.where((c) => c.id != id).toList();
    _stats.remove(id);
    _qcmStats.remove(id);
    await _cardsStore.save(_cards); // D3
    await _statsStore.save(_stats); // D4
    await _qcmStatsStore.save(_qcmStats); // D4 (QCM)
    notifyListeners();
  }

  // --- Statistiques (lecture pour l'écran de consultation) ---

  /// Taux cumulatif (0..1) d'une carte pour un sens en **saisie**, ou null si
  /// jamais tentée.
  double? rateOf(String cardId, Direction dir) =>
      _statsCalc.rateOf(_stats, cardId, dir);

  /// Nombre de tentatives cumulées d'une carte pour un sens en **saisie**.
  int attemptsOf(String cardId, Direction dir) =>
      _stats[cardId]?[dir]?.attempts ?? 0;

  /// Taux cumulatif (0..1) d'une carte pour un sens en **QCM**, ou null si
  /// jamais tentée. Comptabilisé séparément de la saisie.
  double? qcmRateOf(String cardId, Direction dir) =>
      _statsCalc.rateOf(_qcmStats, cardId, dir);

  /// Nombre de tentatives cumulées d'une carte pour un sens en **QCM**.
  int qcmAttemptsOf(String cardId, Direction dir) =>
      _qcmStats[cardId]?[dir]?.attempts ?? 0;

  /// Vide la mémoire : efface toutes les cartes et toutes les statistiques.
  /// Le lien mémorisé est conservé pour pouvoir réimporter facilement.
  Future<void> clearMemory() async {
    _cards = [];
    _stats = {};
    _qcmStats = {};
    await _cardsStore.save(_cards); // D3
    await _statsStore.save(_stats); // D4
    await _qcmStatsStore.save(_qcmStats); // D4 (QCM)
    _lastReport = null;
    _sheetValidCountLive = null;
    _toIntegrateLive = null;
    _homeCheck = HomeCheck.idle;
    notifyListeners();
  }

  // --- Jeu ---

  /// Cartes de la paire de langues [foreignLang] (V2 chantier B).
  List<Flashcard> _cardsOfPair(String foreignLang) => _cards
      .where((c) => c.foreignLang.toUpperCase() == foreignLang.toUpperCase())
      .toList();

  /// Démarre une session sur le périmètre choisi : paire de langues, thème
  /// ([theme] null = tous les thèmes) et sens. [mode] = saisie (défaut) ou
  /// QCM. Renvoie false si le périmètre ne contient aucune carte.
  bool startSession({
    required String foreignLang,
    required String? theme,
    required Direction direction,
    GameMode mode = GameMode.typing,
  }) {
    final pool = _sessionBuilder.build(
      cards: _cards,
      foreignLang: foreignLang,
      theme: theme,
    ); // L3
    if (pool.isEmpty) return false;
    _session = GameSession(
      direction: direction,
      mode: mode,
      motherLang: _motherLang,
      foreignLang: foreignLang,
      pool: pool,
    ); // L4
    notifyListeners();
    return true;
  }

  /// Le mode QCM est-il jouable pour ce sens, sur cette paire ? (au moins 4
  /// mots cibles distincts dans la paire, pour réunir 1 bonne réponse + 3
  /// distracteurs).
  bool isQcmAvailable(Direction direction, String foreignLang) =>
      _qcmBuilder.isAvailable(_cardsOfPair(foreignLang), direction);

  /// Construit les 4 options QCM de la carte courante (bonne réponse + 3
  /// distracteurs tirés de la même paire de langues), dans un ordre aléatoire.
  QcmOptions buildQcmOptions(Flashcard card, {Random? rng}) {
    final session = _session;
    return _qcmBuilder.build(
      card: card,
      cards: session == null ? _cards : _cardsOfPair(session.foreignLang),
      direction: session?.direction ?? Direction.motherToForeign,
      rng: rng,
    );
  }

  /// Enregistre le choix de la carte QCM courante ([correct] = bon choix), met à
  /// jour la statistique QCM correspondante (persistée immédiatement pour
  /// survivre à une fermeture) et avance la session. Les stats QCM sont tenues
  /// séparément des stats de saisie.
  Future<void> answerQcmCurrent(bool correct) async {
    final s = _session;
    final cur = s?.current;
    if (s == null || cur == null) return;
    _statsCalc.registerAttempt(_qcmStats, cur.card.id, s.direction, correct);
    s.answerCurrent(correct);
    await _qcmStatsStore.save(_qcmStats); // D4 (QCM) — persistance immédiate
    notifyListeners();
  }

  /// Enregistre la réponse de la carte courante et met à jour la statistique
  /// correspondante immédiatement (persistée pour survivre à une fermeture).
  Future<void> answerCurrent(bool knew) async {
    final s = _session;
    final cur = s?.current;
    if (s == null || cur == null) return;
    _statsCalc.registerAttempt(_stats, cur.card.id, s.direction, knew); // L5
    s.answerCurrent(knew);
    await _statsStore.save(_stats); // D4 — persistance immédiate
    notifyListeners();
  }

  /// Clôture anticipée de la session (les cartes non jouées ne comptent pas).
  void closeSession() {
    _session?.close();
    notifyListeners();
  }

  /// Termine la session (après le récap) et revient à un état sans partie.
  void endSession() {
    _session = null;
    notifyListeners();
  }

  /// Vérifie sur l'Accueil, en meilleur effort, combien d'entrées valides
  /// existent actuellement dans le Sheet et combien restent à intégrer — sans
  /// rien modifier en mémoire. Silencieux : en cas d'échec (hors-ligne, lien
  /// injoignable), on retombe simplement sur le décompte local.
  Future<void> refreshHomeComparison() async {
    if (_csvLink == null) {
      _homeCheck = HomeCheck.idle;
      notifyListeners();
      return;
    }
    _homeCheck = HomeCheck.checking;
    notifyListeners();
    try {
      final content = await _csvSource.fetch(_csvLink!);
      final rows = _parser.parse(content);
      final validation = _validator.validate(rows);
      final memoryIds = {for (final c in _cards) c.id};
      final toIntegrate = validation.validCards
          .where((c) => !memoryIds.contains(c.id))
          .length;
      _sheetValidCountLive = validation.validCards.length;
      _toIntegrateLive = toIntegrate;
      _homeCheck = HomeCheck.done;
    } catch (_) {
      _homeCheck = HomeCheck.offline;
    }
    notifyListeners();
  }
}

/// État de la vérification Accueil ↔ Sheet.
enum HomeCheck { idle, checking, done, offline }

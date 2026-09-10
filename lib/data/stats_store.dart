import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

/// D4 — Stockage local des statistiques (par carte, par sens).
///
/// Forme mémorisée : { idCarte: { 'FR_EN': {attempts,knew}, 'EN_FR': {...} } }.
/// Survit à la fermeture de l'application (jeu hors-ligne).
///
/// La clé de stockage est paramétrable pour permettre deux jeux de stats
/// indépendants (saisie sous 'stats', QCM sous 'stats_qcm') avec le même code.
class StatsStore {
  final String _key;
  final SharedPreferences _prefs;

  StatsStore(this._prefs, {String key = 'stats'}) : _key = key;

  Map<String, Map<Direction, DirectionStat>> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final result = <String, Map<Direction, DirectionStat>>{};
    decoded.forEach((cardId, byDir) {
      final dirMap = <Direction, DirectionStat>{};
      (byDir as Map<String, dynamic>).forEach((code, stat) {
        dirMap[DirectionInfo.fromCode(code)] =
            DirectionStat.fromJson(stat as Map<String, dynamic>);
      });
      result[cardId] = dirMap;
    });
    return result;
  }

  Future<void> save(Map<String, Map<Direction, DirectionStat>> stats) async {
    final encodable = <String, dynamic>{};
    stats.forEach((cardId, byDir) {
      final dirMap = <String, dynamic>{};
      byDir.forEach((dir, stat) => dirMap[dir.code] = stat.toJson());
      encodable[cardId] = dirMap;
    });
    await _prefs.setString(_key, jsonEncode(encodable));
  }
}

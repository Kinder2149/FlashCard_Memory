import 'package:shared_preferences/shared_preferences.dart';

/// D7 — Stockage du réglage « langue mère » (V2, chantier B).
///
/// Réglage unique de l'app (pas par carte) : on suppose un seul apprenant,
/// donc une seule langue mère pour toutes les paires.
class SettingsStore {
  static const _key = 'mother_lang';
  static const defaultLang = 'FR';
  final SharedPreferences _prefs;

  SettingsStore(this._prefs);

  String load() => _prefs.getString(_key) ?? defaultLang;

  Future<void> save(String code) => _prefs.setString(_key, code.toUpperCase());
}

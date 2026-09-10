import 'package:shared_preferences/shared_preferences.dart';

/// D5 — Stockage du lien CSV.
///
/// Mémorise le lien de publication CSV après le premier import, pour que
/// « mettre à jour » le ré-utilise sans que l'utilisateur le recolle.
class LinkStore {
  static const _key = 'csv_link';
  final SharedPreferences _prefs;

  LinkStore(this._prefs);

  String? load() {
    final v = _prefs.getString(_key);
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> save(String link) async {
    await _prefs.setString(_key, link.trim());
  }
}

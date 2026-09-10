import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

/// D3 — Stockage local des cartes.
///
/// Persiste la liste des flashcards intégrées, sous forme de JSON dans le
/// stockage local de l'appareil. Survit à la fermeture de l'application.
class CardsStore {
  static const _key = 'cards';
  final SharedPreferences _prefs;

  CardsStore(this._prefs);

  List<Flashcard> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<Flashcard> cards) async {
    final raw = jsonEncode(cards.map((c) => c.toJson()).toList());
    await _prefs.setString(_key, raw);
  }
}

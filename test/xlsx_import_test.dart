import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:flashcard_memory/data/local_file_source.dart';
import 'package:flashcard_memory/logic/validation.dart';

/// Vérifie la lecture d'un vrai fichier Excel (D6) sur les données de test,
/// puis le passage dans le validateur commun (L2).
void main() {
  test('lit Flashcard_V1.xlsx et retrouve 57 cartes valides', () {
    final bytes = File('Flashcard_V1.xlsx').readAsBytesSync();
    final rows = LocalFileSource().readRows(bytes);

    final result = Validator().validate(rows);

    expect(result.validCards.length, 57);
    expect(result.incompleteIds, isEmpty);
    // Un mot français avec virgule doit rester intact.
    final en1 = result.validCards.firstWhere((c) => c.id == 'EN-1');
    expect(en1.motherWord, 'dégingandé, grand et mince');
    expect(en1.theme, contains('Corps'));
  });
}

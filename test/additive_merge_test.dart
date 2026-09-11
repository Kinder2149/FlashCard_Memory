import 'package:flutter_test/flutter_test.dart';

import 'package:flashcard_memory/models.dart';
import 'package:flashcard_memory/logic/additive_merge.dart';

void main() {
  final merge = AdditiveMerge();

  Flashcard card(String id, String mother, String foreign, {String theme = ''}) =>
      Flashcard(
          id: id, motherWord: mother, foreignWord: foreign, foreignLang: 'EN', theme: theme);

  group('AdditiveMerge (V2 A5)', () {
    test('deux fichiers différents réutilisant les mêmes ID : rien n\'est perdu', () {
      // Bug rapporté : importer un 2e fichier (ID recommençant à EN-1)
      // effaçait les cartes du 1er fichier.
      final afterFile1 = merge.merge(
        memory: [],
        importedValidCards: [card('EN-1', 'chat', 'cat'), card('EN-2', 'chien', 'dog')],
      );
      expect(afterFile1.added, 2);

      final afterFile2 = merge.merge(
        memory: afterFile1.cards,
        importedValidCards: [card('EN-1', 'maison', 'house')], // même ID, mot différent
      );
      expect(afterFile2.added, 1, reason: 'contenu nouveau → ajouté, jamais écrasé');
      expect(afterFile2.cards.length, 3,
          reason: 'les cartes du 1er fichier doivent survivre');
      expect(afterFile2.cards.map((c) => c.motherWord).toSet(),
          {'chat', 'chien', 'maison'});
    });

    test('même contenu réimporté deux fois : ignoré, pas dupliqué', () {
      final memory = merge.merge(
        memory: [],
        importedValidCards: [card('EN-1', 'chat', 'cat')],
      ).cards;

      final out = merge.merge(
        memory: memory,
        importedValidCards: [card('EN-99', 'Chat', 'CAT')], // casse différente
      );
      expect(out.added, 0);
      expect(out.skipped, 1);
      expect(out.cards.length, 1);
    });

    test('les nouvelles cartes reçoivent un ID IMP-n, jamais celui du fichier', () {
      final out = merge.merge(
        memory: [],
        importedValidCards: [card('EN-1', 'chat', 'cat')],
      );
      expect(out.cards.single.id, 'IMP-1');
    });
  });
}

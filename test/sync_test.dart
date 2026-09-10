import 'package:flutter_test/flutter_test.dart';

import 'package:flashcard_memory/models.dart';
import 'package:flashcard_memory/data/csv_parser.dart';
import 'package:flashcard_memory/logic/validation.dart';
import 'package:flashcard_memory/logic/sync_engine.dart';

void main() {
  final parser = CsvParser();
  final validator = Validator();
  final engine = SyncEngine();

  group('Parsing CSV', () {
    test('gère les virgules dans un champ entre guillemets', () {
      final rows = parser.parse(
        'ID,Français,Anglais,Thème\n'
        'EN-1,"dégingandé, grand et mince",lanky,"👤 Corps & Apparence"\n',
      );
      expect(rows.length, 1);
      expect(rows.first.motherWord, 'dégingandé, grand et mince');
      expect(rows.first.foreignWord, 'lanky');
      expect(rows.first.theme, '👤 Corps & Apparence');
      expect(rows.first.foreignLang, 'EN',
          reason: 'colonne Langue absente → EN par défaut (V1 rétro-compat)');
    });

    test('ignore l\'en-tête et les lignes vides pré-remplies', () {
      final rows = parser.parse(
        'ID,Français,Anglais,Thème\n'
        'EN-1,chien,dog,Animaux\n'
        'EN-2,,,\n'
        'EN-3,,,\n',
      );
      // Les lignes vides passent le parser (ID présent) mais seront écartées
      // par la validation.
      expect(rows.length, 3);
    });

    test('V2 : lit la colonne Langue quand elle est présente', () {
      final rows = parser.parse(
        'ID,Français,Anglais,Thème,Langue\n'
        'ES-1,perro,chien,Animaux,ES\n',
      );
      expect(rows.single.foreignLang, 'ES');
    });
  });

  group('Validation', () {
    test('ligne complète = carte valide ; thème vide autorisé', () {
      final r = validator.validate([
        const RawRow(
            id: 'EN-1', motherWord: 'chat', foreignWord: 'cat', foreignLang: 'EN', theme: ''),
      ]);
      expect(r.validCards.length, 1);
      expect(r.incompleteIds, isEmpty);
    });

    test('ligne avec un seul mot = incomplète', () {
      final r = validator.validate([
        const RawRow(id: 'EN-1', motherWord: 'chat', foreignWord: '', foreignLang: 'EN', theme: 'Animaux'),
        const RawRow(id: 'EN-2', motherWord: '', foreignWord: 'dog', foreignLang: 'EN', theme: ''),
      ]);
      expect(r.validCards, isEmpty);
      expect(r.incompleteIds, ['EN-1', 'EN-2']);
    });

    test('ligne totalement vide = ignorée (ni valide ni incomplète)', () {
      final r = validator.validate([
        const RawRow(id: 'EN-9', motherWord: '', foreignWord: '', foreignLang: 'EN', theme: ''),
      ]);
      expect(r.validCards, isEmpty);
      expect(r.incompleteIds, isEmpty);
    });

    test('même correspondance sous deux ID = doublon signalé', () {
      final r = validator.validate([
        const RawRow(id: 'EN-1', motherWord: 'chat', foreignWord: 'cat', foreignLang: 'EN', theme: ''),
        const RawRow(id: 'EN-5', motherWord: 'Chat', foreignWord: 'CAT', foreignLang: 'EN', theme: 'Animaux'),
      ]);
      expect(r.validCards.length, 2, reason: 'les deux cartes restent');
      expect(r.duplicateIds, ['EN-1', 'EN-5']);
    });

    test('même mots mais langue étrangère différente = pas un doublon', () {
      final r = validator.validate([
        const RawRow(id: 'EN-1', motherWord: 'chat', foreignWord: 'cat', foreignLang: 'EN', theme: ''),
        const RawRow(id: 'ES-1', motherWord: 'chat', foreignWord: 'cat', foreignLang: 'ES', theme: ''),
      ]);
      expect(r.duplicateIds, isEmpty);
    });
  });

  group('Synchronisation (table de la spec)', () {
    List<Flashcard> sheet(List<List<String>> rows) => rows
        .map((r) => Flashcard(
            id: r[0], motherWord: r[1], foreignWord: r[2], foreignLang: 'EN', theme: r[3]))
        .toList();

    test('ID nouveau → ajouté', () {
      final out = engine.synchronize(
        memory: [],
        stats: {},
        validSheetCards: sheet([
          ['EN-1', 'chat', 'cat', ''],
        ]),
      );
      expect(out.added, 1);
      expect(out.cards.single.id, 'EN-1');
    });

    test('contenu identique → inchangé, stats gardées', () {
      final existing = [
        const Flashcard(id: 'EN-1', motherWord: 'chat', foreignWord: 'cat', foreignLang: 'EN', theme: ''),
      ];
      final stats = {
        'EN-1': {Direction.motherToForeign: DirectionStat(attempts: 3, knew: 2)},
      };
      final out = engine.synchronize(
        memory: existing,
        stats: stats,
        validSheetCards: sheet([
          ['EN-1', 'chat', 'cat', ''],
        ]),
      );
      expect(out.unchanged, 1);
      expect(out.stats['EN-1']![Direction.motherToForeign]!.attempts, 3);
    });

    test('texte différent → mis à jour, stats conservées (correction)', () {
      final existing = [
        const Flashcard(id: 'EN-1', motherWord: 'chatt', foreignWord: 'cat', foreignLang: 'EN', theme: ''),
      ];
      final stats = {
        'EN-1': {Direction.motherToForeign: DirectionStat(attempts: 5, knew: 5)},
      };
      final out = engine.synchronize(
        memory: existing,
        stats: stats,
        validSheetCards: sheet([
          ['EN-1', 'chat', 'cat', ''], // faute corrigée
        ]),
      );
      expect(out.updated, 1);
      expect(out.cards.single.motherWord, 'chat');
      expect(out.stats['EN-1']![Direction.motherToForeign]!.attempts, 5,
          reason: 'les stats survivent à la correction');
    });

    test('ID disparu du Sheet → supprimé avec ses stats', () {
      final existing = [
        const Flashcard(id: 'EN-1', motherWord: 'chat', foreignWord: 'cat', foreignLang: 'EN', theme: ''),
        const Flashcard(id: 'EN-2', motherWord: 'chien', foreignWord: 'dog', foreignLang: 'EN', theme: ''),
      ];
      final stats = {
        'EN-2': {Direction.motherToForeign: DirectionStat(attempts: 4, knew: 1)},
      };
      final out = engine.synchronize(
        memory: existing,
        stats: stats,
        validSheetCards: sheet([
          ['EN-1', 'chat', 'cat', ''],
        ]),
      );
      expect(out.deleted, 1);
      expect(out.cards.map((c) => c.id), ['EN-1']);
      expect(out.stats.containsKey('EN-2'), isFalse);
    });

    test(
        'V2 A4 : carte créée manuellement (APP-n) jamais supprimée par un import',
        () {
      final existing = [
        const Flashcard(id: 'EN-1', motherWord: 'chat', foreignWord: 'cat', foreignLang: 'EN', theme: ''),
        const Flashcard(id: 'APP-1', motherWord: 'ordinateur', foreignWord: 'computer', foreignLang: 'EN', theme: ''),
      ];
      final stats = {
        'APP-1': {Direction.motherToForeign: DirectionStat(attempts: 2, knew: 1)},
      };
      final out = engine.synchronize(
        memory: existing,
        stats: stats,
        validSheetCards: sheet([
          ['EN-1', 'chat', 'cat', ''],
        ]),
      );
      expect(out.deleted, 0, reason: 'la carte manuelle ne compte pas comme supprimée');
      expect(out.cards.map((c) => c.id), containsAll(['EN-1', 'APP-1']));
      expect(out.stats['APP-1']![Direction.motherToForeign]!.attempts, 2,
          reason: 'ses stats survivent aussi');
    });
  });
}

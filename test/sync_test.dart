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
      expect(rows.first.fr, 'dégingandé, grand et mince');
      expect(rows.first.en, 'lanky');
      expect(rows.first.theme, '👤 Corps & Apparence');
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
  });

  group('Validation', () {
    test('ligne complète = carte valide ; thème vide autorisé', () {
      final r = validator.validate([
        const RawRow(id: 'EN-1', fr: 'chat', en: 'cat', theme: ''),
      ]);
      expect(r.validCards.length, 1);
      expect(r.incompleteIds, isEmpty);
    });

    test('ligne avec un seul mot = incomplète', () {
      final r = validator.validate([
        const RawRow(id: 'EN-1', fr: 'chat', en: '', theme: 'Animaux'),
        const RawRow(id: 'EN-2', fr: '', en: 'dog', theme: ''),
      ]);
      expect(r.validCards, isEmpty);
      expect(r.incompleteIds, ['EN-1', 'EN-2']);
    });

    test('ligne totalement vide = ignorée (ni valide ni incomplète)', () {
      final r = validator.validate([
        const RawRow(id: 'EN-9', fr: '', en: '', theme: ''),
      ]);
      expect(r.validCards, isEmpty);
      expect(r.incompleteIds, isEmpty);
    });

    test('même correspondance sous deux ID = doublon signalé', () {
      final r = validator.validate([
        const RawRow(id: 'EN-1', fr: 'chat', en: 'cat', theme: ''),
        const RawRow(id: 'EN-5', fr: 'Chat', en: 'CAT', theme: 'Animaux'),
      ]);
      expect(r.validCards.length, 2, reason: 'les deux cartes restent');
      expect(r.duplicateIds, ['EN-1', 'EN-5']);
    });
  });

  group('Synchronisation (table de la spec)', () {
    List<Flashcard> sheet(List<List<String>> rows) => rows
        .map((r) => Flashcard(id: r[0], fr: r[1], en: r[2], theme: r[3]))
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
        const Flashcard(id: 'EN-1', fr: 'chat', en: 'cat', theme: ''),
      ];
      final stats = {
        'EN-1': {Direction.frToEn: DirectionStat(attempts: 3, knew: 2)},
      };
      final out = engine.synchronize(
        memory: existing,
        stats: stats,
        validSheetCards: sheet([
          ['EN-1', 'chat', 'cat', ''],
        ]),
      );
      expect(out.unchanged, 1);
      expect(out.stats['EN-1']![Direction.frToEn]!.attempts, 3);
    });

    test('texte différent → mis à jour, stats conservées (correction)', () {
      final existing = [
        const Flashcard(id: 'EN-1', fr: 'chatt', en: 'cat', theme: ''),
      ];
      final stats = {
        'EN-1': {Direction.frToEn: DirectionStat(attempts: 5, knew: 5)},
      };
      final out = engine.synchronize(
        memory: existing,
        stats: stats,
        validSheetCards: sheet([
          ['EN-1', 'chat', 'cat', ''], // faute corrigée
        ]),
      );
      expect(out.updated, 1);
      expect(out.cards.single.fr, 'chat');
      expect(out.stats['EN-1']![Direction.frToEn]!.attempts, 5,
          reason: 'les stats survivent à la correction');
    });

    test('ID disparu du Sheet → supprimé avec ses stats', () {
      final existing = [
        const Flashcard(id: 'EN-1', fr: 'chat', en: 'cat', theme: ''),
        const Flashcard(id: 'EN-2', fr: 'chien', en: 'dog', theme: ''),
      ];
      final stats = {
        'EN-2': {Direction.frToEn: DirectionStat(attempts: 4, knew: 1)},
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
  });
}

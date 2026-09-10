import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

import 'package:flashcard_memory/models.dart';
import 'package:flashcard_memory/logic/session_builder.dart';
import 'package:flashcard_memory/logic/session_runner.dart';
import 'package:flashcard_memory/logic/stats_calculator.dart';

void main() {
  final cards = [
    const Flashcard(id: 'EN-1', fr: 'chat', en: 'cat', theme: 'Animaux'),
    const Flashcard(id: 'EN-2', fr: 'chien', en: 'dog', theme: 'Animaux'),
    const Flashcard(id: 'EN-3', fr: 'maison', en: 'house', theme: 'Objets'),
  ];

  group('Constitution de session (L3)', () {
    test('filtre par thème', () {
      final pool = SessionBuilder()
          .build(cards: cards, theme: 'Animaux', rng: Random(1));
      expect(pool.length, 2);
      expect(pool.every((c) => c.theme == 'Animaux'), isTrue);
    });

    test('« tout » prend toutes les cartes, une seule fois', () {
      final pool =
          SessionBuilder().build(cards: cards, theme: null, rng: Random(1));
      expect(pool.length, 3);
      expect(pool.map((c) => c.id).toSet().length, 3);
    });
  });

  group('Déroulé et score (L4)', () {
    test('score = bonnes / cartes jouées, clôture anticipée', () {
      final session = GameSession(
        direction: Direction.frToEn,
        pool: cards,
      );
      expect(session.prompt(cards[0]), 'chat'); // FR affiché
      expect(session.answer(cards[0]), 'cat'); // EN attendu

      session.answerCurrent(true); // EN-1 su
      session.answerCurrent(false); // EN-2 pas su
      session.close(); // on arrête avant EN-3

      expect(session.isFinished, isTrue);
      expect(session.playedCount, 2);
      expect(session.correctCount, 1);
    });

    test('sens Anglais → Français inverse invite et réponse', () {
      final session = GameSession(direction: Direction.enToFr, pool: cards);
      expect(session.prompt(cards[0]), 'cat');
      expect(session.answer(cards[0]), 'chat');
    });
  });

  group('Statistiques cumulatives (L5)', () {
    test('taux cumulatif par carte et par sens', () {
      final calc = StatsCalculator();
      final stats = <String, Map<Direction, DirectionStat>>{};

      calc.registerAttempt(stats, 'EN-1', Direction.frToEn, true);
      calc.registerAttempt(stats, 'EN-1', Direction.frToEn, false);
      calc.registerAttempt(stats, 'EN-1', Direction.enToFr, true);

      expect(calc.rateOf(stats, 'EN-1', Direction.frToEn), 0.5);
      expect(calc.rateOf(stats, 'EN-1', Direction.enToFr), 1.0);
      expect(calc.rateOf(stats, 'EN-2', Direction.frToEn), isNull);
    });
  });
}

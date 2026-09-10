import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

import 'package:flashcard_memory/models.dart';
import 'package:flashcard_memory/logic/qcm_builder.dart';
import 'package:flashcard_memory/logic/stats_calculator.dart';

void main() {
  // 6 cartes réparties sur 2 thèmes ; cibles EN distinctes.
  const cards = [
    Flashcard(id: 'EN-1', fr: 'chat', en: 'cat', theme: 'Animaux'),
    Flashcard(id: 'EN-2', fr: 'chien', en: 'dog', theme: 'Animaux'),
    Flashcard(id: 'EN-3', fr: 'cheval', en: 'horse', theme: 'Animaux'),
    Flashcard(id: 'EN-4', fr: 'oiseau', en: 'bird', theme: 'Animaux'),
    Flashcard(id: 'EN-5', fr: 'maison', en: 'house', theme: 'Objets'),
    Flashcard(id: 'EN-6', fr: 'table', en: 'table', theme: 'Objets'),
  ];

  final builder = QcmBuilder();

  group('Disponibilité (L)', () {
    test('paire riche → QCM disponible dans les deux sens', () {
      expect(builder.isAvailable(cards, Direction.frToEn), isTrue);
      expect(builder.isAvailable(cards, Direction.enToFr), isTrue);
    });

    test('moins de 4 mots cibles distincts → indisponible', () {
      const few = [
        Flashcard(id: 'EN-1', fr: 'chat', en: 'cat', theme: 'A'),
        Flashcard(id: 'EN-2', fr: 'chien', en: 'dog', theme: 'A'),
        Flashcard(id: 'EN-3', fr: 'cheval', en: 'horse', theme: 'A'),
      ];
      expect(builder.isAvailable(few, Direction.frToEn), isFalse);
    });

    test('doublons de texte cible ne comptent qu\'une fois', () {
      const dup = [
        Flashcard(id: 'EN-1', fr: 'canapé', en: 'sofa', theme: 'A'),
        Flashcard(id: 'EN-2', fr: 'sofa', en: 'sofa', theme: 'A'), // même EN
        Flashcard(id: 'EN-3', fr: 'chaise', en: 'chair', theme: 'A'),
        Flashcard(id: 'EN-4', fr: 'lit', en: 'bed', theme: 'A'),
      ];
      // 3 cibles EN distinctes (sofa, chair, bed) → indisponible.
      expect(builder.isAvailable(dup, Direction.frToEn), isFalse);
    });
  });

  group('Construction des options (L)', () {
    test('toujours 4 options, bonne réponse présente et bien pointée', () {
      for (var seed = 0; seed < 20; seed++) {
        final o = builder.build(
          card: cards[0], // chat → cat
          cards: cards,
          direction: Direction.frToEn,
          rng: Random(seed),
        );
        expect(o.options.length, 4);
        expect(o.options.contains('cat'), isTrue);
        expect(o.correct, 'cat');
        expect(o.options[o.correctIndex], 'cat');
      }
    });

    test('jamais deux options identiques', () {
      for (var seed = 0; seed < 20; seed++) {
        final o = builder.build(
          card: cards[0],
          cards: cards,
          direction: Direction.frToEn,
          rng: Random(seed),
        );
        expect(o.options.toSet().length, o.options.length);
      }
    });

    test('la position de la bonne réponse varie selon le tirage', () {
      final positions = <int>{};
      for (var seed = 0; seed < 20; seed++) {
        final o = builder.build(
          card: cards[0],
          cards: cards,
          direction: Direction.frToEn,
          rng: Random(seed),
        );
        positions.add(o.correctIndex);
      }
      // Pas figée à une seule position.
      expect(positions.length, greaterThan(1));
    });

    test('thème pauvre → distracteurs puisés dans toute la paire', () {
      // « maison » est seule utile dans « Objets » (table = distracteur mais
      // 1 seul) : les distracteurs doivent venir d'« Animaux ».
      const sparse = [
        Flashcard(id: 'EN-5', fr: 'maison', en: 'house', theme: 'Objets'),
        Flashcard(id: 'EN-1', fr: 'chat', en: 'cat', theme: 'Animaux'),
        Flashcard(id: 'EN-2', fr: 'chien', en: 'dog', theme: 'Animaux'),
        Flashcard(id: 'EN-3', fr: 'cheval', en: 'horse', theme: 'Animaux'),
      ];
      final o = builder.build(
        card: sparse[0], // house, thème Objets (seul)
        cards: sparse,
        direction: Direction.frToEn,
        rng: Random(1),
      );
      expect(o.options.length, 4);
      expect(o.correct, 'house');
      final distractors = o.options.where((t) => t != 'house').toSet();
      expect(distractors, {'cat', 'dog', 'horse'});
    });

    test('sens EN → FR : la cible est le français', () {
      final o = builder.build(
        card: cards[0], // cat → chat
        cards: cards,
        direction: Direction.enToFr,
        rng: Random(3),
      );
      expect(o.correct, 'chat');
      expect(o.options.every((t) => cards.any((c) => c.fr == t)), isTrue);
    });
  });

  group('Statistiques QCM séparées (L)', () {
    test('les stats QCM et saisie sont comptabilisées indépendamment', () {
      final calc = StatsCalculator();
      // Deux maps distinctes = deux jeux de stats (comme dans AppState).
      final typing = <String, Map<Direction, DirectionStat>>{};
      final qcm = <String, Map<Direction, DirectionStat>>{};

      // Même carte, même sens : QCM tout bon, saisie tout faux.
      calc.registerAttempt(qcm, 'EN-1', Direction.frToEn, true);
      calc.registerAttempt(qcm, 'EN-1', Direction.frToEn, true);
      calc.registerAttempt(typing, 'EN-1', Direction.frToEn, false);

      expect(calc.rateOf(qcm, 'EN-1', Direction.frToEn), 1.0);
      expect(calc.rateOf(typing, 'EN-1', Direction.frToEn), 0.0);
      // Aucun croisement entre les deux modes.
      expect(calc.rateOf(qcm, 'EN-1', Direction.enToFr), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flashcard_memory/data/csv_source.dart';

/// Vérifie la transformation d'un lien collé en adresse de données (D1).
void main() {
  group('buildDataUrl', () {
    test('lien Google Sheet normal → adresse CSV ciblant l\'onglet EN', () {
      final out = CsvSource.buildDataUrl(
          'https://docs.google.com/spreadsheets/d/ABC123_xyz/edit?usp=sharing');
      expect(out,
          'https://docs.google.com/spreadsheets/d/ABC123_xyz/gviz/tq?tqx=out:csv&sheet=EN');
    });

    test('fonctionne aussi pour un Excel déposé (paramètres rtpof/ouid)', () {
      final out = CsvSource.buildDataUrl(
          'https://docs.google.com/spreadsheets/d/1m1by8Yr/edit?usp=sharing&ouid=101&rtpof=true&sd=true');
      expect(out,
          'https://docs.google.com/spreadsheets/d/1m1by8Yr/gviz/tq?tqx=out:csv&sheet=EN');
    });

    test('ancien lien de publication CSV → inchangé (rétro-compatibilité)', () {
      const pub =
          'https://docs.google.com/spreadsheets/d/e/2PACX/pub?output=csv';
      expect(CsvSource.buildDataUrl(pub), pub);
    });

    test('URL de données directe (.csv) → inchangée', () {
      const local = 'http://10.0.2.2:8000/Flashcard_V1.csv';
      expect(CsvSource.buildDataUrl(local), local);
    });
  });
}

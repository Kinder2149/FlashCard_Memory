import 'dart:typed_data';
import 'package:excel/excel.dart';

import '../models.dart';
import 'csv_source.dart' show CsvSourceException;

/// D6 — Lecture d'un fichier Excel (.xlsx) local de l'appareil.
///
/// Source de données alternative au lien CSV : lit le contenu d'un fichier
/// choisi par l'utilisateur et le rend sous la même forme de « lignes brutes »
/// (RawRow) que le parsing CSV. Toute la suite (validation, synchronisation,
/// rapport) est donc partagée : le comportement est strictement identique.
///
/// Colonnes attendues par position, comme le template : A=ID, B=mot langue
/// mère, C=mot langue étrangère, D=Thème, E=Langue (V2, code ISO ; absente ou
/// vide → 'EN' par défaut). Onglet `EN` (ou premier onglet à défaut).
class LocalFileSource {
  List<RawRow> readRows(Uint8List bytes) {
    final Excel workbook;
    try {
      workbook = Excel.decodeBytes(bytes);
    } catch (_) {
      throw const CsvSourceException(
          'Ce fichier n\'a pas pu être lu comme un fichier Excel (.xlsx). '
          'Vérifie que c\'est bien le modèle rempli.');
    }

    final sheet = workbook.tables['EN'] ??
        (workbook.tables.isNotEmpty ? workbook.tables.values.first : null);
    if (sheet == null) {
      throw const CsvSourceException('Le fichier Excel ne contient aucun onglet.');
    }

    final rows = <RawRow>[];
    var isFirst = true;
    for (final cells in sheet.rows) {
      String cell(int i) =>
          (i < cells.length ? cells[i]?.value?.toString() : '')?.trim() ?? '';

      final id = cell(0);

      // Ignorer la ligne d'en-tête (« ID, Français, … »).
      if (isFirst) {
        isFirst = false;
        if (id.toLowerCase() == 'id') continue;
      }

      if (id.isEmpty) continue; // ligne sans identifiant : ignorée

      final lang = cell(4);
      rows.add(RawRow(
        id: id,
        motherWord: cell(1),
        foreignWord: cell(2),
        foreignLang: lang.isEmpty ? 'EN' : lang,
        theme: cell(3),
      ));
    }
    return rows;
  }
}

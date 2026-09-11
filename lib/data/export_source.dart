import 'dart:typed_data';
import 'package:excel/excel.dart';

import '../models.dart';

/// D8 — Génère un fichier Excel (.xlsx) à partir de la base de cartes
/// actuelle de l'app (V2 A3/A5).
///
/// Distinct du modèle vierge téléchargeable (assets/Flashcard_modele.xlsx) :
/// celui-ci reflète l'état réel de la « base mère » qui vit dans l'app — une
/// vraie sauvegarde de toutes les paires, quelle que soit leur origine
/// (import Sheet, fichier, ou ajout manuel).
class ExportSource {
  Uint8List buildXlsx(List<Flashcard> cards) {
    final workbook = Excel.createExcel();
    final sheetName = workbook.getDefaultSheet()!;
    final sheet = workbook[sheetName];

    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Mot langue mère'),
      TextCellValue('Mot langue étrangère'),
      TextCellValue('Thème'),
      TextCellValue('Langue'),
    ]);
    for (final c in cards) {
      sheet.appendRow([
        TextCellValue(c.id),
        TextCellValue(c.motherWord),
        TextCellValue(c.foreignWord),
        TextCellValue(c.theme),
        TextCellValue(c.foreignLang),
      ]);
    }

    return Uint8List.fromList(workbook.encode()!);
  }
}

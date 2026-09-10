import '../models.dart';

/// D2 — Parsing du CSV en lignes structurées (ID, mot FR, mot EN, thème).
///
/// Analyseur robuste : gère les champs entre guillemets (ex. un mot français
/// contenant une virgule « dégingandé, grand et mince »), les guillemets
/// échappés ("" à l'intérieur d'un champ), et les fins de ligne CRLF/LF.
///
/// Colonnes attendues par position, selon le template : A=ID, B=Français,
/// C=Anglais, D=Thème. La ligne d'en-tête (« ID,Français,… ») est ignorée.
class CsvParser {
  List<RawRow> parse(String content) {
    final table = _toTable(content);
    if (table.isEmpty) return [];

    final rows = <RawRow>[];
    var startIndex = 0;

    // Ignorer la ligne d'en-tête si la première cellule vaut « ID ».
    final first = table.first;
    if (first.isNotEmpty && first.first.trim().toLowerCase() == 'id') {
      startIndex = 1;
    }

    for (var i = startIndex; i < table.length; i++) {
      final cols = table[i];
      String cell(int index) =>
          index < cols.length ? cols[index].trim() : '';

      final id = cell(0);
      if (id.isEmpty) continue; // ligne sans identifiant : ignorée

      rows.add(RawRow(
        id: id,
        fr: cell(1),
        en: cell(2),
        theme: cell(3),
      ));
    }
    return rows;
  }

  /// Transforme le texte CSV en tableau de lignes de cellules.
  List<List<String>> _toTable(String content) {
    // Retirer un éventuel BOM en tête de fichier.
    var text = content;
    if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
      text = text.substring(1);
    }

    final table = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];

      if (inQuotes) {
        if (ch == '"') {
          // Guillemet doublé « "" » = un vrai guillemet dans le champ.
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
        continue;
      }

      switch (ch) {
        case '"':
          inQuotes = true;
          break;
        case ',':
          row.add(field.toString());
          field.clear();
          break;
        case '\r':
          // Fin de ligne CRLF : le \n suivant sera géré par la clôture ci-dessous.
          break;
        case '\n':
          row.add(field.toString());
          field.clear();
          table.add(row);
          row = <String>[];
          break;
        default:
          field.write(ch);
      }
    }

    // Dernière ligne sans saut final.
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      table.add(row);
    }

    // Retirer les lignes totalement vides.
    return table
        .where((r) => r.any((c) => c.trim().isNotEmpty))
        .toList();
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

/// D1 — Récupération des données depuis un lien Google Sheet.
///
/// À partir du lien collé par l'utilisateur, construit tout seul l'adresse qui
/// renvoie les données (voir [buildDataUrl]), les télécharge, et rend le texte
/// en UTF-8 (pour préserver accents et emojis). Ne parse pas : texte brut.
class CsvSource {
  Future<String> fetch(String pastedLink) async {
    final url = buildDataUrl(pastedLink);

    final Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      throw const CsvSourceException('Le lien collé n\'est pas une adresse valide.');
    }
    if (!uri.hasScheme || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw const CsvSourceException('Le lien doit commencer par http:// ou https://.');
    }

    http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const CsvSourceException(
          'Impossible de contacter le lien (pas de connexion ou lien inaccessible).');
    }

    if (response.statusCode != 200) {
      throw const CsvSourceException(
          'Ce Google Sheet n\'est pas accessible. Ouvre-le, clique « Partager », '
          'choisis « Tous les utilisateurs disposant du lien » (Lecteur), puis '
          'réessaie.');
    }

    final body = utf8.decode(response.bodyBytes, allowMalformed: true);

    // Un Sheet non partagé renvoie une page de connexion Google (du HTML), pas
    // des données. On le détecte pour donner un message clair.
    final contentType = response.headers['content-type'] ?? '';
    final head = body.trimLeft();
    final looksLikeHtml = contentType.contains('text/html') ||
        head.startsWith('<!DOCTYPE') ||
        head.startsWith('<html');
    if (looksLikeHtml) {
      throw const CsvSourceException(
          'Ce Google Sheet n\'est pas partagé publiquement. Ouvre-le, clique '
          '« Partager », choisis « Tous les utilisateurs disposant du lien » '
          '(Lecteur), puis réessaie.');
    }

    return body;
  }

  /// Nom fixe de l'onglet à lire (imposé par le template).
  static const _sheetTab = 'EN';

  /// Transforme le lien collé en adresse de données téléchargeable.
  ///
  /// - Lien Google Sheet normal (« /spreadsheets/d/ID… ») → adresse qui renvoie
  ///   l'onglet `EN` en CSV, ciblé par son nom. Fonctionne aussi bien pour un
  ///   vrai Google Sheet que pour un fichier Excel déposé sur Drive.
  /// - Lien déjà direct (ancienne publication CSV, export, ou fichier .csv) →
  ///   utilisé tel quel.
  static String buildDataUrl(String pastedLink) {
    final url = pastedLink.trim();
    final lower = url.toLowerCase();

    // Lien de données déjà direct : on ne touche pas (rétro-compatibilité).
    if (lower.contains('output=csv') ||
        lower.contains('format=csv') ||
        lower.contains('tqx=out:csv') ||
        lower.endsWith('.csv')) {
      return url;
    }

    // Lien Google Sheet standard → adresse renvoyant l'onglet EN en CSV.
    final idMatch =
        RegExp(r'/spreadsheets/d/([a-zA-Z0-9\-_]+)').firstMatch(url);
    if (idMatch != null) {
      final id = idMatch.group(1)!;
      return 'https://docs.google.com/spreadsheets/d/$id/gviz/tq'
          '?tqx=out:csv&sheet=$_sheetTab';
    }

    // Autre chose (URL de données directe, serveur local de test…) : tel quel.
    return url;
  }
}

class CsvSourceException implements Exception {
  final String message;
  const CsvSourceException(this.message);
  @override
  String toString() => message;
}

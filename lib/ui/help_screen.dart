import 'package:flutter/material.dart';

/// U7 — Comment ça marche ?
///
/// Page d'aide : explique le principe de l'application, l'import, le jeu,
/// l'auto-évaluation (« je savais / je savais pas »), le calcul des
/// statistiques et l'état de la V1. Contient, tout en bas, un bouton caché
/// (easter egg).
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comment ça marche ?')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          children: [
            _Section(
              icon: Icons.lightbulb_outline,
              title: 'Le principe',
              paragraphs: [
                'Flashcard vous aide à réviser du vocabulaire dans une ou '
                    'plusieurs langues étrangères, sous forme de cartes.',
                'C’est vous qui écrivez vos mots et leurs traductions, dans un '
                    'Google Sheet ou dans le modèle Excel fourni. L’application '
                    'lit cette liste et fabrique une carte par correspondance.',
                'L’application ne modifie jamais votre liste : elle la lit, puis '
                    'garde les cartes et vos statistiques sur le téléphone. Une '
                    'fois vos cartes importées, tout fonctionne sans connexion.',
              ],
            ),
            _Section(
              icon: Icons.sync,
              title: 'Importer et mettre à jour ses cartes',
              paragraphs: [
                'Deux façons d’importer, au choix :',
                '• Un fichier Excel (.xlsx) : téléchargez le modèle, remplissez-le '
                    'dans Sheets ou Excel, puis importez-le depuis l’appareil.',
                '• Un lien Google Sheet : réglez le partage de votre Sheet sur '
                    '« Tous les utilisateurs disposant du lien » (Lecteur), collez '
                    'le lien une fois, il est mémorisé, ensuite « Mettre à jour » '
                    'le relit tout seul.',
                'À chaque import, l’application se cale exactement sur votre liste '
                    'et vous montre un rapport : cartes ajoutées, mises à jour, '
                    'supprimées, lignes incomplètes ignorées et doublons repérés.',
                'Corriger une faute dans une carte ne fait pas perdre ses '
                    'statistiques : c’est l’identifiant de la ligne (par ex. EN-42) '
                    'qui fait le lien, pas le texte. Supprimez une ligne de votre '
                    'liste et la carte disparaît de la mémoire au prochain import.',
              ],
            ),
            _Section(
              icon: Icons.play_arrow,
              title: 'Jouer une session',
              paragraphs: [
                'Choisissez une paire de langues (si vous en avez importé plusieurs), '
                    'un thème (ou « tout ») et un sens.',
                'Les cartes défilent une par une, en ordre aléatoire, chacune une '
                    'seule fois. Le mot à traduire s’affiche ; vous pouvez taper '
                    'votre réponse dans le champ — mais ce champ est une simple '
                    'aide à l’écriture, il n’est jamais corrigé automatiquement.',
                'Vous validez pour dévoiler la réponse attendue, puis vous vous '
                    'jugez vous-même. Vous pouvez arrêter la session à tout moment : '
                    'seules les cartes réellement jouées comptent.',
              ],
            ),
            _Section(
              icon: Icons.person_outline,
              title: 'La correction, c’est vous',
              paragraphs: [
                'Après avoir vu la réponse, vous appuyez sur « Je savais » ou '
                    '« Je savais pas ». C’est votre honnêteté qui fait la note — '
                    'l’application ne compare jamais votre saisie au corrigé.',
                'Ce choix met à jour immédiatement la statistique de la carte pour '
                    'le sens en cours.',
              ],
            ),
            _Section(
              icon: Icons.bar_chart,
              title: 'Comment les statistiques sont calculées',
              paragraphs: [
                'Chaque carte a deux taux de réussite distincts, un pour chaque '
                    'sens. Savoir un mot dans un sens n’est pas la même chose '
                    'que dans l’autre.',
                'Le taux est cumulatif, depuis le début : c’est le nombre de '
                    '« Je savais » divisé par le nombre total de tentatives pour ce '
                    'sens. Exemple : 3 « Je savais » sur 4 tentatives = 75 %.',
                'À la fin d’une partie, le score affiché est celui de la session '
                    'seule : bonnes réponses / cartes réellement jouées.',
                'L’écran « Consulter les statistiques » liste vos cartes par thème '
                    'avec leurs deux taux. Tout est conservé même après fermeture.',
              ],
            ),
            _Section(
              icon: Icons.flag_outlined,
              title: 'Ce qui n’est pas encore là',
              paragraphs: [
                'Plusieurs paires de langues peuvent coexister : réglez votre '
                    'langue dans « Gestion des données », et ajoutez la colonne '
                    '« Langue » dans votre fichier pour distinguer chaque langue '
                    'étrangère.',
                'Pas encore là (évolutions prévues) : le choix de la taille des '
                    'sessions, la priorité automatique aux cartes les moins '
                    'réussies (révision espacée), et un taux qui pèse davantage '
                    'vos dernières tentatives.',
                'Pour l’instant, chaque tentative compte à parts égales dans le '
                    'taux cumulatif.',
              ],
            ),
            const SizedBox(height: 24),
            // Bouton caché (easter egg) tout en bas.
            _HiddenEggTrigger(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> paragraphs;

  const _Section({
    required this.icon,
    required this.title,
    required this.paragraphs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...paragraphs.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(p,
                    style: const TextStyle(fontSize: 14, height: 1.35)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Élément discret en bas de page : ressemble à une simple mention de version,
/// mais tout est un bouton qui révèle l'easter egg.
class _HiddenEggTrigger extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showEgg(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: Text(
            'Flashcard · V1',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  void _showEgg(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // on ne revient qu'en appuyant sur le chocolat
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
              decoration: BoxDecoration(
                color: const Color(0xFF4E342E), // brun chocolat
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Crafted with a pinch of Chocolate',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF5E6D3),
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Appuyer sur la tablette de chocolat pour revenir en arrière.
            InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: () => Navigator.of(ctx).pop(),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text('🍫', style: TextStyle(fontSize: 52)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

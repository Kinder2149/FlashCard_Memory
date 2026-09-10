import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../app_state.dart';
import '../models.dart';
import '../data/csv_source.dart';

/// U2 — Import.
///
/// Trois entrées : télécharger le modèle Excel (embarqué dans l'app), importer
/// depuis un fichier .xlsx de l'appareil, ou coller / mettre à jour un lien de
/// publication CSV. Les deux imports (fichier et lien) passent par le même
/// moteur et affichent le même rapport.
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _linkController = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;
  ImportReport? _report;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  /// Exécute un import (lien ou fichier) avec gestion commune de l'attente,
  /// des erreurs et de l'affichage du rapport.
  Future<void> _runImport(Future<ImportReport> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
      _report = null;
    });
    try {
      final report = await action();
      setState(() => _report = report);
    } on CsvSourceException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Import impossible : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Enregistre le modèle Excel embarqué vers un emplacement choisi par
  /// l'utilisateur, pour qu'il le remplisse puis le réimporte.
  Future<void> _downloadModel() async {
    setState(() {
      _error = null;
      _info = null;
    });
    try {
      final data = await rootBundle.load('assets/Flashcard_modele.xlsx');
      final bytes = data.buffer.asUint8List();
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer le modèle Flashcard',
        fileName: 'Flashcard_modele.xlsx',
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        bytes: bytes,
      );
      if (path != null) {
        setState(() => _info =
            'Modèle enregistré. Ouvrez-le dans Sheets ou Excel, remplissez-le, '
            'puis revenez l\'importer ici.');
      }
    } catch (e) {
      setState(() => _error = 'Enregistrement impossible : $e');
    }
  }

  /// Demande confirmation puis vide la mémoire (cartes + statistiques).
  Future<void> _confirmClear() async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider la mémoire ?'),
        content: Text(
            'Les ${app.memoryCount} cartes et toutes leurs statistiques seront '
            'effacées du téléphone. Cette action est définitive. Vous pourrez '
            'réimporter depuis votre Sheet ou votre fichier.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await app.clearMemory();
    if (!mounted) return;
    setState(() {
      _report = null;
      _error = null;
      _info = 'Mémoire vidée. Vous pouvez réimporter quand vous voulez.';
    });
  }

  /// Choisit un fichier .xlsx sur l'appareil et l'importe.
  Future<void> _importFromFile() async {
    final app = context.read<AppState>();
    final FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        dialogTitle: 'Choisir le fichier Excel rempli',
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        withData: true,
      );
    } catch (e) {
      setState(() => _error = 'Sélection du fichier impossible : $e');
      return;
    }
    if (picked == null) return; // annulé

    final bytes = picked.files.single.bytes;
    if (bytes == null) {
      setState(() => _error = 'Le fichier choisi n\'a pas pu être lu.');
      return;
    }
    await _runImport(() => app.importFromXlsxBytes(bytes));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final hasLink = app.hasLink;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des données')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- 1. Télécharger le modèle ---
            _SectionCard(
              title: '1. Partir du modèle',
              children: [
                const Text(
                  'Enregistrez le modèle Excel sur votre appareil, remplissez-le '
                  'dans Sheets ou Excel (colonnes Français / Anglais / Thème, sans '
                  'toucher aux identifiants), puis revenez l\'importer.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _downloadModel,
                  icon: const Icon(Icons.download),
                  label: const Text('Télécharger le modèle (.xlsx)'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- 2. Importer depuis un fichier ---
            _SectionCard(
              title: '2. Importer depuis un fichier',
              children: [
                const Text(
                  'Choisissez le fichier Excel (.xlsx) rempli, présent sur votre '
                  'appareil. Après chaque modification du fichier, réimportez-le '
                  'pour mettre la mémoire à jour.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _busy ? null : _importFromFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Choisir un fichier (.xlsx)'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- 3. Importer depuis un lien Google Sheet ---
            _SectionCard(
              title: hasLink
                  ? '3. Lien Google Sheet — mettre à jour'
                  : '3. Importer depuis un lien Google Sheet',
              children: [
                if (hasLink) ...[
                  const Text(
                    'Un lien est déjà mémorisé. « Mettre à jour » relit votre '
                    'Google Sheet et cale la mémoire sur son contenu exact.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _runImport(
                            () => context.read<AppState>().importFromLink()),
                    icon: const Icon(Icons.sync),
                    label: const Text('Mettre à jour'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Changer de lien',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                ],
                const Text(
                  'Collez le lien de votre Google Sheet (bouton « Partager », ou '
                  'l\'adresse de la barre du navigateur). Important : réglez '
                  'd\'abord le partage sur « Tous les utilisateurs disposant du '
                  'lien » (Lecteur), sinon l\'application ne pourra pas le lire. '
                  'L\'application ne modifie jamais votre Sheet.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _linkController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'https://docs.google.com/spreadsheets/d/…',
                    suffixIcon: IconButton(
                      tooltip: 'Coller',
                      icon: const Icon(Icons.paste),
                      onPressed: () async {
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          _linkController.text = data!.text!.trim();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _runImport(() => context
                          .read<AppState>()
                          .importFromLink(pastedLink: _linkController.text)),
                  icon: const Icon(Icons.cloud_download),
                  label: Text(
                      hasLink ? 'Importer depuis ce nouveau lien' : 'Importer'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- 4. Réinitialiser ---
            _SectionCard(
              title: '4. Réinitialiser',
              children: [
                const Text(
                  'Efface toutes les cartes et leurs statistiques de la mémoire '
                  'du téléphone. Votre Sheet ou fichier n\'est pas touché : vous '
                  'pourrez tout réimporter. Le lien mémorisé est conservé.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: (_busy || !app.hasCards) ? null : _confirmClear,
                  icon: Icon(Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  label: const Text('Vider la mémoire'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (_info != null) _InfoBox(message: _info!),
            if (_error != null) _ErrorBox(message: _error!),
            if (_report != null) _ReportBox(report: _report!),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String message;
  const _InfoBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _ReportBox extends StatelessWidget {
  final ImportReport report;
  const _ReportBox({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rapport d\'import',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _line('Ajoutées', report.added, Icons.add_circle, Colors.green),
            _line('Mises à jour', report.updated, Icons.edit, Colors.orange),
            _line('Supprimées', report.deleted, Icons.remove_circle, Colors.red),
            _line('Inchangées', report.unchanged, Icons.check, Colors.grey),
            const Divider(height: 24),
            Text('Entrées valides dans le fichier : ${report.sheetValidCount}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _idList(context, 'Lignes incomplètes ignorées',
                report.incompleteIds, 'Aucune ligne incomplète.'),
            const SizedBox(height: 8),
            _idList(context, 'Doublons détectés (conservés)',
                report.duplicateIds, 'Aucun doublon.'),
            const SizedBox(height: 16),
            Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Valider — retour à l\'Accueil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, int value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Text('$label : ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('$value'),
        ],
      ),
    );
  }

  Widget _idList(
      BuildContext context, String title, List<String> ids, String emptyMsg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        if (ids.isEmpty)
          Text(emptyMsg, style: const TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ids
                .map((id) => Chip(
                      label: Text(id),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
      ],
    );
  }
}

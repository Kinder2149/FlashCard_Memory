import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../app_state.dart';
import '../models.dart';
import '../data/csv_source.dart';
import '../data/export_source.dart';

enum _Method { model, file, link }

/// Importations — choix de la méthode d'import.
///
/// Présente d'abord les 3 méthodes comme un choix explicite (cartes), puis
/// affiche uniquement le panneau de la méthode choisie — plutôt que d'empiler
/// les 3 formulaires en permanence (retour utilisateur : trop confus, pas
/// orienté « choix »).
class ImportChoiceScreen extends StatefulWidget {
  const ImportChoiceScreen({super.key});

  @override
  State<ImportChoiceScreen> createState() => _ImportChoiceScreenState();
}

class _ImportChoiceScreenState extends State<ImportChoiceScreen> {
  _Method? _selected;
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

  void _select(_Method m) {
    setState(() {
      _selected = m;
      _error = null;
      _info = null;
      _report = null;
    });
  }

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

  /// V2 A3/A5 — Exporte la base réelle de l'app (pas le modèle vierge).
  Future<void> _exportDatabase() async {
    setState(() {
      _error = null;
      _info = null;
    });
    try {
      final app = context.read<AppState>();
      final bytes = ExportSource().buildXlsx(app.cards);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer ma base Flashcard',
        fileName: 'Flashcard_ma_base.xlsx',
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        bytes: bytes,
      );
      if (path != null && mounted) {
        setState(() => _info =
            'Votre base (${app.memoryCount} carte(s)) a été enregistrée.');
      }
    } catch (e) {
      setState(() => _error = 'Export impossible : $e');
    }
  }

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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Importations')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- Base actuelle (V2 A3/A5) : distincte du modèle vierge ---
            Card(
              color: scheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.backup_outlined, color: scheme.primary),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Ma base actuelle',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${app.memoryCount} carte(s) dans l\'app, toutes origines '
                      'confondues (import, ajout manuel). Téléchargez-la pour la '
                      'garder en sauvegarde — différente du modèle vierge ci-dessous.',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: app.hasCards ? _exportDatabase : null,
                      icon: const Icon(Icons.download),
                      label: const Text('Télécharger ma base (.xlsx)'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Comment voulez-vous importer vos cartes ?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _MethodTile(
              icon: Icons.download,
              color: scheme.primaryContainer,
              title: 'Partir du modèle',
              subtitle: 'Téléchargez un fichier Excel vierge à remplir.',
              selected: _selected == _Method.model,
              onTap: () => _select(_Method.model),
            ),
            const SizedBox(height: 10),
            _MethodTile(
              icon: Icons.folder_open,
              color: scheme.secondaryContainer,
              title: 'Fichier Excel',
              subtitle: 'Importez un .xlsx déjà rempli sur l\'appareil.',
              selected: _selected == _Method.file,
              onTap: () => _select(_Method.file),
            ),
            const SizedBox(height: 10),
            _MethodTile(
              icon: Icons.link,
              color: scheme.tertiaryContainer,
              title: hasLink ? 'Google Sheet (lien mémorisé)' : 'Lien Google Sheet',
              subtitle: hasLink
                  ? 'Mettre à jour, ou changer de lien.'
                  : 'Collez le lien de votre Sheet partagé.',
              selected: _selected == _Method.link,
              onTap: () => _select(_Method.link),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              switch (_selected!) {
                _Method.model => _ModelPanel(onDownload: _downloadModel),
                _Method.file => _FilePanel(
                    busy: _busy,
                    onPick: _importFromFile,
                  ),
                _Method.link => _LinkPanel(
                    hasLink: hasLink,
                    busy: _busy,
                    controller: _linkController,
                    onUpdate: () => _runImport(
                        () => context.read<AppState>().importFromLink()),
                    onImportNew: () => _runImport(() => context
                        .read<AppState>()
                        .importFromLink(pastedLink: _linkController.text)),
                  ),
              },
            ],
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

/// Une méthode d'import proposée au choix : icône colorée, titre, description.
class _MethodTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color, child: Icon(icon)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Icon(selected ? Icons.check_circle : Icons.chevron_right,
                  color: selected ? scheme.primary : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelPanel extends StatelessWidget {
  final VoidCallback onDownload;
  const _ModelPanel({required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enregistrez le modèle Excel sur votre appareil, remplissez-le '
              'dans Sheets ou Excel, puis revenez l\'importer ici (méthode '
              '« Fichier Excel »).',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download),
              label: const Text('Télécharger le modèle (.xlsx)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilePanel extends StatelessWidget {
  final bool busy;
  final VoidCallback onPick;
  const _FilePanel({required this.busy, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisissez le fichier Excel (.xlsx) rempli, présent sur votre '
              'appareil. Après chaque modification du fichier, réimportez-le '
              'pour mettre la mémoire à jour.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: busy ? null : onPick,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choisir un fichier (.xlsx)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkPanel extends StatelessWidget {
  final bool hasLink;
  final bool busy;
  final TextEditingController controller;
  final VoidCallback onUpdate;
  final VoidCallback onImportNew;

  const _LinkPanel({
    required this.hasLink,
    required this.busy,
    required this.controller,
    required this.onUpdate,
    required this.onImportNew,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasLink) ...[
              const Text(
                'Un lien est déjà mémorisé. « Mettre à jour » relit votre '
                'Google Sheet et cale la mémoire sur son contenu exact.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: busy ? null : onUpdate,
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
              controller: controller,
              decoration: InputDecoration(
                hintText: 'https://docs.google.com/spreadsheets/d/…',
                suffixIcon: IconButton(
                  tooltip: 'Coller',
                  icon: const Icon(Icons.paste),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      controller.text = data!.text!.trim();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: busy ? null : onImportNew,
              icon: const Icon(Icons.cloud_download),
              label: Text(hasLink ? 'Importer depuis ce nouveau lien' : 'Importer'),
            ),
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
                child: const Text('Valider — retour'),
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

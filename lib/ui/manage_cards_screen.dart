import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';

/// V2 A2 — Gestion manuelle des cartes : liste, ajout, modification,
/// suppression directement dans l'app (sans passer par un import).
class ManageCardsScreen extends StatelessWidget {
  const ManageCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cards = app.cards;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes cartes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: SafeArea(
        child: cards.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aucune carte pour le moment. Ajoutez-en une, ou importez '
                    'depuis un Sheet ou un fichier Excel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: cards.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final c = cards[i];
                  return Card(
                    child: ListTile(
                      title: Text('${c.fr} — ${c.en}'),
                      subtitle:
                          Text(c.theme.isEmpty ? c.id : '${c.theme} · ${c.id}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Modifier',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openEditor(context, existing: c),
                          ),
                          IconButton(
                            tooltip: 'Supprimer',
                            icon: Icon(Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error),
                            onPressed: () => _confirmDelete(context, c),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Flashcard card) async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette carte ?'),
        content: Text(
            '« ${card.fr} — ${card.en} » et ses statistiques seront effacées.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) await app.deleteCard(card.id);
  }

  Future<void> _openEditor(BuildContext context, {Flashcard? existing}) {
    return showDialog(
      context: context,
      builder: (_) => _CardEditorDialog(existing: existing),
    );
  }
}

class _CardEditorDialog extends StatefulWidget {
  final Flashcard? existing;
  const _CardEditorDialog({this.existing});

  @override
  State<_CardEditorDialog> createState() => _CardEditorDialogState();
}

class _CardEditorDialogState extends State<_CardEditorDialog> {
  late final _frCtrl = TextEditingController(text: widget.existing?.fr ?? '');
  late final _enCtrl = TextEditingController(text: widget.existing?.en ?? '');
  late final _themeCtrl =
      TextEditingController(text: widget.existing?.theme ?? '');
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _frCtrl.dispose();
    _enCtrl.dispose();
    _themeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final fr = _frCtrl.text.trim();
    final en = _enCtrl.text.trim();
    if (fr.isEmpty || en.isEmpty) {
      setState(
          () => _error = 'Les deux mots (Français et Anglais) sont obligatoires.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final app = context.read<AppState>();
    final theme = _themeCtrl.text.trim();
    if (widget.existing == null) {
      await app.addCard(fr: fr, en: en, theme: theme);
    } else {
      await app.updateCard(widget.existing!.id, fr: fr, en: en, theme: theme);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.existing == null ? 'Ajouter une carte' : 'Modifier la carte'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _frCtrl,
            decoration: const InputDecoration(labelText: 'Français'),
            autofocus: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _enCtrl,
            decoration: const InputDecoration(labelText: 'Anglais'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _themeCtrl,
            decoration: const InputDecoration(labelText: 'Thème (optionnel)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

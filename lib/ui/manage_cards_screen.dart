import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';

/// V2 A2 + fusion Vocabulaire — Gestion des cartes : consultation groupée par
/// thème (reprend l'ancien écran Vocabulaire, retiré car devenu redondant),
/// ajout, modification et suppression directement dans l'app.
class ManageCardsScreen extends StatelessWidget {
  const ManageCardsScreen({super.key});

  static const _noTheme = 'Sans thème';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cards = app.cards;

    final byTheme = <String, List<Flashcard>>{};
    for (final c in cards) {
      final key = c.theme.isEmpty ? _noTheme : c.theme;
      byTheme.putIfAbsent(key, () => []).add(c);
    }
    final themeNames = byTheme.keys.toList()
      ..sort((a, b) {
        if (a == _noTheme) return 1;
        if (b == _noTheme) return -1;
        return a.compareTo(b);
      });

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
                    'depuis un Sheet ou un fichier Excel (Paramètres → Importations).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : Column(
                children: [
                  _Summary(words: cards.length, themes: themeNames.length),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final theme in themeNames)
                          _ThemeSection(
                            title: theme,
                            cards: byTheme[theme]!
                              ..sort((a, b) =>
                                  a.motherWord.toLowerCase().compareTo(
                                        b.motherWord.toLowerCase(),
                                      )),
                          ),
                        const SizedBox(height: 80), // laisse de la place au FAB
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  static Future<void> _confirmDelete(BuildContext context, Flashcard card) async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette carte ?'),
        content: Text(
            '« ${card.motherWord} — ${card.foreignWord} » et ses statistiques '
            'seront effacées.'),
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

  static Future<void> _openEditor(BuildContext context, {Flashcard? existing}) {
    return showDialog(
      context: context,
      builder: (_) => _CardEditorDialog(existing: existing),
    );
  }
}

/// Bandeau récapitulatif : nombre de mots et de thèmes.
class _Summary extends StatelessWidget {
  final int words;
  final int themes;
  const _Summary({required this.words, required this.themes});

  @override
  Widget build(BuildContext context) {
    final w = '$words ${words <= 1 ? "mot" : "mots"}';
    final t = '$themes ${themes <= 1 ? "thème" : "thèmes"}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text('$w · $t',
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
    );
  }
}

/// Une catégorie : un en-tête de thème puis ses cartes.
class _ThemeSection extends StatelessWidget {
  final String title;
  final List<Flashcard> cards;
  const _ThemeSection({required this.title, required this.cards});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: scheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            '$title  (${cards.length})',
            style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary),
          ),
        ),
        for (final c in cards) _CardRow(card: c),
      ],
    );
  }
}

/// Une carte : mots + actions modifier/supprimer.
class _CardRow extends StatelessWidget {
  final Flashcard card;
  const _CardRow({required this.card});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
          '${card.motherWord}  —  ${card.foreignWord} (${card.foreignLang})'),
      subtitle: Text(card.id, style: const TextStyle(fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () =>
                ManageCardsScreen._openEditor(context, existing: card),
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: Icon(Icons.delete_outline,
                size: 20, color: Theme.of(context).colorScheme.error),
            onPressed: () => ManageCardsScreen._confirmDelete(context, card),
          ),
        ],
      ),
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
  late final _motherCtrl =
      TextEditingController(text: widget.existing?.motherWord ?? '');
  late final _foreignCtrl =
      TextEditingController(text: widget.existing?.foreignWord ?? '');
  late final _themeCtrl =
      TextEditingController(text: widget.existing?.theme ?? '');
  late String _foreignLang = widget.existing?.foreignLang ?? 'EN';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _motherCtrl.dispose();
    _foreignCtrl.dispose();
    _themeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final mother = _motherCtrl.text.trim();
    final foreign = _foreignCtrl.text.trim();
    if (mother.isEmpty || foreign.isEmpty) {
      setState(() => _error = 'Les deux mots sont obligatoires.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final app = context.read<AppState>();
    final theme = _themeCtrl.text.trim();
    if (widget.existing == null) {
      await app.addCard(
          motherWord: mother,
          foreignWord: foreign,
          foreignLang: _foreignLang,
          theme: theme);
    } else {
      await app.updateCard(widget.existing!.id,
          motherWord: mother,
          foreignWord: foreign,
          foreignLang: _foreignLang,
          theme: theme);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return AlertDialog(
      title:
          Text(widget.existing == null ? 'Ajouter une carte' : 'Modifier la carte'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _motherCtrl,
            decoration: InputDecoration(
                labelText: 'Mot en ${Languages.nameOf(app.motherLang)}'),
            autofocus: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _foreignCtrl,
            decoration: const InputDecoration(labelText: 'Mot en langue étrangère'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _foreignLang,
            decoration: const InputDecoration(labelText: 'Langue étrangère'),
            items: Languages.codes
                .where((c) => c != app.motherLang)
                .map((c) => DropdownMenuItem(
                    value: c, child: Text(Languages.nameOf(c))))
                .toList(),
            onChanged: (v) => setState(() => _foreignLang = v!),
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

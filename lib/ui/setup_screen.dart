import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import 'game_screen.dart';
import 'qcm_game_screen.dart';

/// U3 — Paramétrage de partie.
///
/// Quatre réglages : le mode (Saisie ou QCM), la paire de langues (V2, parmi
/// celles disponibles en mémoire), le thème (un thème précis, ou « tout ») et
/// le sens. « Lancer » démarre le jeu dans le mode choisi.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  // null = « Tous les thèmes »
  String? _theme;
  String? _foreignLang; // initialisé au premier build (dépend des données)
  Direction _direction = Direction.motherToForeign;
  GameMode _mode = GameMode.typing;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pairs = app.availablePairs;
    _foreignLang ??= pairs.isNotEmpty ? pairs.first : null;
    final foreignLang = _foreignLang;
    final themes = app.themes;

    // Nombre de cartes dans le périmètre choisi (aperçu).
    final count = foreignLang == null
        ? 0
        : app.cards
            .where((c) => c.foreignLang.toUpperCase() == foreignLang)
            .where((c) => _theme == null || c.theme == _theme)
            .length;

    // Le QCM exige 4 mots exploitables (dépend du sens choisi et de la paire).
    // Indisponible si la paire entière est trop pauvre.
    final qcmUnavailable = foreignLang == null ||
        (_mode == GameMode.qcm &&
            !app.isQcmAvailable(_direction, foreignLang));
    final canLaunch = count > 0 && !qcmUnavailable;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramétrer la partie')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Mode', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RadioGroup<GameMode>(
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v!),
              child: Column(
                children: [
                  _modeTile(GameMode.typing),
                  _modeTile(GameMode.qcm),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Paire de langues',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (pairs.isEmpty)
              const Text('Aucune paire disponible : importez ou ajoutez des cartes.',
                  style: TextStyle(color: Colors.red))
            else
              DropdownButtonFormField<String>(
                initialValue: foreignLang,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: pairs
                    .map((p) => DropdownMenuItem<String>(
                          value: p,
                          child: Text(
                              '${Languages.nameOf(app.motherLang)} ↔ ${Languages.nameOf(p)}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _foreignLang = v),
              ),
            const SizedBox(height: 24),
            const Text('Thème', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _theme,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Tous les thèmes'),
                ),
                ...themes.map((t) => DropdownMenuItem<String?>(
                      value: t,
                      child: Text(t),
                    )),
              ],
              onChanged: (v) => setState(() => _theme = v),
            ),
            const SizedBox(height: 24),
            const Text('Sens', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RadioGroup<Direction>(
              groupValue: _direction,
              onChanged: (v) => setState(() => _direction = v!),
              child: Column(
                children: [
                  _directionTile(Direction.motherToForeign, app.motherLang,
                      foreignLang),
                  _directionTile(Direction.foreignToMother, app.motherLang,
                      foreignLang),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage(count, qcmUnavailable),
              style: TextStyle(
                color: canLaunch ? Colors.grey : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: canLaunch ? () => _launch(context) : null,
              icon: const Icon(Icons.play_arrow),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              label: const Text('Lancer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Message d'aide sous les réglages : priorité au blocage le plus explicite.
  String _statusMessage(int count, bool qcmUnavailable) {
    if (count == 0) return 'Aucune carte dans ce thème.';
    if (qcmUnavailable) {
      return 'Le mode QCM nécessite au moins 4 mots dans ce sens. '
          'Importez-en davantage ou choisissez le mode Saisie.';
    }
    return '$count ${count <= 1 ? "carte" : "cartes"} dans ce périmètre.';
  }

  Widget _modeTile(GameMode m) {
    return RadioListTile<GameMode>(
      value: m,
      title: Text(m.label),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _directionTile(Direction d, String motherLang, String? foreignLang) {
    return RadioListTile<Direction>(
      value: d,
      title: Text(foreignLang == null
          ? '—'
          : directionLabel(d, motherLang, foreignLang)),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _launch(BuildContext context) {
    final foreignLang = _foreignLang;
    if (foreignLang == null) return;
    final ok = context.read<AppState>().startSession(
          foreignLang: foreignLang,
          theme: _theme,
          direction: _direction,
          mode: _mode,
        );
    if (!ok) return;
    final Widget screen =
        _mode == GameMode.qcm ? const QcmGameScreen() : const GameScreen();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

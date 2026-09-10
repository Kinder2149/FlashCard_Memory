import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../logic/qcm_builder.dart';
import 'recap_screen.dart';

/// U — Jeu en mode QCM (choix multiple).
///
/// Présente les cartes une par une : le mot source en haut, puis 4 options dans
/// la langue cible (1 bonne réponse + 3 distracteurs), dans un ordre aléatoire
/// recalculé à chaque carte. On touche une option → évaluation automatique
/// immédiate : la bonne réponse passe au vert ; si le choix est faux, il passe
/// au rouge et la bonne réponse reste mise en évidence. La carte suivante
/// s'enchaîne ensuite d'elle-même. Clôture possible à tout moment.
///
/// Étape 2 : évaluation, feedback, score de session, clôture anticipée. Les
/// statistiques QCM séparées viendront à l'Étape 3.
class QcmGameScreen extends StatefulWidget {
  const QcmGameScreen({super.key});

  @override
  State<QcmGameScreen> createState() => _QcmGameScreenState();
}

class _QcmGameScreenState extends State<QcmGameScreen> {
  // Options de la carte affichée, figées tant qu'on ne change pas de carte.
  QcmOptions? _options;
  String? _optionsCardId;

  // État d'évaluation de la carte courante.
  int? _chosenIndex; // option touchée, null tant qu'on n'a pas répondu
  bool _revealed = false;
  Timer? _advanceTimer;

  // Temps de lecture du feedback avant l'enchaînement (plus long si erreur,
  // pour laisser voir la bonne réponse).
  static const _delayCorrect = Duration(milliseconds: 800);
  static const _delayWrong = Duration(milliseconds: 1700);

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  /// (Re)génère les options quand la carte courante change d'identifiant.
  QcmOptions _optionsFor(AppState app, String cardId) {
    if (_optionsCardId != cardId || _options == null) {
      _optionsCardId = cardId;
      _options = app.buildQcmOptions(app.session!.current!.card);
    }
    return _options!;
  }

  void _pick(int index, QcmOptions options) {
    if (_revealed) return; // déjà répondu : on ignore les autres touchers
    final correct = index == options.correctIndex;
    setState(() {
      _chosenIndex = index;
      _revealed = true;
    });
    _advanceTimer =
        Timer(correct ? _delayCorrect : _delayWrong, () => _advance(correct));
  }

  Future<void> _advance(bool correct) async {
    _advanceTimer?.cancel();
    if (!mounted) return;
    final app = context.read<AppState>();
    // Réinitialiser l'affichage avant d'avancer, pour ne pas montrer le feedback
    // de la carte précédente sur la nouvelle.
    setState(() {
      _revealed = false;
      _chosenIndex = null;
    });
    await app.answerQcmCurrent(correct); // enregistre la stat QCM et avance
    if (!mounted) return;
    if (app.session?.isFinished ?? true) _goRecap();
  }

  void _goRecap() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RecapScreen()),
    );
  }

  Future<void> _confirmClose() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminer la session ?'),
        content: const Text(
            'Les cartes non jouées ne seront pas comptées. Vous verrez le récap '
            'des cartes déjà jouées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuer'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      _advanceTimer?.cancel();
      context.read<AppState>().closeSession();
      _goRecap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final session = app.session;

    if (session == null || session.isFinished) {
      return const SizedBox.shrink();
    }

    final current = session.current!;
    final promptText = session.prompt(current.card);
    final options = _optionsFor(app, current.card.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Carte ${session.position + 1} / ${session.total}'),
        actions: [
          IconButton(
            tooltip: 'Terminer la session',
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: _confirmClose,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: session.total == 0 ? 0 : session.position / session.total,
            ),
            const SizedBox(height: 8),
            Text(session.direction.label,
                style: const TextStyle(color: Colors.grey)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PromptCard(text: promptText),
                    const SizedBox(height: 24),
                    for (var i = 0; i < options.options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OptionButton(
                          text: options.options[i],
                          state: _stateOf(i, options),
                          onTap:
                              _revealed ? null : () => _pick(i, options),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Détermine l'apparence d'une option selon l'état d'évaluation.
  _OptionState _stateOf(int index, QcmOptions options) {
    if (!_revealed) return _OptionState.idle;
    if (index == options.correctIndex) return _OptionState.correct;
    if (index == _chosenIndex) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

/// Carte du haut : le mot à traduire (langue source).
class _PromptCard extends StatelessWidget {
  final String text;
  const _PromptCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Apparence possible d'une option pendant / après l'évaluation.
enum _OptionState { idle, correct, wrong, dimmed }

/// Une option cliquable. En évaluation : verte (bonne), rouge (mauvais choix),
/// atténuée (les autres).
class _OptionButton extends StatelessWidget {
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  const _OptionButton({
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);
    const red = Color(0xFFC62828);

    Color? bg;
    Color? border;
    Color? fg;
    IconData? icon;
    switch (state) {
      case _OptionState.idle:
        break;
      case _OptionState.correct:
        bg = green.withValues(alpha: 0.12);
        border = green;
        fg = green;
        icon = Icons.check_circle;
      case _OptionState.wrong:
        bg = red.withValues(alpha: 0.12);
        border = red;
        fg = red;
        icon = Icons.cancel;
      case _OptionState.dimmed:
        fg = Colors.grey;
    }

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledForegroundColor: fg,
        side: border == null ? null : BorderSide(color: border, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 17))),
          if (icon != null) Icon(icon, color: fg),
        ],
      ),
    );
  }
}

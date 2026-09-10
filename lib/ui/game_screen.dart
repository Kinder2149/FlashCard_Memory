import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import 'recap_screen.dart';

/// U4 — Jeu.
///
/// Présente les cartes une par une, centrées. On écrit sa réponse (aide à
/// l'écriture, jamais comparée), on valide : la carte se retourne pour montrer
/// la réponse attendue de l'autre côté. On peut la re-toucher pour revoir le
/// mot, puis on choisit « je savais » / « je savais pas ». Clôture possible à
/// tout moment via l'icône en haut à droite.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _answerController = TextEditingController();
  bool _revealed = false; // la réponse a été validée
  bool _showBack = false; // face actuellement visible (recto/verso)

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _reveal() => setState(() {
        _revealed = true;
        _showBack = true;
      });

  void _toggleFace() => setState(() => _showBack = !_showBack);

  Future<void> _judge(bool knew) async {
    final app = context.read<AppState>();
    await app.answerCurrent(knew);
    if (!mounted) return;
    _answerController.clear();
    setState(() {
      _revealed = false;
      _showBack = false;
    });
    if (app.session?.isFinished ?? true) _goRecap();
  }

  void _goRecap() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RecapScreen()),
    );
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
    final answerText = session.answer(current.card);

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
              value:
                  session.total == 0 ? 0 : session.position / session.total,
            ),
            const SizedBox(height: 8),
            Text(session.direction.label,
                style: const TextStyle(color: Colors.grey)),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FlipCard(
                        // Une carte neuve par identifiant : pas d'animation
                        // parasite au changement de carte.
                        key: ValueKey(current.card.id),
                        front: promptText,
                        back: answerText,
                        showBack: _showBack,
                        onTap: _revealed ? _toggleFace : null,
                      ),
                      if (_revealed)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'Touchez la carte pour revoir le mot',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _answerController,
                        enabled: !_revealed,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Votre réponse (aide à l\'écriture)',
                        ),
                        onSubmitted: (_) => _revealed ? null : _reveal(),
                      ),
                      const SizedBox(height: 20),
                      if (!_revealed)
                        FilledButton(
                          onPressed: _reveal,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Valider'),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _judge(false),
                                icon: const Icon(Icons.close, color: Colors.red),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                label: const Text('Je savais pas'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _judge(true),
                                icon: const Icon(Icons.check),
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                label: const Text('Je savais'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
      context.read<AppState>().closeSession();
      _goRecap();
    }
  }
}

/// Carte à retournement 3D. Affiche [front] (recto) et [back] (verso) selon
/// [showBack] ; anime la bascule. Un appui déclenche [onTap] (peut être null).
class _FlipCard extends StatefulWidget {
  final String front;
  final String back;
  final bool showBack;
  final VoidCallback? onTap;

  const _FlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.showBack,
    this.onTap,
  });

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: widget.showBack ? 1 : 0,
  );

  @override
  void didUpdateWidget(_FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.showBack != old.showBack) {
      widget.showBack ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * pi;
          final isBack = angle > pi / 2;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // légère perspective
            ..rotateY(angle);
          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: isBack
                // Le verso est « remis à l'endroit » (sinon le texte est en
                // miroir à cause de la rotation).
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _face(context, widget.back, back: true),
                  )
                : _face(context, widget.front, back: false),
          );
        },
      ),
    );
  }

  Widget _face(BuildContext context, String text, {required bool back}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 190),
      decoration: BoxDecoration(
        color: back ? scheme.primary : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: back ? scheme.onPrimary : scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

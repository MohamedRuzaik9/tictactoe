import 'package:flutter/material.dart';
import 'package:tic_tac_toe/main.dart';
import '../core/ai.dart';
import '../core/game_logic.dart';
import '../core/game_models.dart';
import '../core/persistence.dart';

class GameScreen extends StatefulWidget {
  final AIDifficulty difficulty;
  final StatsStore store;
  const GameScreen({super.key, required this.difficulty, required this.store});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState state;
  Stats stats = const Stats();
  final medium = MediumBrain();

  @override
  void initState() {
    super.initState();
    state = GameState.initial();
    widget.store.load().then((s) {
      if (mounted) setState(() => stats = s);
    });
  }

  void _restart() => setState(() => state = GameState.initial());

  Future<void> _resetStats() async {
    await widget.store.reset();
    final s = await widget.store.load();
    if (!mounted) return;
    setState(() => stats = s);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Stats reset')));
  }

  Future<void> _tap(int r, int c) async {
    if (!mounted || !isValidMove(state, r, c) || state.isComplete) return;
    setState(() => state = applyMove(state, r, c));
    await _aiTurnIfNeeded();
  }

  Future<void> _aiTurnIfNeeded() async {
    final w = checkWinner(state);
    if (w != null) return _finishWithWinner(w);
    if (isDraw(state)) return _finishDraw();

    if (!state.isComplete && state.current == Player.o) {
      List<int>? mv;
      switch (widget.difficulty) {
        case AIDifficulty.easy:   mv = easyMove(state);    break;
        case AIDifficulty.medium: mv = medium.move(state); break;
        case AIDifficulty.hard:   mv = hardMove(state);    break;
      }
      if (mv != null) {
        final m = mv;
        setState(() => state = applyMove(state, m[0], m[1]));
      }
      final w2 = checkWinner(state);
      if (w2 != null) return _finishWithWinner(w2);
      if (isDraw(state)) return _finishDraw();
    }
  }

  Future<void> _finishWithWinner(Player p) async {
    final youWon = p == Player.x;
    final updated = youWon
        ? stats.copyWith(wins: stats.wins + 1)
        : stats.copyWith(losses: stats.losses + 1);
    await widget.store.save(updated);
    if (!mounted) return;
    setState(() {
      stats = updated;
      state = state.copyWith(isComplete: true);
    });
  }

  Future<void> _finishDraw() async {
    final updated = stats.copyWith(draws: stats.draws + 1);
    await widget.store.save(updated);
    if (!mounted) return;
    setState(() {
      stats = updated;
      state = state.copyWith(isComplete: true);
    });
  }

  void _undoTwo() {
    if (state.isComplete) return;
    if (state.moveLog.length >= 2) {
      setState(() => state = undo(state));
      setState(() => state = undo(state));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accentO = const Color(0xFF10B3E6);

    // ——— Result pill setup ———
    String? label;
    Color pillTint = Colors.transparent;
    if (state.isComplete) {
      final w = checkWinner(state);
      if (w == Player.x) {
        label = 'YOU WIN!';
        pillTint = const Color(0xFF1B5E20); // dark green
      } else if (w == Player.o) {
        label = 'YOU LOSE!';
        pillTint = const Color(0xFF7F1D1D); // muted dark red
      } else {
        label = 'DRAW!';
        pillTint = Colors.grey.shade700;    // grey for draw
      }
    }

    return Scaffold(
      // solid background; set the global color in main.dart if you want a site-wide change
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: null, // no "Game" text
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              // ——— Result pill (only when finished) ———
              if (label != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: pillTint.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),

              // ——— Board (always visible) ———
              SizedBox(
                width: 360,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size.infinite,
                        painter: _GridPainter(
                          gridColor: Colors.white.withValues(alpha: 0.25),
                          stroke: 2.0,
                          outerStroke: 2.0,
                        ),
                      ),
                      GridView.builder(
                        itemCount: 9,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                        ),
                        itemBuilder: (_, i) {
                          final r = i ~/ 3, c = i % 3;
                          final v = state.board[i];
                          return InkWell(
                            onTap: () => _tap(r, c),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 120),
                                style: TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.w900,
                                  color: v == Player.o ? accentO : cs.primary,
                                ),
                                child: Text(v == null ? '' : (v == Player.x ? 'X' : 'O')),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ——— Buttons ———
              if (state.isComplete) ...[
                SizedBox(
                  width: 360,
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play Again'),
                          onPressed: _restart,
                          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('Back to Home'),
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: 360,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.undo),
                          label: const Text('Undo'),
                          onPressed: _undoTwo,
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Restart'),
                          onPressed: _restart,
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 360,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Stats'),
                    onPressed: _resetStats,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ------- grid painter -------
class _GridPainter extends CustomPainter {
  final Color gridColor;
  final double stroke;
  final double outerStroke;
  _GridPainter({required this.gridColor, required this.stroke, required this.outerStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final inner = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final outer = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerStroke;

    final w = size.width, h = size.height;
    final cw = w / 3, ch = h / 3;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), outer);
    canvas.drawLine(Offset(cw, 0), Offset(cw, h), inner);
    canvas.drawLine(Offset(cw * 2, 0), Offset(cw * 2, h), inner);
    canvas.drawLine(Offset(0, ch), Offset(w, ch), inner);
    canvas.drawLine(Offset(0, ch * 2), Offset(w, ch * 2), inner);
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.gridColor != gridColor || old.stroke != stroke || old.outerStroke != outerStroke;
}

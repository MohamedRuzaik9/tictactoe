import 'package:flutter/material.dart';
import '../core/ai.dart';
import '../core/game_logic.dart';
import '../core/game_models.dart';
import '../core/persistence.dart';

enum AIDifficulty { easy, medium, hard }

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
    if (!mounted || !isValidMove(state, r, c)) return;
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
        case AIDifficulty.easy:
          mv = easyMove(state);
          break;
        case AIDifficulty.medium:
          mv = medium.move(state);
          break;
        case AIDifficulty.hard:
          mv = hardMove(state);
          break;
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

  Widget _resultView({required String title, required Color? tint}) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          if (tint != null)
            Positioned.fill(
              child: ColoredBox(color: tint.withValues(alpha: 0.18)),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play Again'),
                        onPressed: _restart,
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Back to Home'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _undoTwo() {
    if (state.moveLog.length >= 2) {
      setState(() => state = undo(state));
      setState(() => state = undo(state));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentO = const Color(0xFF10B3E6);

    // Show results with tint backgrounds
    if (state.isComplete) {
      final winner = checkWinner(state);
      if (winner == Player.x) {
        return _resultView(title: 'YOU WIN!', tint: const Color(0xFF1B5E20)); // dark green
      } else if (winner == Player.o) {
        return _resultView(title: 'YOU LOSE!', tint: const Color(0xFFB71C1C)); // dark red
      } else {
        return _resultView(title: 'DRAW!', tint: null);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: null,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                // stats row
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 360,
                    child: Row(
                      children: [
                        _statCard('Wins', stats.wins, const Color(0xFF1B5E20)),
                        _statCard('Losses', stats.losses, const Color(0xFFB71C1C)),
                        _statCard('Draws', stats.draws, Colors.grey.shade700),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  'You are X · AI is O',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 16),

                // 3x3 grid
                SizedBox(
                  width: 320,
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
                                    fontSize: 58,
                                    fontWeight: FontWeight.w900,
                                    color: v == Player.o
                                        ? accentO
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                  child: Text(
                                      v == null ? '' : (v == Player.x ? 'X' : 'O')),
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

                // Buttons
                SizedBox(
                  width: 320,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.undo),
                          label: const Text('Undo'),
                          onPressed: _undoTwo,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Restart'),
                          onPressed: _restart,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 320,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Stats'),
                    onPressed: _resetStats,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        height: 88,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 1.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$value',
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color gridColor;
  final double stroke;
  final double outerStroke;
  _GridPainter({required this.gridColor, required this.stroke, required this.outerStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final o = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerStroke;

    final w = size.width, h = size.height;
    final cellW = w / 3, cellH = h / 3;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), o);
    canvas.drawLine(Offset(cellW, 0), Offset(cellW, h), p);
    canvas.drawLine(Offset(cellW * 2, 0), Offset(cellW * 2, h), p);
    canvas.drawLine(Offset(0, cellH), Offset(w, cellH), p);
    canvas.drawLine(Offset(0, cellH * 2), Offset(w, cellH * 2), p);
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.gridColor != gridColor ||
      old.stroke != stroke ||
      old.outerStroke != outerStroke;
}

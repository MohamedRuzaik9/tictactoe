import 'dart:math';

import 'game_logic.dart';
import 'game_models.dart';

final _rng = Random();

/// EASY: random legal move
List<int>? easyMove(GameState s) {
  final moves = legalMoves(s);
  if (moves.isEmpty) return null;
  return moves[_rng.nextInt(moves.length)];
}

/// MEDIUM: alternates between random and strategic (win/block/center/corner/random)
class MediumBrain {
  bool _lastRandom = false;
  List<int>? move(GameState s) {
    _lastRandom = !_lastRandom;
    return _lastRandom ? easyMove(s) : _greedyMove(s);
  }
}

/// HARD: follows strategy (win > block > center > corners > random)
List<int>? hardMove(GameState s) => _greedyMove(s);

List<int>? _greedyMove(GameState s) {
  // 1) winning move
  for (final m in legalMoves(s)) {
    final next = applyMove(s, m[0], m[1]);
    if (checkWinner(next) == s.current) return m;
  }
  // 2) block opponent
  for (final m in legalMoves(s)) {
    final opp = applyMove(s.copyWith(current: s.nextPlayer), m[0], m[1]);
    if (checkWinner(opp) == s.nextPlayer) return m;
  }
  // 3) center
  if (s.board[4] == null) return [1, 1];
  // 4) corners
  const corners = [0, 2, 6, 8];
  for (final i in corners) {
    if (s.board[i] == null) return [i ~/ 3, i % 3];
  }
  // 5) random
  return easyMove(s);
}

import 'package:flutter/foundation.dart';

/// Represents a player or an empty cell.
enum Player { x, o }

@immutable
class Move {
  final int row;
  final int col;
  final Player player;
  const Move({required this.row, required this.col, required this.player});
}

/// Overall immutable game state for testability.
@immutable
class GameState {
  final List<Player?> board; // 9 cells, null = empty
  final Player current;
  final List<Move> moveLog;
  final bool isComplete;

  const GameState({
    required this.board,
    required this.current,
    required this.moveLog,
    required this.isComplete,
  });

  factory GameState.initial({Player starting = Player.x}) => GameState(
        board: List<Player?>.filled(9, null),
        current: starting,
        moveLog: const [],
        isComplete: false,
      );

  GameState copyWith({
    List<Player?>? board,
    Player? current,
    List<Move>? moveLog,
    bool? isComplete,
  }) => GameState(
        board: board ?? this.board,
        current: current ?? this.current,
        moveLog: moveLog ?? this.moveLog,
        isComplete: isComplete ?? this.isComplete,
      );

  Player get nextPlayer => current == Player.x ? Player.o : Player.x;

  Player? cell(int r, int c) => board[r * 3 + c];
}

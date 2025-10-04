import 'game_models.dart';

bool isValidMove(GameState s, int r, int c) {
  if (s.isComplete) return false;
  if (r < 0 || r > 2 || c < 0 || c > 2) return false;
  return s.board[r * 3 + c] == null;
}

GameState applyMove(GameState s, int r, int c) {
  if (!isValidMove(s, r, c)) return s;
  final newBoard = List<Player?>.from(s.board);
  newBoard[r * 3 + c] = s.current;
  final newLog = List<Move>.from(s.moveLog)
    ..add(Move(row: r, col: c, player: s.current));
  final winner = checkWinnerBoard(newBoard);
  final draw = winner == null && newBoard.every((e) => e != null);
  return s.copyWith(
    board: newBoard,
    current: s.nextPlayer,
    moveLog: newLog,
    isComplete: winner != null || draw,
  );
}

/// Returns X or O if someone has won, otherwise null.
Player? checkWinner(GameState s) => checkWinnerBoard(s.board);

Player? checkWinnerBoard(List<Player?> b) {
  const lines = [
    // rows
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    // cols
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    // diags
    [0, 4, 8],
    [2, 4, 6],
  ];
  for (final L in lines) {
    final a = b[L[0]], c = b[L[1]], d = b[L[2]];
    if (a != null && a == c && c == d) return a;
  }
  return null;
}

bool isDraw(GameState s) =>
    checkWinner(s) == null && s.board.every((e) => e != null);

GameState undo(GameState s, {int steps = 1}) {
  var state = s;
  for (int i = 0; i < steps; i++) {
    if (state.moveLog.isEmpty) return state;
    final last = state.moveLog.last;
    final newBoard = List<Player?>.from(state.board);
    newBoard[last.row * 3 + last.col] = null;
    final newLog = List<Move>.from(state.moveLog)..removeLast();
    state = state.copyWith(
      board: newBoard,
      current: last.player, // revert turn
      moveLog: newLog,
      isComplete: false,
    );
  }
  return state;
}

List<List<int>> legalMoves(GameState s) {
  final out = <List<int>>[];
  for (int i = 0; i < 9; i++) {
    if (s.board[i] == null) out.add([i ~/ 3, i % 3]);
  }
  return out;
}

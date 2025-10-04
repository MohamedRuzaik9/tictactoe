import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe/core/game_logic.dart';
import 'package:tic_tac_toe/core/game_models.dart';

void main() {
  test('win detection rows/cols/diagonals', () {
    // Row win for X
    var s = GameState.initial();
    s = applyMove(s, 0, 0); // X
    s = applyMove(s, 1, 0); // O
    s = applyMove(s, 0, 1); // X
    s = applyMove(s, 1, 1); // O
    s = applyMove(s, 0, 2); // X wins
    expect(checkWinner(s), Player.x);

    // Column win for O
    s = GameState.initial();
    s = applyMove(s, 0, 1); // X
    s = applyMove(s, 0, 0); // O
    s = applyMove(s, 1, 1); // X
    s = applyMove(s, 1, 0); // O
    s = applyMove(s, 2, 2); // X
    s = applyMove(s, 2, 0); // O wins
    expect(checkWinner(s), Player.o);

    // Diagonal win
    s = GameState.initial();
    s = applyMove(s, 0, 0);
    s = applyMove(s, 0, 1);
    s = applyMove(s, 1, 1);
    s = applyMove(s, 0, 2);
    s = applyMove(s, 2, 2);
    expect(checkWinner(s), Player.x);
  });

  test('draw detection', () {
    var s = GameState.initial();
    // X O X / X X O / O X O => draw
    final moves = [
      [0,0],[0,1],[0,2],[1,0],[1,1],[1,2],[2,0],[2,1],[2,2]
    ];
    for (final m in moves) {
      s = applyMove(s, m[0], m[1]);
    }
    expect(checkWinner(s), isNull);
    expect(isDraw(s), isTrue);
  });

  test('undo reverts two moves correctly', () {
    var s = GameState.initial();
    s = applyMove(s, 0, 0); // X
    s = applyMove(s, 1, 1); // O
    s = applyMove(s, 0, 1); // X
    final before = s;
    s = undo(s); // undo last (X)
    s = undo(s); // undo (O)
    expect(s.board, isNot(equals(before.board)));
    expect(s.moveLog.length, 1);
    expect(s.current, Player.o);
  });
}

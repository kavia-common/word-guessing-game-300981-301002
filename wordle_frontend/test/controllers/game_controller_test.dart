import 'package:flutter_test/flutter_test.dart';
import 'package:wordle_frontend/controllers/game_controller.dart';
import 'package:wordle_frontend/models/tile_state.dart';

void main() {
  test('win flow marks complete and updates keyboard', () {
    final c = GameController();
    c.startNewGame(daily: false);
    // Force target to a known word by reading current state's target
    final target = c.state.targetWord;
    for (final ch in target.split('')) {
      c.inputLetter(ch);
    }
    c.submitGuess();
    expect(c.state.isComplete, true);
    expect(c.state.isWin, true);
    for (final ch in target.split('')) {
      expect(c.state.keyboardState[ch], TileState.correct);
    }
  });

  test('loss after 6 attempts', () {
    final c = GameController();
    c.startNewGame(daily: false);
    // Submit 6 times a valid but wrong word (ABOUT is valid)
    for (int i = 0; i < 6; i++) {
      for (final ch in 'ABOUT'.split('')) {
        c.inputLetter(ch);
      }
      c.submitGuess();
    }
    expect(c.state.isComplete, true);
  });
}

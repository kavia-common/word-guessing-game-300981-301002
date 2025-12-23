import 'package:flutter_test/flutter_test.dart';
import 'package:wordle_frontend/services/game_logic.dart';
import 'package:wordle_frontend/models/tile_state.dart';
import 'package:wordle_frontend/controllers/game_controller.dart';

void main() {
  group('evaluateGuess', () {
    test('all correct', () {
      final result = evaluateGuess('APPLE', 'APPLE');
      expect(result.every((e) => e == TileState.correct), true);
    });

    test('present and absent with duplicates', () {
      // target: PAPER, guess: PEACE
      final result = evaluateGuess('PEACE', 'PAPER');
      // P correct, E present (one E in target after removing matches), A correct, C absent, E absent (no more E left)
      expect(result[0], TileState.correct);
      expect(result[1], TileState.present);
      expect(result[2], TileState.correct);
      expect(result[3], TileState.absent);
      expect(result[4], TileState.absent);
    });

    test('invalid length throws', () {
      expect(() => evaluateGuess('CAT', 'APPLE'), throwsArgumentError);
    });
  });

  group('keyboard precedence', () {
    test('correct > present > absent', () {
      expect(keyboardPrecedence(TileState.correct) > keyboardPrecedence(TileState.present), true);
      expect(keyboardPrecedence(TileState.present) > keyboardPrecedence(TileState.absent), true);
    });
  });

  group('GameController flow', () {
    test('input and delete letters', () {
      final c = GameController();
      c.startNewGame(daily: false);
      c.inputLetter('a');
      c.inputLetter('b');
      c.inputLetter('1'); // ignored
      expect(c.state.currentInput, 'AB');
      c.deleteLetter();
      expect(c.state.currentInput, 'A');
    });

    test('submit invalid length shows banner', () {
      final c = GameController();
      c.startNewGame(daily: false);
      c.inputLetter('a');
      c.submitGuess();
      expect(c.bannerMessage, isNotNull);
    });

    test('submit valid guess consumes attempt', () {
      final c = GameController();
      c.startNewGame(daily: false);
      // ensure current input is valid regardless of target
      c.inputLetter('a');
      c.inputLetter('b');
      c.inputLetter('o');
      c.inputLetter('u');
      c.inputLetter('t'); // ABOUT is in valid list
      c.submitGuess();
      expect(c.state.guesses.length, 1);
      expect(c.state.attempt, 1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:wordle_frontend/models/tile_state.dart';
import 'package:wordle_frontend/services/game_logic.dart';

void main() {
  group('evaluateGuess algorithm', () {
    test('handles repeated letters correctly', () {
      // target "LEVEL", guess "LEMON"
      final result = evaluateGuess('LEMON', 'LEVEL');
      expect(result[0], TileState.correct); // L
      expect(result[1], TileState.correct); // E
      // M not in remaining -> absent
      expect(result[2], TileState.absent);
      // O absent
      expect(result[3], TileState.absent);
      // N absent
      expect(result[4], TileState.absent);
    });

    test('marks present when available', () {
      final result = evaluateGuess('ALLEY', 'APPLE');
      // A correct, L present, L absent (second L has no remaining), E present, Y absent
      expect(result[0], TileState.correct);
      expect(result[1], TileState.present);
      expect(result[2], TileState.absent);
      expect(result[3], TileState.present);
      expect(result[4], TileState.absent);
    });
  });

  test('selectTargetWord deterministic daily', () {
    final list = ['APPLE', 'BRAVE', 'CRANE'];
    final word1 = selectTargetWord(list, daily: true, date: DateTime(2024, 01, 01));
    final word2 = selectTargetWord(list, daily: true, date: DateTime(2024, 01, 01));
    expect(word1, word2);
  });
}

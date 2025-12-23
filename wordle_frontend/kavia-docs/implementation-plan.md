# Implementation Plan: Wordle Frontend (Flutter)

## Scope and Goals
The goal is to deliver a fully functional Wordle-style mobile app using Flutter for Android and iOS. The app enables users to guess a target five-letter word within a limited number of attempts, receiving feedback for each guess via tile coloring and an on-screen keyboard. The experience follows the Ocean Professional theme and adheres to modern, minimal UI with subtle gradients, rounded corners, and smooth transitions.

Primary goals:
- Implement core gameplay: daily/new game flow, fixed-length guess input, validation against dictionary, feedback coloring per tile, attempt limit handling, and win/loss resolution.
- Provide a responsive, accessible UI with a central board, feedback above guesses, and input at the bottom, styled according to the Ocean Professional theme.
- Include a stats modal, restart/new game controls, and local persistence for simple telemetry and game stats using shared_preferences.
- Ensure clean architecture, clear state management (Provider), modular code structure, and testable core logic.

Out of scope for this iteration:
- Online multiplayer or backend leaderboards.
- Account systems, auth, or cloud sync.
- Complex internationalization beyond basic strings.

## Assumptions
- The word length is five characters. The number of attempts is six (configurable).
- Words are validated against a local dictionary included in assets.
- The target word can be selected from a fixed list (daily or random mode). No server dependency.
- State persistence (e.g., ongoing game, stats) is stored locally using shared_preferences.
- Preview runs automatically; no steps to start it are required in this plan.
- No environment variables are required currently; .env exists but is not used for core gameplay.

## Architecture Overview
The app adopts a layered architecture:
- Presentation Layer (Flutter Widgets): Screens, board tiles, keyboard, dialogs. Theme and layout follow Ocean Professional guidelines.
- State Management: Provider for lightweight, reactive state with ChangeNotifier models. No context across async gaps per Flutter Async Context rules.
- Domain Layer: Pure Dart models and services for game rules, validation, and feedback computation.
- Data Layer: Local data providers for loading word lists and persisting stats/settings via shared_preferences.

State management choice: Provider
- Widely used, simple, and sufficient for app scale.
- Works well with ChangeNotifier and selectors for performance.
- Keeps UI reactive without complexity.

Navigation: Flutter Navigator 2.0 is unnecessary for this scope. Use MaterialApp with standard Navigator for single-stack navigation (Home/GameScreen, optional Settings/Stats modal via showModalBottomSheet or showDialog).

## Feature Breakdown
1) New Game
- Start a new session with a randomly selected target word or a daily seed-based word.
- Reset state: attempts, keyboard coloring, and board tiles.
- Optionally provide a “Restart” button and “New Game” if game finished.

2) Guess Input
- On-screen keyboard supports letters A-Z, backspace, and submit.
- The current guess row updates as users type; letters constrained to five characters.

3) Validation
- Reject guesses not in dictionary with a subtle animated toast/banner.
- Prevent duplicate submissions.
- Enforce expected word length.

4) Feedback Coloring
- For each guess, apply tile states: correct (green-like but per theme), present (amber), absent (neutral gray).
- Follow Wordle rules: handle multiple occurrences correctly (mark as present only up to occurrences in target).

5) Attempt Limits
- Six attempts to guess target word. After last attempt, show loss with reveal.

6) Win/Loss Flow
- On win: Show celebratory animation, reveal stats modal, allow new game.
- On loss: Show target word and allow retry.

7) Keyboard
- Reflect letter states across attempts; keys color-coded to the best-known state (correct supersedes present supersedes absent).
- Smooth transitions when keys update.

8) Stats Modal
- Track games played, win rate, current streak, max streak, guess distribution (histogram of attempts).
- Show modal from app bar icon or on game end. Stored with shared_preferences.

9) Restart
- Confirm before overriding a game in progress. Clear current game state and start fresh.

## UI/UX Plan (Ocean Professional Theme)
Theme and Style:
- Colors: primary #2563EB (blue), secondary/success #F59E0B (amber), error #EF4444, background #f9fafb, surface #ffffff, text #111827.
- Gradients: subtle background gradient “from-blue-500/10 to-gray-50” effect using linear gradients with low alpha.
- Modern minimalist: rounded corners (8–16px), subtle elevation/shadows, smooth transitions for tile flips and keyboard presses.
- Typography: Use Material 3 defaults; emphasize titles with medium weight, ensure legibility.

Layout:
- Central board: 6 rows x 5 columns grid, centered in available space.
- Feedback: Tile flip animation on submit; an inline message area above the board for validation feedback (e.g., “Not in word list”).
- Input: On-screen keyboard docked at bottom, three rows (QWERTY layout), with Enter and Backspace keys enlarged.
- Top AppBar: Title, icons for stats and restart.
- Stats Modal: Bottom sheet or dialog with card-like sections and subtle gradient header.

Animation:
- Tile flip on evaluation.
- Button press ripple and slight scale.
- Smooth color transitions for keys and tiles.

Accessibility:
- Sufficient color contrast (adjust shades if needed).
- Semantic labels for buttons and keys.
- Larger tap targets (min 44x44).
- Haptic feedback on key press if available.

## Data Model
- enum TileState { empty, filled, correct, present, absent }
- class Guess
  - final String word; // up to 5 characters
  - final List<TileState> feedback; // length 5, reflects per-letter evaluation
- class GameState
  - String targetWord;
  - int attempt; // 0..5
  - List<Guess> guesses; // up to 6
  - String currentInput; // up to 5 chars
  - bool isComplete;
  - bool isWin;
  - Map<String, TileState> keyboardState; // per letter
  - DateTime? startedAt;
  - DateTime? completedAt;
- class Stats
  - int gamesPlayed;
  - int gamesWon;
  - int currentStreak;
  - int maxStreak;
  - List<int> guessDistribution; // index 0..5

## State Management Approach and Navigation
- Provider setup in main.dart:
  - ChangeNotifierProvider<GameController> at root.
  - Optional ChangeNotifierProvider<ThemeController> if needed for dark/light toggles later.
- GameController (ChangeNotifier):
  - Holds GameState, exposes actions: startNewGame, inputLetter, deleteLetter, submitGuess.
  - Side effects: load words, choose target, compute feedback, update stats, and persist state.
  - No widget/context calls after await in any method. Async methods modify only primitive state or model values and then notifyListeners.

Navigation:
- Single screen (GameScreen) as home. Stats opens in a modal sheet/dialog. Future enhancements can add separate screens.

## Core Algorithms
Word Selection:
- Random selection: seeded with date for daily mode or true random for “New Game.”
- Source lists: assets/words/target_words.txt (allowed answers) and assets/words/valid_words.txt (valid guesses).

Validation:
- currentInput length must equal 5.
- Must exist in combined valid words set. If not, show validation message.

Feedback Coloring Rules:
- Use a two-pass algorithm:
  1) Mark correct positions and count letter frequencies of target minus correctly matched letters.
  2) For remaining letters, mark present if frequency > 0 and decrement; else absent.

Keyboard State Updates:
- For each evaluated letter: upgrade state in keyboardState only if the new state is “higher” in precedence:
  - correct > present > absent.
- Preserve best-known information across attempts.

Pseudocode (feedback):
```dart
List<TileState> evaluateGuess(String guess, String target) {
  final result = List<TileState>.filled(5, TileState.absent);
  final targetChars = target.split('');
  final guessChars = guess.split('');
  final counts = <String, int>{};

  // First pass: correct positions
  for (int i = 0; i < 5; i++) {
    if (guessChars[i] == targetChars[i]) {
      result[i] = TileState.correct;
    } else {
      counts[targetChars[i]] = (counts[targetChars[i]] ?? 0) + 1;
    }
  }

  // Second pass: present vs absent
  for (int i = 0; i < 5; i++) {
    if (result[i] == TileState.correct) continue;
    final ch = guessChars[i];
    final available = counts[ch] ?? 0;
    if (available > 0) {
      result[i] = TileState.present;
      counts[ch] = available - 1;
    } else {
      result[i] = TileState.absent;
    }
  }
  return result;
}
```

## File/Module Structure Proposal
- lib/
  - main.dart
  - theme/
    - app_theme.dart
  - models/
    - game_state.dart
    - guess.dart
    - tile_state.dart
    - stats.dart
  - services/
    - word_repository.dart // load word lists from assets
    - stats_service.dart // read/write from shared_preferences
    - game_logic.dart // pure functions for evaluation and selection
  - controllers/
    - game_controller.dart // ChangeNotifier: orchestrates flow and state updates
  - widgets/
    - game_board.dart
    - tile.dart
    - keyboard.dart
    - feedback_banner.dart
    - stats_modal.dart
  - screens/
    - game_screen.dart
- assets/
  - words/
    - target_words.txt
    - valid_words.txt

Test structure:
- test/
  - services/
    - game_logic_test.dart // evaluateGuess correctness, keyboard precedence
  - controllers/
    - game_controller_test.dart // flow simulation tests

## Accessibility and Responsiveness
- Use LayoutBuilder/MediaQuery to size tiles and keyboard for various device widths.
- Ensure minimum tap target size and adequate spacing.
- Provide semantics labels for keys and tiles (e.g., “Letter A, state correct”).
- Support larger text scales without breaking layout; constrain and scale tiles proportionally.

## Error Handling and Edge Cases
- Asset loading failures: Show a non-blocking error banner and fallback to a small embedded list to keep app usable.
- Invalid input: Show brief inline feedback; do not block typing unless at max length.
- Duplicate guess: Show “Already guessed” message.
- Multiple occurrences handling: Ensure feedback coloring follows rules even for repeated letters.
- Persistence errors: Fail gracefully, continue without stats update.
- Orientation changes: Recompute sizes; state preserved in controller.

## Analytics/Telemetry Placeholders
- Define an AnalyticsService interface with no-op methods for this iteration:
  - onGameStart(), onGuessSubmitted(len, isValid), onGameEnd(isWin, attempts).
- Later, this can be wired to Firebase Analytics or a privacy-aware local log. Keep off by default.

## Build and Preview Notes
- The preview runs automatically on port 3000. No manual start steps are required here.
- Follow lints in analysis_options.yaml and Effective Dart conventions.
- Ensure all dependencies exist in pubspec.yaml before usage and use full package imports.

## Milestones with Estimates
1) Project Setup and Theme (0.5 day)
- Create theme with Ocean Professional palette, baseline typography, gradients, and shadows.
- Scaffold GameScreen with app bar and containers.

2) Models and Logic (0.5 day)
- Implement TileState, Guess, GameState, Stats.
- Implement evaluateGuess, keyboard precedence logic, word selection.

3) Services and Data (0.5 day)
- WordRepository to load assets.
- StatsService with shared_preferences including schema and migration safety.

4) State Management (0.5 day)
- GameController with Provider wiring, actions (start, input, delete, submit).
- Primitive-only async updates and notifyListeners patterns.

5) UI Components (1.5 days)
- Game board, tiles with flip animation, keyboard with press animations.
- Feedback banner, stats modal, restart confirmation.

6) Validation and Error Handling (0.5 day)
- Enforce rules, shows messages, handle edge cases.

7) Persistence and Stats (0.5 day)
- Persist current game and stats. Restore on app launch.

8) Testing and Polish (0.5 day)
- Unit tests for game_logic and controller flow.
- Accessibility checks, subtle transitions, performance pass.

Total: ~5.5 days

## Risks and Mitigations
- Risk: Complex letter occurrence logic causes incorrect feedback.
  - Mitigation: Comprehensive unit tests covering repeated letters scenarios.
- Risk: Layout breaks on small screens or large text.
  - Mitigation: Responsive sizes via LayoutBuilder; clamp min/max tile sizes and keyboard scaling.
- Risk: State misuse across async gaps.
  - Mitigation: Adhere strictly to Flutter Async Context rules. Update only primitives in async and notify; UI reacts in build.
- Risk: Asset loading failure.
  - Mitigation: Embed minimal fallback word list in code; surface a banner.

## Next Steps Checklist
- [ ] Add kavia-docs plan to repository (this file).
- [ ] Create theme file and define ColorScheme using withAlpha for transparency.
- [ ] Implement models: TileState, Guess, GameState, Stats.
- [ ] Implement services: WordRepository (load assets), StatsService (shared_preferences).
- [ ] Implement game_logic (evaluateGuess, selectTargetWord).
- [ ] Implement GameController with Provider wiring in main.dart.
- [ ] Build UI: GameScreen, board/tiles, keyboard, feedback banner, stats modal.
- [ ] Wire interactions: input, delete, submit, feedback, keyboard coloring.
- [ ] Persist and restore game state and stats.
- [ ] Add unit tests for logic and controller.
- [ ] Polish animations, accessibility labels, and responsiveness.
- [ ] QA pass and finalize.

## Sources
- Existing project structure and dependencies from:
  - lib/main.dart
  - pubspec.yaml
  - analysis_options.yaml
  - test/widget_test.dart
- This plan aligns with the “Ocean Professional” theme data defined in the work item.

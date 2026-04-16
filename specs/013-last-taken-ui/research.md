# Phase 0: Research

## Relative Time Formatting
- **Decision:** Implement a custom relative time formatting extension using Dart's `DateTime` and `intl` for localization.
- **Rationale:** The application relies on `intl` for English and Arabic translations. Adding a heavy package like `timeago` just for "2 hours ago" strings adds unnecessary bundle size overhead. A custom extension method on `DateTime` can accurately measure the difference (`DateTime.now().difference(takenAt)`) and leverage the `intl` package context for the translated labels (e.g. "Just now", "{minutes} minutes ago", "{hours} hours ago").
- **Alternatives considered:** Using the `timeago` package (rejected due to added dependency size for a single screen requirement).

## Text Overflow Handling
- **Decision:** Utilize Flutter's intrinsic multi-line text wrapping for medication names and doses.
- **Rationale:** Spec FR-006 clearly outlines avoiding truncation, requiring UI to scale dynamic list-item height. Using standard `Text()` widgets with `maxLines: null` or sufficiently large bounds within a `Column` natively achieves this in Flutter without clipping.
- **Alternatives considered:** Truncating text and showing a dialog (rejected because it adds an unnecessary step for the user).

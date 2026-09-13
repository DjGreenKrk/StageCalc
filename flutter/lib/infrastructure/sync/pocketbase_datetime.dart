/// Shared date formatting for every PocketBase sync service, so local and
/// remote timestamps compare correctly (ADR-026's "last write wins" only
/// works if both sides serialize the same instant the same way).
library;

/// PocketBase date fields want UTC ISO-8601; local timestamps are otherwise
/// stored as local time throughout the app (see `DateTime.now()` call sites),
/// so every push must convert explicitly.
String toRemoteIso(DateTime value) => value.toUtc().toIso8601String();

/// Parses a PocketBase date field back into local time, matching how every
/// other locally-created row's timestamp is represented. Empty string (an
/// unset PocketBase date field, not null) parses to `null`, and `null`
/// itself is passed through so nullable fields do not need a separate check
/// at every call site.
DateTime? fromRemoteIso(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.parse(value).toLocal();
}

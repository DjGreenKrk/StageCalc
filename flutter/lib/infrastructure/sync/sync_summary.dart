/// Result of reconciling one collection (or the whole run) against
/// PocketBase: how many records were copied in each direction, and whether
/// anything failed. See `docs/DECISIONS.md` ADR-026.
class SyncSummary {
  const SyncSummary({
    this.pushed = 0,
    this.pulled = 0,
    this.unchanged = 0,
    this.errors = const [],
  });

  final int pushed;
  final int pulled;
  final int unchanged;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;

  SyncSummary operator +(SyncSummary other) {
    return SyncSummary(
      pushed: pushed + other.pushed,
      pulled: pulled + other.pulled,
      unchanged: unchanged + other.unchanged,
      errors: [...errors, ...other.errors],
    );
  }

  @override
  String toString() =>
      'SyncSummary(pushed: $pushed, pulled: $pulled, unchanged: $unchanged, '
      'errors: ${errors.length})';
}

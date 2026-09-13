import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/infrastructure/sync/sync_direction.dart';

void main() {
  final earlier = DateTime(2026, 1, 1);
  final later = DateTime(2026, 1, 2);

  test('pulls when the record only exists remotely', () {
    expect(
      decideSyncDirection(localUpdatedAt: null, remoteUpdatedAt: later),
      SyncDirection.pull,
    );
  });

  test('pushes when the record only exists locally', () {
    expect(
      decideSyncDirection(localUpdatedAt: later, remoteUpdatedAt: null),
      SyncDirection.push,
    );
  });

  test('does nothing when the record exists on neither side', () {
    expect(
      decideSyncDirection(localUpdatedAt: null, remoteUpdatedAt: null),
      SyncDirection.none,
    );
  });

  test('pushes the newer local edit over an older remote one', () {
    expect(
      decideSyncDirection(localUpdatedAt: later, remoteUpdatedAt: earlier),
      SyncDirection.push,
    );
  });

  test('pulls the newer remote edit over an older local one', () {
    expect(
      decideSyncDirection(localUpdatedAt: earlier, remoteUpdatedAt: later),
      SyncDirection.pull,
    );
  });

  test('does nothing when both sides already agree', () {
    expect(
      decideSyncDirection(localUpdatedAt: later, remoteUpdatedAt: later),
      SyncDirection.none,
    );
  });
}

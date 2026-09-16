import '../domain/entities/catalog_device.dart';
import '../domain/services/catalog_duplicate_detector.dart';

abstract interface class CatalogRepository {
  Future<List<CatalogDevice>> getDevices();

  Future<void> saveDevice(CatalogDevice device);

  Future<void> deleteDevice(String id);

  /// Likely-duplicate device pairs (`CatalogDuplicateDetector`, ADR-038),
  /// excluding any pair the user already dismissed via
  /// [dismissDuplicatePair].
  Future<List<CatalogDuplicatePair>> getPossibleDuplicates();

  /// Records that a pair is not a duplicate, so [getPossibleDuplicates]
  /// stops surfacing it. Local-only, not synced - see
  /// `DismissedDuplicatePairs`.
  Future<void> dismissDuplicatePair(String deviceIdA, String deviceIdB);
}

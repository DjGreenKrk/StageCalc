import '../../../catalog/domain/entities/catalog_device.dart';
import '../entities/gremium_pack_list.dart';

enum GremiumMatchStatus { linked, newDevice, ownItem }

/// Result of matching one [GremiumItem] against the current catalog, before
/// the user has made any selection in the review panel (ADR-034).
class GremiumMatchResult {
  const GremiumMatchResult({
    required this.item,
    required this.status,
    this.matchedDevice,
  });

  final GremiumItem item;
  final GremiumMatchStatus status;

  /// Set only when [status] is [GremiumMatchStatus.linked].
  final CatalogDevice? matchedDevice;
}

/// Matches Gremium items to the existing catalog purely by a previously
/// saved `gremiumInventoryItemId` (ADR-034) - never guesses by name, per
/// Import_details.md's explicit requirement. Read-only: does not save
/// anything.
class GremiumCatalogMatcher {
  const GremiumCatalogMatcher._();

  static List<GremiumMatchResult> match(
    List<GremiumItem> items,
    List<CatalogDevice> catalogDevices,
  ) {
    return items.map((item) => _matchItem(item, catalogDevices)).toList();
  }

  static GremiumMatchResult _matchItem(
    GremiumItem item,
    List<CatalogDevice> catalogDevices,
  ) {
    final inventoryItemId = item.inventoryItemId;
    if (inventoryItemId == null) {
      return GremiumMatchResult(item: item, status: GremiumMatchStatus.ownItem);
    }

    for (final device in catalogDevices) {
      if (device.gremiumInventoryItemId == inventoryItemId) {
        return GremiumMatchResult(
          item: item,
          status: GremiumMatchStatus.linked,
          matchedDevice: device,
        );
      }
    }

    return GremiumMatchResult(item: item, status: GremiumMatchStatus.newDevice);
  }
}

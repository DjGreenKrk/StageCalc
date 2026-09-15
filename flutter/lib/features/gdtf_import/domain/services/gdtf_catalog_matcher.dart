import '../../../catalog/domain/entities/catalog_device.dart';
import '../entities/gdtf_fixture_type.dart';

enum GdtfMatchStatus { linked, newDevice }

class GdtfMatchResult {
  const GdtfMatchResult({
    required this.fixture,
    required this.status,
    this.matchedDevice,
  });

  final GdtfFixtureType fixture;
  final GdtfMatchStatus status;

  /// Set only when [status] is [GdtfMatchStatus.linked].
  final CatalogDevice? matchedDevice;
}

/// Matches parsed GDTF fixtures against the existing catalog purely by
/// `CatalogDevice.gdtfFixtureTypeId == GdtfFixtureType.fixtureTypeId` - never
/// by name, mirroring `GremiumCatalogMatcher` (ADR-034). Unlike Gremium,
/// there is no "own item, not backed by a catalog entry" status: a GDTF file
/// always describes a catalog device.
class GdtfCatalogMatcher {
  const GdtfCatalogMatcher._();

  static List<GdtfMatchResult> match(
    List<GdtfFixtureType> fixtures,
    List<CatalogDevice> catalogDevices,
  ) {
    return fixtures
        .map((fixture) => _matchOne(fixture, catalogDevices))
        .toList(growable: false);
  }

  static GdtfMatchResult _matchOne(
    GdtfFixtureType fixture,
    List<CatalogDevice> catalogDevices,
  ) {
    for (final device in catalogDevices) {
      if (device.gdtfFixtureTypeId == fixture.fixtureTypeId) {
        return GdtfMatchResult(
          fixture: fixture,
          status: GdtfMatchStatus.linked,
          matchedDevice: device,
        );
      }
    }
    return GdtfMatchResult(fixture: fixture, status: GdtfMatchStatus.newDevice);
  }
}

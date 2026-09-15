import '../../../catalog/data/catalog_repository.dart';
import '../../../catalog/domain/entities/catalog_device.dart';
import '../entities/gdtf_category_guess.dart';
import '../entities/gdtf_fixture_type.dart';
import 'gdtf_connector_mapper.dart';

enum GdtfImportAction { useCatalogDevice, createNewDevice }

class GdtfImportDecision {
  const GdtfImportDecision({
    required this.fixture,
    required this.action,
    this.existingDeviceId,
    this.linkExistingDevice = false,
    this.category,
  });

  final GdtfFixtureType fixture;
  final GdtfImportAction action;

  /// Required for [GdtfImportAction.useCatalogDevice].
  final String? existingDeviceId;

  /// `true` only for a manual "Połącz z istniejącym" link made in the
  /// review panel - stamps `gdtfFixtureTypeId` onto the existing device.
  /// `false` means the row was already linked before the panel opened, so
  /// committing it is a pure no-op (never overwrite a device the user may
  /// have hand-edited since the first import, ADR-035).
  final bool linkExistingDevice;

  /// Required for [GdtfImportAction.createNewDevice].
  final CatalogDeviceCategory? category;
}

class GdtfImportSummary {
  const GdtfImportSummary({
    required this.createdDeviceCount,
    required this.linkedDeviceCount,
    required this.alreadyLinkedCount,
  });

  final int createdDeviceCount;

  /// Newly, manually linked to an existing device in this run.
  final int linkedDeviceCount;

  /// Rows that were already linked before the panel opened - left
  /// untouched.
  final int alreadyLinkedCount;
}

/// Commits reviewed GDTF import decisions to the catalog (ADR-035).
/// Catalog-only: unlike `GremiumImportCommitService`, there is no
/// project/group half here, since a GDTF file has no project concept at
/// all - it only ever describes a catalog device.
class GdtfImportCommitService {
  const GdtfImportCommitService({required this.catalogRepository});

  final CatalogRepository catalogRepository;

  static const _voltageV = 230.0;

  Future<GdtfImportSummary> commit(List<GdtfImportDecision> decisions) async {
    final now = DateTime.now();
    var created = 0;
    var linked = 0;
    var alreadyLinked = 0;

    for (final (index, decision) in decisions.indexed) {
      switch (decision.action) {
        case GdtfImportAction.useCatalogDevice:
          if (!decision.linkExistingDevice) {
            alreadyLinked++;
            continue;
          }
          final devices = await catalogRepository.getDevices();
          final existingDevice = devices.firstWhere(
            (device) => device.id == decision.existingDeviceId,
            orElse: () => throw StateError(
              'Nie znaleziono urządzenia katalogowego do połączenia '
              '(${decision.existingDeviceId}).',
            ),
          );
          await catalogRepository.saveDevice(
            existingDevice.copyWith(
              gdtfFixtureTypeId: decision.fixture.fixtureTypeId,
              updatedAt: now,
            ),
          );
          linked++;
        case GdtfImportAction.createNewDevice:
          final fixture = decision.fixture;
          final category = decision.category ?? guessGdtfCategory(fixture);
          final powerW = category.showsElectricalFields
              ? (fixture.powerW ?? 0)
              : 0.0;
          final currentA =
              category.showsElectricalFields && fixture.powerW != null
              ? fixture.powerW! / _voltageV
              : 0.0;

          final device = CatalogDevice(
            id: 'catalog_${now.microsecondsSinceEpoch}_$index',
            name: fixture.name,
            manufacturer: fixture.manufacturer,
            category: category,
            powerW: powerW,
            currentA: currentA,
            weightKg: fixture.weightKg,
            connectorTypeIds: GdtfConnectorMapper.mapAll(
              fixture.rawConnectorTypes,
            ),
            quantityUnit: CatalogQuantityUnit.pcs,
            createdAt: now,
            updatedAt: now,
            gdtfFixtureTypeId: fixture.fixtureTypeId,
          );
          await catalogRepository.saveDevice(device);
          created++;
      }
    }

    return GdtfImportSummary(
      createdDeviceCount: created,
      linkedDeviceCount: linked,
      alreadyLinkedCount: alreadyLinked,
    );
  }
}

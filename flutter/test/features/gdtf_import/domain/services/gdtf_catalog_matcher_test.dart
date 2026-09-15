import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';
import 'package:stagecalc/features/gdtf_import/domain/entities/gdtf_fixture_type.dart';
import 'package:stagecalc/features/gdtf_import/domain/services/gdtf_catalog_matcher.dart';

void main() {
  CatalogDevice device({
    required String id,
    required String name,
    String? gdtfFixtureTypeId,
  }) {
    final now = DateTime.now();
    return CatalogDevice(
      id: id,
      name: name,
      quantityUnit: CatalogQuantityUnit.pcs,
      createdAt: now,
      updatedAt: now,
      gdtfFixtureTypeId: gdtfFixtureTypeId,
    );
  }

  const fixture = GdtfFixtureType(
    fixtureTypeId: 'guid-1',
    name: 'Robin Painte',
    sourceFileName: 'robe@robin-painte.gdtf',
  );

  test('matches an existing device by gdtfFixtureTypeId', () {
    final linkedDevice = device(
      id: 'd1',
      name: 'Robin Painte',
      gdtfFixtureTypeId: 'guid-1',
    );

    final results = GdtfCatalogMatcher.match([fixture], [linkedDevice]);

    expect(results.single.status, GdtfMatchStatus.linked);
    expect(results.single.matchedDevice, linkedDevice);
  });

  test('never matches by name alone', () {
    // Same name, no matching (or any) gdtfFixtureTypeId - must not link.
    final sameNameDevice = device(id: 'd1', name: 'Robin Painte');
    final differentIdDevice = device(
      id: 'd2',
      name: 'Robin Painte',
      gdtfFixtureTypeId: 'some-other-guid',
    );

    final results = GdtfCatalogMatcher.match(
      [fixture],
      [sameNameDevice, differentIdDevice],
    );

    expect(results.single.status, GdtfMatchStatus.newDevice);
    expect(results.single.matchedDevice, isNull);
  });

  test('reports newDevice when the catalog is empty', () {
    final results = GdtfCatalogMatcher.match([fixture], const []);
    expect(results.single.status, GdtfMatchStatus.newDevice);
  });
}

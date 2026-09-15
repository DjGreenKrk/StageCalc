import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';
import 'package:stagecalc/features/gdtf_import/domain/entities/gdtf_category_guess.dart';
import 'package:stagecalc/features/gdtf_import/domain/entities/gdtf_fixture_type.dart';

void main() {
  const lightingFixture = GdtfFixtureType(
    fixtureTypeId: 'guid-1',
    name: 'Robin Painte',
    sourceFileName: 'robe@robin-painte.gdtf',
  );

  const mediaServerFixture = GdtfFixtureType(
    fixtureTypeId: 'guid-2',
    name: 'Media Server',
    sourceFileName: 'media-server.gdtf',
    hasMediaServerGeometry: true,
  );

  test('defaults to lighting when there is no media server geometry', () {
    expect(guessGdtfCategory(lightingFixture), CatalogDeviceCategory.lighting);
  });

  test(
    'guesses multimedia only when a media server geometry node is present',
    () {
      expect(
        guessGdtfCategory(mediaServerFixture),
        CatalogDeviceCategory.multimedia,
      );
    },
  );

  test('never guesses sound/distribution/cable/rigging/other', () {
    for (final fixture in [lightingFixture, mediaServerFixture]) {
      expect(
        guessGdtfCategory(fixture),
        isIn([
          CatalogDeviceCategory.lighting,
          CatalogDeviceCategory.multimedia,
        ]),
      );
    }
  });
}

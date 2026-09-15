import '../../../catalog/domain/entities/catalog_device.dart';
import 'gdtf_fixture_type.dart';

/// Guesses a [CatalogDeviceCategory] for a parsed GDTF fixture. Deliberately
/// trivial (ADR-035): GDTF has no formal "fixture category" field at all -
/// the whole specification only ever describes lighting/media equipment, so
/// unlike the free-text guessing needed for the Gremium import (ADR-034),
/// there is no meaningful heuristic across the other five
/// [CatalogDeviceCategory] values. Always overridable by the user in the
/// review panel.
CatalogDeviceCategory guessGdtfCategory(GdtfFixtureType fixture) {
  return fixture.hasMediaServerGeometry
      ? CatalogDeviceCategory.multimedia
      : CatalogDeviceCategory.lighting;
}

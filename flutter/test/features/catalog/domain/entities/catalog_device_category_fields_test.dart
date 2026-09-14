import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';

void main() {
  test('only rigging and cable hide electrical fields', () {
    for (final category in CatalogDeviceCategory.values) {
      final expected =
          category != CatalogDeviceCategory.rigging &&
          category != CatalogDeviceCategory.cable;
      expect(category.showsElectricalFields, expected, reason: category.name);
    }
  });

  test('only rigging and cable hide rigging points', () {
    for (final category in CatalogDeviceCategory.values) {
      final expected =
          category != CatalogDeviceCategory.rigging &&
          category != CatalogDeviceCategory.cable;
      expect(category.showsRiggingPoints, expected, reason: category.name);
    }
  });

  test('every category has a non-empty label', () {
    for (final category in CatalogDeviceCategory.values) {
      expect(category.label, isNotEmpty, reason: category.name);
    }
  });
}

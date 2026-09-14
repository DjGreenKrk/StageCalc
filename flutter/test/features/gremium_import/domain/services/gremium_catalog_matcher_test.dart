import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';
import 'package:stagecalc/features/gremium_import/domain/entities/gremium_pack_list.dart';
import 'package:stagecalc/features/gremium_import/domain/services/gremium_catalog_matcher.dart';

void main() {
  final now = DateTime(2026, 9, 14);

  test('matches an item already linked by gremiumInventoryItemId', () {
    final device = CatalogDevice(
      id: 'device_1',
      name: 'DNA Pole One',
      quantityUnit: CatalogQuantityUnit.pcs,
      createdAt: now,
      updatedAt: now,
      gremiumInventoryItemId: 'inv-1',
    );
    const item = GremiumItem(
      lineId: 'line-1',
      inventoryItemId: 'inv-1',
      name: 'DNA Pole One',
      quantity: 1,
    );

    final results = GremiumCatalogMatcher.match([item], [device]);

    expect(results.single.status, GremiumMatchStatus.linked);
    expect(results.single.matchedDevice, device);
  });

  test('treats an item with no matching link as a new device', () {
    const item = GremiumItem(
      lineId: 'line-1',
      inventoryItemId: 'inv-unknown',
      name: 'Nieznana lampa',
      quantity: 1,
    );

    final results = GremiumCatalogMatcher.match([item], const []);

    expect(results.single.status, GremiumMatchStatus.newDevice);
    expect(results.single.matchedDevice, isNull);
  });

  test('never guesses a match by name alone', () {
    final device = CatalogDevice(
      id: 'device_1',
      name: 'Nieznana lampa',
      quantityUnit: CatalogQuantityUnit.pcs,
      createdAt: now,
      updatedAt: now,
    );
    const item = GremiumItem(
      lineId: 'line-1',
      inventoryItemId: 'inv-1',
      name: 'Nieznana lampa',
      quantity: 1,
    );

    final results = GremiumCatalogMatcher.match([item], [device]);

    expect(results.single.status, GremiumMatchStatus.newDevice);
  });

  test('treats an item with no inventoryItemId as an own/custom item', () {
    const item = GremiumItem(
      lineId: 'line-1',
      name: 'Rozdzielnia zapewniana przez podwykonawcę',
      quantity: 1,
    );

    final results = GremiumCatalogMatcher.match([item], const []);

    expect(results.single.status, GremiumMatchStatus.ownItem);
  });
}

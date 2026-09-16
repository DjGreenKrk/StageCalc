import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';
import 'package:stagecalc/features/catalog/domain/services/catalog_duplicate_detector.dart';

CatalogDevice _device({
  required String id,
  required String name,
  CatalogDeviceCategory category = CatalogDeviceCategory.lighting,
}) {
  final now = DateTime(2026, 1, 1);
  return CatalogDevice(
    id: id,
    name: name,
    category: category,
    quantityUnit: CatalogQuantityUnit.pcs,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('flags devices with identical names in the same category', () {
    final devices = [
      _device(id: 'a', name: 'Robe Pointe'),
      _device(id: 'b', name: 'Robe Pointe'),
    ];

    final pairs = CatalogDuplicateDetector.findPairs(devices);

    expect(pairs, hasLength(1));
    expect(pairs.single.similarity, 1.0);
  });

  test('is case- and punctuation-insensitive via normalization', () {
    final devices = [
      _device(id: 'a', name: 'Robe Pointe'),
      _device(id: 'b', name: 'robe-pointe'),
    ];

    final pairs = CatalogDuplicateDetector.findPairs(devices);

    expect(pairs, hasLength(1));
    expect(pairs.single.similarity, 1.0);
  });

  test('never pairs devices from different categories', () {
    final devices = [
      _device(
        id: 'a',
        name: 'Robe Pointe',
        category: CatalogDeviceCategory.lighting,
      ),
      _device(
        id: 'b',
        name: 'Robe Pointe',
        category: CatalogDeviceCategory.rigging,
      ),
    ];

    expect(CatalogDuplicateDetector.findPairs(devices), isEmpty);
  });

  test('does not flag clearly different names', () {
    final devices = [
      _device(id: 'a', name: 'Robe Pointe'),
      _device(id: 'b', name: 'LED Par RGBW'),
    ];

    expect(CatalogDuplicateDetector.findPairs(devices), isEmpty);
  });

  test('respects a custom threshold', () {
    final devices = [
      _device(id: 'a', name: 'Robe Pointe'),
      _device(id: 'b', name: 'Robe Pointe XL'),
    ];

    expect(
      CatalogDuplicateDetector.findPairs(devices, threshold: 0.99),
      isEmpty,
    );
    expect(
      CatalogDuplicateDetector.findPairs(devices, threshold: 0.5),
      hasLength(1),
    );
  });

  test('pairKey is order-independent', () {
    expect(
      CatalogDuplicateDetector.pairKey('a', 'b'),
      CatalogDuplicateDetector.pairKey('b', 'a'),
    );
  });
}

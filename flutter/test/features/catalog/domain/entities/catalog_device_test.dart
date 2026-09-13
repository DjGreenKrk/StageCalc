import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';

void main() {
  group('CatalogConnectorTypeJson.fromJson', () {
    test('matches an exact enum name', () {
      expect(
        CatalogConnectorTypeJson.fromJson('xlr5'),
        CatalogConnectorType.xlr5,
      );
    });

    test('matches legacy free-text values via normalized aliases', () {
      expect(
        CatalogConnectorTypeJson.fromJson('powercon_true1'),
        CatalogConnectorType.powerConTrue1,
      );
      expect(
        CatalogConnectorTypeJson.fromJson('cee_32a_5p'),
        CatalogConnectorType.cee32a5p,
      );
      expect(
        CatalogConnectorTypeJson.fromJson('XLR5'),
        CatalogConnectorType.xlr5,
      );
      expect(
        CatalogConnectorTypeJson.fromJson('RJ45'),
        CatalogConnectorType.etherCon,
      );
    });

    test('returns null instead of guessing for an unrecognized value', () {
      expect(CatalogConnectorTypeJson.fromJson('totally_unknown_plug'), isNull);
      expect(CatalogConnectorTypeJson.fromJson(null), isNull);
    });
  });

  group('CatalogConnectorTypeJson.decodeStoredList', () {
    test('decodes a JSON-encoded array (current storage format)', () {
      expect(CatalogConnectorTypeJson.decodeStoredList('["powerCon","xlr5"]'), [
        CatalogConnectorType.powerCon,
        CatalogConnectorType.xlr5,
      ]);
    });

    test('treats a bare legacy string as a one-item list', () {
      expect(CatalogConnectorTypeJson.decodeStoredList('powercon_true1'), [
        CatalogConnectorType.powerConTrue1,
      ]);
    });

    test('drops unrecognized entries instead of failing the whole list', () {
      expect(CatalogConnectorTypeJson.decodeStoredList('["xlr5","???"]'), [
        CatalogConnectorType.xlr5,
      ]);
    });

    test('returns an empty list for null or blank input', () {
      expect(CatalogConnectorTypeJson.decodeStoredList(null), isEmpty);
      expect(CatalogConnectorTypeJson.decodeStoredList(''), isEmpty);
      expect(CatalogConnectorTypeJson.decodeStoredList('[]'), isEmpty);
    });

    test('round-trips through encodeStoredList', () {
      const types = [CatalogConnectorType.cee32a5p, CatalogConnectorType.bnc];
      final encoded = CatalogConnectorTypeJson.encodeStoredList(types);
      expect(CatalogConnectorTypeJson.decodeStoredList(encoded), types);
    });
  });

  group('CatalogDevice JSON round-trip', () {
    test('toJson/fromJson preserves connectorTypeIds', () {
      final now = DateTime(2026, 9, 13);
      final device = CatalogDevice(
        id: 'device_1',
        name: 'Test fixture',
        quantityUnit: CatalogQuantityUnit.pcs,
        connectorTypeIds: const [
          CatalogConnectorType.powerConTrue1,
          CatalogConnectorType.xlr5,
        ],
        createdAt: now,
        updatedAt: now,
      );

      final restored = CatalogDevice.fromJson(device.toJson());

      expect(restored.connectorTypeIds, device.connectorTypeIds);
    });

    test(
      'fromJson reads a pre-multi-select backup\'s single connectorTypeId',
      () {
        final now = DateTime(2026, 9, 13).toIso8601String();
        final legacyJson = {
          'id': 'device_1',
          'name': 'Old backup fixture',
          'quantityUnit': 'pcs',
          'connectorTypeId': 'powercon',
          'createdAt': now,
          'updatedAt': now,
        };

        final restored = CatalogDevice.fromJson(legacyJson);

        expect(restored.connectorTypeIds, [CatalogConnectorType.powerCon]);
      },
    );

    test('fromJson drops an unrecognized legacy connectorTypeId instead of '
        'throwing', () {
      final now = DateTime(2026, 9, 13).toIso8601String();
      final legacyJson = {
        'id': 'device_1',
        'name': 'Old backup fixture',
        'quantityUnit': 'pcs',
        'connectorTypeId': 'some homemade connector nobody documented',
        'createdAt': now,
        'updatedAt': now,
      };

      final restored = CatalogDevice.fromJson(legacyJson);

      expect(restored.connectorTypeIds, isEmpty);
    });
  });
}

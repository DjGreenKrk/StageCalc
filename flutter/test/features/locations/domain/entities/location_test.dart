import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/locations/domain/entities/location.dart';

void main() {
  group('LocationPowerConnector.decodeStoredList', () {
    test(
      'decodes a JSON-encoded array of entries (current storage format)',
      () {
        final entries = LocationPowerConnector.decodeStoredList(
          '[{"connectorTypeId":"cee_32a_5p","quantity":2},'
          '{"connectorTypeId":"schuko_16a","quantity":4}]',
        );

        expect(entries, [
          const LocationConnectorEntry(
            connectorTypeId: 'cee_32a_5p',
            quantity: 2,
          ),
          const LocationConnectorEntry(
            connectorTypeId: 'schuko_16a',
            quantity: 4,
          ),
        ]);
      },
    );

    test('treats a bare legacy connector-type-id string as a one-entry list, '
        'using legacyQuantity', () {
      final entries = LocationPowerConnector.decodeStoredList(
        'cee_32a_5p',
        legacyQuantity: 3,
      );

      expect(entries, [
        const LocationConnectorEntry(
          connectorTypeId: 'cee_32a_5p',
          quantity: 3,
        ),
      ]);
    });

    test('returns an empty list for null or blank input', () {
      expect(LocationPowerConnector.decodeStoredList(null), isEmpty);
      expect(LocationPowerConnector.decodeStoredList(''), isEmpty);
      expect(LocationPowerConnector.decodeStoredList('[]'), isEmpty);
    });

    test('round-trips through encodeStoredList', () {
      const entries = [
        LocationConnectorEntry(connectorTypeId: 'cee_63a_5p', quantity: 1),
        LocationConnectorEntry(connectorTypeId: 'schuko_16a', quantity: 6),
      ];
      final encoded = LocationPowerConnector.encodeStoredList(entries);

      expect(LocationPowerConnector.decodeStoredList(encoded), entries);
    });
  });

  group('LocationPowerConnector', () {
    test('availablePowerKw sums every entry', () {
      final now = DateTime(2026, 9, 14);
      final connector = LocationPowerConnector(
        id: 'connector_1',
        name: 'Rozdzielnia sceny',
        entries: const [
          LocationConnectorEntry(connectorTypeId: 'cee_32a_5p', quantity: 2),
          LocationConnectorEntry(connectorTypeId: 'schuko_16a', quantity: 4),
        ],
        createdAt: now,
        updatedAt: now,
      );

      expect(connector.availablePowerKw, closeTo(59.1, 0.1));
    });

    test('entriesSummary joins every entry with " + "', () {
      final now = DateTime(2026, 9, 14);
      final connector = LocationPowerConnector(
        id: 'connector_1',
        name: 'Rozdzielnia sceny',
        entries: const [
          LocationConnectorEntry(connectorTypeId: 'cee_32a_5p', quantity: 2),
          LocationConnectorEntry(connectorTypeId: 'schuko_16a', quantity: 4),
        ],
        createdAt: now,
        updatedAt: now,
      );

      expect(connector.entriesSummary, '2x 32 A CEE 5P + 4x 16 A Uni-Schuko');
    });

    test('toJson/fromJson round-trip preserves every entry', () {
      final now = DateTime(2026, 9, 14);
      final connector = LocationPowerConnector(
        id: 'connector_1',
        name: 'Rozdzielnia sceny',
        entries: const [
          LocationConnectorEntry(connectorTypeId: 'cee_32a_5p', quantity: 2),
          LocationConnectorEntry(connectorTypeId: 'schuko_16a', quantity: 4),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final restored = LocationPowerConnector.fromJson(connector.toJson());

      expect(restored.entries, connector.entries);
    });

    test('fromJson reads a pre-multi-entry backup\'s single connectorTypeId/'
        'quantity fields', () {
      final now = DateTime(2026, 9, 14).toIso8601String();
      final legacyJson = {
        'id': 'connector_1',
        'name': 'Rozdzielnia sceny',
        'connectorTypeId': 'cee_32a_5p',
        'quantity': 2,
        'createdAt': now,
        'updatedAt': now,
      };

      final restored = LocationPowerConnector.fromJson(legacyJson);

      expect(restored.entries, [
        const LocationConnectorEntry(
          connectorTypeId: 'cee_32a_5p',
          quantity: 2,
        ),
      ]);
    });
  });
}

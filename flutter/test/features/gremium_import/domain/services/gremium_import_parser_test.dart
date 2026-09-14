import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/gremium_import/domain/services/gremium_import_parser.dart';

String _validJson({List<Map<String, Object?>>? items}) {
  return jsonEncode({
    'schema': 'gremium.stagecalc.pack-list',
    'formatVersion': '1.0',
    'project': {'id': 'event-1', 'name': 'Konferencja medyczna'},
    'items':
        items ??
        [
          {
            'lineId': 'line-1',
            'inventoryItemId': 'inv-1',
            'name': 'DNA Pole One',
            'quantity': 1,
            'technical': {'unitWeightKg': 16.6},
          },
        ],
  });
}

void main() {
  test('parses a valid pack-list', () {
    final result = GremiumImportParser.parse(_validJson());

    expect(result.project.id, 'event-1');
    expect(result.project.name, 'Konferencja medyczna');
    expect(result.items, hasLength(1));
    expect(result.items.single.name, 'DNA Pole One');
    expect(result.items.single.technical.unitWeightKg, 16.6);
  });

  test('missing weight/electrical data does not block parsing', () {
    final result = GremiumImportParser.parse(
      _validJson(
        items: [
          {
            'lineId': 'line-1',
            'name': 'Rozdzielnia podwykonawcy',
            'quantity': 1,
          },
        ],
      ),
    );

    expect(result.items.single.technical.unitWeightKg, isNull);
    expect(result.items.single.technical.ratedPowerW, isNull);
  });

  test('rejects content that is not valid JSON', () {
    expect(
      () => GremiumImportParser.parse('not json'),
      throwsA(isA<GremiumValidationException>()),
    );
  });

  test('rejects an unrecognized schema', () {
    final json = jsonDecode(_validJson()) as Map<String, Object?>;
    json['schema'] = 'something.else';

    expect(
      () => GremiumImportParser.parse(jsonEncode(json)),
      throwsA(isA<GremiumValidationException>()),
    );
  });

  test('rejects an unsupported major format version', () {
    final json = jsonDecode(_validJson()) as Map<String, Object?>;
    json['formatVersion'] = '2.0';

    expect(
      () => GremiumImportParser.parse(jsonEncode(json)),
      throwsA(isA<GremiumValidationException>()),
    );
  });

  test('accepts any minor version within the same major version', () {
    final json = jsonDecode(_validJson()) as Map<String, Object?>;
    json['formatVersion'] = '1.7';

    expect(() => GremiumImportParser.parse(jsonEncode(json)), returnsNormally);
  });

  test('rejects a missing project.id', () {
    final json = jsonDecode(_validJson()) as Map<String, Object?>;
    (json['project']! as Map<String, Object?>).remove('id');

    expect(
      () => GremiumImportParser.parse(jsonEncode(json)),
      throwsA(isA<GremiumValidationException>()),
    );
  });

  test('rejects a missing project.name', () {
    final json = jsonDecode(_validJson()) as Map<String, Object?>;
    (json['project']! as Map<String, Object?>).remove('name');

    expect(
      () => GremiumImportParser.parse(jsonEncode(json)),
      throwsA(isA<GremiumValidationException>()),
    );
  });

  test('rejects a missing items array', () {
    final json = jsonDecode(_validJson()) as Map<String, Object?>;
    json.remove('items');

    expect(
      () => GremiumImportParser.parse(jsonEncode(json)),
      throwsA(isA<GremiumValidationException>()),
    );
  });

  test('rejects an item without a name', () {
    expect(
      () => GremiumImportParser.parse(
        _validJson(
          items: [
            {'lineId': 'line-1', 'quantity': 1},
          ],
        ),
      ),
      throwsA(isA<GremiumValidationException>()),
    );
  });

  test('rejects an item with quantity <= 0', () {
    expect(
      () => GremiumImportParser.parse(
        _validJson(
          items: [
            {'lineId': 'line-1', 'name': 'Kabel', 'quantity': 0},
          ],
        ),
      ),
      throwsA(isA<GremiumValidationException>()),
    );
  });
}

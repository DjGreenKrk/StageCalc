import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';

void main() {
  test('every kind has a non-empty label', () {
    for (final kind in RiggingDeviceKind.values) {
      expect(kind.label, isNotEmpty, reason: kind.name);
    }
  });

  test('toJson/fromJson round-trips every value', () {
    for (final kind in RiggingDeviceKind.values) {
      expect(RiggingDeviceKindJson.fromJson(kind.toJson()), kind);
    }
  });

  test('fromJson returns null for null or unrecognized input', () {
    expect(RiggingDeviceKindJson.fromJson(null), isNull);
    expect(RiggingDeviceKindJson.fromJson('not-a-real-kind'), isNull);
  });
}

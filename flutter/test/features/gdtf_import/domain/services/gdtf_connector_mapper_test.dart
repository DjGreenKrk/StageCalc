import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';
import 'package:stagecalc/features/gdtf_import/domain/services/gdtf_connector_mapper.dart';

void main() {
  final cases = <String, CatalogConnectorType>{
    'CEE 7/7': CatalogConnectorType.schuko16a,
    'Schuko': CatalogConnectorType.schuko16a,
    '16A-CEE-2P': CatalogConnectorType.cee16a3p,
    '16A-CEE': CatalogConnectorType.cee16a5p,
    '32A-CEE-2P': CatalogConnectorType.cee32a3p,
    '32A-CEE': CatalogConnectorType.cee32a5p,
    '63A-CEE': CatalogConnectorType.cee63a5p,
    '125A-CEE': CatalogConnectorType.cee125a5p,
    'Powerlock 200A': CatalogConnectorType.powerlock200a,
    'Powerlock 400A': CatalogConnectorType.powerlock400a,
    'NAC3FCA': CatalogConnectorType.powerCon,
    'NAC3FCB': CatalogConnectorType.powerCon,
    'PowerconTRUE1': CatalogConnectorType.powerConTrue1,
    'powerCONTRUE1TOP': CatalogConnectorType.powerConTrue1Top,
    'XLR3': CatalogConnectorType.xlr3,
    'XLR5': CatalogConnectorType.xlr5,
    'NL4': CatalogConnectorType.speakonNl4,
    'NL8': CatalogConnectorType.speakonNl8,
    'RJ45': CatalogConnectorType.etherCon,
    'BNC': CatalogConnectorType.bnc,
    'HDMI': CatalogConnectorType.hdmi,
    'USB': CatalogConnectorType.usb,
  };

  cases.forEach((raw, expected) {
    test('maps "$raw" to $expected', () {
      expect(GdtfConnectorMapper.map(raw), expected);
    });
  });

  test(
    'bare Powerlock without an amperage falls back rather than guessing',
    () {
      expect(GdtfConnectorMapper.map('Powerlock'), CatalogConnectorType.other);
    },
  );

  test('unrecognized connector types fall back to other', () {
    expect(
      GdtfConnectorMapper.map('Some Custom Plug'),
      CatalogConnectorType.other,
    );
  });

  test('delegates to the catalog enum\'s own alias matcher first', () {
    // "Jack" is not in the GDTF-specific table but is a known alias on
    // CatalogConnectorTypeJson - the mapper should not duplicate it.
    expect(GdtfConnectorMapper.map('Jack'), CatalogConnectorType.jack63);
  });

  test('mapAll deduplicates', () {
    final result = GdtfConnectorMapper.mapAll(['XLR5', 'XLR5', 'RJ45']);
    expect(
      result,
      containsAll([CatalogConnectorType.xlr5, CatalogConnectorType.etherCon]),
    );
    expect(result, hasLength(2));
  });
}

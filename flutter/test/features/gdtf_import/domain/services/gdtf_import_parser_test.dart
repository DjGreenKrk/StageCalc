import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/gdtf_import/domain/services/gdtf_import_parser.dart';

/// Builds a minimal, spec-shaped `.gdtf` ZIP in memory for a test, so the
/// parser suite does not depend on a real downloaded file for its core
/// coverage (a real sample, supplied by the user, is additionally exercised
/// below).
Uint8List _buildTestGdtf({
  required String fixtureTypeId,
  required String name,
  String? manufacturer,
  String dataVersion = '1.2',
  String? weightXml,
  List<String> legacyConnectorTypes = const [],
  List<String> wiringObjectXml = const [],
  bool includeMediaServerLayer = false,
  bool omitDescriptionXml = false,
  bool malformedXml = false,
}) {
  final connectorsXml = legacyConnectorTypes
      .map((type) => '<Connector Type="$type"/>')
      .join();
  final mediaServerXml = includeMediaServerLayer
      ? '<MediaServerLayer Name="Layer 1"/>'
      : '';

  final xml = malformedXml
      ? '<GDTF DataVersion="$dataVersion"><FixtureType Name="$name"'
      : '''
<?xml version="1.0" encoding="UTF-8"?>
<GDTF DataVersion="$dataVersion">
  <FixtureType Name="$name" FixtureTypeID="$fixtureTypeId"
      Manufacturer="${manufacturer ?? ''}">
    <PhysicalDescriptions>
      <Connectors>$connectorsXml</Connectors>
      <Properties>
        ${weightXml ?? ''}
      </Properties>
    </PhysicalDescriptions>
    <Geometries>
      $mediaServerXml
      <Geometry Name="Base">
        ${wiringObjectXml.join()}
      </Geometry>
    </Geometries>
  </FixtureType>
</GDTF>
''';

  final archive = Archive();
  if (!omitDescriptionXml) {
    final bytes = utf8.encode(xml);
    archive.addFile(ArchiveFile('description.xml', bytes.length, bytes));
  }
  return ZipEncoder().encodeBytes(archive);
}

void main() {
  test('happy path parses name/manufacturer/weight/connectors/power', () {
    final bytes = _buildTestGdtf(
      fixtureTypeId: 'guid-1',
      name: 'Robin Painte',
      manufacturer: 'Robe Lighting',
      weightXml: '<Weight Value="19.6"/>',
      wiringObjectXml: [
        '<WiringObject ComponentType="Consumer" ConnectorType="PowerconTRUE1" '
            'ElectricalPayLoad="440"/>',
        '<WiringObject ComponentType="Output" ConnectorType="PowerconTRUE1" '
            'ElectricalPayLoad="440"/>',
        '<WiringObject ComponentType="NetworkInput" ConnectorType="XLR5"/>',
      ],
    );

    final fixture = GdtfImportParser.parse(bytes, sourceFileName: 'test.gdtf');

    expect(fixture.fixtureTypeId, 'guid-1');
    expect(fixture.name, 'Robin Painte');
    expect(fixture.manufacturer, 'Robe Lighting');
    expect(fixture.weightKg, 19.6);
    // Only the Consumer node's payload counts - the Output (pass-through)
    // node must not be double-counted.
    expect(fixture.powerW, 440);
    expect(fixture.rawConnectorTypes, containsAll(['PowerconTRUE1', 'XLR5']));
    expect(fixture.hasMediaServerGeometry, isFalse);
  });

  test(
    'legacy (pre-1.2) file with only PhysicalDescriptions/Connector still parses connectors and leaves power null',
    () {
      final bytes = _buildTestGdtf(
        fixtureTypeId: 'guid-2',
        name: 'Old Fixture',
        dataVersion: '1.1',
        legacyConnectorTypes: ['Schuko'],
      );

      final fixture = GdtfImportParser.parse(bytes, sourceFileName: 'old.gdtf');

      expect(fixture.rawConnectorTypes, ['Schuko']);
      expect(fixture.powerW, isNull);
    },
  );

  test('missing weight defaults to 0', () {
    final bytes = _buildTestGdtf(fixtureTypeId: 'guid-3', name: 'No Weight');
    final fixture = GdtfImportParser.parse(bytes, sourceFileName: 'x.gdtf');
    expect(fixture.weightKg, 0);
  });

  test('no Consumer WiringObject leaves power null, never 0', () {
    final bytes = _buildTestGdtf(
      fixtureTypeId: 'guid-4',
      name: 'No Power Data',
      wiringObjectXml: [
        '<WiringObject ComponentType="NetworkInput" ConnectorType="XLR5"/>',
      ],
    );
    final fixture = GdtfImportParser.parse(bytes, sourceFileName: 'x.gdtf');
    expect(fixture.powerW, isNull);
  });

  test('missing Name throws', () {
    final bytes = _buildTestGdtf(fixtureTypeId: 'guid-5', name: '');
    expect(
      () => GdtfImportParser.parse(bytes, sourceFileName: 'x.gdtf'),
      throwsA(isA<GdtfValidationException>()),
    );
  });

  test('missing FixtureTypeID throws', () {
    final bytes = _buildTestGdtf(fixtureTypeId: '', name: 'Some Fixture');
    expect(
      () => GdtfImportParser.parse(bytes, sourceFileName: 'x.gdtf'),
      throwsA(isA<GdtfValidationException>()),
    );
  });

  test('corrupt ZIP bytes throws', () {
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    expect(
      () => GdtfImportParser.parse(bytes, sourceFileName: 'x.gdtf'),
      throwsA(isA<GdtfValidationException>()),
    );
  });

  test('ZIP without description.xml throws', () {
    final bytes = _buildTestGdtf(
      fixtureTypeId: 'guid-6',
      name: 'x',
      omitDescriptionXml: true,
    );
    expect(
      () => GdtfImportParser.parse(bytes, sourceFileName: 'x.gdtf'),
      throwsA(isA<GdtfValidationException>()),
    );
  });

  test('malformed XML throws', () {
    final bytes = _buildTestGdtf(
      fixtureTypeId: 'guid-7',
      name: 'x',
      malformedXml: true,
    );
    expect(
      () => GdtfImportParser.parse(bytes, sourceFileName: 'x.gdtf'),
      throwsA(isA<GdtfValidationException>()),
    );
  });

  test('unknown/future DataVersion still parses (version-tolerant)', () {
    final bytes = _buildTestGdtf(
      fixtureTypeId: 'guid-8',
      name: 'Future Fixture',
      dataVersion: '9.9',
      weightXml: '<Weight Value="5"/>',
    );
    final fixture = GdtfImportParser.parse(bytes, sourceFileName: 'x.gdtf');
    expect(fixture.name, 'Future Fixture');
    expect(fixture.weightKg, 5);
  });

  test('a MediaServerLayer node sets hasMediaServerGeometry', () {
    final bytes = _buildTestGdtf(
      fixtureTypeId: 'guid-9',
      name: 'Media Server',
      includeMediaServerLayer: true,
    );
    final fixture = GdtfImportParser.parse(bytes, sourceFileName: 'x.gdtf');
    expect(fixture.hasMediaServerGeometry, isTrue);
  });

  group('real-world sample file', () {
    final sampleFile = File(
      '../docs/Robe_Lighting@Robin_Painte@2025-11-07__Personality_RDM_number_revision.gdtf',
    );

    test(
      'parses a real manufacturer .gdtf file without error',
      () {
        final bytes = sampleFile.readAsBytesSync();
        final fixture = GdtfImportParser.parse(
          bytes,
          sourceFileName: sampleFile.uri.pathSegments.last,
        );

        expect(fixture.fixtureTypeId, 'EE88FCC8-6A9A-4523-BFD7-31115B703264');
        expect(fixture.name, 'Robin Painte');
        expect(fixture.manufacturer, 'Robe Lighting');
        expect(fixture.weightKg, closeTo(19.6, 0.01));
        expect(fixture.powerW, closeTo(440, 0.01));
        expect(fixture.hasMediaServerGeometry, isFalse);
      },
      skip: sampleFile.existsSync() ? false : 'sample .gdtf file not found',
    );
  });
}

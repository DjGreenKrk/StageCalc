import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../entities/gdtf_fixture_type.dart';

class GdtfValidationException implements Exception {
  GdtfValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Parses one `.gdtf` file (a ZIP archive containing `description.xml`) down
/// to exactly the fields `CatalogDevice` can use - see `GdtfFixtureType` and
/// ADR-035 for what is deliberately left unparsed and why. A pure function:
/// nothing is saved here, and one call handles exactly one file (batch
/// orchestration over several picked files lives in `gdtf_import_entry.dart`
/// so one bad file never aborts the rest). Throws [GdtfValidationException]
/// on the first blocking problem; a missing weight/electrical reading is
/// never blocking.
///
/// Reads both the legacy (`PhysicalDescriptions/Connector`,
/// pre-GDTF-1.2) and modern (`Geometries/.../WiringObject`) electrical/
/// connector shapes unconditionally, in one pass - that dual read is what
/// makes this parser tolerant of a file's `DataVersion` without ever
/// branching on it, including versions newer than this parser knows about.
class GdtfImportParser {
  const GdtfImportParser._();

  static GdtfFixtureType parse(
    Uint8List zipBytes, {
    required String sourceFileName,
  }) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (_) {
      throw GdtfValidationException('Plik nie jest poprawnym archiwum ZIP.');
    }

    ArchiveFile? descriptionFile;
    for (final file in archive.files) {
      if (file.isFile &&
          _basename(file.name).toLowerCase() == 'description.xml') {
        descriptionFile = file;
        break;
      }
    }
    if (descriptionFile == null) {
      throw GdtfValidationException('Brak pliku description.xml w archiwum.');
    }

    final XmlDocument document;
    try {
      document = XmlDocument.parse(utf8.decode(descriptionFile.content));
    } catch (_) {
      throw GdtfValidationException('Plik description.xml jest uszkodzony.');
    }

    final fixtureTypeElement = _firstElement(
      document.findAllElements('FixtureType'),
    );
    if (fixtureTypeElement == null) {
      throw GdtfValidationException('Brak elementu FixtureType w pliku.');
    }

    final name = _nonEmpty(fixtureTypeElement.getAttribute('Name'));
    if (name == null) {
      throw GdtfValidationException(
        'Plik nie zawiera nazwy urządzenia (FixtureType/Name).',
      );
    }
    final fixtureTypeId = _nonEmpty(
      fixtureTypeElement.getAttribute('FixtureTypeID'),
    );
    if (fixtureTypeId == null) {
      throw GdtfValidationException('Plik nie zawiera FixtureTypeID.');
    }

    return GdtfFixtureType(
      fixtureTypeId: fixtureTypeId,
      name: name,
      sourceFileName: sourceFileName,
      manufacturer: _nonEmpty(fixtureTypeElement.getAttribute('Manufacturer')),
      description: _nonEmpty(fixtureTypeElement.getAttribute('Description')),
      weightKg: _parseWeight(fixtureTypeElement),
      powerW: _sumConsumerPower(fixtureTypeElement),
      rawConnectorTypes: _collectRawConnectorTypes(fixtureTypeElement),
      hasMediaServerGeometry: _hasMediaServerGeometry(fixtureTypeElement),
    );
  }

  static XmlElement? _firstElement(Iterable<XmlElement> elements) {
    final iterator = elements.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final slash = normalized.lastIndexOf('/');
    return slash == -1 ? normalized : normalized.substring(slash + 1);
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// `PhysicalDescriptions/Properties/Weight/@Value`, kilograms - the one
  /// field where "absent" genuinely means `0` per the spec, not "unknown".
  static double _parseWeight(XmlElement fixtureType) {
    final weightElement = _firstElement(fixtureType.findAllElements('Weight'));
    return double.tryParse(weightElement?.getAttribute('Value') ?? '') ?? 0;
  }

  /// Legacy `PhysicalDescriptions/Connector/@Type` plus modern
  /// `Geometries/.../WiringObject/@ConnectorType`, deduplicated - see the
  /// class doc comment on why both are always read.
  static List<String> _collectRawConnectorTypes(XmlElement fixtureType) {
    final types = <String>{};
    for (final connector in fixtureType.findAllElements('Connector')) {
      final type = _nonEmpty(connector.getAttribute('Type'));
      if (type != null) {
        types.add(type);
      }
    }
    for (final wiringObject in fixtureType.findAllElements('WiringObject')) {
      final type = _nonEmpty(wiringObject.getAttribute('ConnectorType'));
      if (type != null) {
        types.add(type);
      }
    }
    return types.toList(growable: false);
  }

  /// Sums `ElectricalPayLoad` (Watt) across every `WiringObject` whose
  /// `ComponentType` is `Consumer` - the modern, structurally-correct home
  /// for a fixture's real power draw (the older device-level
  /// `Properties/PowerConsumption` is spec-obsolete and deliberately never
  /// read here). Deliberately does NOT read `FuseCurrent`: that describes
  /// the protective fuse rating, not the fixture's actual current draw, so
  /// using it as `currentA` would be a semantic error - the commit service
  /// derives current from this power figure instead (ADR-035), the same way
  /// the catalog device dialog already does for manual entries. Returns
  /// `null` (never `0`) when no Consumer node exists, since that means "not
  /// found", not "verified zero".
  static double? _sumConsumerPower(XmlElement fixtureType) {
    double? total;
    for (final wiringObject in fixtureType.findAllElements('WiringObject')) {
      if (wiringObject.getAttribute('ComponentType') != 'Consumer') {
        continue;
      }
      final payload = double.tryParse(
        wiringObject.getAttribute('ElectricalPayLoad') ?? '',
      );
      if (payload == null) {
        continue;
      }
      total = (total ?? 0) + payload;
    }
    return total;
  }

  static const _mediaServerTags = {
    'MediaServerLayer',
    'MediaServerCamera',
    'MediaServerMaster',
  };

  static bool _hasMediaServerGeometry(XmlElement fixtureType) {
    return fixtureType.descendantElements.any(
      (element) => _mediaServerTags.contains(element.name.local),
    );
  }
}

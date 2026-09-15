import '../../../catalog/domain/entities/catalog_device.dart';

/// Maps a raw GDTF connector-type string (from `PhysicalDescriptions/
/// Connector/@Type` or `Geometries/.../WiringObject/@ConnectorType`, per
/// GDTF's Annex D naming) onto StageCalc's fixed [CatalogConnectorType] set
/// (ADR-035). Substring matching on normalized (lowercase, letters/digits
/// only) text, most-specific pattern first, falling back to
/// [CatalogConnectorTypeJson.fromJson]'s own lenient alias matcher before
/// giving up as [CatalogConnectorType.other] - nothing is ever guessed
/// without a real signal in the source text.
class GdtfConnectorMapper {
  const GdtfConnectorMapper._();

  static CatalogConnectorType map(String raw) {
    final normalized = _normalize(raw);

    if (normalized.contains('schuko') || normalized.contains('cee77')) {
      return CatalogConnectorType.schuko16a;
    }

    // GDTF's Annex D naming puts a "-2P" suffix on the single-phase (blue)
    // CEE variants and leaves the bare "NNA-CEE" name for the three-phase
    // ones - so which pin-count StageCalc variant applies is read directly
    // from that suffix, never guessed from the amperage alone.
    final isSinglePhaseCee = normalized.contains('2p');
    if (normalized.contains('125a') && normalized.contains('cee')) {
      return CatalogConnectorType.cee125a5p;
    }
    if (normalized.contains('63a') && normalized.contains('cee')) {
      return CatalogConnectorType.cee63a5p;
    }
    if (normalized.contains('32a') && normalized.contains('cee')) {
      return isSinglePhaseCee
          ? CatalogConnectorType.cee32a3p
          : CatalogConnectorType.cee32a5p;
    }
    if (normalized.contains('16a') && normalized.contains('cee')) {
      return isSinglePhaseCee
          ? CatalogConnectorType.cee16a3p
          : CatalogConnectorType.cee16a5p;
    }

    if (normalized.contains('powerlock')) {
      if (normalized.contains('200')) {
        return CatalogConnectorType.powerlock200a;
      }
      if (normalized.contains('400')) {
        return CatalogConnectorType.powerlock400a;
      }
      // Bare "Powerlock" with no amperage in the text - ambiguous, don't
      // guess a rating; fall through to the generic alias matcher/other.
    }

    if (normalized.contains('nac3fca') || normalized.contains('nac3fcb')) {
      return CatalogConnectorType.powerCon;
    }
    if (normalized.contains('powercontrue1top')) {
      return CatalogConnectorType.powerConTrue1Top;
    }
    if (normalized.contains('powercontrue1')) {
      return CatalogConnectorType.powerConTrue1;
    }

    if (normalized.contains('xlr3')) {
      return CatalogConnectorType.xlr3;
    }
    if (normalized.contains('xlr5')) {
      return CatalogConnectorType.xlr5;
    }
    if (normalized.contains('nl4')) {
      return CatalogConnectorType.speakonNl4;
    }
    if (normalized.contains('nl8')) {
      return CatalogConnectorType.speakonNl8;
    }
    if (normalized.contains('rj45')) {
      return CatalogConnectorType.etherCon;
    }
    if (normalized.contains('bnc')) {
      return CatalogConnectorType.bnc;
    }
    if (normalized.contains('hdmi')) {
      return CatalogConnectorType.hdmi;
    }
    if (normalized.contains('usb')) {
      return CatalogConnectorType.usb;
    }

    return CatalogConnectorTypeJson.fromJson(raw) ?? CatalogConnectorType.other;
  }

  static List<CatalogConnectorType> mapAll(List<String> rawTypes) {
    return rawTypes.map(map).toSet().toList(growable: false);
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  }
}

/// One GDTF file (`description.xml` inside a `.gdtf` ZIP), parsed down to
/// exactly the fields StageCalc's `CatalogDevice` can use (ADR-035) - the
/// much larger rest of the GDTF specification (DMX modes/channels, wheels,
/// 3D models, revisions, macros, protocols) is deliberately never parsed,
/// since none of it maps to an existing catalog field.
class GdtfFixtureType {
  const GdtfFixtureType({
    required this.fixtureTypeId,
    required this.name,
    required this.sourceFileName,
    this.manufacturer,
    this.description,
    this.weightKg = 0,
    this.powerW,
    this.rawConnectorTypes = const [],
    this.hasMediaServerGeometry = false,
  });

  /// `FixtureType/@FixtureTypeID` - a GUID, stable per fixture type across
  /// re-exports/re-downloads of the same file. This is the external-id key
  /// used to match against an already-imported `CatalogDevice` (see
  /// `GdtfCatalogMatcher`), mirroring how the Gremium import matches by
  /// `inventoryItemId` (ADR-034).
  final String fixtureTypeId;

  final String name;

  /// The original picked file's name (e.g. `robe@robin-painte.gdtf`) - shown
  /// in the review panel and in the error list for files that failed to
  /// parse, since a fixture has no on-screen identity until it's parsed.
  final String sourceFileName;

  final String? manufacturer;
  final String? description;

  /// `PhysicalDescriptions/Properties/Weight/@Value`, kilograms. Defaults to
  /// `0` when absent - this is the one field where "absent" and "zero" are
  /// spec-equivalent, unlike [powerW].
  final double weightKg;

  /// Total power draw, summed across every
  /// `Geometries/.../WiringObject[@ComponentType="Consumer"]/@ElectricalPayLoad`
  /// found in the file. `null` means no such node was found - electrical
  /// data is optional and inconsistently provided by manufacturers, so this
  /// is never coerced to `0` (which would read as "verified zero power").
  final double? powerW;

  /// Raw connector-type strings collected from both the legacy
  /// `PhysicalDescriptions/Connector/@Type` elements and the modern
  /// `Geometries/.../WiringObject/@ConnectorType` attributes (read
  /// unconditionally, regardless of the file's `DataVersion`) - mapped to
  /// `CatalogConnectorType` by `GdtfConnectorMapper` at review/commit time.
  final List<String> rawConnectorTypes;

  /// Whether the geometry tree contains a `MediaServerLayer`,
  /// `MediaServerCamera` or `MediaServerMaster` node - the only structural
  /// signal GDTF gives for "this is a media server, not a lighting fixture"
  /// (see `guessGdtfCategory`).
  final bool hasMediaServerGeometry;
}

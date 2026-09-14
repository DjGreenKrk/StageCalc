/// Parsed representation of a `gremium.stagecalc.pack-list` export (see
/// `docs/Gremium import/Import_details.md` and ADR-034). Field names mirror
/// the exported JSON so the parser can stay a thin, direct mapping.
class GremiumPackList {
  const GremiumPackList({
    required this.schema,
    required this.formatVersion,
    required this.project,
    required this.items,
  });

  final String schema;
  final String formatVersion;
  final GremiumProjectInfo project;
  final List<GremiumItem> items;
}

class GremiumProjectInfo {
  const GremiumProjectInfo({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.location,
    this.environment,
  });

  final String id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? location;
  final String? environment;
}

class GremiumItem {
  const GremiumItem({
    required this.name,
    required this.quantity,
    this.lineId,
    this.inventoryItemId,
    this.projectLabel,
    this.manufacturer,
    this.category,
    this.technical = const GremiumTechnical(),
  });

  /// Identifies this checklist row within one Gremium event export - stable
  /// across re-exports of the same project, used to recognize the same
  /// position on a re-import. `null` when the export omits it (falls back
  /// to always treating the row as new on every import).
  final String? lineId;

  /// Gremium's own catalog id for this item - `null` means a one-off
  /// position not backed by their inventory ("Pozycja własna").
  final String? inventoryItemId;
  final String name;
  final String? projectLabel;
  final String? manufacturer;
  final String? category;
  final double quantity;
  final GremiumTechnical technical;

  /// The name to show the user: the checklist label if Gremium set one,
  /// otherwise the catalog item name.
  String get displayLabel {
    final label = projectLabel;
    if (label != null && label.trim().isNotEmpty) {
      return label;
    }
    return name;
  }
}

class GremiumTechnical {
  const GremiumTechnical({
    this.unitWeightKg,
    this.ratedPowerW,
    this.ratedCurrentA,
    this.voltageV,
    this.phases,
    this.riggingPoints,
  });

  final double? unitWeightKg;
  final double? ratedPowerW;
  final double? ratedCurrentA;
  final double? voltageV;
  final int? phases;
  final int? riggingPoints;
}

import 'dart:convert';

import '../entities/gremium_pack_list.dart';

const _expectedSchema = 'gremium.stagecalc.pack-list';

class GremiumValidationException implements Exception {
  GremiumValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Parses and validates a Gremium Panel pack-list export, per
/// `docs/Gremium import/Import_details.md` and ADR-034. A pure function:
/// nothing is saved here. Blocking rules throw [GremiumValidationException]
/// on the first problem found; a missing weight/electrical reading on an
/// item is never blocking - it simply leaves the corresponding field `null`
/// on that [GremiumItem].
class GremiumImportParser {
  const GremiumImportParser._();

  static GremiumPackList parse(String jsonContent) {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonContent);
    } on FormatException {
      throw GremiumValidationException(
        'Plik nie jest poprawnym dokumentem JSON.',
      );
    }
    if (decoded is! Map) {
      throw GremiumValidationException(
        'Plik nie jest poprawnym dokumentem JSON.',
      );
    }
    final json = Map<String, Object?>.from(decoded);

    final schema = json['schema'] as String?;
    if (schema != _expectedSchema) {
      throw GremiumValidationException(
        'Nierozpoznany format pliku (schema: ${schema ?? 'brak'}).',
      );
    }

    final formatVersion = json['formatVersion'] as String?;
    final majorVersion = (formatVersion ?? '').split('.').first;
    if (majorVersion != '1') {
      throw GremiumValidationException(
        'Nieobsługiwana wersja formatu: ${formatVersion ?? 'brak'} '
        '(ta wersja StageCalc obsługuje 1.x).',
      );
    }

    final projectJson = json['project'];
    if (projectJson is! Map) {
      throw GremiumValidationException('Brak sekcji "project" w pliku.');
    }
    final projectId = projectJson['id'] as String?;
    if (projectId == null || projectId.trim().isEmpty) {
      throw GremiumValidationException('Brak "project.id" w pliku.');
    }
    final projectName = projectJson['name'] as String?;
    if (projectName == null || projectName.trim().isEmpty) {
      throw GremiumValidationException('Brak "project.name" w pliku.');
    }

    final itemsJson = json['items'];
    if (itemsJson is! List) {
      throw GremiumValidationException('Brak tablicy "items" w pliku.');
    }

    final items = <GremiumItem>[];
    for (var index = 0; index < itemsJson.length; index++) {
      final raw = itemsJson[index];
      if (raw is! Map) {
        throw GremiumValidationException(
          'Pozycja ${index + 1} w "items" nie jest poprawnym obiektem.',
        );
      }
      items.add(_parseItem(Map<String, Object?>.from(raw), index));
    }

    return GremiumPackList(
      schema: _expectedSchema,
      formatVersion: formatVersion ?? '1.0',
      project: GremiumProjectInfo(
        id: projectId,
        name: projectName,
        startDate: projectJson['startDate'] as String?,
        endDate: projectJson['endDate'] as String?,
        location: projectJson['location'] as String?,
        environment: projectJson['environment'] as String?,
      ),
      items: items,
    );
  }

  static GremiumItem _parseItem(Map<String, Object?> itemJson, int index) {
    final name = itemJson['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      throw GremiumValidationException('Pozycja ${index + 1} nie ma nazwy.');
    }
    final quantity = (itemJson['quantity'] as num?)?.toDouble();
    if (quantity == null || quantity <= 0) {
      throw GremiumValidationException(
        'Pozycja ${index + 1} ("$name") ma niepoprawną ilość.',
      );
    }

    final technicalJson = itemJson['technical'];
    final technical = technicalJson is Map
        ? GremiumTechnical(
            unitWeightKg: (technicalJson['unitWeightKg'] as num?)?.toDouble(),
            ratedPowerW: (technicalJson['ratedPowerW'] as num?)?.toDouble(),
            ratedCurrentA: (technicalJson['ratedCurrentA'] as num?)?.toDouble(),
            voltageV: (technicalJson['voltageV'] as num?)?.toDouble(),
            phases: (technicalJson['phases'] as num?)?.toInt(),
            riggingPoints: (technicalJson['riggingPoints'] as num?)?.toInt(),
          )
        : const GremiumTechnical();

    return GremiumItem(
      lineId: itemJson['lineId'] as String?,
      inventoryItemId: itemJson['inventoryItemId'] as String?,
      name: name,
      projectLabel: itemJson['projectLabel'] as String?,
      manufacturer: itemJson['manufacturer'] as String?,
      category: itemJson['category'] as String?,
      quantity: quantity,
      technical: technical,
    );
  }
}

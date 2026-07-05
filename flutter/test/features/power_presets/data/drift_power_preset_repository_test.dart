import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/power_presets/data/drift_power_preset_repository.dart';
import 'package:stagecalc/features/power_presets/domain/entities/power_preset.dart';
import 'package:stagecalc/features/projects/domain/entities/power_models.dart';
import 'package:stagecalc/infrastructure/local_database/app_database.dart'
    as db;

void main() {
  late db.AppDatabase database;
  late DriftPowerPresetRepository repository;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftPowerPresetRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('seeds, saves, loads, and soft deletes power presets', () async {
    await repository.ensureSeedData();
    final seededPresets = await repository.getPresets();

    expect(seededPresets, isNotEmpty);
    expect(
      seededPresets.any(
        (preset) => preset.name == 'Rozdzielnia 32 A / 6x Schuko',
      ),
      isTrue,
    );

    final now = DateTime(2026, 7, 5);
    const presetId = 'preset_sqlite';
    await repository.savePreset(
      PowerPreset(
        id: presetId,
        name: 'Preset SQLite',
        inputConnectorTypeId: 'cee_32a_5p',
        createdAt: now,
        updatedAt: now,
        outlets: const [
          PowerOutletTemplate(
            id: 'outlet_sqlite_l1',
            name: 'L1',
            connectorTypeId: 'schuko_16a',
            phase: PowerPhase.l1,
          ),
          PowerOutletTemplate(
            id: 'outlet_sqlite_l2',
            name: 'L2',
            connectorTypeId: 'schuko_16a',
            phase: PowerPhase.l2,
          ),
        ],
      ),
    );

    final presets = await repository.getPresets();
    final preset = presets.singleWhere((item) => item.id == presetId);

    expect(preset.outlets, hasLength(2));
    expect(preset.outlets.last.phase, PowerPhase.l2);

    await repository.deletePreset(presetId);
    final presetsAfterDelete = await repository.getPresets();

    expect(presetsAfterDelete.any((item) => item.id == presetId), isFalse);
  });
}

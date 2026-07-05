import 'package:drift/drift.dart';

import '../../../infrastructure/local_database/app_database.dart' as db;
import '../../../shared/models/offline_sync_status.dart';
import '../../projects/domain/entities/power_models.dart';
import '../domain/entities/power_preset.dart';
import 'demo_power_preset_factory.dart';
import 'power_preset_repository.dart';

class DriftPowerPresetRepository implements PowerPresetRepository {
  const DriftPowerPresetRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<List<PowerPreset>> getPresets() async {
    final presetRows =
        await (_database.select(_database.powerPresets)
              ..where((row) => row.deletedAt.isNull())
              ..orderBy([(row) => OrderingTerm.asc(row.name)]))
            .get();

    final presets = <PowerPreset>[];
    for (final presetRow in presetRows) {
      final outletRows =
          await (_database.select(_database.powerOutletTemplates)
                ..where(
                  (row) =>
                      row.presetId.equals(presetRow.id) &
                      row.deletedAt.isNull(),
                )
                ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
              .get();

      presets.add(_mapPreset(presetRow, outletRows));
    }

    return presets;
  }

  @override
  Future<void> savePreset(PowerPreset preset) async {
    await _database.transaction(() async {
      await _database
          .into(_database.powerPresets)
          .insertOnConflictUpdate(
            db.PowerPresetsCompanion(
              id: Value(preset.id),
              name: Value(preset.name),
              inputConnectorTypeId: Value(preset.inputConnectorTypeId),
              notes: Value(preset.notes),
              createdAt: Value(preset.createdAt),
              updatedAt: Value(preset.updatedAt),
              deletedAt: const Value(null),
              syncState: Value(preset.syncStatus.toJson()),
            ),
          );

      final existingOutlets = await (_database.select(
        _database.powerOutletTemplates,
      )..where((row) => row.presetId.equals(preset.id))).get();
      final outletIds = preset.outlets.map((outlet) => outlet.id).toSet();

      for (final existingOutlet in existingOutlets) {
        if (!outletIds.contains(existingOutlet.id)) {
          await (_database.update(
            _database.powerOutletTemplates,
          )..where((row) => row.id.equals(existingOutlet.id))).write(
            db.PowerOutletTemplatesCompanion(
              deletedAt: Value(preset.updatedAt),
              updatedAt: Value(preset.updatedAt),
            ),
          );
        }
      }

      for (final (index, outlet) in preset.outlets.indexed) {
        await _database
            .into(_database.powerOutletTemplates)
            .insertOnConflictUpdate(
              db.PowerOutletTemplatesCompanion(
                id: Value(outlet.id),
                presetId: Value(preset.id),
                name: Value(outlet.name),
                connectorTypeId: Value(outlet.connectorTypeId),
                phase: Value(outlet.phase.toJson()),
                sortOrder: Value(index),
                createdAt: Value(preset.createdAt),
                updatedAt: Value(preset.updatedAt),
                deletedAt: const Value(null),
              ),
            );
      }
    });
  }

  @override
  Future<void> deletePreset(String id) async {
    final now = DateTime.now();
    await _database.transaction(() async {
      await (_database.update(
        _database.powerPresets,
      )..where((row) => row.id.equals(id))).write(
        db.PowerPresetsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      await (_database.update(
        _database.powerOutletTemplates,
      )..where((row) => row.presetId.equals(id))).write(
        db.PowerOutletTemplatesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> ensureSeedData() async {
    final presets = await getPresets();
    if (presets.isNotEmpty) {
      return;
    }

    for (final preset in DemoPowerPresetFactory.createSeedPresets()) {
      await savePreset(preset);
    }
  }

  PowerPreset _mapPreset(
    db.PowerPreset row,
    List<db.PowerOutletTemplate> outletRows,
  ) {
    return PowerPreset(
      id: row.id,
      name: row.name,
      inputConnectorTypeId: row.inputConnectorTypeId,
      notes: row.notes,
      outlets: outletRows.map(_mapOutlet).toList(),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      syncStatus: OfflineSyncStatusJson.fromJson(row.syncState),
    );
  }

  PowerOutletTemplate _mapOutlet(db.PowerOutletTemplate row) {
    return PowerOutletTemplate(
      id: row.id,
      name: row.name,
      connectorTypeId: row.connectorTypeId,
      phase: PowerPhaseJson.fromJson(row.phase),
    );
  }
}

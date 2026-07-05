import '../domain/entities/power_preset.dart';

abstract interface class PowerPresetRepository {
  Future<List<PowerPreset>> getPresets();

  Future<void> savePreset(PowerPreset preset);

  Future<void> deletePreset(String id);

  Future<void> ensureSeedData();
}

import '../../projects/domain/entities/power_models.dart';
import '../domain/entities/power_preset.dart';

class DemoPowerPresetFactory {
  const DemoPowerPresetFactory._();

  static List<PowerPreset> createSeedPresets() {
    final now = DateTime(2026, 7, 5);

    return [
      PowerPreset(
        id: 'distro_32a_6x_schuko',
        name: 'Rozdzielnia 32 A / 6x Schuko',
        inputConnectorTypeId: 'cee_32a_5p',
        createdAt: now,
        updatedAt: now,
        outlets: const [
          PowerOutletTemplate(
            id: 'distro_32a_6x_schuko_l1_1',
            name: 'L1 A',
            connectorTypeId: 'schuko_16a',
            phase: PowerPhase.l1,
          ),
          PowerOutletTemplate(
            id: 'distro_32a_6x_schuko_l1_2',
            name: 'L1 B',
            connectorTypeId: 'schuko_16a',
            phase: PowerPhase.l1,
          ),
          PowerOutletTemplate(
            id: 'distro_32a_6x_schuko_l2_1',
            name: 'L2 A',
            connectorTypeId: 'schuko_16a',
            phase: PowerPhase.l2,
          ),
          PowerOutletTemplate(
            id: 'distro_32a_6x_schuko_l2_2',
            name: 'L2 B',
            connectorTypeId: 'schuko_16a',
            phase: PowerPhase.l2,
          ),
          PowerOutletTemplate(
            id: 'distro_32a_6x_schuko_l3_1',
            name: 'L3 A',
            connectorTypeId: 'schuko_16a',
            phase: PowerPhase.l3,
          ),
          PowerOutletTemplate(
            id: 'distro_32a_6x_schuko_l3_2',
            name: 'L3 B',
            connectorTypeId: 'schuko_16a',
            phase: PowerPhase.l3,
          ),
        ],
      ),
    ];
  }
}

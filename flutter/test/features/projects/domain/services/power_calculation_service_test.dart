import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/projects/domain/entities/power_models.dart';
import 'package:stagecalc/features/projects/domain/entities/project_models.dart';
import 'package:stagecalc/features/projects/domain/services/power_calculation_service.dart';

void main() {
  const service = PowerCalculationService();

  test('puts single-phase group on selected phase', () {
    const group = ProjectGroup(
      id: 'single',
      name: 'Single',
      items: [
        ProjectItem(
          id: 'load',
          nameSnapshot: 'Load',
          quantity: 2,
          currentASnapshot: 5,
        ),
      ],
    );

    final load = service.calculateGroupLoad(
      group: group,
      outletPhase: PowerPhase.l2,
    );

    expect(load.l1A, 0);
    expect(load.l2A, 10);
    expect(load.l3A, 0);
  });

  test('splits symmetric three-phase group across phases', () {
    const group = ProjectGroup(
      id: 'three',
      name: 'Three',
      powerProfile: ProjectGroupPowerProfile.threePhaseSymmetric,
      items: [
        ProjectItem(
          id: 'load',
          nameSnapshot: 'Load',
          quantity: 1,
          currentASnapshot: 30,
        ),
      ],
    );

    final load = service.calculateGroupLoad(
      group: group,
      outletPhase: PowerPhase.all,
    );

    expect(load.l1A, 10);
    expect(load.l2A, 10);
    expect(load.l3A, 10);
  });

  test('calculates outlet load from project connection', () {
    final date = DateTime(2026, 7, 5);
    final project = Project(
      id: 'project',
      name: 'Project',
      createdAt: date,
      updatedAt: date,
      groups: const [
        ProjectGroup(
          id: 'group',
          name: 'Group',
          items: [
            ProjectItem(
              id: 'load',
              nameSnapshot: 'Load',
              quantity: 2,
              currentASnapshot: 8,
            ),
          ],
        ),
      ],
      distros: const [
        ProjectDistro(
          id: 'distro',
          name: 'Distro',
          outlets: [
            ProjectOutlet(
              id: 'outlet',
              name: 'L1',
              connectorTypeId: 'schuko_16a',
              phase: PowerPhase.l1,
              maxCurrentA: 16,
            ),
          ],
        ),
      ],
      connections: const [
        PowerConnection(
          id: 'connection',
          sourceDistroId: 'distro',
          sourceOutletId: 'outlet',
          targetGroupId: 'group',
        ),
      ],
    );

    final loads = service.calculateProjectLoads(project);
    final outletLoad = loads.outletLoads['outlet']!;

    expect(outletLoad.maxLoadedPhaseA, 16);
    expect(outletLoad.isOverloaded, isFalse);
    expect(loads.distroPhaseLoads['distro']!.l1A, 16);
  });

  test('splits group load across multiple outlet connections', () {
    final date = DateTime(2026, 7, 5);
    final outlets = [
      for (final phase in [PowerPhase.l1, PowerPhase.l2, PowerPhase.l3])
        for (final index in [1, 2])
          ProjectOutlet(
            id: '${phase.name}_$index',
            name: '${phase.name.toUpperCase()} $index',
            connectorTypeId: 'schuko_16a',
            phase: phase,
            maxCurrentA: 16,
          ),
    ];
    final project = Project(
      id: 'project',
      name: 'Project',
      createdAt: date,
      updatedAt: date,
      groups: const [
        ProjectGroup(
          id: 'group',
          name: 'Group',
          items: [
            ProjectItem(
              id: 'load',
              nameSnapshot: 'Load',
              quantity: 1,
              currentASnapshot: 45.6,
            ),
          ],
        ),
      ],
      distros: [
        ProjectDistro(
          id: 'distro',
          name: 'Distro',
          inputConnectorTypeId: 'cee_32a_5p',
          outlets: outlets,
        ),
      ],
      connections: [
        for (final outlet in outlets)
          PowerConnection(
            id: 'connection_${outlet.id}',
            sourceDistroId: 'distro',
            sourceOutletId: outlet.id,
            targetGroupId: 'group',
          ),
      ],
    );

    final loads = service.calculateProjectLoads(project);

    for (final outlet in outlets) {
      expect(loads.outletLoads[outlet.id]!.maxLoadedPhaseA, closeTo(7.6, 0.01));
      expect(loads.outletLoads[outlet.id]!.isOverloaded, isFalse);
    }
    expect(loads.distroPhaseLoads['distro']!.l1A, closeTo(15.2, 0.01));
    expect(loads.distroPhaseLoads['distro']!.l2A, closeTo(15.2, 0.01));
    expect(loads.distroPhaseLoads['distro']!.l3A, closeTo(15.2, 0.01));
    expect(loads.distroLoads['distro']!.isInputOverloaded, isFalse);
  });

  test('propagates child distro load to parent outlet', () {
    final date = DateTime(2026, 7, 5);
    final project = Project(
      id: 'project',
      name: 'Project',
      createdAt: date,
      updatedAt: date,
      groups: const [
        ProjectGroup(
          id: 'group',
          name: 'Child load',
          items: [
            ProjectItem(
              id: 'load',
              nameSnapshot: 'Load',
              quantity: 1,
              currentASnapshot: 12,
            ),
          ],
        ),
      ],
      distros: const [
        ProjectDistro(
          id: 'parent',
          name: 'Parent',
          inputConnectorTypeId: 'cee_32a_5p',
          outlets: [
            ProjectOutlet(
              id: 'parent_out',
              name: '32 A OUT',
              connectorTypeId: 'cee_32a_5p',
              phase: PowerPhase.all,
              maxCurrentA: 32,
            ),
          ],
        ),
        ProjectDistro(
          id: 'child',
          name: 'Child',
          inputConnectorTypeId: 'cee_32a_5p',
          outlets: [
            ProjectOutlet(
              id: 'child_out',
              name: 'L1',
              connectorTypeId: 'schuko_16a',
              phase: PowerPhase.l1,
              maxCurrentA: 16,
            ),
          ],
        ),
      ],
      connections: const [
        PowerConnection(
          id: 'parent_to_child',
          sourceDistroId: 'parent',
          sourceOutletId: 'parent_out',
          targetType: PowerConnectionTargetType.distro,
          targetGroupId: null,
          targetDistroId: 'child',
        ),
        PowerConnection(
          id: 'child_to_group',
          sourceDistroId: 'child',
          sourceOutletId: 'child_out',
          targetGroupId: 'group',
        ),
      ],
    );

    final loads = service.calculateProjectLoads(project);

    expect(loads.outletLoads['child_out']!.maxLoadedPhaseA, 12);
    expect(loads.outletLoads['parent_out']!.maxLoadedPhaseA, 12);
    expect(loads.distroPhaseLoads['parent']!.l1A, 12);
  });

  test('marks overloaded distro input', () {
    const distroLoad = DistroPowerLoad(
      distroId: 'distro',
      load: PowerPhaseLoad(l1A: 40, l2A: 20, l3A: 20),
      inputMaxCurrentA: 32,
    );

    expect(distroLoad.isInputOverloaded, isTrue);
    expect(distroLoad.isPhaseOverloaded(PowerPhase.l1), isTrue);
    expect(distroLoad.isPhaseOverloaded(PowerPhase.l2), isFalse);
    expect(distroLoad.isPhaseOverloaded(PowerPhase.l3), isFalse);
  });

  test('marks near-limit distro input and phase', () {
    const distroLoad = DistroPowerLoad(
      distroId: 'distro',
      load: PowerPhaseLoad(l1A: 28.8, l2A: 10, l3A: 0),
      inputMaxCurrentA: 32,
    );

    expect(distroLoad.isInputNearLimit, isTrue);
    expect(distroLoad.isInputOverloaded, isFalse);
    expect(distroLoad.isPhaseNearLimit(PowerPhase.l1), isTrue);
    expect(distroLoad.isPhaseNearLimit(PowerPhase.l2), isFalse);
  });

  test('marks overloaded outlet', () {
    const outletLoad = OutletPowerLoad(
      outletId: 'outlet',
      load: PowerPhaseLoad(l1A: 20),
      maxCurrentA: 16,
    );

    expect(outletLoad.isOverloaded, isTrue);
  });

  test('marks near-limit outlet', () {
    const outletLoad = OutletPowerLoad(
      outletId: 'outlet',
      load: PowerPhaseLoad(l1A: 14.4),
      maxCurrentA: 16,
    );

    expect(outletLoad.isNearLimit, isTrue);
    expect(outletLoad.isOverloaded, isFalse);
  });
}

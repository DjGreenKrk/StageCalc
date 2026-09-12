import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/projects/domain/entities/power_models.dart';
import 'package:stagecalc/features/projects/domain/entities/project_models.dart';
import 'package:stagecalc/features/projects/domain/services/patch_validation_service.dart';
import 'package:stagecalc/features/projects/domain/services/power_calculation_service.dart';

void main() {
  const service = PatchValidationService();

  test('detects duplicated outlet usage', () {
    final date = DateTime(2026, 7, 5);
    final project = Project(
      id: 'project',
      name: 'Project',
      createdAt: date,
      updatedAt: date,
      groups: const [
        ProjectGroup(id: 'group_a', name: 'A', items: []),
        ProjectGroup(id: 'group_b', name: 'B', items: []),
      ],
      connections: const [
        PowerConnection(
          id: 'connection_a',
          sourceDistroId: 'distro',
          sourceOutletId: 'outlet',
          targetGroupId: 'group_a',
        ),
        PowerConnection(
          id: 'connection_b',
          sourceDistroId: 'distro',
          sourceOutletId: 'outlet',
          targetGroupId: 'group_b',
        ),
      ],
    );

    final result = service.validate(
      project,
      const ProjectPowerLoad(outletLoads: {}, distroLoads: {}),
    );

    expect(result.hasWarnings, isTrue);
    expect(result.isOutletDuplicated('outlet'), isTrue);
  });

  test('detects a cycle between cascaded distros', () {
    final date = DateTime(2026, 7, 5);
    final project = Project(
      id: 'project',
      name: 'Project',
      createdAt: date,
      updatedAt: date,
      groups: const [],
      distros: const [
        ProjectDistro(
          id: 'a',
          name: 'A',
          outlets: [
            ProjectOutlet(
              id: 'a_out',
              name: 'Out',
              connectorTypeId: 'cee_32a_5p',
              phase: PowerPhase.all,
              maxCurrentA: 32,
            ),
          ],
        ),
        ProjectDistro(
          id: 'b',
          name: 'B',
          outlets: [
            ProjectOutlet(
              id: 'b_out',
              name: 'Out',
              connectorTypeId: 'cee_32a_5p',
              phase: PowerPhase.all,
              maxCurrentA: 32,
            ),
          ],
        ),
      ],
      connections: const [
        PowerConnection(
          id: 'a_to_b',
          sourceDistroId: 'a',
          sourceOutletId: 'a_out',
          targetType: PowerConnectionTargetType.distro,
          targetGroupId: null,
          targetDistroId: 'b',
        ),
        PowerConnection(
          id: 'b_to_a',
          sourceDistroId: 'b',
          sourceOutletId: 'b_out',
          targetType: PowerConnectionTargetType.distro,
          targetGroupId: null,
          targetDistroId: 'a',
        ),
      ],
    );

    final result = service.validate(
      project,
      const ProjectPowerLoad(outletLoads: {}, distroLoads: {}),
    );

    expect(result.hasWarnings, isTrue);
    expect(result.isDistroInCycle('a'), isTrue);
    expect(result.isDistroInCycle('b'), isTrue);
  });

  test('does not flag a plain cascade (no cycle) as cyclic', () {
    final date = DateTime(2026, 7, 5);
    final project = Project(
      id: 'project',
      name: 'Project',
      createdAt: date,
      updatedAt: date,
      groups: const [],
      distros: const [
        ProjectDistro(
          id: 'parent',
          name: 'Parent',
          outlets: [
            ProjectOutlet(
              id: 'parent_out',
              name: 'Out',
              connectorTypeId: 'cee_32a_5p',
              phase: PowerPhase.all,
              maxCurrentA: 32,
            ),
          ],
        ),
        ProjectDistro(
          id: 'child',
          name: 'Child',
          outlets: [
            ProjectOutlet(
              id: 'child_out',
              name: 'Out',
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
      ],
    );

    final result = service.validate(
      project,
      const ProjectPowerLoad(outletLoads: {}, distroLoads: {}),
    );

    expect(result.cyclicDistroIds, isEmpty);
  });

  test(
    'exposes overload from the computed power load as a validation state',
    () {
      final date = DateTime(2026, 7, 5);
      final project = Project(
        id: 'project',
        name: 'Project',
        createdAt: date,
        updatedAt: date,
        groups: const [],
      );

      final result = service.validate(
        project,
        const ProjectPowerLoad(
          outletLoads: {
            'outlet': OutletPowerLoad(
              outletId: 'outlet',
              load: PowerPhaseLoad(l1A: 20),
              maxCurrentA: 16,
            ),
          },
          distroLoads: {
            'distro': DistroPowerLoad(
              distroId: 'distro',
              load: PowerPhaseLoad(l1A: 40),
              inputMaxCurrentA: 32,
            ),
          },
        ),
      );

      expect(result.hasWarnings, isTrue);
      expect(result.isOutletOverloaded('outlet'), isTrue);
      expect(result.isDistroOverloaded('distro'), isTrue);
    },
  );
}

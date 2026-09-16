import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';
import 'package:stagecalc/features/projects/domain/entities/project_models.dart';
import 'package:stagecalc/features/projects/domain/services/truss_load_service.dart';

void main() {
  const service = TrussLoadService();

  Project buildProject({
    required List<ProjectGroup> groups,
    required ProjectTruss truss,
  }) {
    final date = DateTime(2026, 7, 5);
    return Project(
      id: 'project',
      name: 'Project',
      createdAt: date,
      updatedAt: date,
      groups: groups,
      trusses: [truss],
    );
  }

  test('sums the weight of assigned groups plus the manual load', () {
    final truss = const ProjectTruss(
      id: 'truss',
      name: 'Truss',
      lengthM: 4,
      manualLoadKg: 10,
      assignedGroupIds: ['g1', 'g2'],
    );
    final project = buildProject(
      groups: const [
        ProjectGroup(
          id: 'g1',
          name: 'Lighting',
          items: [
            ProjectItem(
              id: 'i1',
              nameSnapshot: 'Fixture',
              quantity: 4,
              weightKgSnapshot: 5,
            ),
          ],
        ),
        ProjectGroup(
          id: 'g2',
          name: 'Speakers',
          items: [
            ProjectItem(
              id: 'i2',
              nameSnapshot: 'Speaker',
              quantity: 2,
              weightKgSnapshot: 15,
            ),
          ],
        ),
        // Not assigned to the truss - must not count towards its mass.
        ProjectGroup(
          id: 'g3',
          name: 'Unrelated',
          items: [
            ProjectItem(
              id: 'i3',
              nameSnapshot: 'Something else',
              quantity: 100,
              weightKgSnapshot: 100,
            ),
          ],
        ),
      ],
      truss: truss,
    );

    final load = service.calculateLoad(truss, project);

    // g1: 4*5 = 20kg, g2: 2*15 = 30kg, + manual 10kg = 60kg total.
    expect(load.groupsMassKg, 50);
    expect(load.totalMassKg, 60);
    expect(load.distributedLoadKgPerM, 15); // 60kg / 4m
  });

  test('reports unknown limits when neither is set', () {
    const truss = ProjectTruss(id: 'truss', name: 'Truss', lengthM: 4);
    final project = buildProject(groups: const [], truss: truss);

    final load = service.calculateLoad(truss, project);

    expect(load.hasKnownLimits, isFalse);
    expect(load.isOverloaded, isFalse);
  });

  test('flags an overloaded total limit', () {
    const truss = ProjectTruss(
      id: 'truss',
      name: 'Truss',
      lengthM: 4,
      manualLoadKg: 500,
      maxTotalLoadKg: 400,
    );
    final project = buildProject(groups: const [], truss: truss);

    final load = service.calculateLoad(truss, project);

    expect(load.isOverTotalLimit, isTrue);
    expect(load.isOverloaded, isTrue);
  });

  test('flags a near-limit distributed load without being overloaded', () {
    const truss = ProjectTruss(
      id: 'truss',
      name: 'Truss',
      lengthM: 4,
      manualLoadKg: 36, // 9 kg/m of 10 kg/m limit -> 90%
      maxDistributedLoadKgPerM: 10,
    );
    final project = buildProject(groups: const [], truss: truss);

    final load = service.calculateLoad(truss, project);

    expect(load.isNearDistributedLimit, isTrue);
    expect(load.isOverDistributedLimit, isFalse);
    expect(load.isOverloaded, isFalse);
  });

  test(
    'treats a zero-length truss as having no distributed load instead of dividing by zero',
    () {
      const truss = ProjectTruss(id: 'truss', name: 'Truss', manualLoadKg: 50);
      final project = buildProject(groups: const [], truss: truss);

      final load = service.calculateLoad(truss, project);

      expect(load.distributedLoadKgPerM, 0);
    },
  );

  group('hookRequirement', () {
    test('sums riggingPointsSnapshot across items, times their quantity', () {
      const group = ProjectGroup(
        id: 'g1',
        name: 'Moving heads',
        items: [
          ProjectItem(
            id: 'i1',
            nameSnapshot: 'Moving head',
            quantity: 3,
            riggingPointsSnapshot: 2,
          ),
          // No rigging points at all - must contribute nothing.
          ProjectItem(id: 'i2', nameSnapshot: 'Cable', quantity: 10),
        ],
      );

      final requirement = service.hookRequirement(group);

      expect(requirement.requiredHooks, 6);
      expect(requirement.assignedHooks, 0);
      expect(requirement.isSatisfied, isFalse);
    });

    test('counts assigned hooks and their weight', () {
      const group = ProjectGroup(
        id: 'g1',
        name: 'Moving heads',
        items: [
          ProjectItem(
            id: 'i1',
            nameSnapshot: 'Moving head',
            quantity: 2,
            riggingPointsSnapshot: 2,
          ),
        ],
        hookAssignments: [
          ProjectGroupHookAssignment(
            id: 'hook1',
            hookNameSnapshot: 'Half coupler',
            hookWeightKgSnapshot: 0.3,
            quantity: 4,
          ),
        ],
      );

      final requirement = service.hookRequirement(group);

      expect(requirement.requiredHooks, 4);
      expect(requirement.assignedHooks, 4);
      expect(requirement.hooksWeightKg, closeTo(1.2, 0.0001));
      expect(requirement.isSatisfied, isTrue);
    });
  });

  test('adds hook weight from assigned groups on top of their item weight', () {
    final truss = const ProjectTruss(
      id: 'truss',
      name: 'Truss',
      lengthM: 4,
      assignedGroupIds: ['g1'],
    );
    final project = buildProject(
      groups: const [
        ProjectGroup(
          id: 'g1',
          name: 'Moving heads',
          items: [
            ProjectItem(
              id: 'i1',
              nameSnapshot: 'Moving head',
              quantity: 2,
              weightKgSnapshot: 10,
            ),
          ],
          hookAssignments: [
            ProjectGroupHookAssignment(
              id: 'hook1',
              hookNameSnapshot: 'Half coupler',
              hookWeightKgSnapshot: 0.5,
              quantity: 4,
            ),
          ],
        ),
      ],
      truss: truss,
    );

    final load = service.calculateLoad(truss, project);

    // 2*10kg items + 4*0.5kg hooks = 22kg.
    expect(load.groupsMassKg, 22);
  });

  group('interpolated limits from a linked catalog device', () {
    final trussDevice = CatalogDevice(
      id: 'prolyte_h30v',
      name: 'Prolyte H30V',
      category: CatalogDeviceCategory.rigging,
      quantityUnit: CatalogQuantityUnit.pcs,
      createdAt: DateTime(2026, 7, 5),
      updatedAt: DateTime(2026, 7, 5),
      loadChart: const [
        TrussLoadChartEntry(
          id: 'c1',
          lengthM: 4,
          pointLoadKg: 800,
          distributedLoadKgPerM: 200,
        ),
        TrussLoadChartEntry(
          id: 'c2',
          lengthM: 8,
          pointLoadKg: 400,
          distributedLoadKgPerM: 100,
        ),
      ],
    );

    Project buildProjectWithDevice(ProjectTruss truss) {
      final date = DateTime(2026, 7, 5);
      return Project(
        id: 'project',
        name: 'Project',
        createdAt: date,
        updatedAt: date,
        groups: const [],
        trusses: [truss],
      );
    }

    test('uses the exact chart entry when the length matches exactly', () {
      const truss = ProjectTruss(
        id: 'truss',
        name: 'Truss',
        lengthM: 4,
        trussCatalogDeviceId: 'prolyte_h30v',
      );

      final load = service.calculateLoad(
        truss,
        buildProjectWithDevice(truss),
        catalogDevices: [trussDevice],
      );

      expect(load.maxTotalLoadKg, 800);
      expect(load.maxDistributedLoadKgPerM, 200);
      expect(load.totalLimitFromChart, isTrue);
      expect(load.isChartExtrapolated, isFalse);
    });

    test('interpolates linearly between two chart entries', () {
      const truss = ProjectTruss(
        id: 'truss',
        name: 'Truss',
        lengthM: 6, // Halfway between 4m and 8m.
        trussCatalogDeviceId: 'prolyte_h30v',
      );

      final load = service.calculateLoad(
        truss,
        buildProjectWithDevice(truss),
        catalogDevices: [trussDevice],
      );

      expect(load.maxTotalLoadKg, 600);
      expect(load.maxDistributedLoadKgPerM, 150);
      expect(load.isChartExtrapolated, isFalse);
    });

    test('extrapolates and flags it when the length is outside the table', () {
      const truss = ProjectTruss(
        id: 'truss',
        name: 'Truss',
        lengthM: 12,
        trussCatalogDeviceId: 'prolyte_h30v',
      );

      final load = service.calculateLoad(
        truss,
        buildProjectWithDevice(truss),
        catalogDevices: [trussDevice],
      );

      // Same slope as 4m->8m, extended to 12m: 400 - 4/4*400 = 0.
      expect(load.maxTotalLoadKg, 0);
      expect(load.isChartExtrapolated, isTrue);
    });

    test('a manually entered limit wins over the interpolated one', () {
      const truss = ProjectTruss(
        id: 'truss',
        name: 'Truss',
        lengthM: 4,
        trussCatalogDeviceId: 'prolyte_h30v',
        maxTotalLoadKg: 500,
      );

      final load = service.calculateLoad(
        truss,
        buildProjectWithDevice(truss),
        catalogDevices: [trussDevice],
      );

      expect(load.maxTotalLoadKg, 500);
      expect(load.totalLimitFromChart, isFalse);
      // The distributed limit is still untouched, so it still comes from
      // the chart - the manual override only applies per-field.
      expect(load.maxDistributedLoadKgPerM, 200);
      expect(load.distributedLimitFromChart, isTrue);
    });

    test(
      'treats a stored 0 manual limit as unset, falling back to the chart',
      () {
        const truss = ProjectTruss(
          id: 'truss',
          name: 'Truss',
          lengthM: 4,
          trussCatalogDeviceId: 'prolyte_h30v',
          maxTotalLoadKg: 0,
          maxDistributedLoadKgPerM: 0,
        );

        final load = service.calculateLoad(
          truss,
          buildProjectWithDevice(truss),
          catalogDevices: [trussDevice],
        );

        // A real manufacturer limit of 0 makes no physical sense - a stored
        // 0 (whatever put it there) must not silently win over the chart via
        // `??`, which only ever substitutes for `null`.
        expect(load.maxTotalLoadKg, 800);
        expect(load.totalLimitFromChart, isTrue);
        expect(load.maxDistributedLoadKgPerM, 200);
        expect(load.distributedLimitFromChart, isTrue);
      },
    );

    test(
      'treats a stored 0 manual limit as unknown when no device is linked',
      () {
        const truss = ProjectTruss(
          id: 'truss',
          name: 'Truss',
          lengthM: 4,
          maxTotalLoadKg: 0,
          maxDistributedLoadKgPerM: 0,
        );

        final load = service.calculateLoad(
          truss,
          buildProjectWithDevice(truss),
          catalogDevices: [trussDevice],
        );

        expect(load.hasKnownLimits, isFalse);
        expect(load.maxTotalLoadKg, isNull);
        expect(load.maxDistributedLoadKgPerM, isNull);
      },
    );

    test('reports no interpolated limits without a linked device', () {
      const truss = ProjectTruss(id: 'truss', name: 'Truss', lengthM: 4);

      final load = service.calculateLoad(
        truss,
        buildProjectWithDevice(truss),
        catalogDevices: [trussDevice],
      );

      expect(load.hasInterpolatedLimits, isFalse);
      expect(load.maxTotalLoadKg, isNull);
    });
  });
}

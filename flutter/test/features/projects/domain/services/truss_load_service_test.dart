import 'package:flutter_test/flutter_test.dart';
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
}

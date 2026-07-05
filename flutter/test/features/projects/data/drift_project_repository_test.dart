import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/projects/data/drift_project_repository.dart';
import 'package:stagecalc/features/projects/domain/entities/power_models.dart';
import 'package:stagecalc/features/projects/domain/entities/project_models.dart';
import 'package:stagecalc/infrastructure/local_database/app_database.dart'
    as db;

void main() {
  late db.AppDatabase database;
  late DriftProjectRepository repository;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftProjectRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('saves and loads projects from sqlite', () async {
    final now = DateTime(2026, 7, 5);
    final project = Project(
      id: 'project_sqlite',
      name: 'Projekt SQLite',
      createdAt: now,
      updatedAt: now,
      groups: const [
        ProjectGroup(
          id: 'group_sqlite',
          name: 'Front',
          items: [
            ProjectItem(
              id: 'item_sqlite',
              nameSnapshot: 'LED Bar',
              quantity: 4,
              powerWSnapshot: 120,
              currentASnapshot: 0.6,
              weightKgSnapshot: 6,
            ),
          ],
        ),
      ],
    );

    await repository.saveProject(project);
    final projects = await repository.getProjects();

    expect(projects, hasLength(1));
    expect(projects.single.name, 'Projekt SQLite');
    expect(projects.single.groups.single.name, 'Front');
    expect(projects.single.groups.single.items.single.nameSnapshot, 'LED Bar');
  });

  test('saves project client and location references', () async {
    final now = DateTime(2026, 7, 5);
    final project = Project(
      id: 'project_refs',
      name: 'Projekt z relacjami',
      clientId: 'client_refs',
      locationId: 'location_refs',
      createdAt: now,
      updatedAt: now,
      groups: const [],
    );

    await repository.saveProject(project);
    final projects = await repository.getProjects();

    expect(projects.single.clientId, 'client_refs');
    expect(projects.single.locationId, 'location_refs');
  });

  test('saves project distros and outlets from sqlite', () async {
    final now = DateTime(2026, 7, 5);
    final project = Project(
      id: 'project_distro',
      name: 'Projekt z rozdzielnica',
      createdAt: now,
      updatedAt: now,
      groups: const [],
      distros: const [
        ProjectDistro(
          id: 'distro_sqlite',
          name: 'Rozdzielnia FOH',
          presetId: 'preset_sqlite',
          inputConnectorTypeId: 'cee_32a_5p',
          isRootPowerSource: true,
          outlets: [
            ProjectOutlet(
              id: 'outlet_sqlite',
              name: 'L1 A',
              connectorTypeId: 'schuko_16a',
              phase: PowerPhase.l1,
              maxCurrentA: 16,
            ),
          ],
        ),
      ],
    );

    await repository.saveProject(project);
    final projects = await repository.getProjects();
    final distro = projects.single.distros.single;

    expect(distro.name, 'Rozdzielnia FOH');
    expect(distro.isRootPowerSource, isTrue);
    expect(distro.outlets.single.phase, PowerPhase.l1);
    expect(distro.outlets.single.maxCurrentA, 16);
  });

  test('saves project power connections from sqlite', () async {
    final now = DateTime(2026, 7, 5);
    final project = Project(
      id: 'project_connection',
      name: 'Projekt z polaczeniem',
      createdAt: now,
      updatedAt: now,
      groups: const [
        ProjectGroup(id: 'group_connection', name: 'Front', items: []),
      ],
      distros: const [
        ProjectDistro(
          id: 'distro_connection',
          name: 'Rozdzielnia',
          outlets: [
            ProjectOutlet(
              id: 'outlet_connection',
              name: 'L1 A',
              connectorTypeId: 'schuko_16a',
              phase: PowerPhase.l1,
              maxCurrentA: 16,
            ),
          ],
        ),
      ],
      connections: const [
        PowerConnection(
          id: 'connection_sqlite',
          sourceDistroId: 'distro_connection',
          sourceOutletId: 'outlet_connection',
          targetGroupId: 'group_connection',
        ),
      ],
    );

    await repository.saveProject(project);
    final projects = await repository.getProjects();
    final connection = projects.single.connections.single;

    expect(connection.sourceOutletId, 'outlet_connection');
    expect(connection.targetGroupId, 'group_connection');
    expect(connection.targetType, PowerConnectionTargetType.group);
  });

  test('saves project trusses from sqlite', () async {
    final now = DateTime(2026, 7, 5);
    final project = Project(
      id: 'project_truss',
      name: 'Projekt z kratownica',
      createdAt: now,
      updatedAt: now,
      groups: const [
        ProjectGroup(id: 'group_truss', name: 'Rig front', items: []),
      ],
      trusses: const [
        ProjectTruss(
          id: 'truss_sqlite',
          name: 'Front 12 m',
          trussSystemId: 'prolyte_h30v',
          lengthM: 12,
          maxTotalLoadKg: 720,
          maxDistributedLoadKgPerM: 60,
          manualLoadKg: 35,
          assignedGroupIds: ['group_truss'],
          notes: 'Pierwszy model danych kratownic.',
        ),
      ],
    );

    await repository.saveProject(project);
    final projects = await repository.getProjects();
    final truss = projects.single.trusses.single;

    expect(truss.name, 'Front 12 m');
    expect(truss.trussSystemId, 'prolyte_h30v');
    expect(truss.lengthM, 12);
    expect(truss.maxTotalLoadKg, 720);
    expect(truss.maxDistributedLoadKgPerM, 60);
    expect(truss.manualLoadKg, 35);
    expect(truss.assignedGroupIds, ['group_truss']);
    expect(truss.notes, 'Pierwszy model danych kratownic.');
  });

  test('soft deletes removed groups and items on project save', () async {
    final now = DateTime(2026, 7, 5);
    final project = Project(
      id: 'project_sqlite',
      name: 'Projekt SQLite',
      createdAt: now,
      updatedAt: now,
      groups: const [
        ProjectGroup(
          id: 'group_sqlite',
          name: 'Front',
          items: [
            ProjectItem(
              id: 'item_sqlite',
              nameSnapshot: 'LED Bar',
              quantity: 4,
            ),
          ],
        ),
      ],
    );

    await repository.saveProject(project);
    await repository.saveProject(
      project.copyWith(
        groups: const [],
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
    );

    final projects = await repository.getProjects();

    expect(projects.single.groups, isEmpty);
  });
}

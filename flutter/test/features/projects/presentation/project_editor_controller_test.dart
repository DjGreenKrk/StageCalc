import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/projects/data/drift_project_repository.dart';
import 'package:stagecalc/features/projects/domain/entities/project_models.dart';
import 'package:stagecalc/features/projects/presentation/project_editor_controller.dart';
import 'package:stagecalc/infrastructure/local_database/app_database.dart'
    as db;

void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'deleting a group removes its id from every truss assignedGroupIds',
    () async {
      final now = DateTime(2026, 7, 5);
      final repository = DriftProjectRepository(database);
      final project = Project(
        id: 'project',
        name: 'Project',
        createdAt: now,
        updatedAt: now,
        groups: const [
          ProjectGroup(id: 'group_1', name: 'Lighting', items: []),
        ],
        trusses: const [
          ProjectTruss(
            id: 'truss_1',
            name: 'Main truss',
            assignedGroupIds: ['group_1'],
          ),
        ],
      );
      await repository.saveProject(project);

      final controller = ProjectEditorController(
        project: project,
        repository: repository,
      );

      await controller.deleteGroup(project.groups.single);

      expect(controller.project.groups, isEmpty);
      expect(controller.project.trusses.single.assignedGroupIds, isEmpty);

      final reloaded = (await repository.getProjects()).single;
      expect(reloaded.trusses.single.assignedGroupIds, isEmpty);
    },
  );
}

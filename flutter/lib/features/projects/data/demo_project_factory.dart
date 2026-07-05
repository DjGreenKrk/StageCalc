import '../domain/entities/project_models.dart';

class DemoProjectFactory {
  const DemoProjectFactory._();

  static Project createDemoProject() {
    return Project(
      id: 'demo_project',
      name: 'Demo techniczne',
      createdAt: DateTime(2026, 7, 5),
      updatedAt: DateTime(2026, 7, 5),
      groups: const [
        ProjectGroup(
          id: 'lighting',
          name: 'Front light',
          items: [
            ProjectItem(
              id: 'robe_1',
              nameSnapshot: 'Robe BMFL Spot',
              manufacturerSnapshot: 'Robe',
              quantity: 4,
              powerWSnapshot: 2000,
              currentASnapshot: 8.7,
              weightKgSnapshot: 36,
            ),
            ProjectItem(
              id: 'par_1',
              nameSnapshot: 'LED Par RGBW',
              manufacturerSnapshot: 'Generic',
              quantity: 12,
              powerWSnapshot: 200,
              currentASnapshot: 0.9,
              weightKgSnapshot: 4,
            ),
          ],
        ),
      ],
    );
  }
}

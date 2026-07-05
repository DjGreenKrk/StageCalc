import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/projects/domain/entities/project_models.dart';
import 'package:stagecalc/features/projects/domain/services/project_totals_service.dart';

void main() {
  test('calculates project totals from snapshot values', () {
    final project = Project(
      id: 'project',
      name: 'Test',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      groups: const [
        ProjectGroup(
          id: 'group',
          name: 'Group',
          items: [
            ProjectItem(
              id: 'fixture',
              nameSnapshot: 'Fixture',
              quantity: 4,
              powerWSnapshot: 250,
              currentASnapshot: 1.1,
              weightKgSnapshot: 6.5,
            ),
            ProjectItem(
              id: 'distro',
              nameSnapshot: 'Distro',
              quantity: 1,
              powerWSnapshot: 0,
              currentASnapshot: 0,
              weightKgSnapshot: 12,
            ),
          ],
        ),
      ],
    );

    const service = ProjectTotalsService();
    final totals = service.calculate(project);

    expect(totals.powerW, 1000);
    expect(totals.currentA, 4.4);
    expect(totals.weightKg, 38);
  });
}

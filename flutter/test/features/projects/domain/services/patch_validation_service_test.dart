import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/projects/domain/entities/project_models.dart';
import 'package:stagecalc/features/projects/domain/services/patch_validation_service.dart';

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

    final result = service.validate(project);

    expect(result.hasWarnings, isTrue);
    expect(result.isOutletDuplicated('outlet'), isTrue);
  });
}

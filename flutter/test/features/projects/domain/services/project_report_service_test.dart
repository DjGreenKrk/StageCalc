import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/projects/domain/entities/power_models.dart';
import 'package:stagecalc/features/projects/domain/entities/project_models.dart';
import 'package:stagecalc/features/projects/domain/services/project_report_service.dart';

void main() {
  const service = ProjectReportService();
  final generatedAt = DateTime(2026, 7, 5, 14, 30);

  test('includes project name, totals and group items', () {
    final project = Project(
      id: 'project',
      name: 'Koncert testowy',
      createdAt: generatedAt,
      updatedAt: generatedAt,
      groups: const [
        ProjectGroup(
          id: 'group',
          name: 'Front light',
          items: [
            ProjectItem(
              id: 'item',
              nameSnapshot: 'Robe BMFL Spot',
              manufacturerSnapshot: 'Robe',
              quantity: 4,
              powerWSnapshot: 2000,
              currentASnapshot: 8.7,
              weightKgSnapshot: 36,
            ),
          ],
        ),
      ],
    );

    final report = service.buildTextReport(project, generatedAt: generatedAt);

    expect(report, contains('RAPORT TECHNICZNY - Koncert testowy'));
    expect(report, contains('Wygenerowano: 2026-07-05 14:30'));
    expect(report, contains('Moc: 8.0 kW'));
    expect(report, contains('Prad: 34.8 A'));
    expect(report, contains('Masa: 144 kg'));
    expect(report, contains('Front light'));
    expect(report, contains('4x Robe BMFL Spot (Robe)'));
  });

  test('flags a duplicated outlet and an overloaded distro input', () {
    final project = Project(
      id: 'project',
      name: 'Project',
      createdAt: generatedAt,
      updatedAt: generatedAt,
      groups: const [
        ProjectGroup(
          id: 'group',
          name: 'Load',
          items: [
            ProjectItem(
              id: 'item',
              nameSnapshot: 'Load',
              quantity: 1,
              currentASnapshot: 40,
            ),
          ],
        ),
      ],
      distros: const [
        ProjectDistro(
          id: 'distro',
          name: 'Distro',
          inputConnectorTypeId: 'schuko_16a',
          outlets: [
            ProjectOutlet(
              id: 'outlet',
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
          id: 'c1',
          sourceDistroId: 'distro',
          sourceOutletId: 'outlet',
          targetGroupId: 'group',
        ),
        PowerConnection(
          id: 'c2',
          sourceDistroId: 'distro',
          sourceOutletId: 'outlet',
          targetGroupId: 'group',
        ),
      ],
    );

    final report = service.buildTextReport(project, generatedAt: generatedAt);

    expect(report, contains('GNIAZDO UZYTE WIELOKROTNIE'));
    expect(report, contains('OSTRZEZENIE: przeciazone wejscie'));
  });

  test('flags an overloaded truss and one with unknown limits', () {
    final project = Project(
      id: 'project',
      name: 'Project',
      createdAt: generatedAt,
      updatedAt: generatedAt,
      groups: const [],
      trusses: const [
        ProjectTruss(
          id: 't1',
          name: 'Overloaded',
          lengthM: 4,
          manualLoadKg: 500,
          maxTotalLoadKg: 400,
        ),
        ProjectTruss(id: 't2', name: 'Unknown limits', lengthM: 4),
      ],
    );

    final report = service.buildTextReport(project, generatedAt: generatedAt);

    expect(report, contains('Overloaded'));
    expect(report, contains('OSTRZEZENIE: przekroczony limit obciazenia'));
    expect(report, contains('Unknown limits'));
    expect(report, contains('Brak zdefiniowanych limitow obciazenia.'));
  });

  test('shows empty-state lines for a project with nothing in it', () {
    final project = Project(
      id: 'project',
      name: 'Empty project',
      createdAt: generatedAt,
      updatedAt: generatedAt,
      groups: const [],
    );

    final report = service.buildTextReport(project, generatedAt: generatedAt);

    expect(report, contains('Brak grup.'));
    expect(report, contains('Brak rozdzielnic.'));
    expect(report, contains('Brak kratownic.'));
  });
}

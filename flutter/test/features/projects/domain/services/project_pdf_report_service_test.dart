import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/projects/domain/entities/power_models.dart';
import 'package:stagecalc/features/projects/domain/entities/project_models.dart';
import 'package:stagecalc/features/projects/domain/services/project_pdf_report_service.dart';

void main() {
  const service = ProjectPdfReportService();
  final generatedAt = DateTime(2026, 7, 5, 14, 30);

  // The `pdf` package has no text-extraction API, so unlike
  // `project_report_service_test.dart` these tests cannot assert on the
  // rendered content - only that a well-formed PDF comes out the other end
  // for the same project shapes the text report is tested against
  // (duplicated outlets, overloaded trusses, an empty project), including
  // ones that stress table/page layout (many groups).
  void expectValidPdf(List<int> bytes) {
    expect(bytes, isNotEmpty);
    expect(
      String.fromCharCodes(bytes.take(5)),
      '%PDF-',
      reason: 'output does not start with the PDF file signature',
    );
  }

  test('builds a PDF for a project with groups, distros and trusses', () async {
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

    final bytes = await service.buildPdfReport(
      project,
      generatedAt: generatedAt,
    );

    expectValidPdf(bytes);
  });

  test('builds a PDF for a project with nothing in it', () async {
    final project = Project(
      id: 'project',
      name: 'Empty project',
      createdAt: generatedAt,
      updatedAt: generatedAt,
      groups: const [],
    );

    final bytes = await service.buildPdfReport(
      project,
      generatedAt: generatedAt,
    );

    expectValidPdf(bytes);
  });

  test('builds a multi-page PDF for a project with many groups', () async {
    final project = Project(
      id: 'project',
      name: 'Duzy projekt',
      createdAt: generatedAt,
      updatedAt: generatedAt,
      groups: [
        for (var i = 0; i < 40; i++)
          ProjectGroup(
            id: 'group_$i',
            name: 'Grupa $i',
            items: [
              ProjectItem(
                id: 'item_$i',
                nameSnapshot: 'Urzadzenie $i',
                quantity: 2,
                weightKgSnapshot: 10,
              ),
            ],
          ),
      ],
    );

    final bytes = await service.buildPdfReport(
      project,
      generatedAt: generatedAt,
    );

    expectValidPdf(bytes);
  });
}

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../entities/power_models.dart';
import '../entities/project_models.dart';
import 'patch_validation_service.dart';
import 'power_calculation_service.dart';
import 'project_totals_service.dart';
import 'truss_load_service.dart';

const _greenCrewGreen = PdfColor.fromInt(0xFF00C853);

/// Builds a GreenCrew-styled PDF version of the same report as
/// [ProjectReportService] (ADR-021), using the same domain services (ADR-014:
/// a report must not duplicate calculation logic, so its numbers can never
/// drift from what the app itself shows).
///
/// This was deliberately deferred at ADR-021 time - a new dependency and
/// real layout work - in favour of shipping the plain-text report first,
/// which `docs/FEATURE_SCOPE.md` explicitly allows for MVP. PDF is an
/// additional export option now, not a replacement for the text report.
class ProjectPdfReportService {
  const ProjectPdfReportService([
    this._totalsService = const ProjectTotalsService(),
    this._powerService = const PowerCalculationService(),
    this._validationService = const PatchValidationService(),
    this._trussLoadService = const TrussLoadService(),
  ]);

  final ProjectTotalsService _totalsService;
  final PowerCalculationService _powerService;
  final PatchValidationService _validationService;
  final TrussLoadService _trussLoadService;

  Future<Uint8List> buildPdfReport(
    Project project, {
    DateTime? generatedAt,
  }) async {
    final totals = _totalsService.calculate(project);
    final powerLoads = _powerService.calculateProjectLoads(project);
    final patchValidation = _validationService.validate(project, powerLoads);

    // Roboto (bundled under assets/fonts/, OFL-1.1) instead of the `pdf`
    // package's default Helvetica - Helvetica has no Unicode support, so
    // without this every Polish diacritic in the report would render as a
    // missing/broken glyph.
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );

    final document = pw.Document(
      title: 'Raport - ${project.name}',
      author: 'StageCalc',
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    document.addPage(
      pw.MultiPage(
        header: (context) => _buildPageHeader(project, generatedAt),
        footer: (context) => _buildPageFooter(context),
        build: (context) => [
          _buildSummarySection(totals),
          pw.SizedBox(height: 16),
          _buildGroupsSection(project),
          pw.SizedBox(height: 16),
          _buildDistrosSection(project, powerLoads, patchValidation),
          pw.SizedBox(height: 16),
          _buildTrussesSection(project),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _buildPageHeader(Project project, DateTime? generatedAt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              project.name,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'StageCalc',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _greenCrewGreen,
              ),
            ),
          ],
        ),
        pw.Text(
          'Wygenerowano: ${_formatDateTime(generatedAt ?? DateTime.now())}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.Divider(color: _greenCrewGreen, thickness: 2, height: 12),
      ],
    );
  }

  pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Strona ${context.pageNumber} / ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildSummarySection(ProjectTotals totals) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Podsumowanie'),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: _greenCrewGreen),
          cellAlignment: pw.Alignment.centerLeft,
          headers: const ['Moc', 'Prąd', 'Masa'],
          data: [
            [
              '${totals.powerKw.toStringAsFixed(1)} kW',
              '${totals.currentA.toStringAsFixed(1)} A',
              '${totals.weightKg.toStringAsFixed(0)} kg',
            ],
          ],
        ),
      ],
    );
  }

  pw.Widget _buildGroupsSection(Project project) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Grupy urządzeń'),
        if (project.groups.isEmpty)
          pw.Text('Brak grup.')
        else
          for (final group in project.groups) ...[
            _buildGroupTable(group),
            pw.SizedBox(height: 8),
          ],
      ],
    );
  }

  pw.Widget _buildGroupTable(ProjectGroup group) {
    final groupTotals = _totalsService.calculateGroup(group);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '${group.name} - ${groupTotals.powerKw.toStringAsFixed(1)} kW, '
          '${groupTotals.currentA.toStringAsFixed(1)} A, '
          '${groupTotals.weightKg.toStringAsFixed(0)} kg',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        if (group.items.isEmpty)
          pw.Text('Brak pozycji.', style: const pw.TextStyle(fontSize: 9))
        else
          pw.TableHelper.fromTextArray(
            headerStyle: const pw.TextStyle(fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const ['Ilość', 'Nazwa', 'Producent', 'Masa'],
            data: [
              for (final item in group.items)
                [
                  item.quantity.toStringAsFixed(0),
                  item.nameSnapshot,
                  item.manufacturerSnapshot ?? '-',
                  '${(item.weightKgSnapshot * item.quantity).toStringAsFixed(1)} kg',
                ],
            ],
          ),
      ],
    );
  }

  pw.Widget _buildDistrosSection(
    Project project,
    ProjectPowerLoad powerLoads,
    PatchValidationResult patchValidation,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Rozdzielnice'),
        if (project.distros.isEmpty)
          pw.Text('Brak rozdzielnic.')
        else
          for (final distro in project.distros) ...[
            _buildDistroBlock(distro, powerLoads, patchValidation),
            pw.SizedBox(height: 8),
          ],
      ],
    );
  }

  pw.Widget _buildDistroBlock(
    ProjectDistro distro,
    ProjectPowerLoad powerLoads,
    PatchValidationResult patchValidation,
  ) {
    final distroLoad = powerLoads.distroLoads[distro.id];
    final warnings = <String>[
      if (distroLoad != null && distroLoad.isInputOverloaded)
        'Przeciążone wejście (limit '
            '${distroLoad.inputMaxCurrentA.toStringAsFixed(0)} A)',
      if (patchValidation.isDistroInCycle(distro.id))
        'Rozdzielnica jest częścią cyklu połączeń - wynik może być '
            'niekompletny',
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '${distro.name}'
          '${distroLoad == null ? '' : ' - L1: ${distroLoad.load.l1A.toStringAsFixed(1)} A, '
                    'L2: ${distroLoad.load.l2A.toStringAsFixed(1)} A, '
                    'L3: ${distroLoad.load.l3A.toStringAsFixed(1)} A'}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        for (final warning in warnings)
          pw.Text(
            'Ostrzeżenie: $warning',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.red700),
          ),
        if (distro.outlets.isNotEmpty)
          pw.TableHelper.fromTextArray(
            headerStyle: const pw.TextStyle(fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const ['Gniazdo', 'Faza', 'Obciążenie', 'Uwagi'],
            data: [
              for (final outlet in distro.outlets)
                [
                  outlet.name,
                  _phaseLabel(outlet.phase),
                  '${(powerLoads.outletLoads[outlet.id]?.maxLoadedPhaseA ?? 0).toStringAsFixed(1)}/'
                      '${outlet.maxCurrentA.toStringAsFixed(0)} A',
                  [
                    if (patchValidation.isOutletDuplicated(outlet.id))
                      'użyte wielokrotnie',
                    if (powerLoads.outletLoads[outlet.id]?.isOverloaded ??
                        false)
                      'przeciążone',
                  ].join(', '),
                ],
            ],
          ),
      ],
    );
  }

  pw.Widget _buildTrussesSection(Project project) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Kratownice'),
        if (project.trusses.isEmpty)
          pw.Text('Brak kratownic.')
        else
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: _greenCrewGreen),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const [
              'Nazwa',
              'Długość',
              'Obciążenie',
              'Rozłożone',
              'Uwagi',
            ],
            data: [
              for (final truss in project.trusses)
                _buildTrussRow(truss, project),
            ],
          ),
      ],
    );
  }

  List<String> _buildTrussRow(ProjectTruss truss, Project project) {
    final load = _trussLoadService.calculateLoad(truss, project);
    final notes = <String>[
      if (load.isOverloaded) 'przekroczony limit',
      if (!load.hasKnownLimits) 'brak limitów',
    ];

    return [
      truss.name,
      '${truss.lengthM.toStringAsFixed(1)} m',
      '${load.totalMassKg.toStringAsFixed(1)}'
          '${load.maxTotalLoadKg == null ? '' : '/${load.maxTotalLoadKg!.toStringAsFixed(0)}'} kg',
      '${load.distributedLoadKgPerM.toStringAsFixed(1)}'
          '${load.maxDistributedLoadKgPerM == null ? '' : '/${load.maxDistributedLoadKgPerM!.toStringAsFixed(1)}'} kg/m',
      notes.join(', '),
    ];
  }

  String _phaseLabel(PowerPhase phase) {
    return switch (phase) {
      PowerPhase.l1 => 'L1',
      PowerPhase.l2 => 'L2',
      PowerPhase.l3 => 'L3',
      PowerPhase.all => 'All',
    };
  }

  String _formatDateTime(DateTime value) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${pad(value.month)}-${pad(value.day)} '
        '${pad(value.hour)}:${pad(value.minute)}';
  }
}

import '../entities/power_models.dart';
import '../entities/project_models.dart';
import 'patch_validation_service.dart';
import 'power_calculation_service.dart';
import 'project_totals_service.dart';
import 'truss_load_service.dart';

/// Builds a plain-text technical report for a [Project], for handing to a
/// crew on site or archiving alongside a project. Uses the same domain
/// services as the UI (ADR-014: reports must not duplicate calculation
/// logic), so the numbers in a report always match what the app itself
/// shows.
///
/// Plain text rather than PDF for now: `docs/FEATURE_SCOPE.md` explicitly
/// allows "eksport danych lub PDF w prostszej formie, jesli PDF opoznia
/// MVP" - PDF layout is a separate, larger piece of work (new dependency,
/// pagination, GreenCrew-branded styling) that shouldn't block having a
/// readable, shareable report at all.
class ProjectReportService {
  const ProjectReportService([
    this._totalsService = const ProjectTotalsService(),
    this._powerService = const PowerCalculationService(),
    this._validationService = const PatchValidationService(),
    this._trussLoadService = const TrussLoadService(),
  ]);

  final ProjectTotalsService _totalsService;
  final PowerCalculationService _powerService;
  final PatchValidationService _validationService;
  final TrussLoadService _trussLoadService;

  String buildTextReport(Project project, {DateTime? generatedAt}) {
    final totals = _totalsService.calculate(project);
    final powerLoads = _powerService.calculateProjectLoads(project);
    final patchValidation = _validationService.validate(project, powerLoads);
    final buffer = StringBuffer();

    void writeHeader(String title) {
      buffer
        ..writeln()
        ..writeln(title)
        ..writeln('-' * title.length);
    }

    buffer
      ..writeln('RAPORT TECHNICZNY - ${project.name}')
      ..writeln(
        'Wygenerowano: ${_formatDateTime(generatedAt ?? DateTime.now())}',
      );

    writeHeader('PODSUMOWANIE');
    buffer
      ..writeln('Moc: ${totals.powerKw.toStringAsFixed(1)} kW')
      ..writeln('Prad: ${totals.currentA.toStringAsFixed(1)} A')
      ..writeln('Masa: ${totals.weightKg.toStringAsFixed(0)} kg');

    writeHeader('GRUPY URZADZEN');
    if (project.groups.isEmpty) {
      buffer.writeln('Brak grup.');
    }
    for (final group in project.groups) {
      final groupTotals = _totalsService.calculateGroup(group);
      buffer.writeln(
        '- ${group.name}: ${groupTotals.powerKw.toStringAsFixed(1)} kW, '
        '${groupTotals.currentA.toStringAsFixed(1)} A, '
        '${groupTotals.weightKg.toStringAsFixed(0)} kg',
      );
      for (final item in group.items) {
        final manufacturer = item.manufacturerSnapshot;
        buffer.writeln(
          '    ${item.quantity.toStringAsFixed(0)}x ${item.nameSnapshot}'
          '${manufacturer == null ? '' : ' ($manufacturer)'} - '
          '${(item.weightKgSnapshot * item.quantity).toStringAsFixed(1)} kg',
        );
      }
    }

    writeHeader('ROZDZIELNICE');
    if (project.distros.isEmpty) {
      buffer.writeln('Brak rozdzielnic.');
    }
    for (final distro in project.distros) {
      final distroLoad = powerLoads.distroLoads[distro.id];
      buffer.writeln(
        '- ${distro.name}'
        '${distroLoad == null ? '' : ' - L1: ${distroLoad.load.l1A.toStringAsFixed(1)} A, '
                  'L2: ${distroLoad.load.l2A.toStringAsFixed(1)} A, '
                  'L3: ${distroLoad.load.l3A.toStringAsFixed(1)} A'}',
      );
      if (distroLoad != null && distroLoad.isInputOverloaded) {
        buffer.writeln(
          '    OSTRZEZENIE: przeciazone wejscie (limit '
          '${distroLoad.inputMaxCurrentA.toStringAsFixed(0)} A)',
        );
      }
      if (patchValidation.isDistroInCycle(distro.id)) {
        buffer.writeln(
          '    OSTRZEZENIE: rozdzielnica jest czescia cyklu polaczen - wynik '
          'moze byc niekompletny',
        );
      }
      for (final outlet in distro.outlets) {
        final outletLoad = powerLoads.outletLoads[outlet.id];
        final flags = <String>[
          if (patchValidation.isOutletDuplicated(outlet.id))
            'GNIAZDO UZYTE WIELOKROTNIE',
          if (outletLoad != null && outletLoad.isOverloaded) 'PRZECIAZONE',
        ];
        buffer.writeln(
          '    ${outlet.name} (${_phaseLabel(outlet.phase)}): '
          '${(outletLoad?.maxLoadedPhaseA ?? 0).toStringAsFixed(1)}/'
          '${outlet.maxCurrentA.toStringAsFixed(0)} A'
          '${flags.isEmpty ? '' : ' - ${flags.join(', ')}'}',
        );
      }
    }

    writeHeader('KRATOWNICE');
    if (project.trusses.isEmpty) {
      buffer.writeln('Brak kratownic.');
    }
    for (final truss in project.trusses) {
      final load = _trussLoadService.calculateLoad(truss, project);
      buffer.writeln(
        '- ${truss.name} (${truss.lengthM.toStringAsFixed(1)} m): '
        '${load.totalMassKg.toStringAsFixed(1)} kg'
        '${load.maxTotalLoadKg == null ? '' : ' / ${load.maxTotalLoadKg!.toStringAsFixed(0)} kg'}, '
        '${load.distributedLoadKgPerM.toStringAsFixed(1)} kg/m'
        '${load.maxDistributedLoadKgPerM == null ? '' : ' / ${load.maxDistributedLoadKgPerM!.toStringAsFixed(1)} kg/m'}',
      );
      if (load.isOverloaded) {
        buffer.writeln('    OSTRZEZENIE: przekroczony limit obciazenia');
      } else if (!load.hasKnownLimits) {
        buffer.writeln('    Brak zdefiniowanych limitow obciazenia.');
      }
    }

    return buffer.toString();
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

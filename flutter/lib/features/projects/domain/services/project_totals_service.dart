import '../entities/project_models.dart';

class ProjectTotalsService {
  const ProjectTotalsService();

  ProjectTotals calculate(Project project) {
    var powerW = 0.0;
    var currentA = 0.0;
    var weightKg = 0.0;

    for (final group in project.groups) {
      final groupTotals = calculateGroup(group);
      powerW += groupTotals.powerW;
      currentA += groupTotals.currentA;
      weightKg += groupTotals.weightKg;
    }

    return ProjectTotals(
      powerW: powerW,
      currentA: currentA,
      weightKg: weightKg,
    );
  }

  ProjectTotals calculateGroup(ProjectGroup group) {
    var powerW = 0.0;
    var currentA = 0.0;
    var weightKg = 0.0;

    for (final item in group.items) {
      powerW += item.powerWSnapshot * item.quantity;
      currentA += item.currentASnapshot * item.quantity;
      weightKg += item.weightKgSnapshot * item.quantity;
    }

    return ProjectTotals(
      powerW: powerW,
      currentA: currentA,
      weightKg: weightKg,
    );
  }
}

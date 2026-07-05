import '../entities/project_models.dart';

class PatchValidationService {
  const PatchValidationService();

  PatchValidationResult validate(Project project) {
    final outletUsage = <String, List<PowerConnection>>{};

    for (final connection in project.connections) {
      outletUsage
          .putIfAbsent(connection.sourceOutletId, () => <PowerConnection>[])
          .add(connection);
    }

    final duplicateOutletIds = outletUsage.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => entry.key)
        .toSet();

    return PatchValidationResult(duplicateOutletIds: duplicateOutletIds);
  }
}

class PatchValidationResult {
  const PatchValidationResult({required this.duplicateOutletIds});

  final Set<String> duplicateOutletIds;

  bool get hasWarnings => duplicateOutletIds.isNotEmpty;

  bool isOutletDuplicated(String outletId) =>
      duplicateOutletIds.contains(outletId);
}

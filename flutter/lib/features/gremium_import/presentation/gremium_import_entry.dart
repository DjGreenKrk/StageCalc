import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../infrastructure/files/local_file_reader/local_file_reader.dart';
import '../../../infrastructure/local_database/app_database_provider.dart';
import '../../catalog/data/drift_catalog_repository.dart';
import '../../projects/data/drift_project_repository.dart';
import '../domain/services/gremium_catalog_matcher.dart';
import '../domain/services/gremium_import_commit_service.dart';
import '../domain/services/gremium_import_parser.dart';
import 'gremium_import_review_screen.dart';

/// Entry point for importing a Gremium Panel pack-list export (ADR-034):
/// picks a `.json` file, parses/validates it, matches items against the
/// current catalog, then opens the review panel where the user selects what
/// to actually import before anything is saved.
class GremiumImportButton extends StatelessWidget {
  const GremiumImportButton({required this.onImported, super.key});

  /// Called after a successful import so the caller can reload its data
  /// (e.g. the projects list).
  final VoidCallback onImported;

  Future<void> _startImport(BuildContext context) async {
    final PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showMessage(context, 'Nie udało się otworzyć wyboru pliku: $error');
      return;
    }

    final path = picked?.path;
    if (path == null) {
      return;
    }

    final String content;
    try {
      content = await readLocalTextFile(path);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showMessage(context, 'Nie udało się wczytać pliku.\n$error');
      return;
    }

    final packList = GremiumImportParser.parse(content);

    if (!context.mounted) {
      return;
    }

    final catalogRepository = DriftCatalogRepository(
      AppDatabaseProvider.instance,
    );
    final projectRepository = DriftProjectRepository(
      AppDatabaseProvider.instance,
    );
    final catalogDevices = await catalogRepository.getDevices();
    final matches = GremiumCatalogMatcher.match(packList.items, catalogDevices);

    if (!context.mounted) {
      return;
    }

    final summary = await Navigator.of(context).push<GremiumImportSummary>(
      MaterialPageRoute(
        builder: (_) => GremiumImportReviewScreen(
          packList: packList,
          matches: matches,
          catalogDevices: catalogDevices,
          catalogRepository: catalogRepository,
          projectRepository: projectRepository,
        ),
      ),
    );

    if (summary == null) {
      return;
    }

    onImported();

    if (!context.mounted) {
      return;
    }
    _showMessage(
      context,
      summary.createdNewProject
          ? 'Utworzono nowy projekt z ${summary.importedItemCount} pozycjami.'
          : 'Zaktualizowano projekt (${summary.importedItemCount} pozycji).',
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.upload_file_outlined),
      tooltip: 'Importuj z Gremium',
      onPressed: () => _runImport(context),
    );
  }

  Future<void> _runImport(BuildContext context) async {
    try {
      await _startImport(context);
    } on GremiumValidationException catch (error) {
      if (!context.mounted) {
        return;
      }
      _showMessage(context, error.message);
    }
  }
}

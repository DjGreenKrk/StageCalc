import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../infrastructure/files/local_file_reader/local_file_reader.dart';
import '../../../infrastructure/local_database/app_database_provider.dart';
import '../../catalog/data/drift_catalog_repository.dart';
import '../domain/entities/gdtf_fixture_type.dart';
import '../domain/entities/gdtf_import_failure.dart';
import '../domain/services/gdtf_catalog_matcher.dart';
import '../domain/services/gdtf_import_commit_service.dart';
import '../domain/services/gdtf_import_parser.dart';
import 'gdtf_import_review_screen.dart';

/// Entry point for importing one or more GDTF fixture files (ADR-035): picks
/// `.gdtf` files (multi-select, since these are usually distributed as a
/// whole fixture library), parses each one, matches them against the
/// current catalog, then opens the review panel where the user selects what
/// to actually import before anything is saved. A single unreadable file
/// never aborts the rest - it's surfaced in the review panel's error list
/// instead.
class GdtfImportButton extends StatelessWidget {
  const GdtfImportButton({required this.onImported, super.key});

  /// Called after a successful import so the caller can reload its data
  /// (e.g. the catalog list).
  final VoidCallback onImported;

  Future<void> _startImport(BuildContext context) async {
    final List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gdtf'],
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showMessage(context, 'Nie udało się otworzyć wyboru pliku: $error');
      return;
    }

    if (picked.isEmpty) {
      return;
    }

    final fixtures = <GdtfFixtureType>[];
    final failures = <GdtfImportFailure>[];

    for (final file in picked) {
      final path = file.path;
      if (path == null) {
        failures.add(
          GdtfImportFailure(
            fileName: file.name,
            reason: 'Odczyt pliku nie jest wspierany na tej platformie.',
          ),
        );
        continue;
      }
      try {
        final bytes = await readLocalBytes(path);
        fixtures.add(GdtfImportParser.parse(bytes, sourceFileName: file.name));
      } on GdtfValidationException catch (error) {
        failures.add(
          GdtfImportFailure(fileName: file.name, reason: error.message),
        );
      } catch (error) {
        failures.add(GdtfImportFailure(fileName: file.name, reason: '$error'));
      }
    }

    if (fixtures.isEmpty) {
      if (!context.mounted) {
        return;
      }
      _showMessage(
        context,
        'Nie udało się wczytać żadnego z wybranych plików.\n'
        '${failures.map((failure) => '${failure.fileName}: ${failure.reason}').join('\n')}',
      );
      return;
    }

    final catalogRepository = DriftCatalogRepository(
      AppDatabaseProvider.instance,
    );
    final catalogDevices = await catalogRepository.getDevices();
    final matches = GdtfCatalogMatcher.match(fixtures, catalogDevices);

    if (!context.mounted) {
      return;
    }

    final summary = await Navigator.of(context).push<GdtfImportSummary>(
      MaterialPageRoute(
        builder: (_) => GdtfImportReviewScreen(
          matches: matches,
          failures: failures,
          catalogDevices: catalogDevices,
          catalogRepository: catalogRepository,
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
      'Zaimportowano: ${summary.createdDeviceCount} nowych, '
      '${summary.linkedDeviceCount} połączonych.',
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
      tooltip: 'Importuj z GDTF',
      onPressed: () => _startImport(context),
    );
  }
}

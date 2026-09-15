/// One picked `.gdtf` file that could not be turned into a
/// [GdtfFixtureType] (corrupt ZIP, missing `description.xml`, malformed
/// XML, or missing a required attribute) - shown in an informational error
/// list above the review panel. A single bad file never aborts the rest of
/// a multi-file import (ADR-035).
class GdtfImportFailure {
  const GdtfImportFailure({required this.fileName, required this.reason});

  final String fileName;
  final String reason;
}

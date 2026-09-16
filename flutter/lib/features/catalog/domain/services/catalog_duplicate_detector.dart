import '../entities/catalog_device.dart';

class CatalogDuplicatePair {
  const CatalogDuplicatePair({
    required this.deviceA,
    required this.deviceB,
    required this.similarity,
  });

  final CatalogDevice deviceA;
  final CatalogDevice deviceB;

  /// Normalized-name similarity in `[0.0, 1.0]` - `1.0` means identical
  /// once both names are lowercased and stripped of non-alphanumeric
  /// characters.
  final double similarity;
}

/// Flags catalog devices that are probably the same real-world item added
/// twice under slightly different spellings - the gap left by
/// `GdtfCatalogMatcher`/`GremiumCatalogMatcher`, which only dedupe imports
/// carrying a remembered id. A device added by hand has no such id, so two
/// team members on unsynced devices can each add "Robe Pointe" and end up
/// with two permanent records in the shared catalog once both sync (ADR-038).
///
/// Deliberately conservative: this only *flags* pairs for a human to review
/// in `CatalogDuplicateReviewDialog` - it never merges or deletes anything
/// itself, because a high name similarity is not proof of duplication (two
/// different products from different manufacturers can be named almost
/// identically).
class CatalogDuplicateDetector {
  const CatalogDuplicateDetector._();

  static const defaultThreshold = 0.9;

  /// Canonical, order-independent key for a device pair, so a dismissal
  /// recorded as `(a, b)` also matches when the pair later comes back as
  /// `(b, a)`.
  static String pairKey(String deviceIdA, String deviceIdB) {
    final sorted = [deviceIdA, deviceIdB]..sort();
    return '${sorted[0]}|${sorted[1]}';
  }

  static List<CatalogDuplicatePair> findPairs(
    List<CatalogDevice> devices, {
    double threshold = defaultThreshold,
  }) {
    final pairs = <CatalogDuplicatePair>[];
    for (var i = 0; i < devices.length; i++) {
      for (var j = i + 1; j < devices.length; j++) {
        final deviceA = devices[i];
        final deviceB = devices[j];
        if (deviceA.category != deviceB.category) {
          continue;
        }
        final similarity = _nameSimilarity(deviceA.name, deviceB.name);
        if (similarity >= threshold) {
          pairs.add(
            CatalogDuplicatePair(
              deviceA: deviceA,
              deviceB: deviceB,
              similarity: similarity,
            ),
          );
        }
      }
    }
    return pairs;
  }

  static double _nameSimilarity(String a, String b) {
    final normalizedA = _normalize(a);
    final normalizedB = _normalize(b);
    if (normalizedA.isEmpty && normalizedB.isEmpty) {
      return 1;
    }
    final maxLength = normalizedA.length > normalizedB.length
        ? normalizedA.length
        : normalizedB.length;
    if (maxLength == 0) {
      return 1;
    }
    final distance = _levenshteinDistance(normalizedA, normalizedB);
    return 1 - (distance / maxLength);
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  }

  static int _levenshteinDistance(String a, String b) {
    if (a == b) {
      return 0;
    }
    if (a.isEmpty) {
      return b.length;
    }
    if (b.isEmpty) {
      return a.length;
    }

    var previousRow = List<int>.generate(b.length + 1, (index) => index);
    var currentRow = List<int>.filled(b.length + 1, 0);

    for (var i = 0; i < a.length; i++) {
      currentRow[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final deletionCost = previousRow[j + 1] + 1;
        final insertionCost = currentRow[j] + 1;
        final substitutionCost = previousRow[j] + (a[i] == b[j] ? 0 : 1);
        currentRow[j + 1] = [
          deletionCost,
          insertionCost,
          substitutionCost,
        ].reduce((value, element) => value < element ? value : element);
      }
      final swap = previousRow;
      previousRow = currentRow;
      currentRow = swap;
    }

    return previousRow[b.length];
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';
import 'package:stagecalc/features/gremium_import/domain/entities/gremium_category_guess.dart';
import 'package:stagecalc/features/gremium_import/domain/entities/gremium_pack_list.dart';

void main() {
  test(
    'never guesses a category outside the existing CatalogDeviceCategory set',
    () {
      const items = [
        GremiumItem(name: 'Kabel XLR - 2m', quantity: 1, category: 'XLR'),
        GremiumItem(name: 'Alto TS 315', quantity: 1, category: 'Audio'),
        GremiumItem(
          name: 'Ekran Projekcyjny',
          quantity: 1,
          category: 'Multimedia',
        ),
        GremiumItem(
          name: 'Przedłużacz 230V IP45 - 5m',
          quantity: 1,
          category: 'Zasilanie',
        ),
        GremiumItem(name: 'Statyw Kolumnowy', quantity: 1, category: 'Statywy'),
      ];

      for (final item in items) {
        // Compiles and returns a value from the real enum by construction -
        // this is the whole point: there is no separate Gremium taxonomy to
        // accidentally return instead.
        final CatalogDeviceCategory category = guessGremiumCategory(item);
        expect(CatalogDeviceCategory.values, contains(category));
      }
    },
  );

  test('guesses cable for XLR/cable-like items', () {
    const item = GremiumItem(
      name: 'Kabel XLR - 2m',
      quantity: 1,
      category: 'XLR',
    );
    expect(guessGremiumCategory(item), CatalogDeviceCategory.cable);
  });

  test('guesses sound for audio gear', () {
    const item = GremiumItem(
      name: 'Alto TS 315',
      quantity: 1,
      category: 'Audio',
    );
    expect(guessGremiumCategory(item), CatalogDeviceCategory.sound);
  });

  test('guesses multimedia for multimedia gear', () {
    const item = GremiumItem(
      name: 'Ekran Projekcyjny',
      quantity: 1,
      category: 'Multimedia',
    );
    expect(guessGremiumCategory(item), CatalogDeviceCategory.multimedia);
  });

  test('falls back to other for unrecognized categories', () {
    const item = GremiumItem(
      name: 'Statyw Kolumnowy',
      quantity: 1,
      category: 'Statywy',
    );
    expect(guessGremiumCategory(item), CatalogDeviceCategory.other);
  });

  test('guesses truss for kratownica/trawers items', () {
    const items = [
      GremiumItem(name: 'Kratownica 3m', quantity: 1, category: 'Rigging'),
      GremiumItem(name: 'Trawers boczny', quantity: 1, category: 'Rigging'),
    ];
    for (final item in items) {
      expect(guessGremiumRiggingKind(item), RiggingDeviceKind.truss);
    }
  });

  test('guesses hook for hak items', () {
    const item = GremiumItem(name: 'Hak M10', quantity: 1, category: 'Rigging');
    expect(guessGremiumRiggingKind(item), RiggingDeviceKind.hook);
  });

  test(
    'returns null (no guess) for rigging items without a truss/hook signal',
    () {
      const item = GremiumItem(
        name: 'Szekla 3.25t',
        quantity: 1,
        category: 'Rigging',
      );
      expect(guessGremiumRiggingKind(item), isNull);
    },
  );
}

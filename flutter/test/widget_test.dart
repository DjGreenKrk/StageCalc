import 'dart:convert';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/app/app.dart';
import 'package:stagecalc/features/catalog/data/drift_catalog_repository.dart';
import 'package:stagecalc/features/catalog/domain/entities/catalog_device.dart';
import 'package:stagecalc/features/clients/data/drift_client_repository.dart';
import 'package:stagecalc/features/projects/data/drift_project_repository.dart';
import 'package:stagecalc/features/settings/presentation/about_screen.dart';
import 'package:stagecalc/shared/widgets/greencrew_button.dart';
import 'package:stagecalc/shared/widgets/greencrew_card.dart';
import 'package:stagecalc/features/projects/domain/entities/power_models.dart';
import 'package:stagecalc/features/projects/domain/entities/project_models.dart';
import 'package:stagecalc/infrastructure/local_database/app_database.dart'
    as db;
import 'package:stagecalc/infrastructure/local_database/app_database_provider.dart';

void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabaseProvider.overrideForTesting(database);

    // path_provider has no real platform plugin registered under
    // `flutter test`; stub its channel so code that calls
    // getApplicationDocumentsDirectory() (e.g. the backup writer) works.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('shows StageCalc shell and project metrics', (tester) async {
    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    expect(find.text('StageCalc'), findsOneWidget);
    expect(find.text('Projekty'), findsWidgets);
    expect(
      find.text('Tryb offline. Dane są zapisywane lokalnie.'),
      findsOneWidget,
    );
    expect(find.text('Demo techniczne'), findsOneWidget);
    expect(find.text('Moc: 10.4 kW'), findsOneWidget);
  });

  testWidgets('creates project from the project dialog', (tester) async {
    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dodaj projekt').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).last, 'Projekt testowy');
    await tester.tap(find.text('Zapisz').last);
    await tester.pumpAndSettle();

    expect(find.text('Projekt testowy'), findsOneWidget);
    expect(find.text('Projekt zapisany lokalnie'), findsOneWidget);
  });

  testWidgets('adds and edits manual item in project editor', (tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dodaj projekt').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, 'Projekt edycji');
    await tester.tap(find.text('Zapisz').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Projekt edycji'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dodaj grupę'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, 'Front');
    await tester.tap(find.text('Dodaj').last);
    await tester.pumpAndSettle();

    expect(find.text('Front'), findsOneWidget);

    await tester.tap(find.byTooltip('Dodaj ręcznie').last, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'Riser LED');
    await tester.enterText(find.byType(EditableText).at(1), '2');
    await tester.enterText(find.byType(EditableText).at(2), '150');
    await tester.enterText(find.byType(EditableText).at(3), '1,2');
    await tester.enterText(find.byType(EditableText).at(4), '8');
    await tester.tap(find.text('Dodaj').last);
    await tester.pumpAndSettle();

    expect(find.text('Riser LED'), findsOneWidget);
    expect(find.text('2 szt.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byTooltip('Edytuj pozycję').last,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byTooltip('Edytuj pozycję').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'Riser LED MK2');
    await tester.tap(find.text('Zapisz').last);
    await tester.pumpAndSettle();

    expect(find.text('Riser LED MK2'), findsOneWidget);
  });

  testWidgets('adds catalog item with search and quick quantity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dodaj projekt').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, 'Projekt katalogu');
    await tester.tap(find.text('Zapisz').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Projekt katalogu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dodaj grupę'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, 'Backline');
    await tester.tap(find.text('Dodaj').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Dodaj z katalogu').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'LED');
    await tester.pumpAndSettle();

    expect(find.text('LED Par RGBW'), findsOneWidget);
    expect(find.text('BMFL Spot'), findsNothing);

    await tester.tap(find.widgetWithText(ActionChip, '4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dodaj').last);
    await tester.pumpAndSettle();

    expect(find.text('LED Par RGBW'), findsOneWidget);
    expect(find.text('Generic / 4 szt.'), findsOneWidget);
  });

  testWidgets('picks multiple connector types for a catalog device', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Katalog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dodaj urządzenie'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Nazwa'),
      'Testowy fixture',
    );

    final powerConChip = find.widgetWithText(FilterChip, 'powerCON');
    await tester.ensureVisible(powerConChip);
    await tester.pumpAndSettle();
    await tester.tap(powerConChip);
    await tester.pumpAndSettle();

    final xlr5Chip = find.widgetWithText(FilterChip, 'XLR 5-pin (DMX)');
    await tester.ensureVisible(xlr5Chip);
    await tester.pumpAndSettle();
    await tester.tap(xlr5Chip);
    await tester.pumpAndSettle();

    expect(tester.widget<FilterChip>(powerConChip).selected, isTrue);
    expect(tester.widget<FilterChip>(xlr5Chip).selected, isTrue);

    await tester.tap(find.text('Dodaj').last);
    await tester.pumpAndSettle();

    expect(find.text('Testowy fixture'), findsOneWidget);

    final newDeviceCard = find.ancestor(
      of: find.text('Testowy fixture'),
      matching: find.byType(GreenCrewCard),
    );
    await tester.tap(
      find.descendant(
        of: newDeviceCard,
        matching: find.byTooltip('Edytuj urządzenie'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'powerCON'))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(
            find.widgetWithText(FilterChip, 'XLR 5-pin (DMX)'),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'HDMI'))
          .selected,
      isFalse,
    );
  });

  testWidgets('hides fields that dont apply to the selected catalog category', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Katalog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dodaj urządzenie'));
    await tester.pumpAndSettle();

    // Default category (Oświetlenie) shows the full field set.
    expect(find.widgetWithText(TextField, 'Producent'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Moc'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Prąd'), findsOneWidget);
    expect(find.text('Typy złącz (można wybrać kilka)'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Punkty zaczepienia (opcjonalnie)'),
      findsOneWidget,
    );

    // Rigging hardware itself doesn't draw power, doesn't have its own
    // connectors, and doesn't need rigging points (it's what other
    // equipment hangs *from*) - only weight matters for load calculations.
    await tester.tap(
      find.byType(DropdownButtonFormField<CatalogDeviceCategory>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rigging').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Moc'), findsNothing);
    expect(find.widgetWithText(TextField, 'Prąd'), findsNothing);
    expect(find.text('Typy złącz (można wybrać kilka)'), findsNothing);
    expect(
      find.widgetWithText(TextField, 'Punkty zaczepienia (opcjonalnie)'),
      findsNothing,
    );
    expect(find.widgetWithText(TextField, 'Masa'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Producent'), findsOneWidget);

    // Cables don't draw power, aren't meaningfully attributed to a
    // manufacturer, and don't have rigging points of their own - but they
    // do have connectors.
    await tester.tap(
      find.byType(DropdownButtonFormField<CatalogDeviceCategory>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kabel').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Producent'), findsNothing);
    expect(find.widgetWithText(TextField, 'Moc'), findsNothing);
    expect(find.widgetWithText(TextField, 'Prąd'), findsNothing);
    expect(find.text('Typy złącz (można wybrać kilka)'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Punkty zaczepienia (opcjonalnie)'),
      findsNothing,
    );
  });

  testWidgets('filters catalog devices by category', (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Katalog'));
    await tester.pumpAndSettle();

    expect(find.text('BMFL Spot'), findsOneWidget);
    expect(find.text('Zacisk hakowy'), findsOneWidget);

    final riggingChip = find.widgetWithText(ChoiceChip, 'Rigging');
    await tester.ensureVisible(riggingChip);
    await tester.pumpAndSettle();
    await tester.tap(riggingChip);
    await tester.pumpAndSettle();

    expect(find.text('Zacisk hakowy'), findsOneWidget);
    expect(find.text('BMFL Spot'), findsNothing);

    final allChip = find.widgetWithText(ChoiceChip, 'Wszystkie');
    await tester.ensureVisible(allChip);
    await tester.pumpAndSettle();
    await tester.tap(allChip);
    await tester.pumpAndSettle();

    expect(find.text('BMFL Spot'), findsOneWidget);
    expect(find.text('Zacisk hakowy'), findsOneWidget);
  });

  testWidgets(
    'adds a location connector group mixing several connector types',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const StageCalcApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lokacje'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dodaj lokację').first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Nazwa'),
        'Hala Testowa',
      );
      await tester.pumpAndSettle();

      final addGroupButton = find.text('Dodaj grupę');
      await tester.ensureVisible(addGroupButton);
      await tester.pumpAndSettle();
      await tester.tap(addGroupButton);
      await tester.pumpAndSettle();

      // The group dialog opens with one default entry (32 A CEE 5P).
      // Adding a second entry defaults it to the first `ConnectorTypes`
      // entry (16 A Uni-Schuko) - already a different type from the first,
      // without needing to touch either dropdown.
      final addEntryButton = find.text('Dodaj typ złącza');
      await tester.ensureVisible(addEntryButton);
      await tester.pumpAndSettle();
      await tester.tap(addEntryButton);
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));

      // Two `FilledButton`s named "Zapisz" exist at this point - the group
      // dialog's own and the location dialog's underneath it, which stays
      // mounted (just obscured) while the group dialog's route is on top -
      // `.last` is the topmost (most recently pushed) one.
      final saveGroupButton = find.widgetWithText(FilledButton, 'Zapisz').last;
      await tester.ensureVisible(saveGroupButton);
      await tester.pumpAndSettle();
      await tester.tap(saveGroupButton);
      await tester.pumpAndSettle();

      expect(
        find.text('1x 32 A CEE 5P + 1x 16 A Uni-Schuko / 25.8 kW'),
        findsOneWidget,
      );

      final saveLocationButton = find.widgetWithText(FilledButton, 'Zapisz');
      await tester.ensureVisible(saveLocationButton);
      await tester.pumpAndSettle();
      await tester.tap(saveLocationButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Grupa złączy 1: 1x 32 A CEE 5P + 1x 16 A Uni-Schuko'),
        findsOneWidget,
      );
    },
  );

  testWidgets('switches project editor to patcher view', (tester) async {
    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Demo techniczne'));
    await tester.pumpAndSettle();

    expect(find.text('Grupy'), findsOneWidget);

    await tester.tap(find.text('Patcher'));
    await tester.pumpAndSettle();

    expect(find.text('Rozdzielnice'), findsOneWidget);
    expect(find.text('Połączenia'), findsOneWidget);
  });

  testWidgets('deleting a group removes its dangling connections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = DriftProjectRepository(database);
    final now = DateTime(2026, 9, 1);
    await repository.saveProject(
      Project(
        id: 'orphan_test_project',
        name: 'Projekt osieroconych polaczen',
        createdAt: now,
        updatedAt: now,
        groups: const [ProjectGroup(id: 'group_1', name: 'Front', items: [])],
        distros: const [
          ProjectDistro(
            id: 'distro_1',
            name: 'Rozdzielnia testowa',
            outlets: [
              ProjectOutlet(
                id: 'outlet_1',
                name: 'Schuko L1.1',
                connectorTypeId: 'schuko_16a',
                phase: PowerPhase.l1,
                maxCurrentA: 16,
              ),
            ],
          ),
        ],
        connections: const [
          PowerConnection(
            id: 'connection_1',
            sourceDistroId: 'distro_1',
            sourceOutletId: 'outlet_1',
            targetGroupId: 'group_1',
          ),
        ],
      ),
    );

    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Projekt osieroconych polaczen'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patcher'));
    await tester.pumpAndSettle();

    expect(find.text('Brak połączeń grup z rozdzielnicami.'), findsNothing);

    await tester.tap(find.text('Sprzęt'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Usuń grupę'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usuń').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patcher'));
    await tester.pumpAndSettle();

    expect(find.text('Brak połączeń grup z rozdzielnicami.'), findsOneWidget);

    final reloaded = (await repository.getProjects()).firstWhere(
      (project) => project.id == 'orphan_test_project',
    );
    expect(reloaded.connections, isEmpty);
  });

  testWidgets('tapping an outlet tile connects and disconnects it (visual '
      'patcher)', (tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = DriftProjectRepository(database);
    final now = DateTime(2026, 9, 13);
    await repository.saveProject(
      Project(
        id: 'outlet_tile_test_project',
        name: 'Projekt kafelkow gniazd',
        createdAt: now,
        updatedAt: now,
        groups: const [ProjectGroup(id: 'group_1', name: 'Front', items: [])],
        distros: const [
          ProjectDistro(
            id: 'distro_1',
            name: 'Rozdzielnia testowa',
            outlets: [
              ProjectOutlet(
                id: 'outlet_1',
                name: 'Schuko L1.1',
                connectorTypeId: 'schuko_16a',
                phase: PowerPhase.l1,
                maxCurrentA: 16,
              ),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Projekt kafelkow gniazd'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patcher'));
    await tester.pumpAndSettle();

    final outletTile = find.byKey(const ValueKey('outlet_tile_outlet_1'));
    expect(outletTile, findsOneWidget);
    expect(find.text('Wolne'), findsOneWidget);

    // Tap the empty outlet tile - opens the quick-connect dialog instead of
    // the bulk "Połącz" dialog.
    await tester.tap(outletTile);
    await tester.pumpAndSettle();

    expect(find.text('Połącz Schuko L1.1'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Notatki (opcjonalnie)'),
      'DMX kanal 12',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Połącz'));
    await tester.pumpAndSettle();

    expect(find.text('Wolne'), findsNothing);
    expect(
      find.descendant(of: outletTile, matching: find.text('Front')),
      findsOneWidget,
    );

    // Tap the now-patched outlet tile - opens connection details instead of
    // quick-connect again.
    await tester.tap(outletTile);
    await tester.pumpAndSettle();

    expect(find.text('Gniazdo Schuko L1.1'), findsOneWidget);
    expect(find.text('DMX kanal 12'), findsOneWidget);

    await tester.tap(find.byTooltip('Rozłącz'));
    await tester.pumpAndSettle();

    expect(find.text('Wolne'), findsOneWidget);

    final reloaded = (await repository.getProjects()).firstWhere(
      (project) => project.id == 'outlet_tile_test_project',
    );
    expect(reloaded.connections, isEmpty);
  });

  testWidgets('creates a JSON backup file from the About screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Info'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Utwórz kopię zapasową (JSON)'));
    await tester.pump();
    // Real dart:io file writes need real wall-clock time to complete even
    // inside the fake-async test zone, so poll with tester.runAsync until
    // the confirmation dialog appears instead of a single pumpAndSettle.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (find.text('Kopia zapasowa utworzona').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();

    expect(find.text('Kopia zapasowa utworzona'), findsOneWidget);

    final pathFinder = find.byType(SelectableText);
    expect(pathFinder, findsOneWidget);
    final path = tester.widget<SelectableText>(pathFinder).data!;
    expect(File(path).existsSync(), isTrue);

    final contents = jsonDecode(File(path).readAsStringSync());
    expect(contents['manifest']['appName'], 'StageCalc');
    expect((contents['data']['projects'] as List).length, greaterThan(0));

    File(path).parent.deleteSync(recursive: true);
  });

  testWidgets('imports a JSON backup file from the About screen', (
    tester,
  ) async {
    // Tall enough that every field/button on the About screen is visible
    // without scrolling, so the test only has to deal with real vs. fake
    // async timing (see below), not scroll geometry.
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final date = DateTime(2026, 7, 5).toUtc().toIso8601String();
    final backupFile = File(
      '${Directory.systemTemp.path}/stagecalc_import_test_'
      '${DateTime.now().microsecondsSinceEpoch}.json',
    );
    backupFile.writeAsStringSync(
      jsonEncode({
        'manifest': {
          'schemaVersion': 1,
          'appName': 'StageCalc',
          'appVersion': '0.2.0',
          'createdAt': date,
          'workspaceId': 'local',
          'recordCounts': {'clients': 1},
        },
        'data': {
          'projects': [],
          'clients': [
            {
              'id': 'imported_client',
              'name': 'Zaimportowany klient',
              'createdAt': date,
              'updatedAt': date,
              'syncStatus': 'localOnly',
            },
          ],
          'locations': [],
          'catalogDevices': [],
          'powerPresets': [],
        },
      }),
    );
    addTearDown(() {
      if (backupFile.existsSync()) {
        backupFile.deleteSync();
      }
    });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AboutScreen())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Ścieżka do pliku kopii zapasowej'),
      backupFile.path,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wczytaj i zwaliduj'));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (find.text('Zaimportować kopię zapasową?').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();

    expect(find.text('Zaimportować kopię zapasową?'), findsOneWidget);
    expect(find.textContaining('1 klientów'), findsOneWidget);

    await tester.tap(find.text('Importuj'));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (find.textContaining('Zaimportowano').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();

    expect(find.textContaining('Zaimportowano 1 rekordów'), findsOneWidget);

    final clients = await DriftClientRepository(database).getClients();
    expect(
      clients.any(
        (client) =>
            client.id == 'imported_client' &&
            client.name == 'Zaimportowany klient',
      ),
      isTrue,
    );
  });

  testWidgets('picking a backup file fills the import path field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final originalPlatform = FilePickerPlatform.instance;
    FilePickerPlatform.instance = _FakeFilePickerPlatform(
      pickedPath: r'C:\fake\stagecalc_backup.json',
    );
    addTearDown(() => FilePickerPlatform.instance = originalPlatform);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AboutScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Wybierz plik'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Ścieżka do pliku kopii zapasowej'),
    );
    expect(field.controller!.text, r'C:\fake\stagecalc_backup.json');
  });

  testWidgets('adds a truss and shows its calculated mass', (tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Demo techniczne'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kratownice'));
    await tester.pumpAndSettle();

    expect(find.text('Brak kratownic w projekcie.'), findsOneWidget);

    await tester.tap(find.widgetWithText(GreenCrewButton, 'Dodaj'));
    await tester.pumpAndSettle();

    expect(find.text('Dodaj kratownicę'), findsOneWidget);

    // The demo project has a single group ("Front light") totalling 192 kg;
    // assigning it should make the truss show that same total mass.
    await tester.tap(find.text('Front light').last);
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    expect(find.text('Brak kratownic w projekcie.'), findsNothing);
    expect(find.text('Kratownica'), findsOneWidget);
    expect(find.textContaining('192.0 kg'), findsOneWidget);
  });

  testWidgets(
    'linking a truss to a catalog device interpolates its limits from the load chart',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime(2026, 7, 5);
      await DriftCatalogRepository(database).saveDevice(
        CatalogDevice(
          id: 'prolyte_h30v',
          name: 'Prolyte H30V',
          category: CatalogDeviceCategory.rigging,
          quantityUnit: CatalogQuantityUnit.pcs,
          createdAt: now,
          updatedAt: now,
          loadChart: const [
            TrussLoadChartEntry(
              id: 'c1',
              lengthM: 4,
              pointLoadKg: 800,
              distributedLoadKgPerM: 200,
            ),
            TrussLoadChartEntry(
              id: 'c2',
              lengthM: 8,
              pointLoadKg: 400,
              distributedLoadKgPerM: 100,
            ),
          ],
        ),
      );

      await tester.pumpWidget(const StageCalcApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Demo techniczne'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kratownice'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(GreenCrewButton, 'Dodaj'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Długość'), '6');
      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prolyte H30V').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zapisz'));
      await tester.pumpAndSettle();

      expect(find.text('Limity z tabeli producenta'), findsOneWidget);
      // Halfway between the 4m (800kg/200kg-per-m) and 8m (400kg/100kg-per-m)
      // chart entries: 600kg total, 150kg/m distributed.
      expect(find.textContaining('/ 600 kg'), findsOneWidget);
      expect(find.textContaining('/ 150.0 kg/m'), findsOneWidget);
    },
  );

  testWidgets('assigns a hook to a group that needs rigging points', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Demo techniczne'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kratownice'));
    await tester.pumpAndSettle();

    // "Front light" has 4x BMFL Spot needing 2 rigging points each.
    expect(find.text('Front light'), findsOneWidget);
    expect(find.textContaining('Wymagane: 8'), findsOneWidget);
    expect(find.textContaining('Przypisane: 0'), findsOneWidget);

    await tester.tap(find.text('Dodaj hak'));
    await tester.pumpAndSettle();

    expect(find.text('Dodaj z katalogu'), findsOneWidget);
    await tester.enterText(find.byType(EditableText).at(0), 'Zacisk');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zacisk hakowy'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, '8');
    await tester.tap(find.text('Dodaj').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Przypisane: 8'), findsOneWidget);
    expect(find.textContaining('Zacisk hakowy'), findsOneWidget);
  });

  testWidgets('exports a text report from the project editor', (tester) async {
    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Demo techniczne'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Eksportuj raport tekstowy'));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (find.text('Raport wyeksportowany').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();

    expect(find.text('Raport wyeksportowany'), findsOneWidget);

    final pathFinder = find.byType(SelectableText);
    expect(pathFinder, findsOneWidget);
    final path = tester.widget<SelectableText>(pathFinder).data!;
    final reportFile = File(path);
    expect(reportFile.existsSync(), isTrue);

    final content = reportFile.readAsStringSync();
    expect(content, contains('RAPORT TECHNICZNY - Demo techniczne'));
    expect(content, contains('Moc: 10.4 kW'));
    expect(content, contains('Front light'));

    reportFile.parent.deleteSync(recursive: true);
  });

  testWidgets('exports a PDF report from the project editor', (tester) async {
    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Demo techniczne'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Eksportuj raport PDF'));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (find.text('Raport PDF wyeksportowany').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();

    expect(find.text('Raport PDF wyeksportowany'), findsOneWidget);

    final pathFinder = find.byType(SelectableText);
    expect(pathFinder, findsOneWidget);
    final path = tester.widget<SelectableText>(pathFinder).data!;
    final reportFile = File(path);
    expect(reportFile.existsSync(), isTrue);
    expect(path, endsWith('.pdf'));

    final bytes = reportFile.readAsBytesSync();
    expect(
      String.fromCharCodes(bytes.take(5)),
      '%PDF-',
      reason: 'exported file does not start with the PDF file signature',
    );

    reportFile.parent.deleteSync(recursive: true);
  });
}

class _FakeFilePickerPlatform extends FilePickerPlatform {
  _FakeFilePickerPlatform({required this.pickedPath});

  final String pickedPath;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    return _FakePlatformFile(pickedPath);
  }
}

base class _FakePlatformFile extends PlatformFile {
  _FakePlatformFile(this._path);

  final String _path;

  @override
  String get name => _path.split(r'\').last;

  @override
  Uri get uri => Uri.file(_path);

  @override
  XFile get xFile => XFile(_path);

  @override
  int? lengthSync() => null;

  @override
  Future<int> length() async => File(_path).length();

  @override
  Future<Uint8List> readAsBytes() => File(_path).readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() => File(_path).openRead().cast();
}

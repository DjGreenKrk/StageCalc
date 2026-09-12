import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagecalc/app/app.dart';
import 'package:stagecalc/features/projects/data/drift_project_repository.dart';
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
      find.text('Tryb offline. Dane sa zapisywane lokalnie.'),
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

    await tester.tap(find.text('Dodaj grupe'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, 'Front');
    await tester.tap(find.text('Dodaj').last);
    await tester.pumpAndSettle();

    expect(find.text('Front'), findsOneWidget);

    await tester.tap(find.byTooltip('Dodaj recznie').last, warnIfMissed: false);
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
      find.byTooltip('Edytuj pozycje').last,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byTooltip('Edytuj pozycje').last);
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

    await tester.tap(find.text('Dodaj grupe'));
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

  testWidgets('switches project editor to patcher view', (tester) async {
    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Demo techniczne'));
    await tester.pumpAndSettle();

    expect(find.text('Grupy'), findsOneWidget);

    await tester.tap(find.text('Patcher'));
    await tester.pumpAndSettle();

    expect(find.text('Rozdzielnice'), findsOneWidget);
    expect(find.text('Polaczenia'), findsOneWidget);
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

    expect(find.text('Brak polaczen grup z rozdzielnicami.'), findsNothing);

    await tester.tap(find.text('Sprzet'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Usun grupe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usun').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patcher'));
    await tester.pumpAndSettle();

    expect(find.text('Brak polaczen grup z rozdzielnicami.'), findsOneWidget);

    final reloaded = (await repository.getProjects()).firstWhere(
      (project) => project.id == 'orphan_test_project',
    );
    expect(reloaded.connections, isEmpty);
  });

  testWidgets('creates a JSON backup file from the About screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StageCalcApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Info'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Utworz kopie zapasowa (JSON)'));
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
}

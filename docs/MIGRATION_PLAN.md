# StageCalc Flutter Migration Plan

## Cel

Celem migracji jest stworzenie czystszej wersji StageCalc w Flutter + Dart, dzialajacej offline-first na Androidzie i Windows, z mozliwoscia pozniejszego wsparcia Web/iOS oraz pozniejszej synchronizacji bazy danych.

Ten dokument nie zaklada przepisywania aplikacji od razu. Opisuje plan techniczny, zakres i ryzyka.

Aktualna wersja legacy jest zrodlem wymagan domenowych, ale na tym etapie nie jest wymagana kompatybilnosc z wersjami legacy. Nowy Flutter nie musi zachowywac starych formatow danych, nazw pol, tras, kolekcji PocketBase ani importu historycznych projektow.

## Status aktualny

- Katalog `flutter/` zostal utworzony poleceniem `flutter create`.
- Projekt ma nazwe pakietu Dart `stagecalc`.
- Starter Fluttera nie jest jeszcze dostosowany do GreenCrew Tools ani do modelu domenowego StageCalc.
- Przed dalszym kodowaniem nalezy najpierw zastapic starterowy counter app szkieletem aplikacji StageCalc.

## Podsumowanie analizy

Aktualny StageCalc jest dzialajaca aplikacja domenowa, a nie prostym prototypem. Najwazniejsze funkcje to:

- katalog urzadzen scenicznych,
- baza klientow,
- baza lokacji z infrastruktura energetyczna,
- projekty/kalkulacje techniczne,
- grupy urzadzen,
- rozdzielnice i presety gniazd,
- wizualny patcher z obsluga faz,
- obliczenia mocy, pradu, masy i obciazenia faz,
- planowanie kratownic i obciazen,
- eksport PDF,
- logowanie i role w obecnym backendzie PocketBase.

Najwazniejszy byt obecnej aplikacji to `Calculation`. W nowym Flutterze rekomendowana nazwa domenowa to `Project`, bo ten byt obejmuje wiecej niz obliczenie.

## Kontekst GreenCrew Tools

StageCalc Flutter powinien byc projektowany jako aplikacja GreenCrew Tools:

- techniczne narzedzie terenowe, nie aplikacja lifestyle ani ERP,
- telefon jako platforma referencyjna,
- dark mode jako domyslny tryb,
- Material Design,
- wspolny motyw GreenCrew,
- Material Icons/Symbols,
- krotkie polskie komunikaty,
- offline-first jako normalny tryb pracy,
- heksagon GreenCrew z blyskawica jako ikona StageCalc.
- logowanie nie moze blokowac pracy lokalnej,
- backup danych jest osobnym wymaganiem od raportu PDF,
- uprawnienia systemowe maja byc minimalne i funkcjonalnie uzasadnione.

Dokumenty obowiazujace przy projektowaniu:

- `docs/greencrew_docs/branding/GREENCREW_BRANDING.md`
- `docs/greencrew_docs/branding/DESIGN_SYSTEM.md`
- `docs/greencrew_docs/branding/ICONOGRAPHY.md`
- `docs/greencrew_docs/branding/WRITING_GUIDELINES.md`
- `docs/greencrew_docs/project/BRANDING_STAGECALC.md`
- `docs/greencrew_docs/development/ARCHITECTURE.md`
- `docs/greencrew_docs/development/FLUTTER_STANDARDS.md`
- `docs/greencrew_docs/development/CODING_STANDARDS.md`

## Logika biznesowa do zachowania

### Katalog i dane techniczne

- Kategorie i podkategorie urzadzen.
- Wspolne pola urzadzen: moc, prad, masa, producent, notatki.
- Specjalistyczne pola per kategoria.
- Presety rozdzielnic jako wielokrotnego uzytku definicje gniazd.
- Tabele nosnosci kratownic i interpolacja po dlugosci.

### Projekty

- Jeden projekt laczy modul zasilania i kratownic.
- Projekt zawiera grupy urzadzen, rozdzielnice runtime, polaczenia i plan kratownic.
- Projekt moze miec klienta i lokacje.
- Model powinien miec `phaseId`, ale UI faz nie jest czescia obecnego zadania.

### Zasilanie

- Sumowanie mocy, pradu i masy.
- Liczenie obciazenia faz `L1/L2/L3`.
- Obsluga gniazd jednofazowych i `All`.
- `selectedPhases` dla grup 1F podlaczanych do gniazd `All`.
- Grupy `3F_sym` dzielone symetrycznie na trzy fazy.
- Rekurencyjne obciazenie rozdzielnic potomnych.
- Walidacja przeciazen i zajetosci faz.
- Ochrona przed cyklami w grafie rozdzielnic.

### Kratownice

- Przypisywanie grup do kratownic.
- Masa grup z urzadzen, pozycji recznych i hakow.
- Wymagana liczba hakow z `riggingPoints`.
- Manualne obciazenia punktowe i UDL.
- Interpolacja i ostrzeganie przy ekstrapolacji.

## Proponowana struktura aplikacji Flutter

```text
lib/
  main.dart
  app/
    app.dart
    router/
    theme/
    localization/
  core/
    constants/
    errors/
    utils/
    widgets/
  features/
    catalog/
      data/
      domain/
      presentation/
    projects/
      data/
      domain/
        services/
          power_calculation_service.dart
          patch_validation_service.dart
          project_totals_service.dart
      presentation/
        list/
        editor/
        power/
        patcher/
        trusses/
    locations/
      data/
      domain/
      presentation/
    clients/
      data/
      domain/
      presentation/
    settings/
      data/
      domain/
      presentation/
  shared/
    widgets/
      greencrew_app_scaffold.dart
      greencrew_card.dart
      greencrew_button.dart
      greencrew_empty_state.dart
      greencrew_offline_banner.dart
    models/
    services/
  infrastructure/
    local_database/
    export/
    sync/
test/
  domain/
  data/
  presentation/
```

Rekomendowane biblioteki nalezy zatwierdzic na poczatku implementacji, ale kierunek jest taki:

- state management: zrealizowano bez Riverpod/Provider/Bloc - `ChangeNotifier` (`ProjectEditorController`, ADR-015) okazal sie wystarczajacy i nie zwieksza powierzchni zaleznosci,
- lokalna baza: Drift/SQLite dla Android/Windows/iOS; decyzja zaakceptowana w ADR-011,
- Web: zrealizowano jako Drift + sqlite3 wasm (ADR-016), nie adapter IndexedDB,
- routing: nie wprowadzono go_router - obecny prosty shell z zakladkami nie tego potrzebowal,
- modele: recznie pisane `toJson`/`fromJson`, bez freezed/json_serializable,
- PDF: nadal nie zrealizowane (patrz Etap 9).

## Co przepisac 1:1

- Slownik typow zlacz i `maxCurrentA`.
- Kategorie i podkategorie katalogu.
- Wspolne pola urzadzen.
- Pola klienta i lokacji.
- Presety gniazd.
- Obecny kompromis fazowy Model B+:
  - `1F`,
  - `3F_sym`,
  - `selectedPhases`.
- Interpolacje kratownic.
- Podstawowe wzory sumujace moc, prad i mase.

## Co zaprojektowac od nowa

- Model projektu jako relacyjny/offline-first zamiast duzego `Calculation.data`.
- Rozdzielenie `ProjectDistro`, `ProjectOutlet`, `PowerPreset` i `DeviceCatalogItem`.
- Polaczenia jako stabilne encje `PowerConnection`.
- Snapshoty danych katalogowych w `ProjectItem`.
- Zapis inkrementalny zamiast kasowania i odtwarzania polaczen.
- UI kalkulatora jako zestaw ekranow i kontrolerow, nie jeden centralny komponent.
- Synchronizacje jako przyszla warstwe, bez zalozenia PocketBase w domenie.
- Rich text notes: najlepiej Markdown lub jawnie wspierany sanitizowany HTML.
- Wyglad zgodny z GreenCrew Tools od pierwszej wersji, zamiast przenoszenia stylu shadcn/Tailwind.
- Brak importerow i mapperow legacy w MVP.

## Etapy migracji

### Etap 0: Zatwierdzenie decyzji

Wynik:

- Zatwierdzony `DATA_MODEL.md`.
- Zatwierdzony `DECISIONS.md`.
- Decyzja o bibliotece lokalnej bazy i state management.
- Zatwierdzony zakres GreenCrew branding dla StageCalc.

Prace:

- Potwierdzic priorytet platform: Android + Windows jako wymagane.
- Zdecydowac, czy Web ma byc wspierany w MVP czy po MVP.
- Zdecydowac Markdown vs HTML dla notatek.
- Zdecydowac, czy PDF jest w MVP.
- Potwierdzic, ze brak kompatybilnosci legacy obejmuje rowniez brak importera PocketBase w MVP.

### Etap 1: Szkielet Flutter

Wynik:

- Aplikacja uruchamia sie na Android/Windows.
- Jest routing, shell, motyw i podstawowe repozytoria.

Prace:

- Utworzyc projekt Flutter.
- Zweryfikowac istniejacy katalog `flutter/` po `flutter create` i zastapic starterowy counter app.
- Dodac strukture katalogow.
- Skonfigurowac linty i testy.
- Dodac abstrakcje `Repository`.
- Dodac lokalna baze z pierwszymi migracjami.
- Dodac motyw GreenCrew:
  - dark mode,
  - paleta `#00C853` i neutralne powierzchnie,
  - Roboto,
  - Material Icons/Symbols.
- Dodac ekran splash i "O aplikacji" zgodny z brandingiem.
- Dodac pierwsze wspolne komponenty:
  - `GreenCrewAppScaffold`,
  - `GreenCrewCard`,
  - `GreenCrewButton`,
  - `GreenCrewFab`,
  - `GreenCrewTextField`,
  - `GreenCrewSearchBar`,
  - `GreenCrewEmptyState`,
  - `GreenCrewErrorState`,
  - `GreenCrewOfflineBanner`,
  - `GreenCrewConfirmDialog`,
  - `GreenCrewSectionHeader`.
- Ustawic responsywne progi UI: telefon do 600 px, tablet 600-1024 px, desktop powyzej 1024 px.

### Etap 2: Model domenowy i lokalna baza

Wynik:

- Encje domenowe istnieja w Dart.
- Lokalna baza potrafi zapisac katalog, klientow, lokacje i projekt.
- Obecny stan: projekty, katalog, klienci i lokacje zostaly przeniesione na Drift/SQLite.
- `shared_preferences` zostal usuniety z projektu Flutter.

Prace:

- Zaimplementowac encje:
  - `Project`,
  - `ProjectPhase`,
  - `ProjectGroup`,
  - `ProjectItem`,
  - `ProjectDistro`,
  - `ProjectOutlet`,
  - `PowerConnection`,
  - `DeviceCatalogItem`,
  - `Location`,
  - `Client`,
  - `ProjectTruss`.
- Dodac pola sync.
- Dodac seed typow zlacz.
- Powiazanie projektow z klientami i lokacjami jest wykonane.
- Tabele presetow zasilania, runtime rozdzielnic i podstawowe polaczenia patchera sa dodane.
- Dodac testy mapowania i migracji lokalnej bazy.

### Etap 3: Silniki obliczen

Wynik:

- Czyste serwisy Dart licza to samo, co obecna aplikacja.

Prace:

- `ProjectTotalsService`. Zrealizowano.
- `PowerCalculationService`. Zrealizowano, wraz z limitem wejscia z sumy gniazd i recznym override'm (`manualInputMaxCurrentA`).
- `PatchValidationService`. Zrealizowano, wraz z wykrywaniem cykli i przeciazeniem jako stanem walidacji.
- `TrussLoadService`. Zrealizowano (ADR-020) - masa z przypisanych grup + reczne obciazenie, porownanie z limitami. Bez interpolacji tabel nosnosci (patrz Etap 7).
- Testy jednostkowe dla:
  - sum projektu — zrealizowano,
  - obciazenia `L1/L2/L3` — zrealizowano,
  - gniazd `All` — zrealizowano,
  - rozdzielnic potomnych — zrealizowano, w tym poprawnego mapowania fazy kaskady,
  - cykli w grafie — zrealizowano,
  - interpolacji kratownic — nie zrealizowano (brak tabel nosnosci producenta w katalogu, patrz Etap 7).

### Etap 4: Katalog, klienci, lokacje

Wynik:

- Uzytkownik moze zarzadzac podstawowymi danymi offline.

Prace:

- Lista i formularz katalogu.
- Filtrowanie po kategorii.
- Klienci: podstawowy CRUD wykonany i powiazany z projektem.
- Lokacje: podstawowy CRUD wykonany i powiazany z projektem; kolejne kroki to grupy przylaczy.
- Presety rozdzielnic: podstawowy model, repozytorium i UI wykonane.
- Import/seed danych testowych.

### Etap 5: Projekty i grupy urzadzen

Wynik:

- Uzytkownik moze tworzyc projekt, dodawac grupy i urzadzenia.
- Obecny stan: dodawanie pozycji z katalogu wspiera wyszukiwanie po nazwie/producencie, filtrowanie po kategorii i szybkie chipy ilosci.

Prace:

- Lista projektow.
- Ekran projektu.
- Edycja grup.
- Dodawanie pozycji katalogowych i recznych.
- Snapshoty katalogowe.
- Sumy projektu i grup.

### Etap 6: Rozdzielnice i patcher

Wynik:

- Funkcjonalny odpowiednik obecnego wizualnego patchera.
- Obecny stan przejsciowy: edytor projektu ma osobne widoki `Sprzet` i `Patcher`; mozna dodac rozdzielnice w projekcie z presetu, polaczyc grupe z gniazdem, zobaczyc podstawowe obciazenia faz/gniazd i ostrzezenie o wielokrotnym uzyciu gniazda. Ponowne uzycie zajetego gniazda wymaga swiadomego wlaczenia tej opcji.

Prace:

- Dodawanie rozdzielnic z presetu/katalogu/lokacji.
- Obecny stan: mozna dodac szybka rozdzielnice bez tworzenia presetu.
- Obecny stan: mozna utworzyc rozdzielnice custom i edytowac wejscie oraz gniazda istniejacej rozdzielnicy.
- Obecny stan: customowe rozdzielnice i presety moga miec mieszane sekcje wyjsc, np. kilka wyjsc CEE i kilka wyjsc Schuko w jednej rozdzielnicy.
- Tworzenie runtime outletow.
- UI gniazd.
- Polaczenia grupa/rozdzielnica.
- Obecny stan: patcher pozwala laczyc rozdzielnice miedzy soba, filtrujac gniazda po typie wejscia rozdzielnicy podrzednej.
- Obecny stan: obciazenie rozdzielnicy podrzednej jest propagowane do gniazda rozdzielnicy nadrzednej.
- Wybor faz dla `All`.
- Walidacja zajetosci faz.
- Wizualizacja obciazen i przeciazen.
- Obecny stan: jezeli jedna grupa jest podlaczona do wielu gniazd, jej obciazenie jest dzielone rowno miedzy te polaczenia. To jest kompromis MVP do czasu modelu `Gniazdo -> konkretne pozycje z grupy`.
- Obecny stan: wejscie rozdzielnicy jest sprawdzane wzgledem limitu typu zlacza, np. `3F32A`.
- Obecny stan: przeciazenie wejscia jest widoczne rowniez na konkretnej fazie `L1/L2/L3`, nie tylko na gniezdzie lub ogolnym chipie wejscia.
- Obecny stan: obciazenie od 90% limitu pokazuje zolte ostrzezenie dla gniazda, fazy i wejscia rozdzielnicy.

### Etap 6A: Lokacje i przylacza

Wynik:

- Lokacja moze opisac dostepna infrastrukture zasilania obiektu.

Prace:

- Obecny stan: lokacje maja lokalne przylacza energetyczne.
- Obecny stan: dostepna moc obiektu jest liczona z przylaczy.
- Zrealizowano: grupy zlaczy lokacji mozna dodac w patcherze jako zrodla zasilania projektu.

### Etap 7: Kratownice

Wynik:

- Modul kratownic uzywa tych samych grup projektu.
- Obecny stan: `ProjectTruss` (tabela `project_trusses`) plus `TrussLoadService` i widok "Kratownice" w edytorze projektu (ADR-020) - lista, formularz, przypisywanie grup, obciazenia reczne i ostrzezenia o przekroczeniu limitu juz dzialaja.

Prace:

- Lista kratownic w projekcie. Zrealizowano.
- Formularz kratownicy. Zrealizowano.
- Przypisywanie grup. Zrealizowano.
- Haki. Zrealizowano (ADR-024): `CatalogDevice.riggingPoints` + `ProjectItem.riggingPointsSnapshot` (per ADR-008) daja wymagana liczbe hakow na grupe; `ProjectGroupHookAssignment` (nowa tabela) trzyma przypisane haki (urzadzenie z katalogu + ilosc) i ich wage, doliczana do masy grupy przy liczeniu obciazenia kratownicy. Sekcja "Haki grup urzadzen" w widoku Kratownice.
- Obciazenia reczne. Zrealizowano (`manualLoadKg`) - jako jedna zagregowana wartosc, nie rozbita na pozycje punktowe/UDL (`ProjectTrussLoad`).
- Wyniki limitow i ostrzezenia. Zrealizowano dla limitu recznie wpisanego przez uzytkownika (calkowitego i rozlozonego kg/m, prog 90%). Interpolacja tabeli nosnosci producenta i ostrzeganie o ekstrapolacji nie sa zrealizowane - wymaga `trussCatalogDeviceId` na `ProjectTruss` i `TrussLoadChartEntry`/`TrussWeightChartEntry` w katalogu, ktorych jeszcze nie ma.

### Etap 8: Backup i dane startowe

Wynik:

- Aplikacja ma bezpieczny eksport/backup oraz dane startowe potrzebne do pracy.

Prace:

- Eksport JSON backup. Zrealizowano (`AppBackupService`, ekran "O aplikacji"): pelny eksport projektow, klientow, lokacji, katalogu i presetow do jednego pliku JSON z `BackupManifest`. Dziala na Android/Windows; na Web na razie swiadomie niewspierane (`UnsupportedError` z czytelnym komunikatem), zgodnie z Web jako platforma warunkowa.
- Eksport ZIP z JSON i zalacznikami, gdy pojawia sie pliki projektu. Nie zrealizowano - nie ma jeszcze plikow/zalacznikow w projekcie.
- Opcjonalny import backupu w nowym formacie Flutter. Zrealizowano (ADR-019): `AppBackupImportService` waliduje przed zapisem (odrzuca caly import przy pierwszym niepoprawnym rekordzie), potem zapisuje przez upsert. Import ma file picker (ADR-023) i alternatywne reczne pole na sciezke; eksport (backup/raport) zapisuje zawsze do ustalonego katalogu `Documents/StageCalc/...`, bez pickera po tej stronie.
- Seed typow zlacz i przykladowych presetow. Zrealizowano wczesniej (`ConnectorTypes`, seed presetow w katalogu).
- Import legacy tylko jako osobny przyszly projekt, jesli bedzie potrzebny.

### Etap 9: Raporty i eksport

Wynik:

- Projekt mozna wyeksportowac do raportu.
- Obecny stan: `ProjectReportService` (ADR-021) generuje raport tekstowy uzywajac tych samych serwisow domenowych co UI; dostepny z AppBar edytora projektu.

Prace:

- Najpierw eksport JSON/CSV dla diagnostyki. Zrealizowano jako raport tekstowy (czytelniejszy niz surowy CSV do przekazania ekipie na miejscu), nie scisle JSON/CSV - `docs/FEATURE_SCOPE.md` dopuszcza "eksport danych... w prostszej formie".
- Nastepnie PDF z wynikami zasilania i kratownic. Nie zrealizowano - wymaga nowej zaleznosci (`pdf`/`printing`) i pracy nad ukladem/stylem GreenCrew.
- Test porownujacy wartosci raportu z wynikami serwisow domenowych. Zrealizowano (`project_report_service_test.dart`).

### Etap 10: Przygotowanie sync

Wynik:

- Aplikacja nadal dziala offline, ale model jest gotowy na synchronizacje.

Prace:

- Sync queue. Nie zrealizowano.
- Rewizje rekordow. Pole `revision` istnieje w schemacie lokalnym od poczatku, ale nic jeszcze go nie inkrementuje ani nie porownuje.
- Soft delete. Zrealizowano lokalnie (`deletedAt` + diff przy zapisie projektu).
- Strategia konfliktow. Nie zrealizowano.
- Statusy synchronizacji:
  - `localOnly`,
  - `pendingSync`,
  - `synced`,
  - `syncError`,
  - `conflict`.
  Pole istnieje w modelu (`OfflineSyncStatus`), ale nic jeszcze go realnie nie zmienia poza `localOnly`.
- Spike backendu: PocketBase/Supabase/wlasne API. Rozstrzygnieto na PocketBase (juz postawiony jako infrastruktura, ADR-017): pelny schemat 13 kolekcji odzwierciedlajacy tabele Drift oraz pierwszy, jednokierunkowy, idempotentny push `Project` (`PocketBaseProjectSyncService`). To nie jest jeszcze sync queue ani obsluga konfliktow - to dowod, ze polaczenie i mapowanie modelu dzialaja.

### Etap 11: Release i dystrybucja

Wynik:

- Artefakty buildow sa nazwane zgodnie ze standardem GreenCrew.

Prace:

- Wersjonowanie `x.y.z+build`. Zrealizowano od poczatku projektu (`pubspec.yaml`, obecnie `0.2.0+1`).
- Changelog. Zrealizowano od poczatku projektu (`CHANGELOG.md`).
- Nazwy artefaktow (ADR-022): zrealizowano automatyzacje w `tool/package_release.dart` (`dart run tool/package_release.dart`), buduje i pakuje `dist/StageCalc-vX_Y_Z-android.apk` oraz `dist/StageCalc-vX_Y_Z-windows.zip`. Podpisywanie APK wlasnym kluczem (release uzywa na razie klucza debug) i CI nie sa zrealizowane.
- Uprawnienia platformowe (ADR-022): sprawdzono scalony manifest Androida - brakowalo `android.permission.INTERNET`, mimo ze `PocketBaseProjectSyncService` juz laczy sie z siecia. Dodano brakujace uprawnienie; poza nim manifest nie prosi o nic wiecej niz domyslne minimum Fluttera.

## Ryzyka techniczne

### Dokladnosc modelu zasilania

Obecny model dzieli obciazenie grupy przez liczbe przypisan, gdy grupa jest podpieta do wielu gniazd. To jest kompromis, nie pelna reprezentacja fizyczna.

Mitigacja:

- Zachowac Model B+ w MVP.
- Dodac `targetItemIds` jako droge do Modelu C.
- Jasno pokazywac w UI, kiedy obciazenie jest dzielone.

### Offline-first i Web

Drift/SQLite jest wybrana docelowa baza dla Android/Windows/iOS, ale Web moze wymagac osobnego adaptera.

Mitigacja:

- Nie blokowac MVP na Web.
- Trzymac repozytoria za interfejsami.

### Logowanie i praca lokalna

Ryzyko: przeniesienie sposobu myslenia z PocketBase mogloby sprawic, ze aplikacja bez konta bedzie nieuzywalna.

Mitigacja:

- Nie wymagac logowania do podstawowej pracy.
- Konto i sync traktowac jako przyszla warstwe.
- Komunikaty offline formulowac jako normalny stan pracy, nie awarie.

### Migracja danych legacy

Obecny model ma mieszanke JSON, osobnych kolekcji i runtime ID. Na tym etapie zgodnosc z tym modelem nie jest wymagana.

Mitigacja:

- Nie uwzgledniac importera legacy w MVP.
- Nie przenosic pol backward compatibility do nowego modelu.
- Jesli import bedzie potrzebny pozniej, potraktowac go jako osobny modul z raportem ostrzezen.

### Spojnosc z GreenCrew Tools

Ryzyko: aplikacja moze odziedziczyc przypadkowy styl legacy albo stac sie zbyt "dashboardowa".

Mitigacja:

- Projektowac telefon-first.
- Uzyc wspolnych komponentow GreenCrew.
- Trzymac jeden akcent kolorystyczny.
- Komunikaty pisac zgodnie z `WRITING_GUIDELINES.md`.
- W kazdym ekranie pilnowac stanow: pusty, blad, offline, brak wynikow.
- Nie przekazywac informacji tylko kolorem; status ma miec kolor, ikone i tekst.
- Najwazniejsze akcje terenowe trzymac maksymalnie w dwoch tapnieciach.

### Backup

Ryzyko: lokalna baza bez backupu utrudni odzyskanie danych przed wdrozeniem sync.

Mitigacja:

- Wdrozyc JSON backup wczesniej niz sync.
- Oddzielic backup danych od raportow PDF.
- Import backupu walidowac przed zapisem.

### Spojnosc polaczen

Obecny zapis kasuje i odtwarza wszystkie polaczenia. W offline-first to grozi konfliktami i utrata historii.

Mitigacja:

- `PowerConnection` jako normalna encja.
- Zapis inkrementalny.
- Soft delete.

### Snapshoty katalogu

Brak snapshotow w obecnym modelu oznacza, ze historyczne kalkulacje moga zmieniac wyniki po zmianie katalogu.

Mitigacja:

- Snapshoty w `ProjectItem` od pierwszej wersji Flutter.
- Funkcja recznego odswiezenia pozycji z katalogu pozniej.

### Rozmiar zakresu

Katalog, zasilanie, patcher i kratownice to kilka modulow domenowych.

Mitigacja:

- Najpierw silniki domenowe i lokalna baza.
- UI budowac modulami.
- Nie implementowac sync i faz workflow w MVP.

### PDF na wielu platformach

PDF moze roznic sie zachowaniem miedzy Android, Windows i Web.

Mitigacja:

- Raport jako osobny serwis.
- PDF po MVP albo po krotkim spike'u.

### Rich text

Obecne notatki moga byc HTML-em. Flutterowe edytory rich text dodaja zlozonosc.

Mitigacja:

- Preferowac Markdown.
- Przy ewentualnym przyszlym imporcie HTML zachowac notatki jako plain text albo wartosc techniczna importu, jesli konwersja nie jest pewna.

## Kryteria gotowosci migracji

- Testy domenowe pokrywaja obliczenia faz i kratownic.
- Projekt dziala bez sieci po zamknieciu i ponownym otwarciu aplikacji.
- Dodanie pozniejszego sync nie wymaga zmiany kluczowych ID i relacji.
- Flutter nie powiela centralnego, monolitycznego komponentu kalkulatora z legacy.
- UI jest zgodny z GreenCrew Tools i dziala najpierw dobrze na telefonie.
- Brak kompatybilnosci legacy jest swiadomie utrzymany, a ewentualny import legacy jest poza MVP.
- Podstawowa praca nie wymaga konta ani Internetu.
- Kazdy glowny ekran ma stan pusty, blad, offline i brak wynikow.
- Backup JSON jest dostepny przed pierwszym release produkcyjnym.
- Artefakty release maja nazwy zgodne z `StageCalc-vX_Y_Z-platform.ext`.

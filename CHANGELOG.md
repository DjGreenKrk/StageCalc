# Changelog

Wszystkie istotne zmiany w projekcie StageCalc Flutter będą opisywane w tym pliku.

Format jest oparty o Keep a Changelog, a wersjonowanie docelowo powinno używać schematu `MAJOR.MINOR.PATCH+BUILD`.

## [Unreleased]

### Dodano

- Dodano wsparcie lokalnej bazy Drift na platformie Web (ADR-016): `WasmDatabase` (sqlite3 skompilowane do WebAssembly) zamiast `NativeDatabase`, wybierane automatycznie przez conditional import (`infrastructure/local_database/connection/`). `flutter build web` wczesniej w ogole sie nie kompilowal (`dart:io`/`dart:ffi` nie dzialaja na web) — aplikacja pierwszy raz faktycznie dziala w przegladarce.
- Wdrozono StageCalc Web pod `http://192.168.0.113/` (LXC 113, Caddy jako serwer statyczny + reverse proxy do PocketBase na `/api` i `/_`).
- Dodano pierwsza integracje z PocketBase (ADR-017): utworzono w PocketBase 13 kolekcji odzwierciedlajacych obecny schemat Drift, dodano `PocketBaseProjectSyncService` (jednokierunkowy, idempotentny push projektu z pelnym drzewem grup/pozycji/rozdzielnic/gniazd/polaczen/kratownic do PocketBase) i skrypt dowodowy `tool/push_demo_project.dart`. Bez zmian w UI, bez odczytu z powrotem, bez obslugi konfliktow — to pierwszy krok, nie sync engine.
- Dodano pierwszy backup JSON (ADR-018): `AppBackupService` eksportuje wszystkie projekty (z pelnym drzewem), klientow, lokacje i presety rozdzielnic do jednego pliku JSON z `BackupManifest`. Dostepny z ekranu "O aplikacji" ("Utworz kopie zapasowa (JSON)"). Dziala na Android/Windows przez zapis do `Documents/StageCalc/backups/`; na Web na razie swiadomie niewspierany. Dodano brakujace `toJson`/`fromJson` do `Client`, `Location` (+ kontakty/przylacza) i `PowerPreset` (+ szablony gniazd), ktorych do tej pory nie mialy.
- Dodano import backupu JSON (ADR-019): `AppBackupImportService.validate` sprawdza kompletnosc i poprawnosc pliku (JSON, manifest, wersja formatu, kazdy rekord przez `fromJson`) przed jakimkolwiek zapisem — jeden zly rekord odrzuca caly import. Po walidacji UI pokazuje dialog z liczba znalezionych rekordow i ostrzezeniem o nadpisaniu, dopiero potem `import` zapisuje przez istniejace repozytoria (upsert po ID, nic innego nie jest kasowane). Na razie bez file pickera — uzytkownik wkleja sciezke do pliku.
- Dodano pierwszy silnik i UI modulu kratownic (ADR-020): `TrussLoadService` liczy mase kratownicy z przypisanych grup + recznego obciazenia i porownuje z opcjonalnymi limitami (calkowitym i rozlozonym kg/m, z progiem ostrzegawczym 90%). Edytor projektu ma teraz trzeci widok "Kratownice" — lista, dodawanie/edycja (nazwa, dlugosc, reczne obciazenie, limity, notatki, przypisanie grup), usuwanie. Bez hakow i interpolacji tabel nosnosci producenta — to osobny, wiekszy krok wymagajacy nowego schematu (patrz ADR-020). Naprawiono przy okazji ten sam wzorzec osieroconych referencji co przy polaczeniach (ADR-015): usuniecie grupy czysci tez `assignedGroupIds` kratownic.
- Dodano pierwszy eksport raportu projektu (ADR-021): `ProjectReportService.buildTextReport` generuje czytelny raport tekstowy (podsumowanie, grupy z pozycjami, rozdzielnice z obciazeniem faz i ostrzezeniami, kratownice z masa i limitami) uzywajac dokladnie tych samych serwisow domenowych co UI. Dostepny jako ikona w AppBar edytora projektu. Tekst zamiast PDF na razie — `docs/FEATURE_SCOPE.md` dopuszcza to wprost dla MVP; PDF wymagalby osobnej, wiekszej pracy (nowa zaleznosc, uklad, styl GreenCrew). Wydzielono przy okazji wspolny `writeLocalFile` (`infrastructure/files/local_file_writer/`), zamiast trzeciej kopii tego samego trojkata native/web/stub co polaczenie z baza (ADR-016) i backup (ADR-018).

### Naprawiono

- Naprawiono bledne przypisanie fazy przy kaskadzie rozdzielnica -> rozdzielnica: `PowerCalculationService` sumowal obciazenie rozdzielnicy podrzednej wprost po jej wewnetrznych etykietach L1/L2/L3, ignorujac faze gniazda rodzica, przez ktore dziecko jest faktycznie podpiete. Rozdzielnica podrzedna o wejsciu 1-fazowym (kazde jej gniazdo wewnetrznie oznaczone jako "L1") podpieta do gniazda L2 lub L3 rodzica pokazywala caly prad na L1 rodzica zamiast na fazie, na ktorej fizycznie jest podpieta - niezgodnie z `docs/DATA_MODEL.md` ("Jesli dziecko podpiete do 1 fazy rodzica: suma wszystkich faz dziecka trafia na te jedna faze rodzica"). Dodano test regresyjny.

### Dodano

- Dodano wykrywanie cykli w grafie polaczen rozdzielnica-rozdzielnica (`PatchValidationService`). Kalkulator juz wczesniej chronil sie przed nieskonczona rekursja (`visitedDistroIds`), ale robil to cicho - uzytkownik nie mial zadnego sygnalu, ze wynik jest ucinany. Rozdzielnice w cyklu maja teraz w patcherze chip ostrzegawczy "Cykl w polaczeniach rozdzielnic", zgodnie z `docs/DATA_MODEL.md` ("Nalezy blokowac cykle w grafie rozdzielnic").
- Przeniesiono wykrywanie przeciazenia gniazda/wejscia rozdzielnicy z czystego stanu UI (kolor chipa) do `PatchValidationResult` (`isOutletOverloaded`, `isDistroOverloaded`), zgodnie z `docs/DATA_MODEL.md` ("Przekroczenie limitu fazy powinno byc stanem walidacji, nie tylko kolorem UI"). `PatchValidationService.validate` przyjmuje teraz obliczone `ProjectPowerLoad` jako argument.
- Dodano limit wejscia dla rozdzielnic bez zadeklarowanego `inputConnectorTypeId` (np. zaimportowanych z grupy zlaczy lokacji) — domyslnie suma `maxCurrentA` wlasnych gniazd (tak jak w legacy StageCalc), zamiast braku jakiejkolwiek ochrony przed przeciazeniem. Dodano tez `manualInputMaxCurrentA` — reczny override limitu wejscia dla przypadkow, gdy automatyczne oszacowanie jest zbyt optymistyczne (np. 4 gniazda 125 A dzielace tylko 2 zabezpieczenia). Pole edytowalne w dialogu edycji rozdzielnicy. Podniesiono wersje schematu bazy do `10`.

- Naprawiono osierocone połączenia po usunięciu grupy: `_deleteGroup` w edytorze projektu teraz usuwa też wszystkie `PowerConnection` wskazujące na usuniętą grupę (`targetGroupId`), analogicznie do już istniejącego zachowania przy usuwaniu rozdzielnicy. Przed poprawką takie połączenie zostawało w bazie na stałe, pokazywało się jako „Nieznany cel połączenia” na liście Połączeń i trwale blokowało zajęte gniazdo jako niedostępne do ponownego użycia, mimo że nic już nie było do niego podłączone. To dokładnie ten sam błąd „osieroconych połączeń”, który dokumentacja legacy (`docs/legacy_stagecalc_debug_context.md`, sekcja 8) wskazywała jako znany problem do zaadresowania przy przepisaniu na Fluttera.
- Dodano test widgetowy `deleting a group removes its dangling connections` jako regresję dla powyższego przypadku.

### Znane ograniczenia

- Web bez HTTPS: przeglądarka wybiera `sharedIndexedDb` zamiast trwałego OPFS (wymaga bezpiecznego kontekstu, czyli TLS lub `localhost`). Zapisy mogą się zgubić przy twardym odświeżeniu/awarii karty tuż po zapisie. Do czasu skonfigurowania domeny + automatycznego HTTPS w Caddy jest to zaakceptowane ryzyko (patrz ADR-016).
- Kolekcje PocketBase mają na razie **puste (publiczne) reguły dostępu** — każdy z dostępem do serwera może czytać/zapisywać dowolne dane bez logowania. Akceptowalne tylko w obecnej prywatnej sieci LAN (patrz ADR-017).

### Zmieniono

- Rozbito `project_editor_screen.dart` (ok. 3900 linii, jeden plik na cały ekran edytora projektu) zgodnie z ADR-015. Wydzielono `ProjectEditorController` (`ChangeNotifier`) z całą logiką mutacji projektu, ładowaniem danych referencyjnych i przeliczeniami mocy/faz/walidacji patchera. Klasy dialogów i kart podzielono na 9 plików tematycznych w `presentation/project_editor/` (karty/dialog metadanych projektu, karty rozdzielnic, dialog tworzenia rozdzielnicy, edytor sekcji custom, dialog układu/edycji gniazd, karty i dialog połączeń, karty i dialogi grup/pozycji, dialog wyboru z katalogu, wspólne helpery faz/złączy), połączone z ekranem przez `part`/`part of`. Ekran `ProjectEditorScreen` (3900 → 536 linii) pozostał cienkim widokiem: pokazuje dialogi i przekazuje ich wynik do kontrolera. Zachowanie UI się nie zmieniło — potwierdzają to wszystkie dotychczasowe testy widgetowe plus nowy test regresyjny, bez modyfikacji, oraz zielony `flutter build windows`.

## v0.2.0+1 - 2026-07-08

### Dodano

- Dodano tryb `Custom` przy tworzeniu rozdzielnicy w patcherze.
- Dodano obsługę wielu sekcji wyjść w rozdzielnicy custom, np. `2x CEE 32A`, `6x Schuko`, dodatkowe wyjścia mieszane.
- Dodano obsługę wielu sekcji wyjść w presetach rozdzielnic w bibliotece.
- Doprecyzowano fazowanie rozdzielnic: złącza 3F zawsze używają wszystkich faz, a wejście 1F wymusza jedną fazę dla wyjść 1F.
- Poprawiono oznaczenie `Zrodlo` w patcherze: rozdzielnica podpięta do innej rozdzielnicy nie jest już pokazywana jako źródło.
- Etykieta `Zrodlo` jest teraz pokazywana na rozdzielnicy początkowej w drzewie zasilania.
- Dialog połączeń ukrywa użyte złącza, dopóki nie zostanie włączony tryb pokazywania/nadpisywania użytych złączy.
- Dodano szybkie podpinanie jednej grupy do wielu gniazd naraz w dialogu połączeń.
- Zmieniono automatyczny rozkład faz sekcji gniazd na układ blokowy, np. `L1, L1, L2, L2, L3, L3` dla 6 gniazd.
- Dodano przycisk `Auto fazy` w edycji rozdzielnicy, z zachowaniem możliwości ręcznej korekty faz pojedynczych gniazd.
- Nazwa/opis złącza aktualizuje się automatycznie po zmianie typu, dopóki użytkownik nie wpisze własnej nazwy.
- Poprawiono wykrywanie ręcznej edycji nazwy złącza: samo kliknięcie pola nazwy nie blokuje już automatycznej aktualizacji po zmianie typu.
- Przyłącza lokacji są teraz dostępne w patcherze jako źródłowe grupy złączy.
- W lokacjach doprecyzowano nazewnictwo przyłączy jako `Grupy złączy`, zgodnie z pracą na obiektach.
- Katalog lokacji otwiera teraz ekran szczegółów po kliknięciu karty lokacji.
- Formularz dodawania/edycji lokacji ma pogrupowane sekcje danych obiektu, kontaktu, grup złączy i notatek.
- Szczegóły lokacji pokazują pogrupowane informacje oraz akcje otwarcia mapy, telefonu i emaila.
- Lokacje obsługują wiele kontaktów, np. managera obiektu i kontakt techniczny.
- Dodano edycję istniejącej rozdzielnicy:
  - nazwa,
  - typ wejścia,
  - dodawanie gniazd,
  - edycja gniazd,
  - usuwanie gniazd.
- Zmieniono automatyczne nazwy szybkich gniazd na bardziej techniczne, np. `Schuko L1.1`.
- Dodano klikalne podsumowanie klienta i lokalizacji w karcie projektu.
- Dodano przyłącza energetyczne lokacji.
- Dodano obliczanie maksymalnej dostępnej mocy obiektu na podstawie przyłączy.

## v0.1.0+1

### Dodano

- Utworzono aplikację Flutter w katalogu `flutter/`.
- Dodano pakiet Dart `stagecalc`.
- Wygenerowano platformy Android, Windows i Web.
- Dodano motyw GreenCrew Tools:
  - domyślny dark mode,
  - zielony akcent GreenCrew,
  - neutralne powierzchnie,
  - Material Design.
- Dodano responsywną nawigację:
  - bottom navigation na telefonie,
  - navigation rail na większych ekranach.
- Dodano ekrany:
  - Projekty,
  - Katalog,
  - Lokacje,
  - Klienci,
  - Info.
- Dodano lokalną bazę Drift/SQLite.
- Dodano pola przygotowane pod przyszłą synchronizację:
  - `workspaceId`,
  - `remoteId`,
  - `deletedAt`,
  - `revision`,
  - `syncState`,
  - `lastSyncedAt`.
- Dodano modele domenowe projektu:
  - `Project`,
  - `ProjectGroup`,
  - `ProjectItem`,
  - `ProjectDistro`,
  - `ProjectOutlet`,
  - `PowerConnection`.
- Dodano serwisy domenowe:
  - `ProjectTotalsService`,
  - `PowerCalculationService`,
  - `PatchValidationService`.
- Dodano lokalny katalog urządzeń z CRUD i seedem danych.
- Dodano lokalny CRUD klientów.
- Dodano lokalny CRUD lokacji.
- Dodano powiązanie projektu z klientem i lokacją.
- Dodano presety rozdzielnic i szablony gniazd.
- Dodano widok presetów w katalogu.
- Dodano runtime rozdzielnic w projekcie.
- Dodano podstawowy widok patchera w edytorze projektu.
- Dodano połączenia grupa -> rozdzielnica / gniazdo.
- Dodano szybkie tworzenie rozdzielnic w patcherze.
- Dodano łączenie rozdzielnic między sobą.
- Dodano filtrowanie gniazd przy łączeniu rozdzielnic po typie wejścia rozdzielnicy podrzędnej.
- Dodano propagację obciążenia rozdzielnicy podrzędnej do gniazda rozdzielnicy nadrzędnej.
- Dodano obliczanie obciążenia gniazd i faz `L1/L2/L3`.
- Dodano ostrzeganie o przeciążonych gniazdach.
- Dodano dzielenie obciążenia grupy między wiele połączeń tej samej grupy.
- Dodano wykrywanie przeciążenia wejścia rozdzielnicy na podstawie typu złącza wejściowego.
- Dodano ostrzeżenie na karcie rozdzielnicy przy przekroczeniu limitu wejścia.
- Dodano oznaczanie przeciążonej fazy `L1/L2/L3` na chipach obciążenia rozdzielnicy.
- Dodano żółte ostrzeżenie przy 10% lub mniejszym zapasie na gnieździe, fazie i wejściu rozdzielnicy.
- Dodano automatyczne przeliczanie `W <-> A` przy założeniu `230 V` w formularzach urządzeń i pozycji ręcznych.
- Dodano walidację wielokrotnego użycia tego samego gniazda.
- Dodano blokadę ponownego użycia zajętego gniazda bez świadomego przełączenia opcji.
- Dodano wyszukiwanie, filtrowanie i szybkie chipy ilości w dialogu `Dodaj z katalogu`.
- Dodano pierwszy model danych kratownic `ProjectTruss`.
- Dodano tabelę Drift/SQLite `project_trusses`.
- Dodano zapis i odczyt kratownic w repozytorium projektów.
- Dodano test repozytorium projektu dla kratownic.
- Dodano testy:
  - domenowe,
  - repozytoriów Drift/SQLite,
  - widgetowe.
- Dodano dokumentację migracji, modelu danych, zakresu funkcji, decyzji i statusu implementacji.
- Dodano główny `README.md` pod GitHuba.
- Dodano ten `CHANGELOG.md`.

### Zmieniono

- Zastąpiono starterowy counter app szkieletem aplikacji StageCalc.
- Zmieniono myślenie domenowe z legacy `Calculation` na `Project`.
- Przeniesiono projekty i katalog ze `shared_preferences` do Drift/SQLite.
- Uporządkowano edytor projektu na widoki:
  - `Sprzęt`,
  - `Patcher`.
- Uściślono założenie, że legacy StageCalc jest źródłem wymagań, ale nie kontraktem kompatybilności.

### Usunięto

- Usunięto repozytoria i testy oparte o `shared_preferences`.
- Usunięto zależność `shared_preferences`.
- Usunięto domyślną treść README wygenerowaną przez Fluttera.

### Znane ograniczenia

- Pełny wizualny patcher nie jest jeszcze gotowy.
- Moduł kratownic nie został jeszcze wdrożony.
- Backup JSON nie został jeszcze wdrożony.
- Eksport PDF nie został jeszcze wdrożony.
- Synchronizacja z bazą hostowaną nie została jeszcze wdrożona.
- Web/iOS nie są jeszcze platformami referencyjnymi.

### Weryfikacja

- `dart format .` przechodzi.
- `flutter analyze` przechodzi.
- `flutter test` przechodzi.
- `flutter build windows` przechodzi.

## [0.1.0] - planowana pierwsza wersja techniczna

### Cel

- Pierwszy wewnętrzny build techniczny StageCalc Flutter dla Windows/Android.
- Zakres: praca lokalna offline-first, katalog, projekty, klienci, lokacje, presety rozdzielnic i podstawowy patcher.

### Kryteria wydania

- Zielone `flutter analyze`.
- Zielone `flutter test`.
- Działający build Windows.
- Działający build Android APK.
- Aktualny backup lub jasny komunikat, że build nie jest jeszcze przeznaczony do danych produkcyjnych.

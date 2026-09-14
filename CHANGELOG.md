# Changelog

Wszystkie istotne zmiany w projekcie StageCalc Flutter będą opisywane w tym pliku.

Format jest oparty o Keep a Changelog, a wersjonowanie docelowo powinno używać schematu `MAJOR.MINOR.PATCH+BUILD`.

## [Unreleased]

### Dodano

- Dodano kategorie oświetlenie/nagłośnienie/multimedia w katalogu urządzeń (ADR-031), zastępując jedną ogólną kategorię "Urządzenie" - zgodnie z pierwotnym podziałem z `docs/FEATURE_SCOPE.md`. Formularz "Dodaj urządzenie" pokazuje teraz tylko pola sensowne dla wybranej kategorii: "Rigging" nie pokazuje już Mocy/Prądu/typów złącz/punktów zaczepienia, "Kabel" nie pokazuje Mocy/Prądu/Producenta/punktów zaczepienia. Dodano też filtr kategorii (rząd chipów) na ekranie Katalog, obok istniejącego wyszukiwania tekstowego. Bez migracji schematu (kategoria to zwykłe pole tekstowe, ten sam wzorzec co ADR-030) - istniejące urządzenia z kategorią "Urządzenie" wczytują się jako "Inne".
- Grupa złączy lokacji może teraz mieć wiele różnych typów złącz naraz (ADR-032), np. "Rozdzielnia sceny" = 2x CEE 32A 5P + 4x Schuko, zamiast jednego typu na całą grupę. Dialog edycji grupy pokazuje listę wierszy typ+ilość z przyciskiem "Dodaj typ złącza"; tworzenie rozdzielnicy w projekcie z takiej grupy generuje teraz gniazda dla każdego typu osobno. Bez migracji schematu PocketBase (ponownie użyto istniejącego pola tekstowego na JSON, jak w ADR-030/031); lokalna baza dostaje jedną nową kolumnę i automatycznie przepisuje każdą istniejącą grupę na jednoelementową listę.
- Dodano font Roboto (ADR-033) do eksportu PDF (ADR-027) w miejsce domyślnego Helvetica bez wsparcia Unicode, i włączono polskie znaki diakrytyczne we wszystkich tekstach interfejsu oraz w dokumentacji sesji - od ADR-017 aplikacja celowo pisała polski tekst czystym ASCII (bez ą/ć/ę/ł/ń/ó/ś/ź/ż), żeby uniknąć łamanych znaków w eksportowanym PDF-ie; teraz, gdy PDF ma właściwy, wbudowany font (`assets/fonts/Roboto-{Regular,Bold}.ttf`, licencja OFL-1.1), to ograniczenie przestało być potrzebne.

## v0.3.4+1 - 2026-09-14

### Naprawiono

- v0.3.3 nie naprawiła niczego na prawdziwym urządzeniu, mimo że test regresyjny przechodził: `_addColumnIfMissing`/`_createTableIfMissing` łapały `on SqliteException`, ale `NativeDatabase.createInBackground` (używane w prawdziwej aplikacji - `connection_native.dart`) uruchamia każde zapytanie w tle-izolacie i **opakowuje każdy błąd przekraczający granicę izolatu w `DriftRemoteException`** - `catch ... on SqliteException` nigdy nie dopasowywał, bo obiekt, którym `Future` faktycznie się kończy, to opakowanie, nie oryginalny wyjątek. Test w v0.3.3 używał zwykłego `NativeDatabase(File(...))` (ten sam izolat, bez opakowania) - dlatego przechodził, mimo że poprawka nie działała naprawdę.
  - Zmieniono `catch` na dopasowanie po treści błędu (`error.toString()`) zamiast po typie - działa niezależnie od tego, czy wyjątek jest opakowany w `DriftRemoteException`, czy nie, bo `DriftRemoteException.toString()` i tak deleguje do oryginalnego błędu.
  - Test regresyjny przepisany na `NativeDatabase.createInBackground` (dokładnie ten sam wykonawca co prawdziwa aplikacja) - z powrotem na `on SqliteException` test teraz poprawnie zawodzi, potwierdzając, że faktycznie testuje ścieżkę, która się liczy.
  - **Zweryfikowano naprawdę tym razem**: uruchomiono zbudowany plik `.exe` bezpośrednio na tej samej, uszkodzonej lokalnej bazie użytkownika (nie tylko test) - ekran błędu zniknął, Projekty/Katalog/Lokacje wczytały prawdziwe dane, a nowo utworzony projekt poprawnie się zapisał.

## v0.3.3+1 - 2026-09-14

### Naprawiono

- Znaleziono rzeczywistą przyczynę zgłoszenia "offline nie da się nic dodać" (v0.3.2 tylko ukrywała objaw): ekran błędu ujawnił `SqliteException: duplicate column name: rigging_points` przy migracji `ALTER TABLE "catalog_devices" ADD COLUMN "rigging_points"` (krok `from < 11`) - kolumna już fizycznie istniała w pliku bazy, mimo że śledzona wersja schematu (`PRAGMA user_version`) była niższa niż 11. Ten jeden rzucony wyjątek psuł wczytanie danych na wszystkich czterech ekranach na raz, bo wszystkie dzielą tę samą bazę.
  - Wszystkie kroki migracji (`migrator.addColumn`/`migrator.createTable` w `onUpgrade`, wersje 2-15) są teraz idempotentne: nowe `_addColumnIfMissing`/`_createTableIfMissing` w `app_database.dart` łapią `SqliteException` z komunikatem "duplicate column name"/"already exists" i po prostu pomijają ten krok zamiast wywalać całą migrację - krok, który okazuje się już zastosowany, powinien być pominięty, nie powinien psuć całej reszty.
  - Dokładny mechanizm, przez który śledzona wersja schematu rozjechała się z rzeczywistym kształtem tabeli na tym urządzeniu, nie został ustalony - poprawka tego nie wymaga: krok migracji, który jest już zastosowany, jest teraz bezpiecznie pomijany niezależnie od przyczyny.
  - Dodano test regresyjny (`test/infrastructure/local_database/app_database_migration_test.dart`) odtwarzający dokładnie ten scenariusz na prawdziwym pliku sqlite: tworzy świeżą bazę (wszystko fizycznie istnieje przy aktualnej wersji), ręcznie cofa TYLKO `user_version` osobnym, surowym połączeniem (nie ruszając schematu), po czym otwiera plik ponownie przez `AppDatabase` - przed poprawką rzucało dokładnie ten sam `SqliteException`, po poprawce migracja kończy się poprawnie na wersji `15`.
- Instalacja tej wersji powinna sama naprawić zablokowane urządzenia bez utraty danych lokalnych - ten sam krok migracji, który wcześniej wywalał cały proces, teraz po prostu zostanie pominięty jako już zastosowany.

## v0.3.2+1 - 2026-09-14

### Naprawiono

- Zgłoszenie: offline nie dało się dodać projektu (panel pokazuje się, ale nie zapisuje), ani katalogu/lokacji/klienta (przycisk nic nie robi). Każdy z czterech ekranów list (Projekty/Katalog/Lokacje/Klienci) trzyma własne repozytorium jako `_repository`, ustawiane dopiero po udanym początkowym wczytaniu danych z lokalnej bazy - jeśli to wczytanie się nie powiodło albo jeszcze nie skończyło, `_repository` zostawało `null`. Każda z czterech akcji "Dodaj" sprawdzała to pole i po cichu przerywała bez żadnej informacji - dla Klientów/Lokacji/Katalogu sprawdzenie było PRZED otwarciem dialogu (więc przycisk faktycznie nic nie robił), a dla Projektów PO zamknięciu dialogu z wynikiem (więc dialog się pokazywał, ale zapis cicho nie wychodził) - ten sam rdzeń problemu, dwa różne objawy przez niespójne miejsce sprawdzania.
  - Dodano `_ensureRepository()` do wszystkich czterech ekranów: jeśli repozytorium nie jest gotowe, próbuje ponownie wczytać dane, a dopiero gdy to też się nie powiedzie, pokazuje użytkownikowi rzeczywisty komunikat błędu (SnackBar) zamiast ciszy. Projekty ujednolicono do tego samego wzorca co reszta (sprawdzenie przed otwarciem dialogu).
  - Komunikaty błędów wczytywania (`_error` na wszystkich czterech ekranach) pokazują teraz treść wyjątku, nie tylko ogólny tekst - potrzebne do zdiagnozowania, co faktycznie idzie nie tak.
  - **Nie potwierdzono rzeczywistej przyczyny, dla której wczytanie lokalnej bazy miałoby zawodzić offline** - lokalne repozytoria (Drift) nie dotykają sieci w ogóle, więc bezpośredni związek z "offline" pozostaje niejasny. Ta poprawka usuwa cichy brak informacji zwrotnej i dodaje samoleczącą się próbę ponowienia, co powinno pomóc niezależnie od dokładnej przyczyny - i, jeśli problem nadal wystąpi, pokazać prawdziwy komunikat błędu zamiast ciszy.

## v0.3.1+1 - 2026-09-14

### Naprawiono

- Zgłoszenie: "Android nie wstaje" po instalacji v0.3.0. Przeglądem kodu (bez potwierdzenia na urządzeniu - środowisko sesji nie utrzymywało stabilnie emulatora Android do weryfikacji) znaleziono dwa realne problemy specyficzne dla Androida wprowadzone/odsłonięte przez ADR-028:
  - `main()` blokował `runApp()` na nieopakowanym `await PocketBaseClientProvider.initialize()` (otwarcie lokalnej bazy + przywrócenie sesji logowania) - jakikolwiek wyjątek albo spowolnienie w tym kroku (np. wolne uruchomienie tła-izolatu Drift na niektórych urządzeniach Android) nie pozwalało aplikacji pokazać żadnego UI. Owinięte w `try`/`timeout(5s)` - awaria tego kroku teraz nigdy nie blokuje startu, tylko cofa do niezalogowanego stanu (zgodnie z zasadą ADR-028 "praca lokalna nie jest blokowana logowaniem").
  - Android 9+ domyślnie blokuje ruch `http://` (bez TLS) dla aplikacji z nowoczesnym `targetSdkVersion` - a adres PocketBase (`http://192.168.0.113`, ADR-017) nigdy nie miał `usesCleartextTraffic`/network security config. To nie blokowało startu aplikacji, ale każda próba logowania/synchronizacji na Androidzie kończyłaby się cichą awarią połączenia. Dodano `network_security_config.xml` zezwalający na cleartext wyłącznie do tego jednego adresu LAN.
- `AppMetadata.version` zsynchronizowane z `0.3.1`.

## v0.3.0+1 - 2026-09-14

### Dodano

- Dodano wielokrotny wybór typów złącz w katalogu urządzeń (ADR-030): pole "Typ złącza" było wolnym tekstem, teraz to siatka `FilterChip` z zamkniętą listą 23 typów (zasilanie: Schuko/CEE/Powerlock/powerCON, sygnał: XLR/SpeakON/EtherCON/BNC/Jack/RCA/HDMI/SDI/USB) - urządzenie może mieć zaznaczonych kilka naraz. Stare wartości tekstowe (w tym dane demo) migrowane automatycznie tam, gdzie da się je jednoznacznie rozpoznać; nierozpoznane porzucane, nie zgadywane. Zero zmian schematu PocketBase. Schemat lokalny podniesiony do wersji `15`. `docs/CATALOG_IMPORT_GUIDE.md` zaktualizowany o pełną listę dozwolonych wartości dla wsadu generowanego przez GPT.
- Dodano wizualny układ patchera (ADR-029): gniazda rozdzielnic to teraz klikalna siatka kafelków (faza, zajętość L1/L2/L3, obciążenie, podłączony cel) zamiast czysto informacyjnych pigułek. Dotknięcie pustego gniazda otwiera szybki dialog połączenia (cel + fazy dla gniazd "All" + notatka), dotknięcie zajętego pokazuje szczegóły połączenia z edytowalnymi notatkami i przyciskiem rozłączenia. Notatki do połączeń (pole istniejące w schemacie od ADR-017) mają wreszcie UI do zapisu i odczytu. Zbiorowy dialog "Połącz" (jedna grupa na wiele gniazd naraz) i lista "Połączenia" działają bez zmian.
- Dodano prawdziwą autoryzację PocketBase (ADR-028), zastępując puste/publiczne reguły dostępu z ADR-017: konta osobiste (kolekcja `users`), nowa karta "Konto" w ekranie "O aplikacji" (logowanie/wylogowanie), sesja logowania przeżywająca restart aplikacji (`AsyncAuthStore`). Katalog urządzeń, lokacje i presety zasilania są wspólne dla każdego zalogowanego członka zespołu; klienci i projekty są prywatne (widoczne tylko dla właściciela, stemplowanego automatycznie przy pierwszej synchronizacji). Praca lokalna działa normalnie bez logowania — tylko synchronizacja czeka, aż ktoś się zaloguje.
- Dodano wsparcie lokalnej bazy Drift na platformie Web (ADR-016): `WasmDatabase` (sqlite3 skompilowane do WebAssembly) zamiast `NativeDatabase`, wybierane automatycznie przez conditional import (`infrastructure/local_database/connection/`). `flutter build web` wcześniej w ogóle się nie kompilował (`dart:io`/`dart:ffi` nie działają na web) — aplikacja pierwszy raz faktycznie działa w przeglądarce.
- Wdrożono StageCalc Web pod `http://192.168.0.113/` (LXC 113, Caddy jako serwer statyczny + reverse proxy do PocketBase na `/api` i `/_`).
- Dodano pierwszą integrację z PocketBase (ADR-017): utworzono w PocketBase 13 kolekcji odzwierciedlających obecny schemat Drift, dodano `PocketBaseProjectSyncService` (jednokierunkowy, idempotentny push projektu z pełnym drzewem grup/pozycji/rozdzielnic/gniazd/połączeń/kratownic do PocketBase) i skrypt dowodowy `tool/push_demo_project.dart`. Bez zmian w UI, bez odczytu z powrotem, bez obsługi konfliktów — to pierwszy krok, nie sync engine.
- Dodano pierwszy backup JSON (ADR-018): `AppBackupService` eksportuje wszystkie projekty (z pełnym drzewem), klientów, lokacje i presety rozdzielnic do jednego pliku JSON z `BackupManifest`. Dostępny z ekranu "O aplikacji" ("Utwórz kopię zapasową (JSON)"). Działa na Android/Windows przez zapis do `Documents/StageCalc/backups/`; na Web na razie świadomie niewspierany. Dodano brakujące `toJson`/`fromJson` do `Client`, `Location` (+ kontakty/przyłącza) i `PowerPreset` (+ szablony gniazd), których do tej pory nie miały.
- Dodano import backupu JSON (ADR-019): `AppBackupImportService.validate` sprawdza kompletność i poprawność pliku (JSON, manifest, wersja formatu, każdy rekord przez `fromJson`) przed jakimkolwiek zapisem — jeden zły rekord odrzuca cały import. Po walidacji UI pokazuje dialog z liczbą znalezionych rekordów i ostrzeżeniem o nadpisaniu, dopiero potem `import` zapisuje przez istniejące repozytoria (upsert po ID, nic innego nie jest kasowane). Na razie bez file pickera — użytkownik wkleja ścieżkę do pliku.
- Dodano pierwszy silnik i UI modułu kratownic (ADR-020): `TrussLoadService` liczy masę kratownicy z przypisanych grup + ręcznego obciążenia i porównuje z opcjonalnymi limitami (całkowitym i rozłożonym kg/m, z progiem ostrzegawczym 90%). Edytor projektu ma teraz trzeci widok "Kratownice" — lista, dodawanie/edycja (nazwa, długość, ręczne obciążenie, limity, notatki, przypisanie grup), usuwanie. Bez haków i interpolacji tabel nośności producenta — to osobny, większy krok wymagający nowego schematu (patrz ADR-020). Naprawiono przy okazji ten sam wzorzec osieroconych referencji co przy połączeniach (ADR-015): usunięcie grupy czyści też `assignedGroupIds` kratownic.
- Dodano pierwszy eksport raportu projektu (ADR-021): `ProjectReportService.buildTextReport` generuje czytelny raport tekstowy (podsumowanie, grupy z pozycjami, rozdzielnice z obciążeniem faz i ostrzeżeniami, kratownice z masą i limitami) używając dokładnie tych samych serwisów domenowych co UI. Dostępny jako ikona w AppBar edytora projektu. Tekst zamiast PDF na razie — `docs/FEATURE_SCOPE.md` dopuszcza to wprost dla MVP; PDF wymagałby osobnej, większej pracy (nowa zależność, układ, styl GreenCrew). Wydzielono przy okazji wspólny `writeLocalFile` (`infrastructure/files/local_file_writer/`), zamiast trzeciej kopii tego samego trójkąta native/web/stub co połączenie z bazą (ADR-016) i backup (ADR-018).
- Dodano `tool/package_release.dart` (ADR-022): `dart run tool/package_release.dart` buduje i pakuje release Android/Windows do `dist/StageCalc-vX_Y_Z-android.apk` / `-windows.zip`, zgodnie z nazewnictwem z ADR-012F. Wersja czytana z `pubspec.yaml`.
- Dodano file picker dla importu backupu (ADR-023): przycisk "Wybierz plik" obok pola ścieżki w ekranie "O aplikacji" otwiera natywny wybór pliku (`.json`) zamiast wymagać ręcznego wklejenia ścieżki. Pole ręcznej ścieżki zostaje jako alternatywa. Bez nowych uprawnień Android (SAF/`GET_CONTENT`, zgodnie z ADR-012E).
- Dodano haki kratownic (ADR-024): `CatalogDevice.riggingPoints` (liczba punktów zaczepienia na urządzenie, pole w formularzu katalogu) + `ProjectItem.riggingPointsSnapshot` (snapshot per ADR-008) dają wymaganą liczbę haków dla każdej grupy. Nowa tabela `project_group_hook_assignments` trzyma przypisane haki (wybierane z katalogu, tak jak zwykłe pozycje) wraz z ich wagą, która dolicza się do masy grupy przy liczeniu obciążenia przypisanej kratownicy (`TrussLoadService.hookRequirement`). Nowa sekcja "Haki grup urządzeń" w widoku Kratownice pokazuje "Wymagane / Przypisane" per grupa (czerwony chip gdy za mało) i pozwala dodawać/usuwać/zmieniać ilość haków. Schemat bazy podniesiony do wersji `11`.
- Dodano eksport raportu do PDF (ADR-027), uzupełniając raport tekstowy z ADR-021: `ProjectPdfReportService` używa dokładnie tych samych serwisów domenowych co UI i raport tekstowy (Podsumowanie/Grupy/Rozdzielnice/Kratownice jako tabele z akcentem GreenCrew, te same ostrzeżenia), przez pakiet `pdf` (czysty Dart, bez natywnych zależności). Nowa ikona "Eksportuj raport PDF" w AppBar edytora projektu, obok istniejącego eksportu tekstowego. `local_file_writer` rozszerzony o `writeLocalBytesFile` - pierwszy binarny plik do zapisania lokalnie.
- Dodano dwukierunkową synchronizację z PocketBase (ADR-026), zamykając Etap 10: pięć serwisów synchronizujących (projekty z pełnym drzewem, katalog, klienci, lokacje, presety), strategia konfliktów "ostatni zapis wygrywa" po `updatedAt` (`decideSyncDirection`), reconciliacja na poziomie całego agregatu (nie pojedynczych zagnieżdżonych rekordów), nic nigdy nie jest twardo usuwane - tylko upsert z flagą `deleted`/`deleted_at` po obu stronach. Nowy przełącznik "Automatyczna synchronizacja" + przycisk "Synchronizuj teraz" w ekranie "O aplikacji" (nowa tabela `AppSettings`), automatyczny sync co 15 minut gdy włączony. Dopisano brakujące pola/kolekcje do zdalnego schematu PocketBase (haki, riggingPoints, tabela nośności, link kratownicy do katalogu) jako pliki migracji, teraz wersjonowane w repozytorium (`pocketbase/pb_migrations/`) zamiast istnieć tylko na serwerze. Zastępuje jednokierunkowy `pushProject` z ADR-017.
- Dodano interpolację tabel nośności kratownic (ADR-025), zamykając Etap 7 w całości: `ProjectTruss.trussCatalogDeviceId` linkuje kratownicę do modelu z katalogu (kategoria Rigging), `CatalogDevice.loadChart` trzyma tabelę nośności producenta (długość/obciążenie punktowe/obciążenie rozłożone), edytowalną w formularzu katalogu dla tej kategorii. `TrussLoadService` liczy limit interpolacją liniową między najbliższymi punktami tabeli, z ekstrapolacją i ostrzeżeniem gdy długość kratownicy wykracza poza tabelę - port logiki z legacy kalkulatora. Ręczne `maxTotalLoadKg`/`maxDistributedLoadKgPerM` działają teraz jako override per pole (gdy puste, liczy się z tabeli; gdy wypełnione, wygrywa ręcznie wpisana wartość) - ta sama zasada co `manualInputMaxCurrentA` dla rozdzielnic. Schemat bazy podniesiony do wersji `12`.

### Naprawiono

- `AppMetadata.version` (pokazywane jako "Wersja" w ekranie "O aplikacji" i zapisywane w `manifest.appVersion` każdego backupu) było od początku zahardkodowane jako `1.0.0`, całkowicie niezależne od rzeczywistej wersji w `pubspec.yaml`. Zsynchronizowano z wersją release `0.3.0`.
- Dodano brakujące `android.permission.INTERNET` w `AndroidManifest.xml` (ADR-022). Zweryfikowano w scalonym manifeście release builda, że uprawnienia nie było ani z aplikacji, ani z żadnej biblioteki — `PocketBaseProjectSyncService` (ADR-017) na Androidzie kończyłby każde połączenie `SecurityException`, niezależnie od trybu builda. Błąd niezauważony wcześniej, bo sync był dotychczas testowany tylko z Windows (`tool/push_demo_project.dart`), nie z samej aplikacji na telefonie.
- Naprawiono błędne przypisanie fazy przy kaskadzie rozdzielnica -> rozdzielnica: `PowerCalculationService` sumował obciążenie rozdzielnicy podrzędnej wprost po jej wewnętrznych etykietach L1/L2/L3, ignorując fazę gniazda rodzica, przez które dziecko jest faktycznie podpięte. Rozdzielnica podrzędna o wejściu 1-fazowym (każde jej gniazdo wewnętrznie oznaczone jako "L1") podpięta do gniazda L2 lub L3 rodzica pokazywała cały prąd na L1 rodzica zamiast na fazie, na której fizycznie jest podpięta - niezgodnie z `docs/DATA_MODEL.md` ("Jeśli dziecko podpięte do 1 fazy rodzica: suma wszystkich faz dziecka trafia na tę jedną fazę rodzica"). Dodano test regresyjny.

### Dodano

- Dodano wykrywanie cykli w grafie połączeń rozdzielnica-rozdzielnica (`PatchValidationService`). Kalkulator już wcześniej chronił się przed nieskończoną rekursją (`visitedDistroIds`), ale robił to cicho - użytkownik nie miał żadnego sygnału, że wynik jest ucinany. Rozdzielnice w cyklu mają teraz w patcherze chip ostrzegawczy "Cykl w połączeniach rozdzielnic", zgodnie z `docs/DATA_MODEL.md` ("Należy blokować cykle w grafie rozdzielnic").
- Przeniesiono wykrywanie przeciążenia gniazda/wejścia rozdzielnicy z czystego stanu UI (kolor chipa) do `PatchValidationResult` (`isOutletOverloaded`, `isDistroOverloaded`), zgodnie z `docs/DATA_MODEL.md` ("Przekroczenie limitu fazy powinno być stanem walidacji, nie tylko kolorem UI"). `PatchValidationService.validate` przyjmuje teraz obliczone `ProjectPowerLoad` jako argument.
- Dodano limit wejścia dla rozdzielnic bez zadeklarowanego `inputConnectorTypeId` (np. zaimportowanych z grupy złączy lokacji) — domyślnie suma `maxCurrentA` własnych gniazd (tak jak w legacy StageCalc), zamiast braku jakiejkolwiek ochrony przed przeciążeniem. Dodano też `manualInputMaxCurrentA` — ręczny override limitu wejścia dla przypadków, gdy automatyczne oszacowanie jest zbyt optymistyczne (np. 4 gniazda 125 A dzielące tylko 2 zabezpieczenia). Pole edytowalne w dialogu edycji rozdzielnicy. Podniesiono wersję schematu bazy do `10`.

- Naprawiono osierocone połączenia po usunięciu grupy: `_deleteGroup` w edytorze projektu teraz usuwa też wszystkie `PowerConnection` wskazujące na usuniętą grupę (`targetGroupId`), analogicznie do już istniejącego zachowania przy usuwaniu rozdzielnicy. Przed poprawką takie połączenie zostawało w bazie na stałe, pokazywało się jako „Nieznany cel połączenia” na liście Połączeń i trwale blokowało zajęte gniazdo jako niedostępne do ponownego użycia, mimo że nic już nie było do niego podłączone. To dokładnie ten sam błąd „osieroconych połączeń”, który dokumentacja legacy (`docs/legacy_stagecalc_debug_context.md`, sekcja 8) wskazywała jako znany problem do zaadresowania przy przepisaniu na Fluttera.
- Dodano test widgetowy `deleting a group removes its dangling connections` jako regresję dla powyższego przypadku.

### Znane ograniczenia

- Web bez HTTPS: przeglądarka wybiera `sharedIndexedDb` zamiast trwałego OPFS (wymaga bezpiecznego kontekstu, czyli TLS lub `localhost`). Zapisy mogą się zgubić przy twardym odświeżeniu/awarii karty tuż po zapisie. Do czasu skonfigurowania domeny + automatycznego HTTPS w Caddy jest to zaakceptowane ryzyko (patrz ADR-016).
- Klienci/projekty utworzeni przed ADR-028 (bez przypisanego właściciela) nie są już synchronizowalne przez nikogo, dopóki superuser ręcznie nie przypisze im właściciela — jednorazowy koszt migracji z publicznego na oparty na właścicielu model dostępu (patrz ADR-028, sekcja "Konsekwencje").
- Zakładanie kont użytkowników PocketBase wymaga superusera (brak samodzielnej rejestracji) — zamierzone dla małego, zamkniętego zespołu (ADR-028).

### Zmieniono

- Rozbito `project_editor_screen.dart` (ok. 3900 linii, jeden plik na cały ekran edytora projektu) zgodnie z ADR-015. Wydzielono `ProjectEditorController` (`ChangeNotifier`) z całą logiką mutacji projektu, ładowaniem danych referencyjnych i przeliczeniami mocy/faz/walidacji patchera. Klasy dialogów i kart podzielono na 9 plików tematycznych w `presentation/project_editor/` (karty/dialog metadanych projektu, karty rozdzielnic, dialog tworzenia rozdzielnicy, edytor sekcji custom, dialog układu/edycji gniazd, karty i dialog połączeń, karty i dialogi grup/pozycji, dialog wyboru z katalogu, wspólne helpery faz/złączy), połączone z ekranem przez `part`/`part of`. Ekran `ProjectEditorScreen` (3900 → 536 linii) pozostał cienkim widokiem: pokazuje dialogi i przekazuje ich wynik do kontrolera. Zachowanie UI się nie zmieniło — potwierdzają to wszystkie dotychczasowe testy widgetowe plus nowy test regresyjny, bez modyfikacji, oraz zielony `flutter build windows`.

## v0.2.0+1 - 2026-07-08

### Dodano

- Dodano tryb `Custom` przy tworzeniu rozdzielnicy w patcherze.
- Dodano obsługę wielu sekcji wyjść w rozdzielnicy custom, np. `2x CEE 32A`, `6x Schuko`, dodatkowe wyjścia mieszane.
- Dodano obsługę wielu sekcji wyjść w presetach rozdzielnic w bibliotece.
- Doprecyzowano fazowanie rozdzielnic: złącza 3F zawsze używają wszystkich faz, a wejście 1F wymusza jedną fazę dla wyjść 1F.
- Poprawiono oznaczenie `Źródło` w patcherze: rozdzielnica podpięta do innej rozdzielnicy nie jest już pokazywana jako źródło.
- Etykieta `Źródło` jest teraz pokazywana na rozdzielnicy początkowej w drzewie zasilania.
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

- Pełny wizualny patcher (drag&drop) nie jest jeszcze gotowy — obecny patcher działa przez listy i dialogi.
- Moduł kratownic jest kompletny dla zakresu MVP (haki ADR-024, interpolacja ADR-025) — brakuje tylko rozbicia obciążeń ręcznych na pozycje punktowe/UDL (`ProjectTrussLoad`), które nadal są jedną zagregowaną wartością (`manualLoadKg`).
- Eksport PDF (ADR-027) używa domyślnych fontów PDF (Helvetica) — bez własnego fontu Roboto ani logo StageCalc, pełny branding pozostaje przyszłym krokiem.
- Synchronizacja z bazą hostowaną (ADR-026) rozwiązuje konflikty tylko przez "ostatni zapis wygrywa" po czasie edycji — bez kolejki z retry, bez ręcznego scalania i bez prawdziwej autoryzacji (kolekcje PocketBase mają nadal puste/publiczne reguły dostępu, ADR-017).
- Backup i raport eksportują zawsze do ustalonego katalogu `Documents/StageCalc/...` — file picker (ADR-023) jest na razie tylko po stronie importu.
- Android APK jest podpisywany kluczem debug (`signingConfig` w `android/app/build.gradle.kts`) — brak jeszcze własnego klucza release.
- Web/iOS nie są jeszcze platformami referencyjnymi; Web bez HTTPS traci trwałość zapisów przy twardym odświeżeniu (ADR-016).

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

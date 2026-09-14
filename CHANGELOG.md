# Changelog

Wszystkie istotne zmiany w projekcie StageCalc Flutter będą opisywane w tym pliku.

Format jest oparty o Keep a Changelog, a wersjonowanie docelowo powinno używać schematu `MAJOR.MINOR.PATCH+BUILD`.

## [Unreleased]

## v0.3.3+1 - 2026-09-14

### Naprawiono

- Znaleziono rzeczywista przyczyne zgloszenia "offline nie da sie nic dodac" (v0.3.2 tylko ukrywala objaw): ekran bledu ujawnil `SqliteException: duplicate column name: rigging_points` przy migracji `ALTER TABLE "catalog_devices" ADD COLUMN "rigging_points"` (krok `from < 11`) - kolumna juz fizycznie istniala w pliku bazy, mimo ze sledzona wersja schematu (`PRAGMA user_version`) byla nizsza niz 11. Ten jeden rzucony wyjatek psul wczytanie danych na wszystkich czterech ekranach na raz, bo wszystkie dziela ta sama baze.
  - Wszystkie kroki migracji (`migrator.addColumn`/`migrator.createTable` w `onUpgrade`, wersje 2-15) sa teraz idempotentne: nowe `_addColumnIfMissing`/`_createTableIfMissing` w `app_database.dart` lapia `SqliteException` z komunikatem "duplicate column name"/"already exists" i po prostu pomijaja ten krok zamiast wywalac cala migracje - krok, ktory okazuje sie juz zastosowany, powinien byc pominiety, nie powinien psuc calej reszty.
  - Dokladny mechanizm, przez ktory sledzona wersja schematu rozjechala sie z rzeczywistym ksztaltem tabeli na tym urzadzeniu, nie zostal ustalony - poprawka tego nie wymaga: krok migracji, ktory jest juz zastosowany, jest teraz bezpiecznie pomijany niezaleznie od przyczyny.
  - Dodano test regresyjny (`test/infrastructure/local_database/app_database_migration_test.dart`) odtwarzajacy dokladnie ten scenariusz na prawdziwym pliku sqlite: tworzy swieza baze (wszystko fizycznie istnieje przy aktualnej wersji), recznie cofa TYLKO `user_version` osobnym, surowym polaczeniem (nie ruszajac schematu), po czym otwiera plik ponownie przez `AppDatabase` - przed poprawka rzucalo dokladnie ten sam `SqliteException`, po poprawce migracja konczy sie poprawnie na wersji `15`.
- Instalacja tej wersji powinna sama naprawic zablokowane urzadzenia bez utraty danych lokalnych - ten sam krok migracji, ktory wczesniej wywalal caly proces, teraz po prostu zostanie pominiety jako juz zastosowany.

## v0.3.2+1 - 2026-09-14

### Naprawiono

- Zgloszenie: offline nie dalo sie dodac projektu (panel pokazuje sie, ale nie zapisuje), ani katalogu/lokacji/klienta (przycisk nic nie robi). Kazdy z czterech ekranow list (Projekty/Katalog/Lokacje/Klienci) trzyma wlasne repozytorium jako `_repository`, ustawiane dopiero po udanym poczatkowym wczytaniu danych z lokalnej bazy - jesli to wczytanie sie nie powiodlo albo jeszcze nie skonczylo, `_repository` zostawalo `null`. Kazda z czterech akcji "Dodaj" sprawdzala to pole i po cichu przerywala bez zadnej informacji - dla Klientow/Lokacji/Katalogu sprawdzenie bylo PRZED otwarciem dialogu (wiec przycisk faktycznie nic nie robil), a dla Projektow PO zamknieciu dialogu z wynikiem (wiec dialog sie pokazywal, ale zapis cicho nie wychodzil) - ten sam rdzen problemu, dwa rozne objawy przez niespojne miejsce sprawdzania.
  - Dodano `_ensureRepository()` do wszystkich czterech ekranow: jesli repozytorium nie jest gotowe, probuje ponownie wczytac dane, a dopiero gdy to tez sie nie powiedzie, pokazuje uzytkownikowi rzeczywisty komunikat bledu (SnackBar) zamiast ciszy. Projekty ujednolicono do tego samego wzorca co reszta (sprawdzenie przed otwarciem dialogu).
  - Komunikaty bledow wczytywania (`_error` na wszystkich czterech ekranach) pokazuja teraz tresc wyjatku, nie tylko ogolny tekst - potrzebne do zdiagnozowania, co faktycznie idzie nie tak.
  - **Nie potwierdzono rzeczywistej przyczyny, dla ktorej wczytanie lokalnej bazy mialoby zawodzic offline** - lokalne repozytoria (Drift) nie dotykaja sieci w ogole, wiec bezposredni zwiazek z "offline" pozostaje niejasny. Ta poprawka usuwa cichy brak informacji zwrotnej i dodaje samoleczaca sie probe ponowienia, co powinno pomoc niezaleznie od dokladnej przyczyny - i, jesli problem nadal wystapi, pokazac prawdziwy komunikat bledu zamiast ciszy.

## v0.3.1+1 - 2026-09-14

### Naprawiono

- Zgloszenie: "Android nie wstaje" po instalacji v0.3.0. Przegladem kodu (bez potwierdzenia na urzadzeniu - srodowisko sesji nie utrzymywalo stabilnie emulatora Android do weryfikacji) znaleziono dwa realne problemy specyficzne dla Androida wprowadzone/odsloniete przez ADR-028:
  - `main()` blokowal `runApp()` na nieopakowanym `await PocketBaseClientProvider.initialize()` (otwarcie lokalnej bazy + przywrocenie sesji logowania) - jakikolwiek wyjatek albo spowolnienie w tym kroku (np. wolne uruchomienie tla-izolatu Drift na niektorych urzadzeniach Android) nie pozwalalo aplikacji pokazac zadnego UI. Owiniete w `try`/`timeout(5s)` - awaria tego kroku teraz nigdy nie blokuje startu, tylko cofa do niezalogowanego stanu (zgodnie z zasada ADR-028 "praca lokalna nie jest blokowana logowaniem").
  - Android 9+ domyslnie blokuje ruch `http://` (bez TLS) dla aplikacji z nowoczesnym `targetSdkVersion` - a adres PocketBase (`http://192.168.0.113`, ADR-017) nigdy nie mial `usesCleartextTraffic`/network security config. To nie blokowalo startu aplikacji, ale kazda proba logowania/synchronizacji na Androidzie konczylaby sie cicha awaria polaczenia. Dodano `network_security_config.xml` zezwalajacy na cleartext wylacznie do tego jednego adresu LAN.
- `AppMetadata.version` zsynchronizowane z `0.3.1`.

## v0.3.0+1 - 2026-09-14

### Dodano

- Dodano wielokrotny wybor typow zlacz w katalogu urzadzen (ADR-030): pole "Typ zlacza" bylo wolnym tekstem, teraz to siatka `FilterChip` z zamknieta lista 23 typow (zasilanie: Schuko/CEE/Powerlock/powerCON, sygnal: XLR/SpeakON/EtherCON/BNC/Jack/RCA/HDMI/SDI/USB) - urzadzenie moze miec zaznaczonych kilka naraz. Stare wartosci tekstowe (w tym dane demo) migrowane automatycznie tam, gdzie da sie je jednoznacznie rozpoznac; nierozpoznane porzucane, nie zgadywane. Zero zmian schematu PocketBase. Schemat lokalny podniesiony do wersji `15`. `docs/CATALOG_IMPORT_GUIDE.md` zaktualizowany o pelna liste dozwolonych wartosci dla wsadu generowanego przez GPT.
- Dodano wizualny uklad patchera (ADR-029): gniazda rozdzielnic to teraz klikalna siatka kafelkow (faza, zajetosc L1/L2/L3, obciazenie, podlaczony cel) zamiast czysto informacyjnych pigulek. Dotkniecie pustego gniazda otwiera szybki dialog polaczenia (cel + fazy dla gniazd "All" + notatka), dotkniecie zajetego pokazuje szczegoly polaczenia z edytowalnymi notatkami i przyciskiem rozlaczenia. Notatki do polaczen (pole istniejace w schemacie od ADR-017) maja wreszcie UI do zapisu i odczytu. Zbiorowy dialog "Polacz" (jedna grupa na wiele gniazd naraz) i lista "Polaczenia" dzialaja bez zmian.
- Dodano prawdziwa autoryzacje PocketBase (ADR-028), zastepujac puste/publiczne reguly dostepu z ADR-017: konta osobiste (kolekcja `users`), nowa karta "Konto" w ekranie "O aplikacji" (logowanie/wylogowanie), sesja logowania przezywajaca restart aplikacji (`AsyncAuthStore`). Katalog urzadzen, lokacje i presety zasilania sa wspolne dla kazdego zalogowanego czlonka zespolu; klienci i projekty sa prywatne (widoczne tylko dla wlasciciela, stemplowanego automatycznie przy pierwszej synchronizacji). Praca lokalna dziala normalnie bez logowania — tylko synchronizacja czeka, az ktos sie zaloguje.
- Dodano wsparcie lokalnej bazy Drift na platformie Web (ADR-016): `WasmDatabase` (sqlite3 skompilowane do WebAssembly) zamiast `NativeDatabase`, wybierane automatycznie przez conditional import (`infrastructure/local_database/connection/`). `flutter build web` wczesniej w ogole sie nie kompilowal (`dart:io`/`dart:ffi` nie dzialaja na web) — aplikacja pierwszy raz faktycznie dziala w przegladarce.
- Wdrozono StageCalc Web pod `http://192.168.0.113/` (LXC 113, Caddy jako serwer statyczny + reverse proxy do PocketBase na `/api` i `/_`).
- Dodano pierwsza integracje z PocketBase (ADR-017): utworzono w PocketBase 13 kolekcji odzwierciedlajacych obecny schemat Drift, dodano `PocketBaseProjectSyncService` (jednokierunkowy, idempotentny push projektu z pelnym drzewem grup/pozycji/rozdzielnic/gniazd/polaczen/kratownic do PocketBase) i skrypt dowodowy `tool/push_demo_project.dart`. Bez zmian w UI, bez odczytu z powrotem, bez obslugi konfliktow — to pierwszy krok, nie sync engine.
- Dodano pierwszy backup JSON (ADR-018): `AppBackupService` eksportuje wszystkie projekty (z pelnym drzewem), klientow, lokacje i presety rozdzielnic do jednego pliku JSON z `BackupManifest`. Dostepny z ekranu "O aplikacji" ("Utworz kopie zapasowa (JSON)"). Dziala na Android/Windows przez zapis do `Documents/StageCalc/backups/`; na Web na razie swiadomie niewspierany. Dodano brakujace `toJson`/`fromJson` do `Client`, `Location` (+ kontakty/przylacza) i `PowerPreset` (+ szablony gniazd), ktorych do tej pory nie mialy.
- Dodano import backupu JSON (ADR-019): `AppBackupImportService.validate` sprawdza kompletnosc i poprawnosc pliku (JSON, manifest, wersja formatu, kazdy rekord przez `fromJson`) przed jakimkolwiek zapisem — jeden zly rekord odrzuca caly import. Po walidacji UI pokazuje dialog z liczba znalezionych rekordow i ostrzezeniem o nadpisaniu, dopiero potem `import` zapisuje przez istniejace repozytoria (upsert po ID, nic innego nie jest kasowane). Na razie bez file pickera — uzytkownik wkleja sciezke do pliku.
- Dodano pierwszy silnik i UI modulu kratownic (ADR-020): `TrussLoadService` liczy mase kratownicy z przypisanych grup + recznego obciazenia i porownuje z opcjonalnymi limitami (calkowitym i rozlozonym kg/m, z progiem ostrzegawczym 90%). Edytor projektu ma teraz trzeci widok "Kratownice" — lista, dodawanie/edycja (nazwa, dlugosc, reczne obciazenie, limity, notatki, przypisanie grup), usuwanie. Bez hakow i interpolacji tabel nosnosci producenta — to osobny, wiekszy krok wymagajacy nowego schematu (patrz ADR-020). Naprawiono przy okazji ten sam wzorzec osieroconych referencji co przy polaczeniach (ADR-015): usuniecie grupy czysci tez `assignedGroupIds` kratownic.
- Dodano pierwszy eksport raportu projektu (ADR-021): `ProjectReportService.buildTextReport` generuje czytelny raport tekstowy (podsumowanie, grupy z pozycjami, rozdzielnice z obciazeniem faz i ostrzezeniami, kratownice z masa i limitami) uzywajac dokladnie tych samych serwisow domenowych co UI. Dostepny jako ikona w AppBar edytora projektu. Tekst zamiast PDF na razie — `docs/FEATURE_SCOPE.md` dopuszcza to wprost dla MVP; PDF wymagalby osobnej, wiekszej pracy (nowa zaleznosc, uklad, styl GreenCrew). Wydzielono przy okazji wspolny `writeLocalFile` (`infrastructure/files/local_file_writer/`), zamiast trzeciej kopii tego samego trojkata native/web/stub co polaczenie z baza (ADR-016) i backup (ADR-018).
- Dodano `tool/package_release.dart` (ADR-022): `dart run tool/package_release.dart` buduje i pakuje release Android/Windows do `dist/StageCalc-vX_Y_Z-android.apk` / `-windows.zip`, zgodnie z nazewnictwem z ADR-012F. Wersja czytana z `pubspec.yaml`.
- Dodano file picker dla importu backupu (ADR-023): przycisk "Wybierz plik" obok pola sciezki w ekranie "O aplikacji" otwiera natywny wybor pliku (`.json`) zamiast wymagac recznego wklejenia sciezki. Pole recznej sciezki zostaje jako alternatywa. Bez nowych uprawnien Android (SAF/`GET_CONTENT`, zgodnie z ADR-012E).
- Dodano haki kratownic (ADR-024): `CatalogDevice.riggingPoints` (liczba punktow zaczepienia na urzadzenie, pole w formularzu katalogu) + `ProjectItem.riggingPointsSnapshot` (snapshot per ADR-008) daja wymagana liczbe hakow dla kazdej grupy. Nowa tabela `project_group_hook_assignments` trzyma przypisane haki (wybierane z katalogu, tak jak zwykle pozycje) wraz z ich waga, ktora dolicza sie do masy grupy przy liczeniu obciazenia przypisanej kratownicy (`TrussLoadService.hookRequirement`). Nowa sekcja "Haki grup urzadzen" w widoku Kratownice pokazuje "Wymagane / Przypisane" per grupa (czerwony chip gdy za malo) i pozwala dodawac/usuwac/zmieniac ilosc hakow. Schemat bazy podniesiony do wersji `11`.
- Dodano eksport raportu do PDF (ADR-027), uzupelniajac raport tekstowy z ADR-021: `ProjectPdfReportService` uzywa dokladnie tych samych serwisow domenowych co UI i raport tekstowy (Podsumowanie/Grupy/Rozdzielnice/Kratownice jako tabele z akcentem GreenCrew, te same ostrzezenia), przez pakiet `pdf` (czysty Dart, bez natywnych zaleznosci). Nowa ikona "Eksportuj raport PDF" w AppBar edytora projektu, obok istniejacego eksportu tekstowego. `local_file_writer` rozszerzony o `writeLocalBytesFile` - pierwszy binarny plik do zapisania lokalnie.
- Dodano dwukierunkowa synchronizacje z PocketBase (ADR-026), zamykajac Etap 10: piec serwisow synchronizujacych (projekty z pelnym drzewem, katalog, klienci, lokacje, presety), strategia konfliktow "ostatni zapis wygrywa" po `updatedAt` (`decideSyncDirection`), reconciliacja na poziomie calego agregatu (nie pojedynczych zagniezdzonych rekordow), nic nigdy nie jest twardo usuwane - tylko upsert z flaga `deleted`/`deleted_at` po obu stronach. Nowy przelacznik "Automatyczna synchronizacja" + przycisk "Synchronizuj teraz" w ekranie "O aplikacji" (nowa tabela `AppSettings`), automatyczny sync co 15 minut gdy wlaczony. Dopisano brakujace pola/kolekcje do zdalnego schematu PocketBase (haki, riggingPoints, tabela nosnosci, link kratownicy do katalogu) jako pliki migracji, teraz wersjonowane w repozytorium (`pocketbase/pb_migrations/`) zamiast istniec tylko na serwerze. Zastepuje jednokierunkowy `pushProject` z ADR-017.
- Dodano interpolacje tabel nosnosci kratownic (ADR-025), zamykajac Etap 7 w calosci: `ProjectTruss.trussCatalogDeviceId` linkuje kratownice do modelu z katalogu (kategoria Rigging), `CatalogDevice.loadChart` trzyma tabele nosnosci producenta (dlugosc/obciazenie punktowe/obciazenie rozlozone), edytowalna w formularzu katalogu dla tej kategorii. `TrussLoadService` liczy limit interpolacja liniowa miedzy najblizszymi punktami tabeli, z ekstrapolacja i ostrzezeniem gdy dlugosc kratownicy wykracza poza tabele - port logiki z legacy kalkulatora. Reczne `maxTotalLoadKg`/`maxDistributedLoadKgPerM` dzialaja teraz jako override per pole (gdy puste, liczy sie z tabeli; gdy wypelnione, wygrywa recznie wpisana wartosc) - ta sama zasada co `manualInputMaxCurrentA` dla rozdzielnic. Schemat bazy podniesiony do wersji `12`.

### Naprawiono

- `AppMetadata.version` (pokazywane jako "Wersja" w ekranie "O aplikacji" i zapisywane w `manifest.appVersion` kazdego backupu) bylo od poczatku zahardkodowane jako `1.0.0`, calkowicie niezalezne od rzeczywistej wersji w `pubspec.yaml`. Zsynchronizowano z wersja release `0.3.0`.
- Dodano brakujace `android.permission.INTERNET` w `AndroidManifest.xml` (ADR-022). Zweryfikowano w scalonym manifescie release builda, ze uprawnienia nie bylo ani z aplikacji, ani z zadnej biblioteki — `PocketBaseProjectSyncService` (ADR-017) na Androidzie konczylby kazde polaczenie `SecurityException`, niezaleznie od trybu builda. Blad niezauwazony wczesniej, bo sync byl dotychczas testowany tylko z Windows (`tool/push_demo_project.dart`), nie z samej aplikacji na telefonie.
- Naprawiono bledne przypisanie fazy przy kaskadzie rozdzielnica -> rozdzielnica: `PowerCalculationService` sumowal obciazenie rozdzielnicy podrzednej wprost po jej wewnetrznych etykietach L1/L2/L3, ignorujac faze gniazda rodzica, przez ktore dziecko jest faktycznie podpiete. Rozdzielnica podrzedna o wejsciu 1-fazowym (kazde jej gniazdo wewnetrznie oznaczone jako "L1") podpieta do gniazda L2 lub L3 rodzica pokazywala caly prad na L1 rodzica zamiast na fazie, na ktorej fizycznie jest podpieta - niezgodnie z `docs/DATA_MODEL.md` ("Jesli dziecko podpiete do 1 fazy rodzica: suma wszystkich faz dziecka trafia na te jedna faze rodzica"). Dodano test regresyjny.

### Dodano

- Dodano wykrywanie cykli w grafie polaczen rozdzielnica-rozdzielnica (`PatchValidationService`). Kalkulator juz wczesniej chronil sie przed nieskonczona rekursja (`visitedDistroIds`), ale robil to cicho - uzytkownik nie mial zadnego sygnalu, ze wynik jest ucinany. Rozdzielnice w cyklu maja teraz w patcherze chip ostrzegawczy "Cykl w polaczeniach rozdzielnic", zgodnie z `docs/DATA_MODEL.md` ("Nalezy blokowac cykle w grafie rozdzielnic").
- Przeniesiono wykrywanie przeciazenia gniazda/wejscia rozdzielnicy z czystego stanu UI (kolor chipa) do `PatchValidationResult` (`isOutletOverloaded`, `isDistroOverloaded`), zgodnie z `docs/DATA_MODEL.md` ("Przekroczenie limitu fazy powinno byc stanem walidacji, nie tylko kolorem UI"). `PatchValidationService.validate` przyjmuje teraz obliczone `ProjectPowerLoad` jako argument.
- Dodano limit wejscia dla rozdzielnic bez zadeklarowanego `inputConnectorTypeId` (np. zaimportowanych z grupy zlaczy lokacji) — domyslnie suma `maxCurrentA` wlasnych gniazd (tak jak w legacy StageCalc), zamiast braku jakiejkolwiek ochrony przed przeciazeniem. Dodano tez `manualInputMaxCurrentA` — reczny override limitu wejscia dla przypadkow, gdy automatyczne oszacowanie jest zbyt optymistyczne (np. 4 gniazda 125 A dzielace tylko 2 zabezpieczenia). Pole edytowalne w dialogu edycji rozdzielnicy. Podniesiono wersje schematu bazy do `10`.

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

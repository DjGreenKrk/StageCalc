# StageCalc Flutter Migration - Decisions

## Cel dokumentu

Ten dokument zbiera proponowane decyzje architektoniczne dla migracji StageCalc do Flutter + Dart. Status `proposed` oznacza rekomendacje do zatwierdzenia przed implementacja.

## ADR-001: Flutter jako czysta aplikacja domenowa

Status: proposed

Decyzja:

- Nie przenosic struktury Next.js/React 1:1.
- Nie zachowywac kompatybilnosci ze strukturami legacy, jesli nie zostanie to osobno zlecone.
- Zbudowac Fluttera jako czysta aplikacje z rozdzieleniem warstw:
  - `features/<feature>/domain`,
  - `features/<feature>/data`,
  - `features/<feature>/presentation`,
  - `infrastructure`,
  - `shared`.

Uzasadnienie:

- Obecna aplikacja dziala, ale najwiekszy komponent kalkulatora laczy UI, pobieranie danych, zapisywanie i obliczenia.
- Flutter powinien przejac wymagania, nie ksztalt komponentow React.

## ADR-002: Offline-first od pierwszego dnia

Status: proposed

Decyzja:

- Lokalna baza jest zrodlem prawdy.
- Synchronizacja online zostanie dodana jako osobna warstwa pozniej.
- Kazda encja dostaje pola potrzebne do sync: `revision`, `syncState`, `remoteId`, `deletedAt`.
- Statusy sync w modelu Flutter: `localOnly`, `pendingSync`, `synced`, `syncError`, `conflict`.

Uzasadnienie:

- Docelowe platformy obejmuja Android i Windows, gdzie praca bez sieci jest realnym scenariuszem produkcyjnym.
- Pozniejszy sync bez pól metadanych wymusilby bolesna migracje.

## ADR-003: Project zamiast Calculation

Status: proposed

Decyzja:

- W domenie Fluttera uzywac nazwy `Project`.
- Jesli import legacy zostanie kiedys dodany, mapowanie `Calculation -> Project` bedzie czescia osobnego modulu importu.

Uzasadnienie:

- Obecna `Calculation` jest w praktyce projektem technicznym, zawiera zasilanie, kratownice, klienta, lokacje i docelowo fazy.
- Brak wymogu kompatybilnosci pozwala od razu nazwac model zgodnie z domena.

## ADR-003A: Legacy jako zrodlo wymagan, nie kontrakt

Status: proposed

Decyzja:

- Legacy StageCalc sluzy do zrozumienia funkcji, obliczen i problemow uzytkownika.
- Nowy Flutter nie musi wspierac starych formatow danych, starych nazw pol, starych tras ani importu PocketBase w MVP.
- Kazde wymaganie kompatybilnosci legacy musi byc dodane jako osobna decyzja i osobny zakres prac.

Uzasadnienie:

- Uzytkownik wskazal, ze na tym etapie kompatybilnosc z wersjami legacy nie jest wymagana.
- Pozwala to uproscic model offline-first i uniknac przenoszenia dlugu technicznego.

## ADR-004: Fazy projektu jako model, nie funkcja MVP

Status: proposed

Decyzja:

- Dodac `ProjectPhase` i `phaseId` do bytow projektowych.
- W MVP automatycznie tworzyc jedna faze domyslna.
- Nie implementowac jeszcze UI ani logiki workflow faz.

Uzasadnienie:

- Uzytkownik wymaga miejsca na pozniejsze fazy.
- Wczesne dodanie `phaseId` jest tanie, pozniejsze dodanie byloby migracja przekrojowa przez caly model.

## ADR-005: Runtime Distro jako osobny byt

Status: proposed

Decyzja:

- Rozdzielic:
  - urzadzenie katalogowe rozdzielnicy,
  - preset gniazd,
  - konkretna instancje rozdzielnicy w projekcie.
- Wprowadzic `ProjectDistro` i `ProjectOutlet`.

Uzasadnienie:

- Obecne `sourceDeviceId` czasem oznacza ID rozdzielnicy w projekcie, a czasem sugeruje urzadzenie katalogowe.
- Precyzyjne nazewnictwo zmniejszy ryzyko bledow w obliczeniach i synchronizacji.

## ADR-006: Polaczenia jako dane domenowe

Status: proposed

Decyzja:

- `PowerConnection` ma byc pelnoprawna encja lokalnej bazy.
- Nie zapisywac polaczen jako ukryty stan UI.
- Nie kasowac wszystkich polaczen przy kazdym zapisie projektu.

Uzasadnienie:

- Polaczenia sa kluczowe dla obliczen fazowych.
- Offline-first wymaga inkrementalnych zmian, historii rewizji i mozliwosci sync.

## ADR-007: Zachowac Model B+, zostawic droge do Modelu C

Status: proposed

Decyzja:

- Pierwsza wersja Flutter zachowuje obecny kompromis:
  - grupa `singlePhase`,
  - grupa `threePhaseSymmetric`,
  - `selectedPhases` dla gniazd `All`.
- W `PowerConnection` zostawic opcjonalne `targetItemIds` na pozniejsze mapowanie konkretnych pozycji.

Uzasadnienie:

- Model B+ jest juz czesciowo obecny i rozwiazuje duza czesc problemow fazowych.
- Pelny Model C jest lepszy technicznie, ale moze spowolnic workflow i znacznie powiekszyc MVP.

## ADR-008: Snapshot danych katalogowych w projekcie

Status: proposed

Decyzja:

- `ProjectItem` zapisuje snapshot nazwy, producenta, kategorii, mocy, pradu i masy.
- `catalogDeviceId` pozostaje jako link do aktualnego katalogu.

Uzasadnienie:

- Historyczna kalkulacja nie powinna zmieniac wynikow tylko dlatego, ze poprawiono katalog.
- Uzytkownik moze pozniej recznie odswiezyc snapshoty, jesli tego chce.

## ADR-009: Jedna tabela katalogu z danymi kategorii

Status: proposed

Decyzja:

- W lokalnym modelu preferowac jedna tabele `DeviceCatalogItem`.
- Specyficzne pola kategorii trzymac w strukturze `categoryData` lub powiazanych tabelach dla najbardziej relacyjnych danych, np. tabele nosnosci kratownic.

Uzasadnienie:

- Obecny podzial na kolekcje kategorii utrudnia wyszukiwanie, import i wspolny katalog w UI.
- Flutter/Dart zyska prostszy model list i filtrow.

## ADR-010: Warstwa obliczen jako czysty Dart

Status: proposed

Decyzja:

- Obliczenia zasilania i kratownic zaimplementowac jako czyste serwisy domenowe bez zaleznosci od Flutter UI i bazy.

Uzasadnienie:

- Latwe testy jednostkowe.
- Mniejsze ryzyko regresji przy przebudowie UI.
- Mozliwosc uzycia tej samej logiki w eksporcie, walidacji i widokach.

## ADR-011: Lokalna baza i kompatybilnosc platform

Status: accepted

Decyzja:

- Docelowa lokalna baza StageCalc: Drift + SQLite.
- Drift/SQLite bedzie glowna implementacja offline-first dla:
  - Android,
  - Windows,
  - iOS, jesli zostanie dodany,
  - macOS/Linux, jesli kiedys beda potrzebne.
- Web pozostaje platforma warunkowa:
  - preferowac adapter Drift web, jesli ograniczenia beda akceptowalne,
  - w razie problemow przygotowac osobna implementacje repozytoriow na IndexedDB.
- `shared_preferences` pozostaje tylko warstwa przejsciowa/prototypowa dla obecnego etapu.
- Nie wybierac Hive jako glownej bazy domenowej, poniewaz model StageCalc jest relacyjny.
- Nie wybierac ObjectBox/Isar jako glownej bazy na tym etapie, poniewaz synchronizacja z przyszla hostowana baza bedzie prostsza przy jawnych tabelach, migracjach SQL i relacjach.

Uzasadnienie:

- Android i Windows sa najwazniejsze.
- StageCalc bedzie mial duzo relacji:
  - projekty,
  - fazy,
  - grupy,
  - pozycje,
  - katalog,
  - klienci,
  - lokacje,
  - rozdzielnice,
  - gniazda,
  - polaczenia,
  - kratownice,
  - rekordy sync.
- Przyszla hostowana baza danych bedzie wymagala:
  - stabilnych ID,
  - rewizji rekordow,
  - soft delete,
  - kolejek synchronizacji,
  - zapytan po `updatedAt`, `syncState`, `workspaceId`, `remoteId`,
  - transakcji przy zapisie projektu i polaczen.
- Drift daje:
  - jawny schemat,
  - migracje,
  - transakcje,
  - typowane zapytania,
  - testowalna warstwe data,
  - dobry model pod offline-first i pozniejszy sync.
- Web/iOS sa mozliwe, ale nie powinny blokowac poprawnego modelu offline-first dla Android/Windows.

Konsekwencje:

- Kolejny etap implementacji powinien przeniesc projekty i katalog ze `shared_preferences` do Drift.
- Repozytoria domenowe zostaja za interfejsami, zeby UI nie zalezal bezposrednio od Drift.
- Schemat bazy musi od poczatku zawierac pola synchronizacyjne:
  - `id`,
  - `workspaceId`,
  - `remoteId`,
  - `createdAt`,
  - `updatedAt`,
  - `deletedAt`,
  - `revision`,
  - `syncState`,
  - `lastSyncedAt`.
- Synchronizacja z hostowana baza bedzie osobna warstwa nad lokalna baza, a nie zamiennik lokalnej bazy.

## ADR-012: Import legacy poza MVP

Status: proposed

Decyzja:

- Nie przygotowywac importera JSON/PocketBase jako wymagania MVP.
- Zachowac mozliwosc dodania importera pozniej, jesli pojawi sie realna potrzeba przeniesienia danych.
- Nie uzalezniac Fluttera od PocketBase jako glownego runtime backendu.

Uzasadnienie:

- Aktualny StageCalc jest zrodlem wymagan, ale nowa aplikacja ma byc czystsza.
- Sync moze pozniej uzyc PocketBase, Supabase, wlasnego API lub innego mechanizmu.
- Brak kompatybilnosci legacy zmniejsza ryzyko i zakres pierwszej wersji.

## ADR-012A: GreenCrew Branding jako wymaganie produktu

Status: proposed

Decyzja:

- StageCalc Flutter musi byc zgodny z dokumentami GreenCrew Tools:
  - `GREENCREW_BRANDING.md`,
  - `DESIGN_SYSTEM.md`,
  - `ICONOGRAPHY.md`,
  - `WRITING_GUIDELINES.md`,
  - `BRANDING_STAGECALC.md`,
  - `FLUTTER_STANDARDS.md`.
- Domyslny wyglad:
  - dark mode,
  - czarne tlo,
  - neutralne powierzchnie,
  - GreenCrew Green jako glowny akcent,
  - Material Design,
  - Material Icons/Symbols.
- Ikona aplikacji: heksagon GreenCrew z geometryczna blyskawica.
- Komunikaty w aplikacji: krotkie, techniczne, po polsku.

Uzasadnienie:

- StageCalc ma byc czescia rodziny GreenCrew Tools, a nie samodzielna aplikacja o przypadkowym stylu.
- Branding definiuje praktyczny, terenowy charakter produktu i powinien kierowac projektowaniem UI od pierwszego ekranu.

## ADR-012B: Telefon-first i responsywnosc

Status: proposed

Decyzja:

- Platforma referencyjna dla UI to Android/telefon.
- Tablet powinien uzywac ukladow dwukolumnowych lub Navigation Rail.
- Windows/Web powinny uzywac sidebar/master-detail i tabel tylko tam, gdzie pomagaja.
- Progi robocze:
  - telefon: do 600 px,
  - tablet: 600-1024 px,
  - desktop: powyzej 1024 px.

Uzasadnienie:

- GreenCrew Tools sa projektowane do pracy w terenie, czesto na malym ekranie i pod presja czasu.
- Ekran, ktory dziala dobrze na telefonie, latwiej rozszerzyc na desktop niz odwrotnie.

## ADR-012C: Logowanie nie blokuje pracy lokalnej

Status: proposed

Decyzja:

- MVP StageCalc nie wymaga logowania do podstawowej pracy.
- Konto/synchronizacja moze pojawic sie pozniej jako warstwa dodatkowa.
- Dane lokalne musza pozostac dostepne bez serwera.

Uzasadnienie:

- GreenCrew Architecture mowi, ze aplikacja offline nie powinna byc bezuzyteczna bez logowania.
- StageCalc ma dzialac podczas wydarzen i konsultacji technicznych, takze bez Internetu.

## ADR-012D: Backup i eksport danych

Status: proposed

Decyzja:

- Aplikacja powinna miec backup danych w nowym formacie, niezaleznym od legacy.
- Preferowany backup: JSON lub ZIP z JSON i zalacznikami.
- Backup jest oddzielony od raportow technicznych PDF/CSV/XLSX.

Uzasadnienie:

- Dane projektowe sa wazne i nie moga istniec wylacznie jako ukryta baza lokalna.
- Backup jest podstawowym zabezpieczeniem przed utrata danych przed wdrozeniem sync.

## ADR-012E: Uprawnienia systemowe minimalne

Status: proposed

Decyzja:

- Aplikacja prosi tylko o uprawnienia potrzebne do konkretnej funkcji.
- Dostep do plikow jest potrzebny dopiero przy imporcie/eksporcie/backupie.
- Brak dostepu do lokalizacji, zdjec lub kontaktow w MVP, chyba ze funkcja zostanie jawnie dodana.

Uzasadnienie:

- Narzedzie terenowe powinno byc przewidywalne i nie prosic o niepotrzebne uprawnienia.

## ADR-012F: Nazewnictwo release

Status: proposed

Decyzja:

- Artefakty release nazywac wedlug wzoru `StageCalc-vX_Y_Z-platform.ext`.
- Przyklad: `StageCalc-v1_0_0-android.apk`, `StageCalc-v1_0_0-windows.zip`.

Uzasadnienie:

- Standard GreenCrew wymaga spójnych nazw artefaktow.

## ADR-013: Tekst rich-text

Status: proposed

Decyzja:

- Notatki przechowywac jako Markdown albo sanitizowany HTML z jasna decyzja przed implementacja.
- Dla MVP preferowany Markdown.

Uzasadnienie:

- Obecna aplikacja uzywa edytora rich text i HTML. Flutter latwiej utrzyma bezpiecznie w Markdown.
- Ewentualny przyszly import legacy moze konwertowac HTML do tekstu/Markdown albo zachowac HTML jako wartosc techniczna importu.

## ADR-014: PDF jako eksport warstwy aplikacyjnej

Status: proposed

Decyzja:

- Eksport PDF nie powinien mieszkac w widokach.
- Zbudowac serwis `ProjectReportService`, ktory pobiera wynik obliczen i generuje raport.

Uzasadnienie:

- Obecnie PDF jest czescia duzego komponentu kalkulatora.
- W Flutterze raport powinien uzywac tych samych serwisow domenowych co UI.

## ADR-032: Wiele typow zlacz w jednej grupie zlaczy lokacji

Status: accepted

Kontekst:

- `LocationPowerConnector` ("grupa zlaczy" na ekranie Lokacje, np. "Rozdzielnia sceny") mial dokladnie jeden `connectorTypeId` i jedna `quantity` na grupe - realna rozdzielnia sceniczna prawie zawsze oferuje kilka roznych typow zlacz naraz (np. 2x CEE 32A 5P + 4x Schuko), wiec taka grupa musiala byc sztucznie rozbita na kilka osobnych grup o tej samej nazwie, albo po prostu nie oddawala realnego wyposazenia.
- Uzytkownik: "jak już mamy 'grupa złączy' to dobrze żeby w tej grupie dało się dodać różne rodzaje złącz."

Decyzja:

- `LocationPowerConnector` traci pola `connectorTypeId`/`quantity`, zyskuje `entries: List<LocationConnectorEntry>` - kazdy wpis to wlasny `connectorTypeId` + `quantity`. `availablePowerKw` sumuje wszystkie wpisy; nowy getter `entriesSummary` buduje czytelny opis typu "2x 32 A CEE 5P + 4x 16 A Uni-Schuko" (uzywany wszedzie tam, gdzie grupa jest wyswietlana - karta lokacji, szczegoly, dialog edycji, dialog tworzenia rozdzielnicy z lokacji w projekcie), zeby ten format nie byl duplikowany w kazdym miejscu z osobna.
- **Lokalny magazyn (Drift)**: nowa kolumna `LocationPowerConnectors.entriesJson` (JSON-encoded array `{connectorTypeId, quantity}`, domyslnie `'[]'`) - dokladnie ten sam wzorzec co `CatalogDevices.connectorTypeIdsJson` z ADR-030/031. Stare kolumny `connectorTypeId`/`quantity` **zostaja fizycznie w schemacie bez zmiany nullability** (wciaz `NOT NULL`) - aplikacja nadal je zapisuje (pierwszy wpis z `entries`), tylko wylacznie po to, zeby ten wciaz-`NOT NULL` warunek pozostal spelniony; odczyt idzie zawsze przez `entriesJson`. Swiadomie NIE zmieniono `connectorTypeId` na `nullable()` (mimo ze `CatalogDevices.connectorTypeId` tak zrobiono w ADR-030) - nullability zadeklarowana w kodzie Dart dotyczy tylko `onCreate` na *nowej* bazie, a fizyczny `NOT NULL` istniejacych, migrowanych baz uzytkownikow zostaje niezmieniony (SQLite nie potrafi zdjac ograniczenia kolumny przez zwykly `ALTER TABLE ADD COLUMN`), wiec poleganie na tym dla nowych insertow byloby niespojne miedzy swieza instalacja a zaktualizowana - a to dokladnie ten rodzaj cichej niespojnosci, ktory juz raz kosztowal falszywie pozytywny test w v0.3.3.
  - Migracja `from < 16`: dodaje `entriesJson`, potem dla kazdego istniejacego wiersza przepisuje jego stary pojedynczy `connectorTypeId`+`quantity` jako jednoelementowa tablice JSON - bez tego kroku kazda grupa zapisana przed ta zmiana wygladalaby po aktualizacji na pusta.
- **Zdalny magazyn (PocketBase)**: zero migracji schematu - ponownie uzyto wymaganego pola tekstowego `connector_type_id` do przenoszenia calego JSON-a `entries` (identyczny trik co `pocketbase_catalog_sync_service.dart` z ADR-030/031 dla `connectorTypeIdsJson`). Odczyt (`decodeStoredList`) probuje `jsonDecode`; jesli to sie nie uda (stary zdalny rekord z pojedynczym connector-type-id jako czystym tekstem, zsynchronizowany przed ta zmiana), traktuje cala wartosc jako jednoelementowa liste, biorac `quantity` z osobnego zdalnego pola jako `legacyQuantity`.
- **`distro_create_dialog.dart`** (tworzenie rozdzielnicy w projekcie z grupy zlaczy lokacji): `_locationOutlets` iteruje teraz po kazdym `entry` w grupie i generuje gniazda dla kazdego typu osobno (zamiast zakladac jeden typ na cala grupe) - to jedyne miejsce poza samym ekranem Lokacje, ktore faktycznie konsumowalo pojedynczy `connectorTypeId`/`quantity`, wiec bez tej zmiany wybranie grupy z wieloma typami po cichu zgubiloby wszystkie typy poza pierwszym.
- **UI dialogu grupy** (`_PowerConnectorDialog`): zamiast jednego dropdownu + pola ilosci, lista wierszy (typ zlacza + ilosc + usun), kazdy z wlasnym `TextEditingController`, plus przycisk "Dodaj typ zlacza"; usuniecie ostatniego pozostalego wiersza jest zablokowane (grupa musi miec co najmniej jeden typ).

Uzasadnienie:

- Ponowne uzycie istniejacego wymaganego pola tekstowego zamiast dodawania nowego pola w PocketBase to ten sam kompromis co w ADR-030/031 - unika kolejnej reczej migracji `pb_migrations` dla czegos, co i tak jest zwyklym tekstem z punktu widzenia bazy.
- Zachowanie fizycznej `NOT NULL` starych kolumn (zamiast probowac je poluzowac) jest bezposrednia lekcja z DriftRemoteException/`SqliteException` z v0.3.3-v0.3.4: zmiana nullability w kodzie Dart nie gwarantuje tego samego zachowania na juz-zmigrowanej bazie uzytkownika, wiec bezpieczniej jest po prostu zawsze cos zapisac niz polegac na zgodnosci schematu, ktorej nie da sie w pelni zweryfikowac bez fizycznego dostepu do kazdej wersji bazy w terenie.

Konsekwencje:

- Kazda grupa zlaczy zapisana przed ta zmiana (lokalnie lub zdalnie) zostaje przy nastepnym odczycie/synchronizacji automatycznie przepisana na jednoelementowa liste `entries` - bez utraty danych i bez akcji uzytkownika.

## ADR-031: Kategorie i pola zalezne od kategorii w katalogu urzadzen

Status: accepted

Kontekst:

- Uzytkownik zglosil trzy problemy z formularzem "Dodaj urzadzenie" po realnym uzyciu: (1) kategoria "Rigging" pokazywala pola nieadekwatne do rzeczywistego sprzetu riggingowego - typy zlacz, Moc/Prad, punkty zaczepienia; (2) jedna ogolna kategoria "Urzadzenie" byla za uboga do filtrowania - potrzeba przynajmniej podzialu na oswietlenie/naglosnienie/multimedia; (3) kategoria "Kabel" pokazywala Moc/Prad (kable nie pobieraja mocy) i Producenta (kable nie sa sensownie przypisywane do producenta). Po pierwszym wdrozeniu i zywej weryfikacji na Windows uzytkownik doprecyzowal, ze punkty zaczepienia sa zbedne rowniez dla kabla (kabel, tak jak sprzet riggingowy, nie jest tym, co wpina sie w hak).
- `docs/FEATURE_SCOPE.md` od poczatku projektu wymienial dokladnie taki podzial ("oswietlenie, dzwiek, multimedia, okablowanie i dystrybucja, rigging, inne") - uproszczenie do jednej ogolnej kategorii `device` bylo wczesniejsza decyzja implementacyjna, nie celowym odejsciem od tej specyfikacji.

Decyzja:

- `CatalogDeviceCategory` rozszerzony z `{device, distribution, cable, rigging, other}` na `{lighting, sound, multimedia, distribution, cable, rigging, other}` - `device` usuniete, zastapione trzema bardziej szczegolowymi kategoriami. Domyslna kategoria nowego urzadzenia to `lighting` (najczesciej dodawany typ sprzetu).
- **Wsteczna kompatybilnosc bez migracji schematu**: `category` jest w Drift/PocketBase zwyklym polem tekstowym (nie enumem SQL), wiec usuniecie `device` z enuma Dart nie wymaga zadnej migracji - `CatalogDeviceCategoryJson.fromJson` po prostu mapuje nierozpoznany tekst (w tym stare `device`) na `other` zamiast na usuniety wariant. Istniejace urzadzenia z `category: "device"` nadal sie wczytuja, po prostu jako "Inne", do reczne przekategoryzowania.
- **Pola formularza zalezne od kategorii** (`_CatalogDeviceDialogState`, nowe gettery `_showElectrical`/`_showConnectors`/`_showRiggingPoints`/`_showManufacturer`):
  - `rigging`: ukryte Moc/Prad, typy zlacz, punkty zaczepienia. Widoczne: nazwa, producent, masa, jednostka, tabela nosnosci (juz wczesniej warunkowa tylko dla rigging).
  - `cable`: ukryte Moc/Prad, producent, punkty zaczepienia. Widoczne: nazwa, masa, typy zlacz, jednostka.
  - Pozostale kategorie: pelny zestaw pol, bez zmian.
  - `_submit()` **jawnie zeruje/czysci ukryte pola** (nie tylko chowa je wizualnie) - jesli ktos wpisal Moc przed przelaczeniem na "Rigging", zapisana wartosc to `0`, nie zapamietana-ale-niewidoczna liczba z kontrolera tekstowego. Zapobiega to cichemu zapisaniu nieaktualnych danych.
- **Filtr kategorii na ekranie Katalog** (nie tylko w istniejacym filtrze wewnatrz dialogu wyboru z katalogu przy dodawaniu do projektu): rzad `ChoiceChip` ("Wszystkie" + kazda kategoria) nad lista urzadzen, filtrujacy `_filteredDevices` razem z wyszukiwaniem tekstowym.
- Dane demo (`DemoCatalogFactory`) zaktualizowane: BMFL Spot i LED Par RGBW (byly `device`) -> `lighting`.

Uzasadnienie:

- Pole tekstowe (nie enum) w warstwie przechowywania to dokladnie ten sam wzorzec co ADR-030 (`connectorTypeIdsJson`) - kolejny dowod, ze ta konwencja (elastycznosc kategorii/wartosci enum bez migracji schematu) sie sprawdza przy realnych zmianach wymagan.
- Ukrywanie pol per kategoria (zamiast np. osobnych formularzy per kategoria) jest najmniejsza zmiana rozwiazujaca zgloszony problem - te same kontrolery/stan, tylko warunkowe budowanie widgetow, spojne z istniejacym juz wzorcem warunkowej tabeli nosnosci dla rigging.
- Jawne zerowanie ukrytych pol w `_submit()` (a nie tylko ukrywanie w UI) jest wazne dla poprawnosci danych - `TextEditingController` nie czysci sie sam przy zmianie kategorii, wiec bez tego uzytkownik mogilby przypadkiem zapisac np. Moc dla kabla, ktorej nigdy nie widzial na ekranie w momencie zapisu.

Konsekwencje:

- Istniejace urzadzenia z `category: "device"` (w tym ewentualne realne dane uzytkownika sprzed tej decyzji) staja sie "Inne" do czasu recznego przypisania nowej, bardziej szczegolowej kategorii - jednorazowy koszt, analogiczny do tych juz zaakceptowanych w ADR-028/ADR-030.
- Podzial na `lighting`/`sound`/`multimedia` jest na razie plaski (bez podkategorii) - zgodnie z tym, o co uzytkownik poprosil ("chociaz na ten moment"), z mozliwoscia dalszego uszczegoławiania w przyszlosci, jesli okaze sie potrzebne.

## ADR-030: Wielokrotny wybor typow zlacz w katalogu urzadzen

Status: accepted

Kontekst:

- Pole `CatalogDevice.connectorTypeId` bylo od poczatku wolnym tekstem (`TextField` w formularzu katalogu, `String?` w schemacie) - `docs/CATALOG_IMPORT_GUIDE.md` (przygotowany na potrzeby generowania wsadu katalogu przez GPT) wprost to udokumentowal, wraz z ostrzezeniem, ze to inne pojecie niz zamkniety slownik `ConnectorTypes` (Schuko/CEE/Powerlock) uzywany dla gniazd rozdzielnic w projekcie.
- Uzytkownik okreslil to jako blad i poprosil o zamiane na liste wielokrotnego wyboru. Zapytany, czy urzadzenie ma miec dokladnie jedno zlacze z listy, czy moze ich miec wiecej naraz jednoczesnie, wybral **prawdziwy multi-select** - jedno urzadzenie moze miec zaznaczonych kilka typow zlacz rownoczesnie (np. fixture z wejsciem `powerCON` i osobnym wejsciem DMX `XLR 5-pin`).

Decyzja:

- Nowy enum `CatalogConnectorType` (`features/catalog/domain/entities/catalog_device.dart`) - 23 wartosci obejmujace zarowno zlacza zasilania (Schuko, CEE 16/32/63/125A, Powerlock 200/400A, powerCON/TRUE1/TRUE1 TOP) jak i sygnalowe (XLR3/5, SpeakON NL4/NL8, EtherCON, BNC, Jack 6.3mm, RCA, HDMI, SDI, USB) plus `other` - szerszy niz `ConnectorTypes` (uzywany tylko dla gniazd rozdzielnic), bo katalog obejmuje oswietlenie/dzwiek/multimedia/okablowanie/rigging, nie tylko zasilanie.
- `CatalogDevice.connectorTypeId` (`String?`) zastapione przez `connectorTypeIds` (`List<CatalogConnectorType>`, domyslnie puste) - w formularzu katalogu (`catalog_screen.dart`) wolne pole tekstowe zastapiono siatka `FilterChip` (ten sam wzorzec co selektor faz w dialogu polaczenia) z etykieta kazdej wartosci enuma.
- **Nic nigdy nie jest zgadywane przy odczycie**: `CatalogConnectorTypeJson.fromJson` probuje dokladnego dopasowania do nazwy enuma, potem znormalizowanego (male litery, tylko litery/cyfry) dopasowania do tabeli aliasow pokrywajacej stare dane demo (`powercon_true1`, `powercon`, `cee_32a_5p`) i typowe warianty zapisu (`RJ45`->`etherCon`, `DMX`->`xlr5`, `cinch`->`rca` itd.) - wartosc, ktora niczego nie dopasuje, jest **po cichu pomijana**, nigdy zgadywana na sile. Ta sama funkcja obsluguje: odczyt starego pojedynczego pola `connectorTypeId` z backupu sprzed tej decyzji, odczyt kolumny Drift/PocketBase (patrz nizej) i walidacje wsadu z `docs/CATALOG_IMPORT_GUIDE.md`.
- Schemat lokalny: nowa kolumna `CatalogDevices.connectorTypeIdsJson` (TEXT, JSON-owa tablica id-kow enuma, dokladnie ten sam wzorzec co `PowerConnections.selectedPhasesJson` z ADR-026) - podniesiono schemat bazy do wersji `15`. Stara kolumna `connectorTypeId` **zostaje w schemacie, ale nie jest juz nigdzie zapisywana** - migracja `if (from < 15)` dodaje nowa kolumne i dla kazdego istniejacego wiersza z niepustym starym polem zapisuje je jako jednoelementowa tablice JSON w nowej kolumnie (bez proby walidacji na tym poziomie - schemat lokalny celowo nie zna domeny/enumow, zgodnie z jego dotychczasowa architektura); to `CatalogConnectorTypeJson.decodeStoredList` (warstwa repozytorium) dopiero interpretuje ten surowy tekst na liste enumow, odrzucajac to, czego nie rozpozna.
- PocketBase: **zero zmian schematu**. `catalog_devices.connector_type_id` byl juz zwyklym polem `text` (bez ograniczen), wiec dalej przechowuje ten sam tekst co lokalna kolumna `connectorTypeIdsJson` (teraz tablica JSON zamiast pojedynczej wartosci) - push/pull w `PocketBaseCatalogSyncService` po prostu przekazuja ten string 1:1 miedzy lokalna kolumna a zdalnym polem, bez zadnej interpretacji enumow po stronie synchronizacji.
- `docs/CATALOG_IMPORT_GUIDE.md` zaktualizowany: `connectorTypeId` (string) -> `connectorTypeIds` (tablica), z pelna tabela 23 dozwolonych wartosci i jawnym ostrzezeniem, ze nierozpoznana wartosc zostanie po cichu odrzucona przy imporcie.

Uzasadnienie:

- Multi-select (a nie jeden wybor z listy) odzwierciedla realny sprzet: wiele urzadzen ma jednoczesnie zlacze zasilania i osobne zlacze sygnalowe/danych, i uzytkownik jawnie potwierdzil, ze o to chodzi.
- Zachowanie surowego tekstu w kolumnie Drift/PocketBase (zamiast np. osobnej tabeli relacyjnej) unika jakiejkolwiek migracji schematu po stronie PocketBase - dokladnie ten sam kompromis co `selectedPhasesJson` w ADR-026, teraz konsekwentnie zastosowany drugi raz.
- Rozdzielenie "surowy tekst w warstwie Drift" od "interpretacja na enum w warstwie repozytorium" (zamiast probowac zwalidowac/zaimportowac enum juz w pliku migracji) utrzymuje `app_database.dart` wolny od zaleznosci domenowych - zgodnie z juz istniejaca, celowa architektura tego pliku (zaden inny plik w `infrastructure/local_database` nie importuje enumow z `features/`).
- "Po cichu odrzuc niepasujaca wartosc" (zamiast rzucic wyjatek albo zgadywac najblizsza) jest spojne z tym, jak `CatalogDeviceCategoryJson.fromJson`/`CatalogQuantityUnitJson.fromJson` juz dzialaja w tym samym pliku (fallback na wartosc domyslna) - ale tutaj "domyslna wartosc" dla listy to po prostu pominiecie elementu, nie zgadywanie jednego z 23 zlacz.

Konsekwencje:

- Urzadzenia z (jakimkolwiek) wolnym tekstem w starym polu `connectorTypeId`, ktory nie pasuje do zadnego z 23 nowych id ani ich aliasow, **traca to zlacze po migracji** (staja sie widoczne jako urzadzenie bez zaznaczonych zlacz) - jednorazowy koszt uporzadkowania nieograniczonego pola. Surowy tekst nie ginie calkowicie: stara kolumna `connectorTypeId` zostaje w bazie nietkniete, wiec teoretycznie odzyskiwalny recznie (SQL), ale appka go juz nigdzie nie pokazuje ani nie czyta.
- Zamkniete 23 wartosci moga z czasem okazac sie niewystarczajace dla rzadszego sprzetu (np. Speakon NL2, XLR4) - dodanie kolejnej wartosci enuma jest jednak tania, addytywna zmiana (nowy element `CatalogConnectorType`, nowa etykieta, opcjonalnie nowy alias), nie wymaga kolejnej migracji schematu.
- Pole nadal nie jest uzywane w zadnych obliczeniach mocy/faz/obciazenia - to czysto informacyjna/inwentarzowa etykieta, jak przed ta decyzja.

## ADR-029: Wizualny uklad patchera (kafelki gniazd)

Status: accepted

Kontekst:

- `docs/FEATURE_SCOPE.md` od poczatku definiowal "Wizualny patcher": pokazuje gniazda rozdzielnicy, laczy gniazdo z grupa lub inna rozdzielnica, wybiera fazy dla grup 1F podlaczanych do gniazda "All", wykrywa zajetosc faz, pozwala dodawac notatki do polaczen. Etap 6 (`docs/MIGRATION_PLAN.md`) dostarczyl "funkcjonalny odpowiednik" tej specyfikacji (mozna laczyc, widac obciazenia, ostrzezenia), ale bez wizualnej, klikalnej reprezentacji gniazd - byly to czysto informacyjne pigulki (`Chip`), a jedynym sposobem laczenia byl osobny przycisk "Polacz" otwierajacy zbiorowy dialog (wybierz cel, potem gniazda). Notatki do polaczen (`PowerConnection.notes`, juz w schemacie od ADR-017) nigdy nie mialy zadnego UI do wpisania czy odczytania.
- Backlog (`docs/IMPLEMENTATION_STATUS.md`, "Nastepny krok") mial to jako pozycje nr 1: "Przygotowac bardziej wizualny uklad patchera".
- Uzytkownik potwierdzil kierunek: gniazda staja sie wieksza, klikalna siatka kafelkow, a dotychczasowy zbiorowy dialog "Polacz" i lista "Polaczenia" zostaja bez zmian jako opcja do podlaczenia jednej grupy do wielu gniazd naraz.

Decyzja:

- `_OutletTile` (`presentation/project_editor/distro_widgets.dart`) zastepuje dawny `_OutletLoadChip`: kafelek ok. 140px szerokosci pokazujacy etykiete fazy, kropki zajetosci L1/L2/L3 dla gniazd fazy "All" (wyliczane z `PowerConnection.selectedPhases`, a dla polaczen z rozdzielnica podrzedna - jako zajmujace wszystkie trzy fazy), ikone stanu (plus/blyskawica/ostrzezenie/rozlaczony-duplikat), nazwe podlaczonego celu (lub "Wolne"), nazwe gniazda i odczyt A/max A. Kolor tla/obwodki reuzywaja tej samej hierarchii stanow co poprzednio (bezpieczny/ostrzezenie/blad/zajete), tylko na wiekszym, klikalnym `InkWell`.
- Dotkniecie pustego gniazda otwiera nowy `_QuickConnectDialog` (`connection_widgets.dart`) - lzejszy odpowiednik `_ConnectionDialog` z JUZ USTALONYM zrodlem (ta rozdzielnica/to gniazdo): trzeba wybrac tylko cel (grupa albo pasujaca rozdzielnica podrzedna, filtrowana po zgodnosci `inputConnectorTypeId`), opcjonalnie fazy dla gniazd "All" (pomijajac fazy juz zajete) i notatke poczatkowa.
- Dotkniecie juz podlaczonego gniazda otwiera `_OutletDetailsDialog`: lista wszystkich polaczen na tym gniezdzie (zwykle jedno, wiecej dla wspoldzielonego gniazda "All"), kazde z nazwa celu, fazami, edytowalnym polem notatek (przycisk zapisu przy kazdym) i przyciskiem "Rozlacz". Gdy gniazdo nie jest jeszcze pelne (wolna faza na "All"), dodatkowy przycisk "Dodaj kolejne" otwiera `_QuickConnectDialog` z juz zajetymi fazami wykluczonymi z wyboru.
- `PowerConnection.notes` dostaje wreszcie UI do zapisu i odczytu (nowa metoda `ProjectEditorController.editConnectionNotes`) - wypelnia luke z oryginalnej specyfikacji "Wizualny patcher", ktora nigdy wczesniej nie miala zadnego pola notatek w interfejsie.
- Istniejacy przycisk "Polacz" + `_ConnectionDialog` (zbiorowe podlaczenie jednej grupy do wielu wolnych gniazd naraz, z przelacznikiem "Pokaz uzyte zlacza") oraz lista "Polaczenia" ponizej pozostaja bez zmian - dwie sciezki do tego samego efektu koincydujace w jednym ekranie: kafelki gniazd do szybkiego, pojedynczego podlaczenia/podgladu, zbiorowy dialog do hurtowego przypisania.

Uzasadnienie:

- Zachowanie zbiorowego dialogu bez zmian (zamiast probowac przerobic go pod jeden ustalony outlet) unika ryzykownej zmiany w juz dzialajacym, przetestowanym kodzie i utrzymuje jego unikalna, wygodna funkcje (jedna grupa -> wiele gniazd jednym kliknieciem), ktorej model "kliknij gniazdo" nie odtwarza naturalnie.
- Osobny `_QuickConnectDialog` zamiast parametryzowania `_ConnectionDialog` dodatkowym "ustalonym zrodlem" jest prostszy: `_ConnectionDialog` filtruje gniazda po celu, `_QuickConnectDialog` filtruje cele po (ustalonym) gniezdzie - odwrotny kierunek dopasowania, ktory jako jeden dialog z trybami bylby trudniejszy do zrozumienia niz dwa male, jednoznaczne dialogi.
- Model "tap pusty = polacz, tap zajety = szczegoly" (zamiast jednego trybu z przelacznikiem) odzwierciedla naturalne oczekiwanie uzytkownika patrzacego na diagram patch bay - kafelek juz pokazuje, czy jest zajety, wiec dotkniecie go powinno pokazac to, co juz jest podlaczone, a nie od razu proponowac nadpisanie.

Konsekwencje:

- To nadal siatka kafelkow, nie prawdziwy diagram z liniami laczacymi gniazdo z grupa/rozdzielnica (jak np. edytor patch bay z liniami polaczen) - `docs/FEATURE_SCOPE.md` tego nie wymagal wprost, a rysowanie polaczen na canvasie miedzy odleglymi kartami rozdzielnic byloby duzo wiekszym, osobnym projektem UI.
- `PatchValidationService.isOutletDuplicated` nadal traktuje kazde gniazdo z wiecej niz jednym polaczeniem jednolicie jako ostrzezenie "uzyte wiele razy", niezaleznie od tego, czy to legalne wspoldzielenie faz gniazda "All", czy przypadkowy duplikat - `_OutletDetailsDialog` pokazuje wszystkie polaczenia niezaleznie od tego ostrzezenia, wiec uzytkownik i tak widzi pelny obraz, ale sama etykieta ostrzezenia nie rozroznia tych dwoch przypadkow (ten sam, juz istniejacy uproszczony model sprzed tej decyzji).
- Nowy test widgetowy (`test/widget_test.dart`, "tapping an outlet tile connects and disconnects it") pokrywa pelny cykl: pusty kafelek -> quick connect z notatka -> szczegoly pokazujace notatke -> rozlaczenie -> pusty kafelek ponownie.

## ADR-028: Prawdziwa autoryzacja PocketBase (konta osobiste, wlasciciel danych)

Status: accepted

Kontekst:

- ADR-017 zostawila reguly dostepu wszystkich kolekcji PocketBase puste (publiczne) jako swiadome, tymczasowe ryzyko, akceptowalne tylko w prywatnej sieci LAN - "do czasu zaprojektowania prawdziwego modelu autoryzacji". ADR-026 dodala pelny dwukierunkowy sync dla piedu agregatow, ale nie zmienila regul dostepu - kazdy z dostepem do serwera nadal mogl czytac/edytowac/usuwac dowolny rekord bez logowania.
- Uzytkownik potwierdzil, ze czas to zaadresowac, i wspolnie ustalono model: **konta osobne dla kazdej osoby** (nie jedno wspolne konto zespolu) - uzytkownik moglby tez uzyc jednego konta i je udostepnic, ale wybral osobne konta i poprosil o polozenie prawdziwych podwalin pod wieloosobowosc, skoro takie bylo pierwotne zalozenie projektu.
- Zapytany o zachowanie synchronizacji bez zalogowania: **praca lokalna dziala normalnie, synchronizacja po prostu czeka** - appka nigdy nie blokuje uzytkownika przed zalogowaniem, tylko przycisk/timer "Synchronizuj teraz" nic nie robi, dopoki nikt nie jest zalogowany.
- Zapytany, co ma byc wspolne, a co prywatne: **klienci i projekty prywatne** (widoczne tylko dla wlasciciela), katalog urzadzen, lokacje i presety zasilania **wspolne** dla kazdego zalogowanego czlonka zespolu - to odzwierciedla realny podzial pracy (katalog sprzetu i lokacje sa wspolna wiedza ekipy, ale konkretny projekt/klient danej osoby nie musi byc widoczny dla innych).

Decyzja:

### Model danych i reguly dostepu (PocketBase)

- Ponownie uzyto domyslnej kolekcji `users` (auth), ktora PocketBase tworzy automatycznie przy pierwszym starcie - **nie** utworzono nowej kolekcji o tej samej nazwie (pierwsza proba wlasnie to zrobila i wywolala petle restartow uslugi: "Collection name must be unique (case insensitive)"). `listRule`/`viewRule`/`updateRule` = `"id = @request.auth.id"` (kazdy widzi/edytuje tylko wlasne konto), `createRule`/`deleteRule` = `null` (zakladanie/usuwanie kont tylko przez superusera - swiadomie brak samodzielnej rejestracji, bo to nadal male, zamkniete narzedzie dla jednej ekipy).
- Nowe pole relacyjne `owner` (-> `users`, `maxSelect: 1`) na `clients` i `projects`.
- Trzy poziomy regul dostepu na 16 juz istniejacych kolekcjach:
  - `authRule` (`@request.auth.id != ''`) - na 7 kolekcjach **wspolnych**: `catalog_devices`, `truss_load_chart_entries`, `locations`, `location_contacts`, `location_power_connectors`, `power_presets`, `power_outlet_templates`. Kazdy zalogowany widzi i edytuje wszystko - to wspolna wiedza ekipy, nie dane jednej osoby.
  - `ownerRule` (`@request.auth.id != '' && owner = @request.auth.id`) - na `clients` i `projects`. Tylko wlasciciel widzi/edytuje swoj rekord.
  - `projectOwnerRule` (`@request.auth.id != '' && project.owner = @request.auth.id`) - na 7 kolekcjach zagniezdzonych pod projektem (`project_groups`, `project_items`, `project_group_hook_assignments`, `project_distros`, `project_outlets`, `power_connections`, `project_trusses`), sprawdzajac wlasciciela **rodzica** przez relacje `project`, nie wlasne, nieistniejace pole `owner`.
  - Wszystkie migracje maja pelna funkcje `down` przywracajaca puste reguly z ADR-017.
- Migracje w `pocketbase/pb_migrations/` (i zastosowane na LXC 113): `1789300210_updated_users.js`, `1789300220_updated_clients_projects_owner.js`, `1789300230_updated_access_rules.js`. Przed zmiana schematu wykonano kopie `pb_data` na serwerze, tak jak w ADR-026.

### Lokalny schemat i sesja logowania

- `Clients.ownerId`/`Projects.ownerId` (`String?`) - id rekordu `users` w PocketBase (uzywane bezposrednio, bez tlumaczenia przez `local_id` - konta uzytkownikow istnieja tylko zdalnie, w przeciwienstwie do kazdego innego odwolania krzyzowego w tym schemacie). `null`, dopoki rekord nie zostanie po raz pierwszy wypchniety przez zalogowanego uzytkownika (patrz "Stemplowanie wlasciciela" nizej) - klient/projekt mozna wiec nadal tworzyc offline, przed zalogowaniem.
- `AppSettings.authSessionData` (`String?`) - jeden nieprzezroczysty blob JSON, ktorym samodzielnie zarzadza `AsyncAuthStore` z `package:pocketbase` (token + model uzytkownika w jednym polu) - zamiast trzech osobnych kolumn (`authToken`/`authUserId`/`authUserEmail`), ktore wymagalyby recznego utrzymywania spojnosci z wewnetrznym formatem SDK.
- Schemat lokalny podniesiony do wersji `14` (dodanie `Clients.ownerId`, `Projects.ownerId`, `AppSettings.authSessionData`).
- `PocketBaseClientProvider.initialize()` (wywolywane raz w `main()`, przed `runApp`) tworzy globalna instancje `PocketBase` z `AsyncAuthStore` podpiete pod `DriftAppSyncSettingsRepository.setAuthSessionData`/`getSettings().authSessionData` - sesja logowania przezywa restart aplikacji dokladnie tak samo jak reszta lokalnych danych.
- `PocketBaseAuthService` (`infrastructure/remote/pocketbase_auth_service.dart`) - cienka warstwa nad `PocketBase.authStore`: `isLoggedIn`, `currentUserEmail`, `currentUserId`, `login(email, password)` (`authWithPassword`), `logout()` (`authStore.clear()`). Nie trzyma wlasnego stanu - zawsze czyta ten sam `authStore`, ktorego uzywaja serwisy synchronizacji.

### UI logowania

- Nowa karta "Konto" na ekranie "O aplikacji" (przed juz istniejaca karta "Synchronizacja"): pola e-mail/haslo i przycisk "Zaloguj sie", gdy nikt nie jest zalogowany; e-mail zalogowanego uzytkownika i przycisk "Wyloguj", gdy jest.

### Stemplowanie wlasciciela i blokada synchronizacji

- Przy pushu `Client`/`Project` (`_push` w odpowiednim serwisie synchronizacji): jesli lokalny rekord nie ma jeszcze `ownerId`, zostaje on ustawiony na `PocketBase.authStore.record?.id` (aktualnie zalogowany uzytkownik), zapisany lokalnie (targetowany update Companion), i dopiero potem wyslany w ciele requestu jako pole `owner`. Rekord utworzony offline, zanim ktokolwiek sie zalogowal, staje sie wiec wlasnoscia tego, kto pierwszy go zsynchronizuje.
- `SyncCoordinator.syncAll()` sprawdza `PocketBase.authStore.isValid` **przed** wywolaniem ktoregokolwiek z pieciu serwisow synchronizacji - brak logowania zwraca od razu `SyncSummary(errors: ['Zaloguj sie, aby zsynchronizowac dane.'])` zamiast piedu serwisow zwracajacych po kolei zaglos bledow 403 z tym samym, mniej czytelnym efektem. To realizuje decyzje "praca lokalna dziala normalnie, sync po prostu czeka" - appka sama w sobie nigdy nie sprawdza stanu logowania poza tym jednym miejscem.

Uzasadnienie:

- Reuzycie domyslnej kolekcji `users` zamiast tworzenia nowej unika duplikatu i jest zgodne z tym, jak PocketBase faktycznie dziala od pierwszego startu - nowy programista czytajacy migracje "updated_users" od razu wie, ze kolekcja juz istniala.
- Podzial wspolne/prywatne (katalog/lokacje/presety kontra klienci/projekty) odzwierciedla rzeczywisty podzial pracy ekipy, ktory uzytkownik jawnie okreslil, zamiast arbitralnej decyzji "wszystko prywatne" albo "wszystko wspolne".
- `AsyncAuthStore` zamiast recznego zarzadzania tokenem: SDK juz rozwiazuje serializacje, wygasanie (`isValid` sprawdza `exp` w JWT) i normalizacje base64 - odtwarzanie tego recznie byloby zbednym, podatnym na bledy duplikatem.
- Stemplowanie wlasciciela dopiero przy pushu (nie przy tworzeniu rekordu) pozwala nadal tworzyc klientow/projekty offline, przed pierwszym logowaniem - zgodnie z ADR-002 (offline-first od pierwszego dnia), ktore ta decyzja w pelni respektuje.

Konsekwencje:

- **Rekordy `clients`/`projects` utworzone przed ta decyzja (bez `owner`) staja sie niedostepne do edycji/synchronizacji przez kogokolwiek** - `ownerRule` wymaga scislej zgodnosci `owner = @request.auth.id`, a pusty `owner` nie jest rowny zadnemu zalogowanemu uzytkownikowi. Zweryfikowano to bezposrednio: probe push takich rekordow (stare dane demo z ADR-026, `sync_demo_client`/`demo_project`) konczy sie bledem 403, podczas gdy nowy rekord z tym samym uzytkownikiem synchronizuje sie poprawnie. To jednorazowy koszt migracji - kazdy realny klient/projekt sprzed tej decyzji wymaga recznego przypisania `owner` przez superusera (przez API albo panel admina PocketBase) zanim bedzie znow synchronizowalny; appka lokalnie nadal ma te dane bez zmian, tylko przestaja sie synchronizowac.
- `tool/sync_demo_data.dart` wymaga teraz zmiennych srodowiskowych `SYNC_DEMO_EMAIL`/`SYNC_DEMO_PASSWORD` (istniejace konto) przed uruchomieniem - narzedzie samo w sobie nie zaklada kont (`createRule` jest superuser-only).
- Zweryfikowano recznie pelny przeplyw logowanie -> push (ze stemplowaniem wlasciciela) -> pull do nowej, pustej bazy lokalnej -> odmowa dostepu dla niezalogowanego klienta, na tymczasowym koncie testowym utworzonym i usunietym wylacznie na czas tej weryfikacji.
- `revision` nadal nie jest uzywane (patrz ADR-026) - ta decyzja tego nie zmienia.
- Zalozenia pod wieloosobowosc sa teraz realne (osobne konta, wlasciciel na rekordzie), ale nadal brak: UI do zarzadzania kontami (zaklada je superuser recznie), przenoszenia wlasnosci miedzy uzytkownikami, i jakiegokolwiek podgladu "kto jest zalogowany na innym urzadzeniu" - zaden z tych scenariuszy nie zostal poproszony, wiec zostaja przyszlym, osobnym krokiem, gdy pojawi sie realna potrzeba.

## ADR-027: Eksport raportu do PDF

Status: accepted

Kontekst:

- ADR-021 swiadomie wybrala raport tekstowy zamiast PDF dla MVP - `docs/FEATURE_SCOPE.md` wprost dopuszcza "eksport danych... w prostszej formie", a PDF wymagal nowej zaleznosci i realnej pracy nad ukladem. Ten dlug zostal teraz splacony jako dodatkowa opcja eksportu, nie zamiennik raportu tekstowego.

Decyzja:

- `ProjectPdfReportService` (`features/projects/domain/services/project_pdf_report_service.dart`) generuje PDF przez pakiet `pdf` (widgets API), uzywajac dokladnie tych samych serwisow domenowych co `ProjectReportService` i UI (`ProjectTotalsService`, `PowerCalculationService`, `PatchValidationService`, `TrussLoadService`) - ta sama zasada ADR-014, ze raport nie powiela logiki obliczen.
- Uklad: naglowek z nazwa projektu i akcentem GreenCrew (`#00C853`), sekcje Podsumowanie/Grupy urzadzen/Rozdzielnice/Kratownice jako tabele (`pw.TableHelper.fromTextArray`), stopka z numeracja stron. Tresc sekcji 1:1 odpowiada raportowi tekstowemu (te same ostrzezenia: gniazdo uzyte wielokrotnie, przeciazone wejscie/gniazdo, cykl polaczen, przekroczony limit kratownicy).
- Domyslne fonty PDF (Helvetica przez baze 14 fontow standardu PDF) zamiast wlasnego pliku Roboto - PDF jest dodatkowa opcja eksportu, nie glownym UI aplikacji, wiec brak pelnego brandingu typograficznego jest akceptowalny na start; pakiet `pdf` ostrzega w konsoli, ze te fonty nie maja pelnego wsparcia Unicode, ale caly tekst w aplikacji jest juz pisany bez polskich znakow diakrytycznych, wiec w praktyce nie ma to znaczenia.
- Zapis do pliku przez rozszerzenie wspolnego `local_file_writer` (ADR-021) o `writeLocalBytesFile` - PDF to pierwszy binarny plik do zapisania lokalnie, wiec funkcja przyjmujaca `String content` nie wystarczala; dodano siostrzana funkcje zamiast zmieniac istniejacy, juz uzywany podpis.
- Ikona "Eksportuj raport PDF" w AppBar edytora projektu, obok istniejacej "Eksportuj raport tekstowy" - obie opcje dostepne rownolegle.

Uzasadnienie:

- Ta sama tresc co juz sprawdzony raport tekstowy (te same dane, te same ostrzezenia) minimalizuje ryzyko rozjazdu miedzy formatami i pozwala poddac PDF tej samej weryfikacji regresyjnej co reszte projektu.
- Pakiet `pdf` jest czystym Dartem (dziala na Windows/Android/Web bez natywnych zaleznosci), spojnie z reszta stosu (Drift, PocketBase - zadnych platformowych pluginow ponad juz istniejace).

Konsekwencje:

- Testy PDF (`project_pdf_report_service_test.dart`) nie moga sprawdzac tresci - pakiet `pdf` nie ma API do odczytu z powrotem - wiec asercje ograniczaja sie do poprawnosci pliku (niepusty, zaczyna sie od sygnatury `%PDF-`) dla tych samych ksztaltow projektu, ktore sprawdza test raportu tekstowego (duplikat gniazda, przeciazona kratownica, pusty projekt, projekt wielostronicowy).
- Jesli w przyszlosci pojawi sie realna potrzeba pelnego brandingu PDF (font Roboto, logo StageCalc), to osobny, nastepny krok - nie zablokowal tego pierwszego dzialajacego eksportu.

## ADR-026: Dwukierunkowa synchronizacja z PocketBase

Status: accepted

Kontekst:

- ADR-017 dala tylko jednokierunkowy, no-conflict push jednego `Project` - "dowod, ze polaczenie i mapowanie modelu dzialaja", jawnie nie sync engine. Etap 10 (`docs/MIGRATION_PLAN.md`) mial nadal do zrobienia: kolejke synchronizacji, strategie konfliktow, realne statusy sync (`syncState`/`lastSyncedAt` istnialy w schemacie, ale nic ich nie zmienialo poza `localOnly`), i sync dla katalogu/klientow/lokacji/presetow (nie tylko projektu).
- Zdecydowano wspolnie z uzytkownikiem: konflikty rozwiazuje "ostatni zapis wygrywa" po `updatedAt` (bez UI do recznego scalania), wyzwalacz to ustawienie w "O aplikacji" (automatyczny w tle albo przycisk "Synchronizuj teraz" w trybie recznym), a zakres to wszystkie piec agregatow (projekty, katalog, klienci, lokacje, presety), nie tylko projekty.

Decyzja:

### Silnik synchronizacji

- `decideSyncDirection` (`infrastructure/sync/sync_direction.dart`) - czysta funkcja: porownuje `updatedAt` lokalnego i zdalnego rekordu, zwraca `push`/`pull`/`none`. Rekord istniejacy tylko po jednej stronie zawsze trafia na druga, niezaleznie od kierunku.
- Piec serwisow (`PocketBase{Client,Location,PowerPreset,Catalog,Project}SyncService`, po jednym per agregat, wzorowane na juz istniejacych repozytoriach Drift) laczy sie z PocketBase i dla kazdego rekordu (dopasowanego po `local_id`) wykonuje `decideSyncDirection`, potem push lub pull. `SyncCoordinator.syncAll()` uruchamia wszystkie piec po kolei (klienci/lokacje/presety/katalog przed projektami, zeby `Project.client`/`location` mialy juz co rozwiazac zdalnie) i zapisuje `lastSyncedAt`.
- **Reconciliacja na poziomie calego drzewa, nie pojedynczych rekordow potomnych**: tak jak `saveProject`/`saveLocation` itd. juz dzialaja lokalnie (jeden zapis = caly agregat, znaczkowany jednym `updatedAt` korzenia), sync tez traktuje np. cala kratownice grup/pozycji/hakow projektu jako jedna jednostke - wygrywa/przegrywa razem z korzeniem. Bez tego mergowanie pojedynczych zmienionych elementow z obu stron byloby prawdziwym problemem 3-way merge, ktorego ten krok swiadomie unika.
- **Nic nigdy nie jest twardo usuwane, ani lokalnie, ani zdalnie** (`pocketbase_child_sync.dart`, `upsertRemoteChildren`): appka juz wszedzie soft-deletuje (`deletedAt`, ADR-011), wiec sync po prostu upsertuje kazdy rekord - lokalny czy zdalny - wraz z jego flaga `deleted`/`deleted_at`. To duzo prostsze niz kaskadowe twarde usuwanie (np. usuniecie grupy pociagajace usuniecie jej pozycji i hakow po drugiej stronie) i spojne z reszta architektury.
- Powiazania `client`/`location` na `Project` (lokalne ID, nie relacje PocketBase) sa rozwiazywane do zdalnego ID przez wyszukanie po `local_id` w danej kolekcji (`_findRemoteId`/`_findLocalId`) - nie sa duplikowane wewnatrz `PocketBaseProjectSyncService`, bo klienci/lokacje maja juz wlasny serwis synchronizujacy.
- Znane, swiadome ograniczenie: `project_distros.catalog_device`/`preset` (relacje PocketBase) nie sa jeszcze wypelniane przy pushu - nic ich dzis nie czyta z powrotem, wiec rozwiazywanie tych relacji zostaje przyszlym, osobnym krokiem, gdy pojawi sie realny powod.

### Migracja schematu PocketBase

- Brakujace pola/kolekcje z ADR-020/ADR-024/ADR-025 (dodane do lokalnego schematu Drift po tym, jak ADR-017 juz zamrozila zdalny schemat) dopisano do PocketBase na LXC 113 jako pliki migracji w `/opt/pocketbase/pb_migrations/` (dokladnie ten mechanizm, ktorego ADR-017 juz uzywala) i zastosowano restartem uslugi: `catalog_devices.rigging_points`, `project_items.rigging_points_snapshot`, `project_trusses.truss_catalog_device_id`, `project_distros.manual_input_max_current_a`, oraz dwie nowe kolekcje `project_group_hook_assignments` i `truss_load_chart_entries`.
- Wykonano kopie `pb_data` na serwerze przed migracja (`/root/pb_data_backup_*.tar.gz`) i zweryfikowano kazde nowe pole/kolekcje przez publiczne API (puste `listRule` z ADR-017) zamiast logowania sie jako superuser, zeby nie tworzyc/przekazywac zadnych poswiadczen bez potrzeby.
- **Wszystkie pliki migracji PocketBase sa teraz w repozytorium** (`pocketbase/pb_migrations/`) - do tej pory caly schemat zdalny istnial tylko na serwerze, bez sladu w repo. To pierwszy krok do tego, zeby historia schematu byla odtwarzalna, a nie tylko pamietana przez serwer.

### Ustawienia i automatyzacja

- Nowa tabela `AppSettings` (pojedynczy wiersz `id='app'`) zamiast generycznego key-value store - `ADR-011` juz odrzucila `shared_preferences` na rzecz jawnego schematu relacyjnego, a appka ma na razie jedno ustawienie (`autoSyncEnabled` + `lastSyncedAt`).
- Ekran "O aplikacji" ma nowa karte "Synchronizacja": przelacznik "Automatyczna synchronizacja" + (widoczny tylko gdy przelacznik jest wylaczony) przycisk "Synchronizuj teraz" + tekst statusu (czas ostatniej synchronizacji albo wynik ostatniej proby).
- `StageCalcShell` (nie `AboutScreen`) trzyma `Timer.periodic` (co 15 minut, plus jedno wywolanie od razu przy starcie), bo tylko wybrany ekran nawigacji jest w drzewie widgetow - `AboutScreen` znika przy zmianie zakladki. Timer za kazdym razem na nowo czyta `autoSyncEnabled` z bazy zamiast cache'owac je w pamieci, wiec przelaczenie w Ustawieniach dziala od nastepnego tyknicia bez zadnego dodatkowego kanalu komunikacji miedzy ekranami. Bledy synchronizacji w tle sa celowo ciche (offline-first: nieudana synchronizacja to normalny stan, nie blad przerywajacy prace) - ekran Ustawien pokazuje czas ostatniej udanej synchronizacji dla kogos, kto chce sprawdzic.

### Weryfikacja

- Logika decyzyjna (`decideSyncDirection`) i `AppSyncSettings`/`DriftAppSyncSettingsRepository` sa w pelni pokryte testami jednostkowymi. Sprostowanie: pierwsza wersja tego ADR twierdzila, ze `insertOnConflictUpdate` z czesciowym companionem resetuje pominiete kolumny (rzekomo przez `excluded.col` w SQLite) - to nieprawda, Drift jawnie dokumentuje, ze kolumny nieobecne w companionie zostaja niezmienione przy konflikcie. Prawdziwy blad zlapany przez test byl inny: `AppSyncSettings.copyWith` uzywa `??`, wiec jawne przekazanie `null` (np. przy czyszczeniu sesji logowania) jest nieodrozniane od "nic nie zmieniaj" i po prostu zachowuje stara wartosc zamiast ja wyczyscic - std. `withAuthSessionData`/`withAuthSession`-owe metody nie-scalajace, zamiast `copyWith`, tam gdzie trzeba faktycznie wyczyscic pole do `null`.
- Same wywolania sieciowe do PocketBase nie sa mockowane (jak w ADR-017) - `tool/sync_demo_data.dart` (uruchamiane przez `flutter test tool/sync_demo_data.dart`, nie `dart run`: `AppDatabase` importuje `path_provider`, ktore samo importuje `package:flutter`, wiec zwykla maszyna wirtualna Dart tego nie skompiluje) sieje dane demo do bazy w pamieci i synchronizuje je z prawdziwym serwerem w obie strony: push nowych danych, drugi przebieg pokazujacy pelna idempotentnosc (same "unchanged"), i osobny test pull do zupelnie pustej bazy lokalnej z asercjami na tresc (nazwa klienta, grupy/pozycje projektu) - zweryfikowane realnie dzialajace dla klientow, lokacji, presetow, katalogu i projektow (wraz z zagniezdzonymi grupami/pozycjami).
- Sciezki dla dystrybutorow/gniazd/polaczen/kratownic/hakow uzywaja dokladnie tego samego wzorca co juz zweryfikowane grupy/pozycje, ale nie sa osobno cwiczone przez dane demo (`DemoProjectFactory` nie ma jeszcze rozdzielnic ani kratownic) - kolejny kandydat do rozszerzenia `tool/sync_demo_data.dart`, jesli okaza sie potrzebne wczesniej niz przy pierwszym realnym uzyciu.

Uzasadnienie:

- "Ostatni zapis wygrywa" jest jedyna strategia, ktora nie wymaga nowego UI do recznego scalania - dokladnie to, o co poprosil uzytkownik, i spojne z tym, ze to nadal male, LAN-owe narzedzie, nie system wieloosobowej edycji w czasie rzeczywistym.
- Upsert zamiast twardego usuwania po obu stronach oznacza zero nowej logiki kaskadowego kasowania - i tak juz nigdzie w tej appce nic nie jest usuwane na twardo.
- Migracje PocketBase w repozytorium (zamiast tylko na serwerze) to jedyny sposob, zeby schemat zdalny byl odtwarzalny i przegladalny w code review, tak jak juz jest schemat lokalny (`app_database.dart`).

Konsekwencje:

- Kazda przyszla zmiana lokalnego schematu, ktora ma sie synchronizowac, wymaga rowniez nowego pliku migracji w `pocketbase/pb_migrations/` (lokalnie i wgranego na serwer) - latwo o tym zapomniec, tak jak stalo sie to miedzy ADR-017 a ADR-020/024/025.
- Reguly dostepu kolekcji PocketBase sa nadal puste/publiczne (ADR-017) - nic w tej ADR tego nie zmienia; prawdziwa autoryzacja zostaje przyszlym, osobnym krokiem (zaadresowane w ADR-028).
- `revision` (pole w kazdej tabeli od ADR-011) nadal nic nie inkrementuje - "ostatni zapis wygrywa" po `updatedAt` nie go potrzebuje. Zostaje nieuzywane, chyba ze pojawi sie powod na bardziej wyrafinowana strategie konfliktow.

## ADR-025: Interpolacja tabel nosnosci kratownic

Status: accepted

Kontekst:

- Druga (i ostatnia) rzecz odlozona przez ADR-020 przy pierwszej wersji modulu kratownic. `ProjectTruss` mial dotychczas tylko rekznie wpisywane `maxTotalLoadKg`/`maxDistributedLoadKgPerM` - bez zadnego powiazania z konkretnym modelem kratownicy i jego rzeczywista tabela nosnosci od producenta.
- Legacy (`legacy/firebase/src/components/truss/truss-calculator.tsx`, `getInterpolatedLimits`/`interpolate`) trzyma tabele nosnosci (`loadChart`) na urzadzeniu-kratownicy w katalogu i interpoluje liniowo limit punktowy/rozlozony po dlugosci; poza zakresem tabeli ekstrapoluje z dwoch najblizszych punktow i oznacza wynik jako ekstrapolacje. Logika przeniesiona 1:1 (`docs/MIGRATION_PLAN.md`: "Co przepisac 1:1 - Interpolacje kratownic").

Decyzja:

- `ProjectTruss.trussCatalogDeviceId` (`String?`) - opcjonalny link do `CatalogDevice` reprezentujacego model kratownicy. Wybierany z listy urzadzen kategorii "Rigging" w dialogu kratownicy (`_TrussDialog`), niezalezny od istniejacego, wciaz nieuzywanego w UI pola `trussSystemId`.
- `CatalogDevice.loadChart` (`List<TrussLoadChartEntry>`, nowa tabela `truss_load_chart_entries`) - punkty `{lengthM, pointLoadKg, distributedLoadKgPerM}` wpisywane w formularzu katalogu, widoczne tylko dla kategorii "Rigging". Bez pol ugiecia (`deflection*`) z legacy - nieuzywane przez zadna kalkulacje ani tam, ani tutaj; jesli okaza sie potrzebne, to osobny, later dodany krok.
- `TrussLoadService._interpolateLimits` - port `getInterpolatedLimits`/`interpolate` z legacy: dokladne trafienie, interpolacja miedzy dwoma najblizszymi punktami, ekstrapolacja z dwoch skrajnych gdy dlugosc jest poza tabela, `no-data` gdy urzadzenie nie ma tabeli.
- Reguła override: `maxTotalLoadKg`/`maxDistributedLoadKgPerM` na `ProjectTruss` pozostaja recznym nadpisaniem, dokladnie jak `manualInputMaxCurrentA` dla limitu wejscia rozdzielnicy (ta sama zasada "domyslnie wyliczone + mozliwosc ustalenia" z wczesniejszej decyzji uzytkownika w tej sesji) - kazde z obu pol dziala niezaleznie: gdy puste, brany jest wynik interpolacji; gdy wypelnione, wygrywa wartosc reczna.
- `TrussLoad` ma teraz `totalLimitFromChart`/`distributedLimitFromChart` (czy dany limit pochodzi z tabeli) i `hasInterpolatedLimits`/`isChartExtrapolated` do pokazania w UI. `_TrussCard` pokazuje chip "Limity z tabeli producenta" albo ostrzegawczy "Dlugosc poza tabela producenta (ekstrapolacja)".
- Schemat bazy podniesiony do wersji `12`.

Uzasadnienie:

- Zgodnosc z `docs/MIGRATION_PLAN.md` ("Co przepisac 1:1") - sama matematyka interpolacji nie ma powodu roznic sie od sprawdzonej w legacy.
- Reuzycie wzorca "wyliczone + reczny override" (zamiast np. blokowania recznego pola, gdy jest tabela) jest spojne z ADR z Etapu 6 i nie wymaga nowej decyzji produktowej.
- `trussCatalogDeviceId` jako osobne pole (zamiast przeciazania `trussSystemId`) unika nadania nowego znaczenia polu, ktore juz istnieje w schemacie i bazie danych uzytkownikow.

Konsekwencje:

- Etap 7 (`docs/MIGRATION_PLAN.md`) jest zrealizowany w calosci dla zakresu MVP - haki (ADR-024) i interpolacja (ta ADR).
- `ProjectEditorController` cache'uje teraz `catalogDevices` (ladowane w `loadReferences()`, jak `clients`/`locations`/`powerPresets`) - potrzebne do synchronicznego liczenia `trussLoad()` w `build()`. Ten cache ma te sama, juz zaakceptowana wczesniej niedoskonalosc co pozostale trzy: moze sie zdezaktualizowac, jesli katalog zmieni sie w tle podczas edycji projektu.
- Ewentualne dodanie ugiecia (`deflectionPointLoadMm`/`deflectionDistributedLoadMm`) z `docs/DATA_MODEL.md` zostaje przyszlym, osobnym krokiem, gdy pojawi sie realna potrzeba go pokazac.

## ADR-024: Haki kratownic (riggingPoints)

Status: accepted

Kontekst:

- Etap 7 (`docs/MIGRATION_PLAN.md`) zostawil dwie rzeczy poza pierwsza wersja modulu kratownic (ADR-020): haki (`riggingPoints`) i interpolacje tabel nosnosci producenta. Ta ADR realizuje pierwsza z nich; interpolacja zostaje nadal poza zakresem, bo wymaga dodatkowo powiazania `ProjectTruss` z konkretnym urzadzeniem katalogowym (`trussCatalogDeviceId` z `docs/DATA_MODEL.md` tez jeszcze nie istnieje) i tabeli `TrussLoadChartEntry`.
- Logika w legacy (`legacy/firebase/src/components/truss/truss-calculator.tsx`, `getGroupWeight`): wymagana liczba hakow to suma `device.riggingPoints * item.quantity` po pozycjach grupy z katalogu; przypisane haki to osobna lista `{hookId, quantity}` per grupa, ktorej waga dolicza sie do calkowitej wagi grupy (a wiec i do obciazenia kratownicy, do ktorej grupa jest przypisana).

Decyzja:

- `CatalogDevice.riggingPoints` (`int?`) - liczba punktow zaczepienia potrzebnych na sztuke urzadzenia. Pole w formularzu katalogu, opcjonalne, widoczne jako chip na karcie urzadzenia gdy ustawione.
- `ProjectItem.riggingPointsSnapshot` (`int?`) - snapshot `riggingPoints` w momencie dodania pozycji z katalogu, zgodnie z ADR-008 (snapshoty katalogowe) - zmiana `riggingPoints` w katalogu pozniej nie zmienia juz policzonych wymagan istniejacych projektow.
- `ProjectGroupHookAssignment` (nowa tabela `project_group_hook_assignments`, analogiczna do `ProjectItems`): `id`, `hookCatalogDeviceId`, `hookNameSnapshot`, `hookWeightKgSnapshot`, `quantity`. Lista `hookAssignments` na `ProjectGroup`. Hak to zwykle urzadzenie z katalogu (kategoria "Rigging" w praktyce, ale nie wymuszone strukturalnie) wybierane przez ten sam `_CatalogSelectionDialog`, ktorego uzywa dodawanie pozycji do grupy - bez nowego pola "podkategoria" w katalogu, ktorego DATA_MODEL nie definiuje.
- `TrussLoadService.hookRequirement(ProjectGroup)` liczy `requiredHooks` (suma `riggingPointsSnapshot * quantity`, zaokraglona w gore), `assignedHooks` (suma ilosci przypisanych hakow) i `hooksWeightKg`. `calculateLoad` dolicza `hooksWeightKg` do masy kazdej przypisanej grupy - haki sa wlasnoscia grupy, nie kratownicy, wiec licza sie niezaleznie od tego, do ktorej kratownicy grupa trafi.
- Nowa sekcja "Haki grup urzadzen" w widoku "Kratownice" edytora projektu: lista grup z `requiredHooks > 0`, chip "Wymagane: X / Przypisane: Y" (czerwony gdy niewystarczajace), lista przypisanych hakow z kontrolkami ilosci i usuwaniem, przycisk "Dodaj hak".
- Schemat bazy podniesiony do wersji `11`: `catalog_devices.rigging_points`, `project_items.rigging_points_snapshot`, nowa tabela `project_group_hook_assignments`.

Uzasadnienie:

- Snapshot zamiast live-lookup (w odroznieniu od legacy, ktore czytalo `device.riggingPoints` na biezaco z katalogu) jest spojny z reszta aplikacji (ADR-008) i unika niespodziewanej zmiany wymagan istniejacego projektu po edycji katalogu.
- Reuzycie `_CatalogSelectionDialog` zamiast nowego pickera dla hakow unika duplikacji UI i nie wymaga decyzji o nowym polu "podkategoria" w katalogu, ktorej DATA_MODEL nie przewiduje.
- Wymagania hakow sa wlasnoscia grupy (fizyczne haki wpiete w urzadzenia), nie kratownicy - stad `hookRequirement` przyjmuje `ProjectGroup`, a nie `ProjectTruss`, i dziala tak samo niezaleznie od przypisania.

Konsekwencje:

- Interpolacja tabel nosnosci producenta i `trussCatalogDeviceId` pozostaja kolejnym, osobnym krokiem Etapu 7.
- Kazda przyszla zmiana liczaca mase grupy (np. eksport raportu) powinna pamietac, ze `ProjectTotalsService.calculateGroup(...).weightKg` **nie** zawiera wagi hakow - to celowe, bo haki maja sens tylko w kontekscie kratownic, nie w ogolnym sumowaniu projektu; `TrussLoadService` jest jedynym miejscem, ktore je dolicza.

## ADR-023: File picker dla importu backupu

Status: accepted

Kontekst:

- Import backupu (ADR-019) wymagal recznego wklejenia pelnej sciezki do pliku JSON - niewygodne i podatne na literowki, zwlaszcza na Androidzie, gdzie sciezki do `Documents/StageCalc/backups/` nie sa widoczne w typowym eksploratorze plikow bez wpisania ich z pamieci.

Decyzja:

- Dodano zaleznosc `file_picker` (`^12.3.0`) i przycisk "Wybierz plik" (ikona folderu) obok istniejacego pola na sciezke w ekranie "O aplikacji". Przycisk otwiera natywny wybor pliku (`FilePicker.pickFile`, filtr `.json`) i wypelnia pole sciezki wynikiem.
- Reczne pole na sciezke zostaje - to nie jest zamiennik, tylko dodatkowy, wygodniejszy sposob jej wypelnienia. Caly przeplyw walidacji/importu (ADR-019) sie nie zmienia.
- `file_picker` na Androidzie (`android_file_picker`) dziala przez Storage Access Framework/`GET_CONTENT` intent, wiec nie wymaga zadnego dodatkowego uprawnienia w `AndroidManifest.xml` - zgodne z ADR-012E (minimalne uprawnienia). Zweryfikowano tresc `AndroidManifest.xml` paczki `android_file_picker`: deklaruje tylko `<queries>` (widocznosc pakietow), zero `<uses-permission>`.
- Na Windows uzywany jest natywny dialog plikow (`windows_file_picker`), rowniez bez dodatkowych uprawnien.

Uzasadnienie:

- Mala, samodzielna poprawka UX bez wplywu na model danych czy logike importu.
- Brak nowego uprawnienia systemowego utrzymuje zasade ADR-012E.

Konsekwencje:

- Testy widgetowe importu podmieniaja `FilePickerPlatform.instance` na fake (`_FakeFilePickerPlatform` w `widget_test.dart`) zamiast klikac prawdziwy natywny dialog, ktorego `flutter test` i tak nie potrafi wyswietlic.
- `file_picker` nie jest jeszcze uzywany do eksportu (backup/raport zapisuja zawsze do ustalonego katalogu `Documents/StageCalc/...`) - to osobna, nie zadana jeszcze zmiana.

## ADR-022: Uprawnienie INTERNET i skrypt pakowania release

Status: accepted

Kontekst:

- Przy przegladzie Etapu 11 (`docs/MIGRATION_PLAN.md`) okazalo sie, ze `AndroidManifest.xml` nie deklarowal `android.permission.INTERNET`, mimo ze `PocketBaseProjectSyncService` (ADR-017) juz laczy sie z serwerem PocketBase. Zweryfikowano w scalonym manifescie release builda (`build/app/.../processReleaseMainManifest/AndroidManifest.xml`) - uprawnienia INTERNET nie bylo tam ani z aplikacji, ani z zadnej biblioteki. Na Androidzie brak tego uprawnienia konczy kazde polaczenie sieciowe `SecurityException`, niezaleznie od trybu builda (debug/release) - to nie byla jeszcze zauwazona regresja, bo dotychczasowa synchronizacja byla testowana tylko z `dart run tool/push_demo_project.dart` na Windows, nie z samej aplikacji na telefonie.
- ADR-012F (nazewnictwo release, `StageCalc-vX_Y_Z-platform.ext`) i pozycja "Przygotowac nazwy artefaktow" w Etapie 11 byly zdecydowane, ale nie mialy jeszcze zadnej automatyzacji - nazwa musialaby byc nadawana recznie po kazdym `flutter build`.

Decyzja:

- Dodano `<uses-permission android:name="android.permission.INTERNET" />` do `android/app/src/main/AndroidManifest.xml`, z komentarzem odsylajacym do ADR-017 jako powodu.
- Dodano `tool/package_release.dart` (`dart run tool/package_release.dart [--platform=android|windows|all]`), ktory:
  - czyta wersje z `pubspec.yaml` (`version: X.Y.Z+build`, numer builda pomijany w nazwie pliku - zgodnie z przykladami w ADR-012F),
  - uruchamia `flutter build apk --release` / `flutter build windows --release`,
  - kopiuje/pakuje wynik do `dist/StageCalc-vX_Y_Z-android.apk` i `dist/StageCalc-vX_Y_Z-windows.zip`.
- Do pakowania Windows uzyto `Compress-Archive` z PowerShell zamiast dodawania zaleznosci `archive` do `pubspec.yaml` - pakowanie Windows i tak dziala tylko na maszynie z Windows (tam, gdzie mozna skompilowac `.exe`), wiec PowerShell jest zawsze dostepny.
- `dist/` dodany do `.gitignore` - to sa artefakty builda, nie zrodla.

Uzasadnienie:

- To dokladnie ten typ bledu, ktory user prosil zglaszac od razu: "dlaczego cos dziala tak jak dziala, a nie inaczej" — tu odpowiedzia bylo "bo jeszcze nikt nie sprawdzil, ze telefon w ogole moze wykonac zapytanie sieciowe".
- Automatyzacja nazewnictwa usuwa reczny, latwy do pomylenia krok przed kazdym udostepnieniem builda.

Konsekwencje:

- Etap 11 (`Przygotowac nazwy artefaktow`) jest zrealizowany dla Android/Windows. Podpisywanie APK wlasnym kluczem (obecnie release uzywa klucza debug) i ewentualny CI pozostaja poza zakresem tej zmiany.
- Kazda przyszla platforma (np. iOS) powinna dostac wlasna funkcje `_packageX` w tym samym skrypcie, zamiast osobnego narzedzia.

## ADR-021: Raport tekstowy zamiast PDF, plus wspolny zapis plikow

Status: accepted

Kontekst:

- ADR-014 (proposed) zaklada `ProjectReportService` osobny od widokow, uzywajacy tych samych serwisow domenowych co UI - ale nie przesadzil formatu.
- `docs/FEATURE_SCOPE.md` (Zakres MVP) explicite dopuszcza prostszy format: "eksport danych lub PDF w prostszej formie, jesli PDF opoznia MVP".
- PDF wymagalby nowej, wiekszej zaleznosci (`pdf`/`printing`) i osobnej pracy nad ukladem/stylem zgodnym z GreenCrew branding - nie jest to male rozszerzenie.
- Przy okazji: trzeci raz z rzedu (polaczenie z baza - ADR-016, backup - ADR-018, teraz raport) potrzebny byl niemal identyczny trojkat plikow native/web/stub do zapisu czegos na dysku.

Decyzja:

- `ProjectReportService.buildTextReport(Project)` generuje czytelny raport tekstowy (podsumowanie mocy/pradu/masy, grupy z pozycjami, rozdzielnice z obciazeniem faz i ostrzezeniami - przeciazenie, duplikat gniazda, cykl - kratownice z masa i ostrzezeniami o limicie), uzywajac dokladnie tych samych serwisow co UI edytora (`ProjectTotalsService`, `PowerCalculationService`, `PatchValidationService`, `TrussLoadService`), wiec liczby w raporcie nigdy nie roznia sie od tego, co pokazuje aplikacja.
- Akcja "Eksportuj raport tekstowy" jako ikona w AppBar edytora projektu (raport jest per-projekt, nie aplikacyjny jak backup).
- Wydzielono `infrastructure/files/local_file_writer/` (`writeLocalFile({subfolder, fileName, content})`) jako jedyny mechanizm zapisu lokalnych plikow tekstowych/JSON, zapisujacy do `Documents/StageCalc/<subfolder>/`. `AppBackupService` i `ProjectReportService`/ekran edytora korzystaja z niego zamiast z wlasnych kopii tego samego trojkata plikow. Odczyt backupu (`backup_file_reader/`) zostaje osobno, bo ma inny ksztalt (czyta po sciezce) i na razie tylko jeden uzytkownik.
- PDF pozostaje mozliwym nastepnym krokiem (Etap 9 planu migracji), ale nie blokuje posiadania czytelnego, dajacego sie skopiowac/wyslac raportu juz teraz.

Uzasadnienie:

- Trzeci niemal identyczny trojkat plikow to dokladnie ten prog, po ktorym duplikacja przestaje byc "trzy proste linie" i staje sie realnym kosztem utrzymania (kazda przyszla zmiana - np. dodanie prawdziwego file pickera - musialaby powtorzyc sie w trzech miejscach zamiast jednym).

## ADR-020: Pierwszy silnik i UI kratownic (bez hakow i interpolacji)

Status: accepted

Kontekst:

- `ProjectTruss` mial juz model danych i tabele Drift od poczatku (`assignedGroupIds`, `manualLoadKg`, `maxTotalLoadKg`, `maxDistributedLoadKgPerM`), ale `TrussLoadService` z Etapu 3 planu migracji nigdy nie powstal, i nie bylo zadnego UI - modul kratownic byl niewidoczny dla uzytkownika.
- Pelny docelowy model z `docs/DATA_MODEL.md` obejmuje tez `ProjectTrussLoad` (pozycje punktowe/UDL), `ProjectGroupHookAssignment` (haki) i tabele nosnosci producenta (`TrussLoadChartEntry`, `TrussWeightChartEntry`) z interpolacja liniowa - **zadna z tych czterech rzeczy jeszcze nie istnieje** w schemacie.

Decyzja:

- Dodano `TrussLoadService` dzialajacy wylacznie na obecnym modelu `ProjectTruss`: `totalMassKg = suma masy przypisanych grup (ProjectTotalsService) + manualLoadKg`, `distributedLoadKgPerM = totalMassKg / lengthM` (0, nie dzielenie przez zero, gdy `lengthM == 0`). Porownuje to z `maxTotalLoadKg`/`maxDistributedLoadKgPerM` (progi near-limit 90%, jak `PowerCalculationService`) i wystawia `hasKnownLimits`, zeby brak zdefiniowanych limitow czytal sie jako "nieznane", a nie milczaco jako "OK".
- Dodano trzeci widok w edytorze projektu ("Kratownice", obok "Sprzet"/"Patcher"): lista kratownic, dialog dodawania/edycji (nazwa, dlugosc, reczne obciazenie, opcjonalne limity, notatki, wybor przypisanych grup checkboxami), usuwanie.
- Naprawiono przy okazji ten sam wzorzec osieroconych referencji co ADR-015 (dla polaczen), zanim zdazyl sie powtorzyc: usuniecie grupy usuwa teraz jej ID takze z `assignedGroupIds` kazdej kratownicy.

Swiadomie pominiete (nowy schemat, nie architektoniczne "nie da sie" - patrz `docs/DATA_MODEL.md` "Kratownice"):

- Haki (`ProjectGroupHookAssignment`, liczenie z `riggingPoints`) - wymaga pola `riggingPoints` w katalogu urzadzen, ktorego jeszcze nie ma.
- Rozbicie obciazenia na pozycje punktowe/UDL (`ProjectTrussLoad`) - obecny model liczy jedna zagregowana mase, nie rozklad wzdluz kratownicy.
- Interpolacja tabel nosnosci producenta (`TrussLoadChartEntry`) i ostrzeganie o ekstrapolacji - `maxTotalLoadKg`/`maxDistributedLoadKgPerM` sa na razie zwyklymi polami wpisywanymi recznie przez uzytkownika, nie wartosciami odczytanymi z tabeli producenta dla konkretnej dlugosci.

Uzasadnienie:

- Ten zakres realizuje dokladnie to, co `docs/FEATURE_SCOPE.md` opisuje jako czesc MVP ("obliczanie masy grup z urzadzen, recznych pozycji" i "kontrola calkowitego limitu obciazenia, obciazenia rozlozonego kg/m"), bez projektowania schematu pod haki/tabele nosnosci, ktore nie maja jeszcze zadnego zrodla danych w katalogu.
- Dodanie tych czterech rzeczy pozniej nie wymaga przebudowy `TrussLoadService` - to rozszerzenia, nie zmiana istniejacego kontraktu (`ProjectTruss`/`TrussLoad` zostaja, przybywa nowych pol/serwisow).

## ADR-019: Import backupu JSON

Status: accepted

Kontekst:

- ADR-018 dostarczyl eksport (`AppBackupService`), ale import zostal tam swiadomie wylaczony z zakresu.
- `docs/DATA_MODEL.md` ("Backup") wymaga, zeby "Import backupu... walidowal dane przed zapisem".

Decyzja:

- Dodano `AppBackupImportService` z dwoma odrebnymi krokami:
  1. `validate(String jsonContent) -> BackupImportPreview` — czysta funkcja, nic nie zapisuje. Sprawdza: poprawnosc JSON, obecnosc sekcji `manifest`/`data`, `schemaVersion` (odrzuca backup z **nowszego** formatu niz `appBackupFormatVersion` obslugiwany przez ta wersje aplikacji), oraz parsuje kazdy rekord w kazdej sekcji przez odpowiadajace `fromJson`. Pierwszy niepoprawny rekord przerywa cala walidacje z komunikatem wskazujacym sekcje i numer rekordu — **zero rekordow** trafia do bazy, jesli cokolwiek jest zle.
  2. `import(BackupImportPreview) -> Future<void>` — zapisuje juz zwalidowane dane przez istniejace repozytoria (`save*`), ktore wszystkie robia upsert po `id`. Rekordy o pasujacym ID sa nadpisywane; nic, czego nie ma w backupie, nie jest usuwane.
- Wczytanie pliku idzie przez kolejny conditional-import writer/reader (`backup_file_reader/`, analogicznie do ADR-016/ADR-018): native czyta plik z podanej sciezki, web/stub rzuca czytelny `UnsupportedError`.
- UI (ekran "O aplikacji"): pole tekstowe na sciezke pliku (bez file pickera — patrz "Swiadomie pominiete" nizej), przycisk "Wczytaj i zwaliduj", a po udanej walidacji dialog potwierdzenia pokazujacy liczby rekordow per sekcja i jawne ostrzezenie "Rekordy o tych samych ID... zostana nadpisane... Tej operacji nie mozna cofnac" przed faktycznym zapisem.

Swiadomie pominiete (mniejszy zakres, nie architektoniczne "nie da sie"):

- Brak prawdziwego file pickera (`file_picker`/`file_selector`) — uzytkownik wkleja sciezke, ktora i tak zobaczyl po eksporcie. Dodanie file pickera to osobna, przyszla decyzja o nowej zaleznosci, nie blokuje pierwszego dzialajacego importu.
- Brak importu na Web, spojnie z eksportem (ADR-018) i statusem Web jako platformy warunkowej.
- Import nie laczy sie z odczytem/scalaniem "inteligentnym" (np. wykrywaniem konfliktow wersji `revision`) - to nalezy do przyszlego Etapu 10 (sync), nie do prostego przywracania z lokalnego pliku.

Uzasadnienie:

- Rozdzielenie "waliduj" od "zapisz" na dwie osobne, jawne metody wprost realizuje wymog z `DATA_MODEL.md` i daje UI naturalne miejsce na krok potwierdzenia miedzy nimi.
- Merge-by-upsert (zamiast pelnego zastapienia lokalnej bazy) jest bezpieczniejszym domyslnym zachowaniem: przywrocenie starszego backupu nie kasuje danych dodanych po jego utworzeniu, chyba ze maja to samo ID.

## ADR-018: Pierwszy backup JSON

Status: accepted

Kontekst:

- ADR-012D i `docs/DATA_MODEL.md` ("Backup") wymagaly eksportu JSON niezaleznego od legacy, oddzielonego od raportow PDF/CSV. `IMPLEMENTATION_STATUS.md` mial to jako pkt 2 "Nastepny krok".
- Czesc encji (`Client`, `Location` + `LocationContact`/`LocationPowerConnector`, `PowerPreset` + `PowerOutletTemplate`) nie miala jeszcze `toJson`/`fromJson` — tylko `Project` (z pelnym drzewem) i `CatalogDevice` je mialy.

Decyzja:

- Dodano `toJson`/`fromJson` do wszystkich encji, ktorych brakowalo, zeby kazdy top-level agregat dalo sie zserializowac.
- Dodano `AppBackupService` (`infrastructure/backup/`): buduje jeden JSON z `BackupManifest` (`schemaVersion`, `appName`, `appVersion`, `createdAt`, `workspaceId`, `recordCounts`) i sekcja `data` z pelnymi projektami, klientami, lokacjami, katalogiem i presetami.
- `schemaVersion` w manifescie (`appBackupFormatVersion`) jest **niezalezny** od wersji schematu Drift — wersjonuje sam format pliku backupu, nie wewnetrzny schemat SQLite. Nie maja obowiazku byc rownolegle.
- Zapis pliku idzie przez conditional import (`backup_file_writer_native.dart` / `_web.dart` / `_stub.dart`), analogicznie do polaczenia z baza danych (ADR-016): native zapisuje do `Documents/StageCalc/backups/`, web na razie rzuca `UnsupportedError` z czytelnym komunikatem zamiast probowac niepewnego mechanizmu pobierania w przegladarce.
- Wejscie do funkcji: przycisk "Utworz kopie zapasowa (JSON)" na ekranie "O aplikacji" (`AboutScreen`) — to funkcja aplikacyjna, nie projektowa, wiec pasuje tam zgodnie z `docs/DATA_MODEL.md` ("ekran O aplikacji jako funkcja aplikacyjna").
- To jest **eksport-only**. Import backupu (z walidacja przed zapisem, jak wymaga `DATA_MODEL.md`) jest swiadomie poza zakresem tej decyzji.

Uzasadnienie:

- Backup jest podstawowym zabezpieczeniem przed utrata danych i ma powstac przed sync (ADR-012D) — to zostalo zachowane w kolejnosci prac.
- Rozdzielenie wersji formatu backupu od wersji schematu Drift pozwala pozniej zmieniac jedno bez wymuszania zmiany drugiego (np. dodanie pola do backupu bez migracji SQLite).
- Ten sam wzorzec conditional-import co polaczenie z baza (ADR-016) utrzymuje spojnosc w sposobie obslugi roznic platformowych w projekcie.

Znane ograniczenie:

- Backup na Web nie dziala. Wymagalby albo mechanizmu pobierania pliku w przegladarce (Blob + link), albo zaakceptowania, ze na Web funkcja jest niedostepna do czasu realnej potrzeby.

## ADR-017: Pierwsza integracja z PocketBase (push, bez syncu)

Status: accepted

Kontekst:

- LXC 113 (`stagecalc`, 192.168.0.113) ma dzialajacy PocketBase 0.40.4 za Caddy (`/api`, `/_`), bez zadnego schematu i bez konta admina. ADR-012 zostawial backend syncu jako otwarty wybor (PocketBase/Supabase/wlasne API) - PocketBase jest tym, co realnie jest juz postawione.
- Uzytkownik poprosil o pelny schemat kolekcji wedlug `docs/DATA_MODEL.md` oraz o pierwszy prawdziwy push lokalnego `Project` do PocketBase, bez UI i bez obslugi konfliktow.

Decyzja:

- Utworzono w PocketBase 13 kolekcji odzwierciedlajacych 1:1 obecne tabele Drift (nie hipotetyczny przyszly model): `clients`, `locations`, `location_contacts`, `location_power_connectors`, `catalog_devices`, `power_presets`, `power_outlet_templates`, `projects`, `project_groups`, `project_items`, `project_distros`, `project_outlets`, `power_connections`, `project_trusses`. Kazda ma pole `local_id` (unikalny klucz lokalny, nie ten sam co PocketBase `id`) plus `created_at`/`updated_at`/`deleted_at`/`revision`/`deleted` gdzie ma to sens.
- Encje nie majace jeszcze implementacji w aplikacji (Workspace/AppUser, ConnectorTypeDefinition jako kolekcja, tabele nosnosci kratownic, haki grup) **nie zostaly utworzone** - `ConnectorTypeDefinition` pozostaje stalym slownikiem w kodzie (`ConnectorTypes` w `power_models.dart`), zgodnie z tym co `DATA_MODEL.md` juz sugerowal ("na start moze byc seedowany jako dane stale aplikacji").
- Dodano `PocketBaseProjectSyncService` (`features/projects/data/pocketbase_project_sync_service.dart`): jednokierunkowy push jednego `Project` z pelnym drzewem (grupy, pozycje, rozdzielnice, gniazda, polaczenia, kratownice) plus opcjonalny `Client`/`Location`. Upsert po `local_id` (idempotentny - ponowny push aktualizuje te same rekordy zamiast tworzyc duplikaty), ale **bez wykrywania konfliktow** i **bez odczytu z powrotem do lokalnej bazy**.
- Adres backendu (`PocketBaseClientProvider`) jest na razie zahardkodowany na `http://192.168.0.113` - nie ma jeszcze ekranu ustawien do jego konfiguracji.
- Dowod dzialania: `flutter/tool/push_demo_project.dart` (`dart run tool/push_demo_project.dart`) - pushuje projekt demo i wypisuje zdalne ID. Zweryfikowano recznie w PocketBase, ze rekordy i relacje (`project` -> `project_groups` -> `project_items` itd.) sa poprawne, oraz ze podwojne uruchomienie nie tworzy duplikatow.

Uzasadnienie:

- Schemat 1:1 z obecnymi tabelami Drift, a nie z pelnym `DATA_MODEL.md`, unika projektowania kolekcji pod funkcje ktore jeszcze nie istnieja w aplikacji (kratownice - haki/tabele nosnosci, konta/role) - dokladnie ten typ przedwczesnej abstrakcji, ktorego projekt ma unikac.
- Push zamiast pelnego dwukierunkowego syncu jest swiadomie minimalnym pierwszym krokiem: dowodzi, ze polaczenie i mapowanie modelu dzialaja, bez podejmowania jeszcze decyzji o strategii rozwiazywania konfliktow (to osobna, wieksza decyzja projektowa).

Ryzyka i znane ograniczenia (do adresowania, zanim to wyjdzie poza prywatna siec LAN):

- **Wszystkie reguly dostepu kolekcji sa puste (publiczne)** - kazdy z dostepem do `http://192.168.0.113` moze czytac/tworzyc/edytowac/usuwac dowolny rekord bez logowania. Akceptowalne tylko w obecnej, prywatnej sieci LAN, do czasu zaprojektowania prawdziwego modelu autoryzacji.
- Push nie usuwa po stronie PocketBase rekordow, ktore lokalnie zostaly soft-deleted (`deletedAt`) - `deleted`/`deleted_at` istnieja w schemacie, ale serwis jeszcze ich nie ustawia.
- Brak odczytu/importu z PocketBase - to tylko kierunek lokalne -> zdalne.

## ADR-016: Wsparcie lokalnej bazy na Web (Drift + sqlite3 wasm)

Status: accepted

Kontekst:

- `flutter build web` nie kompilowal sie w ogole: `app_database.dart` uzywal `dart:io` (`File`, `getApplicationDocumentsDirectory`) i `NativeDatabase` z Drift, co pod spodem wymaga `dart:ffi` - niedostepnego w kompilacji na web (dart2js/wasm). Aplikacja nigdy nie miala dzialajacej sciezki bazy danych na Web, mimo ze ADR-011 to przewidywal ("Web pozostaje platforma warunkowa... adapter Drift web").

Decyzja:

- Rozdzielono polaczenie z baza na trzy pliki w `infrastructure/local_database/connection/` wybierane przez conditional import (`connection_stub.dart` / `connection_native.dart` / `connection_web.dart`), spinane przez `connection/connection.dart`. `app_database.dart` nie zawiera juz zadnego kodu specyficznego dla platformy.
- Native (`dart.library.io`): bez zmian, `NativeDatabase.createInBackground` na pliku w katalogu dokumentow.
- Web (`dart.library.js_interop`): `drift/wasm.dart` (`WasmDatabase.open`) z `sqlite3.wasm` i `drift_worker.js` skopiowanymi do `web/` (pliki binarne, nie sa czescia zrodel Dart - trzeba je podmieniac przy kazdej istotnej podmianie wersji `drift`/`sqlite3`).
- Dodano `sqlite3` jako bezposrednia zaleznosc (wymagane przez `package:sqlite3/wasm.dart`), usunieto `sqlite3_flutter_libs` (od wersji 0.6.0 pakiet jest pustym no-opem, jego wlasny README zaleca usuniecie po migracji na `sqlite3` v3.x).

Uzasadnienie:

- Zgodnie z ADR-011: web ma dzialac przez Drift + sqlite3 wasm, nie osobna implementacje IndexedDB.
- Podzial przez conditional import pozwala trzymac jeden model domenowy i jeden `AppDatabase`, bez duplikowania logiki tabel/migracji per platforma.

Znane ograniczenie (do rozwiazania pozniej, patrz PS niżej):

- `WasmDatabase.open` probuje wybrac najbardziej trwala implementacje storage (OPFS), ale OPFS/`SharedArrayBuffer` wymagaja bezpiecznego kontekstu przegladarki (HTTPS lub `localhost`). Serwer LXC 113 (`stagecalc`, 192.168.0.113) obecnie nie ma domeny ani TLS, wiec przegladarka spada do `sharedIndexedDb` - dziala, ale zapisy moga zostac utracone przy twardym odswiezeniu/awarii karty tuz po zapisie (zweryfikowane empirycznie: nowo dodany projekt znikal po `location.reload()` mimo widocznego komunikatu "Projekt zapisany lokalnie"). Uzytkownik swiadomie zaakceptowal to ryzyko do czasu, az pojawi sie domena i mozliwosc automatycznego Let's Encrypt w Caddy. Gdy domena bedzie dostepna, dodac w bloku SPA Caddyfile naglowki `Cross-Origin-Opener-Policy: same-origin` i `Cross-Origin-Embedder-Policy: require-corp`, co odblokuje OPFS.

## ADR-015: Rozbicie ProjectEditorScreen na kontroler i widoki

Status: accepted

Kontekst:

- `project_editor_screen.dart` urosl do ok. 3900 linii i stal sie dokladnie tym "nadmiernie duzym komponentem kalkulatora", ktory ADR-001 i `FEATURE_SCOPE.md` (sekcja "Elementy do pominiecia lub przeprojektowania") wskazuja jako wzorzec do unikniecia przy migracji z legacy.
- Plik laczyl w jednym miejscu: stan UI (`_view`, `_hasChanges`), ladowanie referencji (klienci, lokacje, presety) bezposrednio z repozytoriow Drift, wszystkie mutacje projektu (dodawanie/edycja/usuwanie grup, pozycji, rozdzielnic, polaczen), wywolania serwisow obliczeniowych w `build()` i ok. 15 prywatnych klas dialogow/kart.
- Brak wydzielonej warstwy sprawil, ze blad "osieroconych polaczen" (usuniecie grupy bez usuniecia jej `PowerConnection`, dokladnie ten sam problem co w legacy, opisany w `docs/legacy_stagecalc_debug_context.md`) przeszedl niezauwazony: logika usuwania grupy i rozdzielnicy byla zduplikowana w dwoch miejscach zamiast zyc w jednym testowalnym miejscu.

Decyzja:

- Wprowadzic `ProjectEditorController` (`ChangeNotifier`) w `features/projects/presentation/project_editor_controller.dart`, ktory:
  - trzyma stan edytora: biezacy `Project`, liste klientow/lokacji/presetow, flage `hasChanges`, tryb widoku,
  - laduje referencje z repozytoriow,
  - wykonuje wszystkie mutacje projektu (dodaj/edytuj/usun grupe, pozycje, rozdzielnice, gniazda, polaczenia) i zapisuje przez `ProjectRepository`,
  - udostepnia jako gettery wyniki `ProjectTotalsService`, `PowerCalculationService` i `PatchValidationService` przeliczone z biezacego stanu.
- `ProjectEditorScreen` zostaje cienkim widokiem: pokazuje dialogi (bo tylko widok ma `BuildContext`), a wynik dialogu przekazuje do metody kontrolera. Widok nie wykonuje juz samodzielnie logiki czyszczenia powiazanych rekordow.
- Klasy dialogow i kart (`_DistroCreateDialog`, `_ConnectionDialog`, `_OutletEditDialog`, `_GroupCard`, `_ConnectionCard` itd.) zostaja przeniesione z jednego pliku do osobnych plikow w `features/projects/presentation/project_editor/`, pogrupowane tematycznie (rozdzielnice, polaczenia, grupy/pozycje, metadane projektu), zamiast zyc w jednym pliku 1:1 z ekranem.
- Nie wprowadzamy nowej zaleznosci do zarzadzania stanem (np. Riverpod/Bloc) na tym etapie — `ChangeNotifier` z Fluttera wystarcza i nie zwieksza powierzchni zaleznosci projektu.

Uzasadnienie:

- Zgodnosc z ADR-001: rozdzielenie `domain`/`data`/`presentation` mialo dotyczyc rowniez najwiekszego ekranu aplikacji, nie tylko nowych funkcji.
- Logika mutacji projektu (np. "usuniecie grupy usuwa tez jej polaczenia") staje sie mozliwa do przetestowania niezaleznie od drzewa widgetow i bez duplikacji miedzy operacjami.
- Mniejsze, tematyczne pliki prezentacji latwiej przegladac i code-review'owac niz jeden plik na 3900 linii.

Konsekwencje:

- Widoki nie moga juz zakladac, ze maja bezposredni dostep do repozytoriow — wywoluja metody kontrolera.
- Kazda nowa operacja na projekcie (dodanie kolejnego typu mutacji) powinna trafiac do `ProjectEditorController`, nie bezposrednio do widgetu ekranu.
- Testy widgetowe edytora projektu pozostaja aktualne, poniewaz zachowanie UI (teksty, dialogi, przeplyw) sie nie zmienia — zmienia sie tylko miejsce, w ktorym zyje logika.

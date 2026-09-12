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

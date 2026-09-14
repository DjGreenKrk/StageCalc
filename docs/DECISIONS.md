# StageCalc Flutter Migration - Decisions

## Cel dokumentu

Ten dokument zbiera proponowane decyzje architektoniczne dla migracji StageCalc do Flutter + Dart. Status `proposed` oznacza rekomendacje do zatwierdzenia przed implementacją.

## ADR-001: Flutter jako czysta aplikacja domenowa

Status: proposed

Decyzja:

- Nie przenosić struktury Next.js/React 1:1.
- Nie zachowywać kompatybilności ze strukturami legacy, jeśli nie zostanie to osobno zlecone.
- Zbudować Fluttera jako czystą aplikację z rozdzieleniem warstw:
  - `features/<feature>/domain`,
  - `features/<feature>/data`,
  - `features/<feature>/presentation`,
  - `infrastructure`,
  - `shared`.

Uzasadnienie:

- Obecna aplikacja działa, ale największy komponent kalkulatora łączy UI, pobieranie danych, zapisywanie i obliczenia.
- Flutter powinien przejąć wymagania, nie kształt komponentów React.

## ADR-002: Offline-first od pierwszego dnia

Status: proposed

Decyzja:

- Lokalna baza jest źródłem prawdy.
- Synchronizacja online zostanie dodana jako osobna warstwa później.
- Każda encja dostaje pola potrzebne do sync: `revision`, `syncState`, `remoteId`, `deletedAt`.
- Statusy sync w modelu Flutter: `localOnly`, `pendingSync`, `synced`, `syncError`, `conflict`.

Uzasadnienie:

- Docelowe platformy obejmują Android i Windows, gdzie praca bez sieci jest realnym scenariuszem produkcyjnym.
- Późniejszy sync bez pól metadanych wymusiłby bolesną migrację.

## ADR-003: Project zamiast Calculation

Status: proposed

Decyzja:

- W domenie Fluttera używać nazwy `Project`.
- Jeśli import legacy zostanie kiedyś dodany, mapowanie `Calculation -> Project` będzie częścią osobnego modułu importu.

Uzasadnienie:

- Obecna `Calculation` jest w praktyce projektem technicznym, zawiera zasilanie, kratownice, klienta, lokacje i docelowo fazy.
- Brak wymogu kompatybilności pozwala od razu nazwać model zgodnie z domeną.

## ADR-003A: Legacy jako źródło wymagań, nie kontrakt

Status: proposed

Decyzja:

- Legacy StageCalc służy do zrozumienia funkcji, obliczeń i problemów użytkownika.
- Nowy Flutter nie musi wspierać starych formatów danych, starych nazw pól, starych tras ani importu PocketBase w MVP.
- Każde wymaganie kompatybilności legacy musi być dodane jako osobna decyzja i osobny zakres prac.

Uzasadnienie:

- Użytkownik wskazał, że na tym etapie kompatybilność z wersjami legacy nie jest wymagana.
- Pozwala to uprościć model offline-first i uniknąć przenoszenia długu technicznego.

## ADR-004: Fazy projektu jako model, nie funkcja MVP

Status: proposed

Decyzja:

- Dodać `ProjectPhase` i `phaseId` do bytów projektowych.
- W MVP automatycznie tworzyć jedną fazę domyślną.
- Nie implementować jeszcze UI ani logiki workflow faz.

Uzasadnienie:

- Użytkownik wymaga miejsca na późniejsze fazy.
- Wczesne dodanie `phaseId` jest tanie, późniejsze dodanie byłoby migracją przekrojową przez cały model.

## ADR-005: Runtime Distro jako osobny byt

Status: proposed

Decyzja:

- Rozdzielić:
  - urządzenie katalogowe rozdzielnicy,
  - preset gniazd,
  - konkretną instancję rozdzielnicy w projekcie.
- Wprowadzić `ProjectDistro` i `ProjectOutlet`.

Uzasadnienie:

- Obecne `sourceDeviceId` czasem oznacza ID rozdzielnicy w projekcie, a czasem sugeruje urządzenie katalogowe.
- Precyzyjne nazewnictwo zmniejszy ryzyko błędów w obliczeniach i synchronizacji.

## ADR-006: Połączenia jako dane domenowe

Status: proposed

Decyzja:

- `PowerConnection` ma być pełnoprawną encją lokalnej bazy.
- Nie zapisywać połączeń jako ukryty stan UI.
- Nie kasować wszystkich połączeń przy każdym zapisie projektu.

Uzasadnienie:

- Połączenia są kluczowe dla obliczeń fazowych.
- Offline-first wymaga inkrementalnych zmian, historii rewizji i możliwości sync.

## ADR-007: Zachować Model B+, zostawić drogę do Modelu C

Status: proposed

Decyzja:

- Pierwsza wersja Flutter zachowuje obecny kompromis:
  - grupa `singlePhase`,
  - grupa `threePhaseSymmetric`,
  - `selectedPhases` dla gniazd `All`.
- W `PowerConnection` zostawić opcjonalne `targetItemIds` na późniejsze mapowanie konkretnych pozycji.

Uzasadnienie:

- Model B+ jest już częściowo obecny i rozwiązuje dużą część problemów fazowych.
- Pełny Model C jest lepszy technicznie, ale może spowolnić workflow i znacznie powiększyć MVP.

## ADR-008: Snapshot danych katalogowych w projekcie

Status: proposed

Decyzja:

- `ProjectItem` zapisuje snapshot nazwy, producenta, kategorii, mocy, prądu i masy.
- `catalogDeviceId` pozostaje jako link do aktualnego katalogu.

Uzasadnienie:

- Historyczna kalkulacja nie powinna zmieniać wyników tylko dlatego, że poprawiono katalog.
- Użytkownik może później ręcznie odświeżyć snapshoty, jeśli tego chce.

## ADR-009: Jedna tabela katalogu z danymi kategorii

Status: proposed

Decyzja:

- W lokalnym modelu preferować jedną tabelę `DeviceCatalogItem`.
- Specyficzne pola kategorii trzymać w strukturze `categoryData` lub powiązanych tabelach dla najbardziej relacyjnych danych, np. tabele nośności kratownic.

Uzasadnienie:

- Obecny podział na kolekcje kategorii utrudnia wyszukiwanie, import i wspólny katalog w UI.
- Flutter/Dart zyska prostszy model list i filtrów.

## ADR-010: Warstwa obliczeń jako czysty Dart

Status: proposed

Decyzja:

- Obliczenia zasilania i kratownic zaimplementować jako czyste serwisy domenowe bez zależności od Flutter UI i bazy.

Uzasadnienie:

- Łatwe testy jednostkowe.
- Mniejsze ryzyko regresji przy przebudowie UI.
- Możliwość użycia tej samej logiki w eksporcie, walidacji i widokach.

## ADR-011: Lokalna baza i kompatybilność platform

Status: accepted

Decyzja:

- Docelowa lokalna baza StageCalc: Drift + SQLite.
- Drift/SQLite będzie główną implementacją offline-first dla:
  - Android,
  - Windows,
  - iOS, jeśli zostanie dodany,
  - macOS/Linux, jeśli kiedyś będą potrzebne.
- Web pozostaje platformą warunkową:
  - preferować adapter Drift web, jeśli ograniczenia będą akceptowalne,
  - w razie problemów przygotować osobną implementację repozytoriów na IndexedDB.
- `shared_preferences` pozostaje tylko warstwą przejściową/prototypową dla obecnego etapu.
- Nie wybierać Hive jako głównej bazy domenowej, ponieważ model StageCalc jest relacyjny.
- Nie wybierać ObjectBox/Isar jako głównej bazy na tym etapie, ponieważ synchronizacja z przyszłą hostowaną bazą będzie prostsza przy jawnych tabelach, migracjach SQL i relacjach.

Uzasadnienie:

- Android i Windows są najważniejsze.
- StageCalc będzie miał dużo relacji:
  - projekty,
  - fazy,
  - grupy,
  - pozycje,
  - katalog,
  - klienci,
  - lokacje,
  - rozdzielnice,
  - gniazda,
  - połączenia,
  - kratownice,
  - rekordy sync.
- Przyszła hostowana baza danych będzie wymagała:
  - stabilnych ID,
  - rewizji rekordów,
  - soft delete,
  - kolejek synchronizacji,
  - zapytań po `updatedAt`, `syncState`, `workspaceId`, `remoteId`,
  - transakcji przy zapisie projektu i połączeń.
- Drift daje:
  - jawny schemat,
  - migracje,
  - transakcje,
  - typowane zapytania,
  - testowalną warstwę data,
  - dobry model pod offline-first i późniejszy sync.
- Web/iOS są możliwe, ale nie powinny blokować poprawnego modelu offline-first dla Android/Windows.

Konsekwencje:

- Kolejny etap implementacji powinien przenieść projekty i katalog ze `shared_preferences` do Drift.
- Repozytoria domenowe zostają za interfejsami, żeby UI nie zależał bezpośrednio od Drift.
- Schemat bazy musi od początku zawierać pola synchronizacyjne:
  - `id`,
  - `workspaceId`,
  - `remoteId`,
  - `createdAt`,
  - `updatedAt`,
  - `deletedAt`,
  - `revision`,
  - `syncState`,
  - `lastSyncedAt`.
- Synchronizacja z hostowaną bazą będzie osobną warstwą nad lokalną bazą, a nie zamiennikiem lokalnej bazy.

## ADR-012: Import legacy poza MVP

Status: proposed

Decyzja:

- Nie przygotowywać importera JSON/PocketBase jako wymagania MVP.
- Zachować możliwość dodania importera później, jeśli pojawi się realna potrzeba przeniesienia danych.
- Nie uzależniać Fluttera od PocketBase jako głównego runtime backendu.

Uzasadnienie:

- Aktualny StageCalc jest źródłem wymagań, ale nowa aplikacja ma być czystsza.
- Sync może później użyć PocketBase, Supabase, własnego API lub innego mechanizmu.
- Brak kompatybilności legacy zmniejsza ryzyko i zakres pierwszej wersji.

## ADR-012A: GreenCrew Branding jako wymaganie produktu

Status: proposed

Decyzja:

- StageCalc Flutter musi być zgodny z dokumentami GreenCrew Tools:
  - `GREENCREW_BRANDING.md`,
  - `DESIGN_SYSTEM.md`,
  - `ICONOGRAPHY.md`,
  - `WRITING_GUIDELINES.md`,
  - `BRANDING_STAGECALC.md`,
  - `FLUTTER_STANDARDS.md`.
- Domyślny wygląd:
  - dark mode,
  - czarne tło,
  - neutralne powierzchnie,
  - GreenCrew Green jako główny akcent,
  - Material Design,
  - Material Icons/Symbols.
- Ikona aplikacji: heksagon GreenCrew z geometryczną błyskawicą.
- Komunikaty w aplikacji: krótkie, techniczne, po polsku.

Uzasadnienie:

- StageCalc ma być częścią rodziny GreenCrew Tools, a nie samodzielną aplikacją o przypadkowym stylu.
- Branding definiuje praktyczny, terenowy charakter produktu i powinien kierować projektowaniem UI od pierwszego ekranu.

## ADR-012B: Telefon-first i responsywność

Status: proposed

Decyzja:

- Platforma referencyjna dla UI to Android/telefon.
- Tablet powinien używać układów dwukolumnowych lub Navigation Rail.
- Windows/Web powinny używać sidebar/master-detail i tabel tylko tam, gdzie pomagają.
- Progi robocze:
  - telefon: do 600 px,
  - tablet: 600-1024 px,
  - desktop: powyżej 1024 px.

Uzasadnienie:

- GreenCrew Tools są projektowane do pracy w terenie, często na małym ekranie i pod presją czasu.
- Ekran, który działa dobrze na telefonie, łatwiej rozszerzyć na desktop niż odwrotnie.

## ADR-012C: Logowanie nie blokuje pracy lokalnej

Status: proposed

Decyzja:

- MVP StageCalc nie wymaga logowania do podstawowej pracy.
- Konto/synchronizacja może pojawić się później jako warstwa dodatkowa.
- Dane lokalne muszą pozostać dostępne bez serwera.

Uzasadnienie:

- GreenCrew Architecture mówi, że aplikacja offline nie powinna być bezużyteczna bez logowania.
- StageCalc ma działać podczas wydarzeń i konsultacji technicznych, także bez Internetu.

## ADR-012D: Backup i eksport danych

Status: proposed

Decyzja:

- Aplikacja powinna mieć backup danych w nowym formacie, niezależnym od legacy.
- Preferowany backup: JSON lub ZIP z JSON i załącznikami.
- Backup jest oddzielony od raportów technicznych PDF/CSV/XLSX.

Uzasadnienie:

- Dane projektowe są ważne i nie mogą istnieć wyłącznie jako ukryta baza lokalna.
- Backup jest podstawowym zabezpieczeniem przed utratą danych przed wdrożeniem sync.

## ADR-012E: Uprawnienia systemowe minimalne

Status: proposed

Decyzja:

- Aplikacja prosi tylko o uprawnienia potrzebne do konkretnej funkcji.
- Dostęp do plików jest potrzebny dopiero przy imporcie/eksporcie/backupie.
- Brak dostępu do lokalizacji, zdjęć lub kontaktów w MVP, chyba że funkcja zostanie jawnie dodana.

Uzasadnienie:

- Narzędzie terenowe powinno być przewidywalne i nie prosić o niepotrzebne uprawnienia.

## ADR-012F: Nazewnictwo release

Status: proposed

Decyzja:

- Artefakty release nazywać według wzoru `StageCalc-vX_Y_Z-platform.ext`.
- Przykład: `StageCalc-v1_0_0-android.apk`, `StageCalc-v1_0_0-windows.zip`.

Uzasadnienie:

- Standard GreenCrew wymaga spójnych nazw artefaktów.

## ADR-013: Tekst rich-text

Status: proposed

Decyzja:

- Notatki przechowywać jako Markdown albo sanitizowany HTML z jasną decyzją przed implementacją.
- Dla MVP preferowany Markdown.

Uzasadnienie:

- Obecna aplikacja używa edytora rich text i HTML. Flutter łatwiej utrzyma bezpiecznie w Markdown.
- Ewentualny przyszły import legacy może konwertować HTML do tekstu/Markdown albo zachować HTML jako wartość techniczną importu.

## ADR-014: PDF jako eksport warstwy aplikacyjnej

Status: proposed

Decyzja:

- Eksport PDF nie powinien mieszkać w widokach.
- Zbudować serwis `ProjectReportService`, który pobiera wynik obliczeń i generuje raport.

Uzasadnienie:

- Obecnie PDF jest częścią dużego komponentu kalkulatora.
- W Flutterze raport powinien używać tych samych serwisów domenowych co UI.

## ADR-034: Import listy sprzętu z Gremium Panel

Status: accepted

Kontekst:

- Gremium Panel (zewnętrzny system magazynowy/checklistowy używany przez użytkownika) eksportuje planowaną listę sprzętu wydarzenia jako jeden plik JSON (`gremium.stagecalc.pack-list`, `formatVersion: "1.0"`) - pełny kontrakt formatu, wraz z przykładowym plikiem, dostarczył użytkownik w `docs/Gremium import/Import_details.md`.
- Użytkownik poprosił o zaprojektowanie tej integracji i doprecyzował trzy istotne wymagania ponad to, co sam dokument opisuje wprost: (1) nie każda pozycja z checklisty Gremium ma trafić do StageCalc, więc import musi pokazać pełną listę do przejrzenia i odznaczenia zbędnych pozycji, zanim cokolwiek zostanie zapisane; (2) urządzenia i pozycje pochodzące z Gremium mają stać się w pełni natywnymi rekordami StageCalc, nieodróżnialnymi od dodanych ręcznie, jedynie z dopisanym id z systemu Gremium jako zwykłą kolumną - bez żadnej osobnej tabeli powiązań/mapowań ani osobnej "kategorii" importowanych urządzeń; (3) dla pozycji, których Gremium nie potrafi dopasować do katalogu StageCalc, użytkownik musi mieć możliwość ręcznego połączenia jej z urządzeniem, które już ma w swojej bibliotece (np. ręcznie dodaną wcześniej lampą), żeby import nie tworzył bezsensownych duplikatów.

Decyzja:

- Nowy moduł `features/gremium_import/` (domain/presentation, zgodnie z ADR-001): `GremiumImportParser` (parsowanie i walidacja pliku - blokujące błędy: niepoprawny JSON, zła `schema`, nieobsługiwana główna wersja `formatVersion`, brak `project.id`/`project.name`/`items`, pozycja bez nazwy albo z ilością ≤ 0; brak masy/danych elektrycznych NIGDY nie blokuje importu), `GremiumCatalogMatcher` (dopasowanie do katalogu wyłącznie po zapamiętanym id Gremium, nigdy po samej nazwie) i `GremiumImportCommitService` (zapis - patrz niżej).
- **Id z Gremium jako zwykłe, natywne kolumny na istniejących encjach, nie osobna tabela powiązań** - `CatalogDevice.gremiumInventoryItemId`, `Project.gremiumProjectId`, `ProjectItem.gremiumLineId` (wszystkie `String?`, `null` dla każdego rekordu nie powiązanego z Gremium). To dokładnie ten sam wzorzec, jaki `CatalogDevices`/`Projects`/itd. już mają dla `remoteId` (id w PocketBase, ADR-017) - nullable kolumna tekstowa wprost na rekordzie zamiast osobnego mechanizmu synchronizacji. Schemat lokalny podniesiony do wersji `17` (trzy nowe, niezależne od siebie kolumny dodane jednym krokiem migracji `_addColumnIfMissing`, ten sam idiom co blok `if (from < 14)` z ADR-028).
- **Jeden interaktywny panel przeglądu (`GremiumImportReviewScreen`), pokazywany zaraz po wczytaniu i dopasowaniu pliku, zanim cokolwiek zostanie zapisane**: każda pozycja ma checkbox "importuj" (domyślnie zaznaczony, odznaczenie całkowicie wyklucza pozycję z importu), edytowalne pole grupy docelowej (domyślnie jedna wspólna grupa nazwana po projekcie Gremium, z akcją "Przypisz zaznaczone do grupy" dla wielu pozycji naraz), a dla pozycji bez istniejącego dopasowania katalogowego - wybór **kategorii z już istniejącego, zamkniętego enuma `CatalogDeviceCategory`** (Oświetlenie/Nagłośnienie/Multimedia/Rozdzielnia/Kabel/Rigging/Inne - te same siedem kategorii co wszędzie indziej w katalogu, żadna nowa "kategoria Gremium"; zgadywana domyślnie z tekstu kategorii/nazwy Gremium przez `guessGremiumCategory`, zawsze poprawialna) ORAZ przycisk "Połącz z istniejącym", który otwiera wyszukiwarkę po obecnym katalogu (`GremiumLinkDeviceDialog`, lekki, samodzielny dialog - nie próbowano na siłę reużywać prywatnego `_CatalogSelectionDialog` z edytora projektu, zgodnie z precedensem ADR-029's `_QuickConnectDialog`). Wybranie istniejącego urządzenia dopisuje mu `gremiumInventoryItemId` zamiast tworzyć duplikat. Podsumowanie na dole ekranu liczy się na żywo wyłącznie z aktualnie zaznaczonych wierszy (w tym listę "wymaga uzupełnienia mocy/prądu") - odznaczony kabel nigdy nie wygeneruje ostrzeżenia o brakującej mocy.
- **Pierwsza wersja tej decyzji wprowadziła osobny enum `GremiumDeviceType` (odbiornik 1F/3F, urządzenie pasywne, kabel, element riggingowy) jako pośrednią warstwę między pozycją Gremium a kategorią katalogową - użytkownik to poprawił**: "Utwórz jako" nie powinno wymyślać nowej taksonomii, tylko przypisywać wprost do kategorii, które już istnieją w katalogu. Poprawka: `GremiumDeviceType` usunięty; "Utwórz jako" wybiera bezpośrednio `CatalogDeviceCategory`. Reguła "co liczy się jako brak danych" (moc/prąd wymagane, punkty podwieszenia opcjonalne) przeniesiona z osobnej logiki per-typ na współdzieloną regułę `CatalogDeviceCategoryFields.showsElectricalFields`/`showsRiggingPoints` (nowe rozszerzenie w `catalog_device.dart`) - dokładnie te same reguły widoczności pól, które formularz katalogu już stosuje per kategoria (ADR-031: rigging i kabel nie pokazują mocy/prądu/punktów podwieszenia, reszta kategorii pokazuje). Lista "wymaga uzupełnienia" w panelu przestała osobno liczyć brakujące punkty podwieszenia - to pole jest opcjonalne wszędzie indziej w aplikacji (nigdy nie jest wymagane na ekranie Katalog), więc nie powinno być wymuszane tylko w tym jednym miejscu.
- **Nieznane urządzenia bez ręcznego połączenia: masowe utworzenie w tle, bez blokującego kreatora krok-po-kroku.** Przy dużej liście (np. 29 nowych pozycji w przykładowym pliku od użytkownika) kreator pytający o komplet danych dla każdej pozycji z osobna byłby bardzo długim procesem. Zamiast tego `GremiumImportCommitService` tworzy `CatalogDevice` od razu z tego, co Gremium podało (nazwa, masa, zgadywana kategoria z wybranego typu), zerami/`null` tam gdzie brakuje danych - listę pozycji nadal wymagających uzupełnienia widać w panelu przed importem, a po imporcie można je swobodnie poprawić na zwykłym ekranie Katalogu.
- **Docelowy projekt**: szukany po `gremiumProjectId == packList.project.id` - jeśli istnieje, aktualizowany; jeśli nie, tworzony nowy (bez klienta/lokacji, jak przy zwykłym "Dodaj projekt"). Zapis całego drzewa projektu jednym wywołaniem `ProjectRepository.saveProject` (ten sam wzorzec reconciliacji co ADR-026), wykonywany "headless" bez otwartego `ProjectEditorController`, analogicznie do `AppBackupImportService.import()`.
- **Ponowny import tego samego projektu**: pozycje dopasowywane po `gremiumLineId`. Pozycja nadal obecna w nowym pliku i zaznaczona w panelu - aktualizowana jest tylko `quantity` (i grupa, jeśli zmieniona w panelu), **nigdy** `powerWSnapshot`/`currentASnapshot`/`weightKgSnapshot`/inne pola, które użytkownik mógł już ręcznie poprawić w StageCalc. Pozycja, która zniknęła z nowego pliku albo została odznaczona - usuwana z projektu.
- Wydzielono `infrastructure/files/local_file_reader/` (`readLocalTextFile`, warianty native/web/stub) jako neutralnie nazwaną wersję dotychczasowego `backup_file_reader/` (ADR-019) - ten sam plik-czytający-String trójkąt, tylko bez nazwy przywiązanej do backupu, żeby nie duplikować go po raz trzeci (ten sam argument co uzasadnił ADR-021). `AppBackupImportService` przepięty na wspólną wersję; stary `backup_file_reader/` usunięty.

Uzasadnienie:

- Natywne kolumny (zamiast osobnej tabeli powiązań) były jawnym wymogiem użytkownika: zaimportowane rekordy mają być zwykłymi rekordami StageCalc, nie osobną kategorią bytów - a `remoteId` już dowodzi, że ten wzorzec (nullable kolumna referencji do zewnętrznego systemu wprost na rekordzie) sprawdza się w tym schemacie.
- Panel przeglądu przed zapisem (zamiast importu "na ślepo") był drugim jawnym wymogiem użytkownika - realna checklista magazynowa z Gremium może zawierać sprzęt, który nie ma trafić do konkretnego projektu StageCalc.
- Ręczne łączenie z istniejącym urządzeniem był trzecim jawnym wymogiem użytkownika - bez tego każdy import dubluje urządzenia już ręcznie skatalogowane wcześniej, tylko bez zapamiętanego id Gremium.
- Braki danych elektrycznych liczone per kategoria katalogowa (nie ślepe "czy pole jest puste") odzwierciedla uwagę użytkownika, że np. kabel nigdy nie będzie miał sensownej mocy w watach - liczenie tego jako braku byłoby fałszywym alarmem. Reużycie reguły widoczności pól z formularza katalogu (zamiast osobnej reguły per wymyślony typ) jest zarazem prostsze i z definicji spójne z tym, jak te same kategorie zachowują się wszędzie indziej w aplikacji.

Konsekwencje:

- Dodanie trzech nowych, niezależnych kolumn `gremium*` do trzech różnych tabel to jednorazowy, addytywny koszt schematu - żadna z nich nie wymaga wypełnienia dla rekordów nie pochodzących z Gremium.
- Zgadywanie typu urządzenia/kategorii z wolnego tekstu Gremium jest z założenia niedoskonałe (Gremium ma własną, niezależną taksonomię kategorii) - zawsze poprawialne ręcznie w panelu przed importem albo później na ekranie Katalog.
- `local_file_reader/` jest teraz jedynym miejscem czytającym lokalny plik tekstowy po ścieżce - każda przyszła funkcja importu (kolejny zewnętrzny system, inny format) powinna go reużyć zamiast dodawać czwarty niemal identyczny trójkąt plików.

## ADR-033: Font Roboto w PDF i pełne polskie znaki diakrytyczne

Status: accepted

Kontekst:

- ADR-027 świadomie wybrała domyślne fonty PDF (Helvetica), argumentując, że cały tekst aplikacji był wtedy pisany bez polskich znaków diakrytycznych, więc brak wsparcia Unicode nie miał znaczenia praktycznego.
- Użytkownik poprosił o pełny przegląd projektu pod kątem brakujących polskich znaków, a następnie doprecyzował, że celem nie jest ujednolicenie na ASCII, tylko odwrotnie: dodanie właściwych polskich znaków diakrytycznych (ą, ć, ę, ł, ń, ó, ś, ź, ż) w całym UI Fluttera i w dokumentacji sesji. Zapytany o zakres, wybrał: najpierw dodać do eksportu PDF font z pełnym wsparciem Unicode, dopiero potem wprowadzać znaki diakrytyczne wszędzie; zakres znaków diakrytycznych ograniczony do UI Fluttera i dokumentacji sesji (bez komentarzy w kodzie i bez opisów testów); dla dokumentacji - pełne przepisanie istniejącej treści, nie tylko nowych wpisów.

Decyzja:

- Do `flutter/assets/fonts/` dodano prawdziwe pliki fontu Roboto (`Roboto-Regular.ttf`, `Roboto-Bold.ttf`, wersja statyczna, nie zmienna - pakiet `pdf` nie potrafi wybierać wag z fontu zmiennego) wraz z licencją `Roboto-OFL.txt` (OFL-1.1), zadeklarowane jako `assets` w `pubspec.yaml`.
- `ProjectPdfReportService.buildPdfReport` ładuje oba pliki przez `rootBundle.load()` i buduje `pw.ThemeData.withFont(base: ..., bold: ...)`, podpięte do `pw.Document(theme: ...)` - każdy `pw.TextStyle(fontWeight: pw.FontWeight.bold)` używany dalej w dokumencie automatycznie korzysta z fontu pogrubionego z motywu, bez podawania `font:` w każdym miejscu z osobna.
- Po dodaniu fontu wprowadzono pełne polskie znaki diakrytyczne w całym UI Fluttera (warstwa prezentacji i odpowiednie miejsca warstwy infrastruktury) oraz w pięciu dokumentach sesji: `docs/FEATURE_SCOPE.md`, `docs/CATALOG_IMPORT_GUIDE.md`, `CHANGELOG.md`, `docs/IMPLEMENTATION_STATUS.md`, ten dokument. Dokumenty `docs/greencrew_docs/**` i `docs/legacy_*.md` pozostają poza zakresem - istniały już w pełnej polskiej pisowni od pierwotnego autora, w innej konwencji, i nie mają być dotykane.
- Testy widgetowe (`test/widget_test.dart`) i testy serwisów raportów zaktualizowane pod nowe, zaakcentowane teksty; test `project_pdf_report_service_test.dart` dostał `TestWidgetsFlutterBinding.ensureInitialized()`, wymagane przez `rootBundle.load()` poza drzewem widgetów.

Uzasadnienie:

- Font najpierw, znaki potem (kolejność wybrana przez użytkownika) unika sytuacji, w której PDF przez pewien czas renderowałby znaki diakrytyczne jako puste kwadraty/znaki zastępcze - Helvetica z bazy 14 fontów PDF nie ma pełnego wsparcia Unicode.
- Prawdziwe polskie znaki w UI i dokumentacji są tym, czego użytkownik chciał od początku - pierwotne założenie "ASCII jest celową konwencją" było błędną interpretacją z mojej strony, poprawioną wprost przez użytkownika.
- Pełne przepisanie istniejącej dokumentacji (zamiast tylko nowych wpisów) było jawnym wyborem użytkownika, mimo kosztu (pięć plików, łącznie około 1900 linii) - częściowa konwersja zostawiłaby dokumentację w mieszanym, niespójnym stanie.

Konsekwencje:

- Rozmiar assetów aplikacji rośnie o dwa pliki fontu TTF (Roboto Regular + Bold) - akceptowalny koszt wobec poprawnego renderowania polskiego tekstu w eksporcie PDF.
- Pełny branding PDF (logo StageCalc w nagłówku raportu) pozostaje osobnym, kolejnym krokiem - font jest już częścią tej decyzji, brakuje tylko logo.
- Komentarze w kodzie i opisy/dane testów świadomie pozostają bez zmian (poza zdjęciem znaków tam, gdzie test dosłownie sprawdzał treść UI) - to był jawny wybór zakresu, nie przeoczenie.

## ADR-032: Wiele typów złącz w jednej grupie złączy lokacji

Status: accepted

Kontekst:

- `LocationPowerConnector` ("grupa złączy" na ekranie Lokacje, np. "Rozdzielnia sceny") miał dokładnie jeden `connectorTypeId` i jedną `quantity` na grupę - realna rozdzielnia sceniczna prawie zawsze oferuje kilka różnych typów złącz naraz (np. 2x CEE 32A 5P + 4x Schuko), więc taka grupa musiała być sztucznie rozbita na kilka osobnych grup o tej samej nazwie, albo po prostu nie oddawała realnego wyposażenia.
- Użytkownik: "jak już mamy 'grupa złączy' to dobrze żeby w tej grupie dało się dodać różne rodzaje złącz."

Decyzja:

- `LocationPowerConnector` traci pola `connectorTypeId`/`quantity`, zyskuje `entries: List<LocationConnectorEntry>` - każdy wpis to własny `connectorTypeId` + `quantity`. `availablePowerKw` sumuje wszystkie wpisy; nowy getter `entriesSummary` buduje czytelny opis typu "2x 32 A CEE 5P + 4x 16 A Uni-Schuko" (używany wszędzie tam, gdzie grupa jest wyświetlana - karta lokacji, szczegóły, dialog edycji, dialog tworzenia rozdzielnicy z lokacji w projekcie), żeby ten format nie był duplikowany w każdym miejscu z osobna.
- **Lokalny magazyn (Drift)**: nowa kolumna `LocationPowerConnectors.entriesJson` (JSON-encoded array `{connectorTypeId, quantity}`, domyślnie `'[]'`) - dokładnie ten sam wzorzec co `CatalogDevices.connectorTypeIdsJson` z ADR-030/031. Stare kolumny `connectorTypeId`/`quantity` **zostają fizycznie w schemacie bez zmiany nullability** (wciąż `NOT NULL`) - aplikacja nadal je zapisuje (pierwszy wpis z `entries`), tylko wyłącznie po to, żeby ten wciąż-`NOT NULL` warunek pozostał spełniony; odczyt idzie zawsze przez `entriesJson`. Świadomie NIE zmieniono `connectorTypeId` na `nullable()` (mimo że `CatalogDevices.connectorTypeId` tak zrobiono w ADR-030) - nullability zadeklarowana w kodzie Dart dotyczy tylko `onCreate` na *nowej* bazie, a fizyczny `NOT NULL` istniejących, migrowanych baz użytkowników zostaje niezmieniony (SQLite nie potrafi zdjąć ograniczenia kolumny przez zwykły `ALTER TABLE ADD COLUMN`), więc poleganie na tym dla nowych insertów byłoby niespójne między świeżą instalacją a zaktualizowaną - a to dokładnie ten rodzaj cichej niespójności, który już raz kosztował fałszywie pozytywny test w v0.3.3.
  - Migracja `from < 16`: dodaje `entriesJson`, potem dla każdego istniejącego wiersza przepisuje jego stary pojedynczy `connectorTypeId`+`quantity` jako jednoelementową tablicę JSON - bez tego kroku każda grupa zapisana przed tą zmianą wyglądałaby po aktualizacji na pustą.
- **Zdalny magazyn (PocketBase)**: zero migracji schematu - ponownie użyto wymaganego pola tekstowego `connector_type_id` do przenoszenia całego JSON-a `entries` (identyczny trik co `pocketbase_catalog_sync_service.dart` z ADR-030/031 dla `connectorTypeIdsJson`). Odczyt (`decodeStoredList`) próbuje `jsonDecode`; jeśli to się nie uda (stary zdalny rekord z pojedynczym connector-type-id jako czystym tekstem, zsynchronizowany przed tą zmianą), traktuje całą wartość jako jednoelementową listę, biorąc `quantity` z osobnego zdalnego pola jako `legacyQuantity`.
- **`distro_create_dialog.dart`** (tworzenie rozdzielnicy w projekcie z grupy złączy lokacji): `_locationOutlets` iteruje teraz po każdym `entry` w grupie i generuje gniazda dla każdego typu osobno (zamiast zakładać jeden typ na całą grupę) - to jedyne miejsce poza samym ekranem Lokacje, które faktycznie konsumowało pojedynczy `connectorTypeId`/`quantity`, więc bez tej zmiany wybranie grupy z wieloma typami po cichu zgubiłoby wszystkie typy poza pierwszym.
- **UI dialogu grupy** (`_PowerConnectorDialog`): zamiast jednego dropdownu + pola ilości, lista wierszy (typ złącza + ilość + usuń), każdy z własnym `TextEditingController`, plus przycisk "Dodaj typ złącza"; usunięcie ostatniego pozostałego wiersza jest zablokowane (grupa musi mieć co najmniej jeden typ).

Uzasadnienie:

- Ponowne użycie istniejącego wymaganego pola tekstowego zamiast dodawania nowego pola w PocketBase to ten sam kompromis co w ADR-030/031 - unika kolejnej ręcznej migracji `pb_migrations` dla czegoś, co i tak jest zwykłym tekstem z punktu widzenia bazy.
- Zachowanie fizycznej `NOT NULL` starych kolumn (zamiast próbować je poluzować) jest bezpośrednią lekcją z DriftRemoteException/`SqliteException` z v0.3.3-v0.3.4: zmiana nullability w kodzie Dart nie gwarantuje tego samego zachowania na już-zmigrowanej bazie użytkownika, więc bezpieczniej jest po prostu zawsze coś zapisać niż polegać na zgodności schematu, której nie da się w pełni zweryfikować bez fizycznego dostępu do każdej wersji bazy w terenie.

Konsekwencje:

- Każda grupa złączy zapisana przed tą zmianą (lokalnie lub zdalnie) zostaje przy następnym odczycie/synchronizacji automatycznie przepisana na jednoelementową listę `entries` - bez utraty danych i bez akcji użytkownika.

## ADR-031: Kategorie i pola zależne od kategorii w katalogu urządzeń

Status: accepted

Kontekst:

- Użytkownik zgłosił trzy problemy z formularzem "Dodaj urządzenie" po realnym użyciu: (1) kategoria "Rigging" pokazywała pola nieadekwatne do rzeczywistego sprzętu riggingowego - typy złącz, Moc/Prąd, punkty zaczepienia; (2) jedna ogólna kategoria "Urządzenie" była za uboga do filtrowania - potrzeba przynajmniej podziału na oświetlenie/nagłośnienie/multimedia; (3) kategoria "Kabel" pokazywała Moc/Prąd (kable nie pobierają mocy) i Producenta (kable nie są sensownie przypisywane do producenta). Po pierwszym wdrożeniu i żywej weryfikacji na Windows użytkownik doprecyzował, że punkty zaczepienia są zbędne również dla kabla (kabel, tak jak sprzęt riggingowy, nie jest tym, co wpina się w hak).
- `docs/FEATURE_SCOPE.md` od początku projektu wymieniał dokładnie taki podział ("oświetlenie, dźwięk, multimedia, okablowanie i dystrybucja, rigging, inne") - uproszczenie do jednej ogólnej kategorii `device` było wcześniejszą decyzją implementacyjną, nie celowym odejściem od tej specyfikacji.

Decyzja:

- `CatalogDeviceCategory` rozszerzony z `{device, distribution, cable, rigging, other}` na `{lighting, sound, multimedia, distribution, cable, rigging, other}` - `device` usunięte, zastąpione trzema bardziej szczegółowymi kategoriami. Domyślna kategoria nowego urządzenia to `lighting` (najczęściej dodawany typ sprzętu).
- **Wsteczna kompatybilność bez migracji schematu**: `category` jest w Drift/PocketBase zwykłym polem tekstowym (nie enumem SQL), więc usunięcie `device` z enuma Dart nie wymaga żadnej migracji - `CatalogDeviceCategoryJson.fromJson` po prostu mapuje nierozpoznany tekst (w tym stare `device`) na `other` zamiast na usunięty wariant. Istniejące urządzenia z `category: "device"` nadal się wczytują, po prostu jako "Inne", do ręcznego przekategoryzowania.
- **Pola formularza zależne od kategorii** (`_CatalogDeviceDialogState`, nowe gettery `_showElectrical`/`_showConnectors`/`_showRiggingPoints`/`_showManufacturer`):
  - `rigging`: ukryte Moc/Prąd, typy złącz, punkty zaczepienia. Widoczne: nazwa, producent, masa, jednostka, tabela nośności (już wcześniej warunkowa tylko dla rigging).
  - `cable`: ukryte Moc/Prąd, producent, punkty zaczepienia. Widoczne: nazwa, masa, typy złącz, jednostka.
  - Pozostałe kategorie: pełny zestaw pól, bez zmian.
  - `_submit()` **jawnie zeruje/czyści ukryte pola** (nie tylko chowa je wizualnie) - jeśli ktoś wpisał Moc przed przełączeniem na "Rigging", zapisana wartość to `0`, nie zapamiętana-ale-niewidoczna liczba z kontrolera tekstowego. Zapobiega to cichemu zapisaniu nieaktualnych danych.
- **Filtr kategorii na ekranie Katalog** (nie tylko w istniejącym filtrze wewnątrz dialogu wyboru z katalogu przy dodawaniu do projektu): rząd `ChoiceChip` ("Wszystkie" + każda kategoria) nad listą urządzeń, filtrujący `_filteredDevices` razem z wyszukiwaniem tekstowym.
- Dane demo (`DemoCatalogFactory`) zaktualizowane: BMFL Spot i LED Par RGBW (były `device`) -> `lighting`.

Uzasadnienie:

- Pole tekstowe (nie enum) w warstwie przechowywania to dokładnie ten sam wzorzec co ADR-030 (`connectorTypeIdsJson`) - kolejny dowód, że ta konwencja (elastyczność kategorii/wartości enum bez migracji schematu) się sprawdza przy realnych zmianach wymagań.
- Ukrywanie pól per kategoria (zamiast np. osobnych formularzy per kategoria) jest najmniejszą zmianą rozwiązującą zgłoszony problem - te same kontrolery/stan, tylko warunkowe budowanie widgetów, spójne z istniejącym już wzorcem warunkowej tabeli nośności dla rigging.
- Jawne zerowanie ukrytych pól w `_submit()` (a nie tylko ukrywanie w UI) jest ważne dla poprawności danych - `TextEditingController` nie czyści się sam przy zmianie kategorii, więc bez tego użytkownik mógłby przypadkiem zapisać np. Moc dla kabla, której nigdy nie widział na ekranie w momencie zapisu.

Konsekwencje:

- Istniejące urządzenia z `category: "device"` (w tym ewentualne realne dane użytkownika sprzed tej decyzji) stają się "Inne" do czasu ręcznego przypisania nowej, bardziej szczegółowej kategorii - jednorazowy koszt, analogiczny do tych już zaakceptowanych w ADR-028/ADR-030.
- Podział na `lighting`/`sound`/`multimedia` jest na razie płaski (bez podkategorii) - zgodnie z tym, o co użytkownik poprosił ("chociaż na ten moment"), z możliwością dalszego uszczegółowiania w przyszłości, jeśli okaże się potrzebne.

## ADR-030: Wielokrotny wybór typów złącz w katalogu urządzeń

Status: accepted

Kontekst:

- Pole `CatalogDevice.connectorTypeId` było od początku wolnym tekstem (`TextField` w formularzu katalogu, `String?` w schemacie) - `docs/CATALOG_IMPORT_GUIDE.md` (przygotowany na potrzeby generowania wsadu katalogu przez GPT) wprost to udokumentował, wraz z ostrzeżeniem, że to inne pojęcie niż zamknięty słownik `ConnectorTypes` (Schuko/CEE/Powerlock) używany dla gniazd rozdzielnic w projekcie.
- Użytkownik określił to jako błąd i poprosił o zamianę na listę wielokrotnego wyboru. Zapytany, czy urządzenie ma mieć dokładnie jedno złącze z listy, czy może ich mieć więcej naraz jednocześnie, wybrał **prawdziwy multi-select** - jedno urządzenie może mieć zaznaczonych kilka typów złącz równocześnie (np. fixture z wejściem `powerCON` i osobnym wejściem DMX `XLR 5-pin`).

Decyzja:

- Nowy enum `CatalogConnectorType` (`features/catalog/domain/entities/catalog_device.dart`) - 23 wartości obejmujące zarówno złącza zasilania (Schuko, CEE 16/32/63/125A, Powerlock 200/400A, powerCON/TRUE1/TRUE1 TOP) jak i sygnałowe (XLR3/5, SpeakON NL4/NL8, EtherCON, BNC, Jack 6.3mm, RCA, HDMI, SDI, USB) plus `other` - szerszy niż `ConnectorTypes` (używany tylko dla gniazd rozdzielnic), bo katalog obejmuje oświetlenie/dźwięk/multimedia/okablowanie/rigging, nie tylko zasilanie.
- `CatalogDevice.connectorTypeId` (`String?`) zastąpione przez `connectorTypeIds` (`List<CatalogConnectorType>`, domyślnie puste) - w formularzu katalogu (`catalog_screen.dart`) wolne pole tekstowe zastąpiono siatką `FilterChip` (ten sam wzorzec co selektor faz w dialogu połączenia) z etykietą każdej wartości enuma.
- **Nic nigdy nie jest zgadywane przy odczycie**: `CatalogConnectorTypeJson.fromJson` próbuje dokładnego dopasowania do nazwy enuma, potem znormalizowanego (małe litery, tylko litery/cyfry) dopasowania do tabeli aliasów pokrywającej stare dane demo (`powercon_true1`, `powercon`, `cee_32a_5p`) i typowe warianty zapisu (`RJ45`->`etherCon`, `DMX`->`xlr5`, `cinch`->`rca` itd.) - wartość, która niczego nie dopasuje, jest **po cichu pomijana**, nigdy zgadywana na siłę. Ta sama funkcja obsługuje: odczyt starego pojedynczego pola `connectorTypeId` z backupu sprzed tej decyzji, odczyt kolumny Drift/PocketBase (patrz niżej) i walidację wsadu z `docs/CATALOG_IMPORT_GUIDE.md`.
- Schemat lokalny: nowa kolumna `CatalogDevices.connectorTypeIdsJson` (TEXT, JSON-owa tablica id-ków enuma, dokładnie ten sam wzorzec co `PowerConnections.selectedPhasesJson` z ADR-026) - podniesiono schemat bazy do wersji `15`. Stara kolumna `connectorTypeId` **zostaje w schemacie, ale nie jest już nigdzie zapisywana** - migracja `if (from < 15)` dodaje nową kolumnę i dla każdego istniejącego wiersza z niepustym starym polem zapisuje je jako jednoelementową tablicę JSON w nowej kolumnie (bez próby walidacji na tym poziomie - schemat lokalny celowo nie zna domeny/enumów, zgodnie z jego dotychczasową architekturą); to `CatalogConnectorTypeJson.decodeStoredList` (warstwa repozytorium) dopiero interpretuje ten surowy tekst na listę enumów, odrzucając to, czego nie rozpozna.
- PocketBase: **zero zmian schematu**. `catalog_devices.connector_type_id` był już zwykłym polem `text` (bez ograniczeń), więc dalej przechowuje ten sam tekst co lokalna kolumna `connectorTypeIdsJson` (teraz tablica JSON zamiast pojedynczej wartości) - push/pull w `PocketBaseCatalogSyncService` po prostu przekazują ten string 1:1 między lokalną kolumną a zdalnym polem, bez żadnej interpretacji enumów po stronie synchronizacji.
- `docs/CATALOG_IMPORT_GUIDE.md` zaktualizowany: `connectorTypeId` (string) -> `connectorTypeIds` (tablica), z pełną tabelą 23 dozwolonych wartości i jawnym ostrzeżeniem, że nierozpoznana wartość zostanie po cichu odrzucona przy imporcie.

Uzasadnienie:

- Multi-select (a nie jeden wybór z listy) odzwierciedla realny sprzęt: wiele urządzeń ma jednocześnie złącze zasilania i osobne złącze sygnałowe/danych, i użytkownik jawnie potwierdził, że o to chodzi.
- Zachowanie surowego tekstu w kolumnie Drift/PocketBase (zamiast np. osobnej tabeli relacyjnej) unika jakiejkolwiek migracji schematu po stronie PocketBase - dokładnie ten sam kompromis co `selectedPhasesJson` w ADR-026, teraz konsekwentnie zastosowany drugi raz.
- Rozdzielenie "surowy tekst w warstwie Drift" od "interpretacja na enum w warstwie repozytorium" (zamiast próbować zwalidować/zaimportować enum już w pliku migracji) utrzymuje `app_database.dart` wolny od zależności domenowych - zgodnie z już istniejącą, celową architekturą tego pliku (żaden inny plik w `infrastructure/local_database` nie importuje enumów z `features/`).
- "Po cichu odrzuć niepasującą wartość" (zamiast rzucić wyjątek albo zgadywać najbliższą) jest spójne z tym, jak `CatalogDeviceCategoryJson.fromJson`/`CatalogQuantityUnitJson.fromJson` już działają w tym samym pliku (fallback na wartość domyślną) - ale tutaj "domyślna wartość" dla listy to po prostu pominięcie elementu, nie zgadywanie jednego z 23 złącz.

Konsekwencje:

- Urządzenia z (jakimkolwiek) wolnym tekstem w starym polu `connectorTypeId`, który nie pasuje do żadnego z 23 nowych id ani ich aliasów, **tracą to złącze po migracji** (stają się widoczne jako urządzenie bez zaznaczonych złącz) - jednorazowy koszt uporządkowania nieograniczonego pola. Surowy tekst nie ginie całkowicie: stara kolumna `connectorTypeId` zostaje w bazie nietknięta, więc teoretycznie odzyskiwalna ręcznie (SQL), ale appka go już nigdzie nie pokazuje ani nie czyta.
- Zamknięte 23 wartości mogą z czasem okazać się niewystarczające dla rzadszego sprzętu (np. Speakon NL2, XLR4) - dodanie kolejnej wartości enuma jest jednak tanią, addytywną zmianą (nowy element `CatalogConnectorType`, nowa etykieta, opcjonalnie nowy alias), nie wymaga kolejnej migracji schematu.
- Pole nadal nie jest używane w żadnych obliczeniach mocy/faz/obciążenia - to czysto informacyjna/inwentarzowa etykieta, jak przed tą decyzją.

## ADR-029: Wizualny układ patchera (kafelki gniazd)

Status: accepted

Kontekst:

- `docs/FEATURE_SCOPE.md` od początku definiował "Wizualny patcher": pokazuje gniazda rozdzielnicy, łączy gniazdo z grupą lub inną rozdzielnicą, wybiera fazy dla grup 1F podłączanych do gniazda "All", wykrywa zajętość faz, pozwala dodawać notatki do połączeń. Etap 6 (`docs/MIGRATION_PLAN.md`) dostarczył "funkcjonalny odpowiednik" tej specyfikacji (można łączyć, widać obciążenia, ostrzeżenia), ale bez wizualnej, klikalnej reprezentacji gniazd - były to czysto informacyjne pigułki (`Chip`), a jedynym sposobem łączenia był osobny przycisk "Połącz" otwierający zbiorowy dialog (wybierz cel, potem gniazda). Notatki do połączeń (`PowerConnection.notes`, już w schemacie od ADR-017) nigdy nie miały żadnego UI do wpisania czy odczytania.
- Backlog (`docs/IMPLEMENTATION_STATUS.md`, "Następny krok") miał to jako pozycję nr 1: "Przygotować bardziej wizualny układ patchera".
- Użytkownik potwierdził kierunek: gniazda stają się większą, klikalną siatką kafelków, a dotychczasowy zbiorowy dialog "Połącz" i lista "Połączenia" zostają bez zmian jako opcja do podłączenia jednej grupy do wielu gniazd naraz.

Decyzja:

- `_OutletTile` (`presentation/project_editor/distro_widgets.dart`) zastępuje dawny `_OutletLoadChip`: kafelek ok. 140px szerokości pokazujący etykietę fazy, kropki zajętości L1/L2/L3 dla gniazd fazy "All" (wyliczane z `PowerConnection.selectedPhases`, a dla połączeń z rozdzielnicą podrzędną - jako zajmujące wszystkie trzy fazy), ikonę stanu (plus/błyskawica/ostrzeżenie/rozłączony-duplikat), nazwę podłączonego celu (lub "Wolne"), nazwę gniazda i odczyt A/max A. Kolor tła/obwódki reużywają tej samej hierarchii stanów co poprzednio (bezpieczny/ostrzeżenie/błąd/zajęte), tylko na większym, klikalnym `InkWell`.
- Dotknięcie pustego gniazda otwiera nowy `_QuickConnectDialog` (`connection_widgets.dart`) - lżejszy odpowiednik `_ConnectionDialog` z JUŻ USTALONYM źródłem (ta rozdzielnica/to gniazdo): trzeba wybrać tylko cel (grupa albo pasująca rozdzielnica podrzędna, filtrowana po zgodności `inputConnectorTypeId`), opcjonalnie fazy dla gniazd "All" (pomijając fazy już zajęte) i notatkę początkową.
- Dotknięcie już podłączonego gniazda otwiera `_OutletDetailsDialog`: lista wszystkich połączeń na tym gnieździe (zwykle jedno, więcej dla współdzielonego gniazda "All"), każde z nazwą celu, fazami, edytowalnym polem notatek (przycisk zapisu przy każdym) i przyciskiem "Rozłącz". Gdy gniazdo nie jest jeszcze pełne (wolna faza na "All"), dodatkowy przycisk "Dodaj kolejne" otwiera `_QuickConnectDialog` z już zajętymi fazami wykluczonymi z wyboru.
- `PowerConnection.notes` dostaje wreszcie UI do zapisu i odczytu (nowa metoda `ProjectEditorController.editConnectionNotes`) - wypełnia lukę z oryginalnej specyfikacji "Wizualny patcher", która nigdy wcześniej nie miała żadnego pola notatek w interfejsie.
- Istniejący przycisk "Połącz" + `_ConnectionDialog` (zbiorowe podłączenie jednej grupy do wielu wolnych gniazd naraz, z przełącznikiem "Pokaż użyte złącza") oraz lista "Połączenia" poniżej pozostają bez zmian - dwie ścieżki do tego samego efektu koincydujące w jednym ekranie: kafelki gniazd do szybkiego, pojedynczego podłączenia/podglądu, zbiorowy dialog do hurtowego przypisania.

Uzasadnienie:

- Zachowanie zbiorowego dialogu bez zmian (zamiast próbować przerobić go pod jeden ustalony outlet) unika ryzykownej zmiany w już działającym, przetestowanym kodzie i utrzymuje jego unikalną, wygodną funkcję (jedna grupa -> wiele gniazd jednym kliknięciem), której model "kliknij gniazdo" nie odtwarza naturalnie.
- Osobny `_QuickConnectDialog` zamiast parametryzowania `_ConnectionDialog` dodatkowym "ustalonym źródłem" jest prostszy: `_ConnectionDialog` filtruje gniazda po celu, `_QuickConnectDialog` filtruje cele po (ustalonym) gnieździe - odwrotny kierunek dopasowania, który jako jeden dialog z trybami byłby trudniejszy do zrozumienia niż dwa małe, jednoznaczne dialogi.
- Model "tap pusty = połącz, tap zajęty = szczegóły" (zamiast jednego trybu z przełącznikiem) odzwierciedla naturalne oczekiwanie użytkownika patrzącego na diagram patch bay - kafelek już pokazuje, czy jest zajęty, więc dotknięcie go powinno pokazać to, co już jest podłączone, a nie od razu proponować nadpisanie.

Konsekwencje:

- To nadal siatka kafelków, nie prawdziwy diagram z liniami łączącymi gniazdo z grupą/rozdzielnicą (jak np. edytor patch bay z liniami połączeń) - `docs/FEATURE_SCOPE.md` tego nie wymagał wprost, a rysowanie połączeń na canvasie między odległymi kartami rozdzielnic byłoby dużo większym, osobnym projektem UI.
- `PatchValidationService.isOutletDuplicated` nadal traktuje każde gniazdo z więcej niż jednym połączeniem jednolicie jako ostrzeżenie "użyte wiele razy", niezależnie od tego, czy to legalne współdzielenie faz gniazda "All", czy przypadkowy duplikat - `_OutletDetailsDialog` pokazuje wszystkie połączenia niezależnie od tego ostrzeżenia, więc użytkownik i tak widzi pełny obraz, ale sama etykieta ostrzeżenia nie rozróżnia tych dwóch przypadków (ten sam, już istniejący uproszczony model sprzed tej decyzji).
- Nowy test widgetowy (`test/widget_test.dart`, "tapping an outlet tile connects and disconnects it") pokrywa pełny cykl: pusty kafelek -> quick connect z notatką -> szczegóły pokazujące notatkę -> rozłączenie -> pusty kafelek ponownie.

## ADR-028: Prawdziwa autoryzacja PocketBase (konta osobiste, właściciel danych)

Status: accepted

Kontekst:

- ADR-017 zostawiła reguły dostępu wszystkich kolekcji PocketBase puste (publiczne) jako świadome, tymczasowe ryzyko, akceptowalne tylko w prywatnej sieci LAN - "do czasu zaprojektowania prawdziwego modelu autoryzacji". ADR-026 dodała pełny dwukierunkowy sync dla pięciu agregatów, ale nie zmieniła reguł dostępu - każdy z dostępem do serwera nadal mógł czytać/edytować/usuwać dowolny rekord bez logowania.
- Użytkownik potwierdził, że czas to zaadresować, i wspólnie ustalono model: **konta osobne dla każdej osoby** (nie jedno wspólne konto zespołu) - użytkownik mógłby też użyć jednego konta i je udostępnić, ale wybrał osobne konta i poprosił o położenie prawdziwych podwalin pod wieloosobowość, skoro takie było pierwotne założenie projektu.
- Zapytany o zachowanie synchronizacji bez zalogowania: **praca lokalna działa normalnie, synchronizacja po prostu czeka** - appka nigdy nie blokuje użytkownika przed zalogowaniem, tylko przycisk/timer "Synchronizuj teraz" nic nie robi, dopóki nikt nie jest zalogowany.
- Zapytany, co ma być wspólne, a co prywatne: **klienci i projekty prywatne** (widoczne tylko dla właściciela), katalog urządzeń, lokacje i presety zasilania **wspólne** dla każdego zalogowanego członka zespołu - to odzwierciedla realny podział pracy (katalog sprzętu i lokacje są wspólną wiedzą ekipy, ale konkretny projekt/klient danej osoby nie musi być widoczny dla innych).

Decyzja:

### Model danych i reguły dostępu (PocketBase)

- Ponownie użyto domyślnej kolekcji `users` (auth), którą PocketBase tworzy automatycznie przy pierwszym starcie - **nie** utworzono nowej kolekcji o tej samej nazwie (pierwsza próba właśnie to zrobiła i wywołała pętlę restartów usługi: "Collection name must be unique (case insensitive)"). `listRule`/`viewRule`/`updateRule` = `"id = @request.auth.id"` (każdy widzi/edytuje tylko własne konto), `createRule`/`deleteRule` = `null` (zakładanie/usuwanie kont tylko przez superusera - świadomie brak samodzielnej rejestracji, bo to nadal małe, zamknięte narzędzie dla jednej ekipy).
- Nowe pole relacyjne `owner` (-> `users`, `maxSelect: 1`) na `clients` i `projects`.
- Trzy poziomy reguł dostępu na 16 już istniejących kolekcjach:
  - `authRule` (`@request.auth.id != ''`) - na 7 kolekcjach **wspólnych**: `catalog_devices`, `truss_load_chart_entries`, `locations`, `location_contacts`, `location_power_connectors`, `power_presets`, `power_outlet_templates`. Każdy zalogowany widzi i edytuje wszystko - to wspólna wiedza ekipy, nie dane jednej osoby.
  - `ownerRule` (`@request.auth.id != '' && owner = @request.auth.id`) - na `clients` i `projects`. Tylko właściciel widzi/edytuje swój rekord.
  - `projectOwnerRule` (`@request.auth.id != '' && project.owner = @request.auth.id`) - na 7 kolekcjach zagnieżdżonych pod projektem (`project_groups`, `project_items`, `project_group_hook_assignments`, `project_distros`, `project_outlets`, `power_connections`, `project_trusses`), sprawdzając właściciela **rodzica** przez relację `project`, nie własne, nieistniejące pole `owner`.
  - Wszystkie migracje mają pełną funkcję `down` przywracającą puste reguły z ADR-017.
- Migracje w `pocketbase/pb_migrations/` (i zastosowane na LXC 113): `1789300210_updated_users.js`, `1789300220_updated_clients_projects_owner.js`, `1789300230_updated_access_rules.js`. Przed zmianą schematu wykonano kopię `pb_data` na serwerze, tak jak w ADR-026.

### Lokalny schemat i sesja logowania

- `Clients.ownerId`/`Projects.ownerId` (`String?`) - id rekordu `users` w PocketBase (używane bezpośrednio, bez tłumaczenia przez `local_id` - konta użytkowników istnieją tylko zdalnie, w przeciwieństwie do każdego innego odwołania krzyżowego w tym schemacie). `null`, dopóki rekord nie zostanie po raz pierwszy wypchnięty przez zalogowanego użytkownika (patrz "Stemplowanie właściciela" niżej) - klienta/projekt można więc nadal tworzyć offline, przed zalogowaniem.
- `AppSettings.authSessionData` (`String?`) - jeden nieprzezroczysty blob JSON, którym samodzielnie zarządza `AsyncAuthStore` z `package:pocketbase` (token + model użytkownika w jednym polu) - zamiast trzech osobnych kolumn (`authToken`/`authUserId`/`authUserEmail`), które wymagałyby ręcznego utrzymywania spójności z wewnętrznym formatem SDK.
- Schemat lokalny podniesiony do wersji `14` (dodanie `Clients.ownerId`, `Projects.ownerId`, `AppSettings.authSessionData`).
- `PocketBaseClientProvider.initialize()` (wywoływane raz w `main()`, przed `runApp`) tworzy globalną instancję `PocketBase` z `AsyncAuthStore` podpiętą pod `DriftAppSyncSettingsRepository.setAuthSessionData`/`getSettings().authSessionData` - sesja logowania przeżywa restart aplikacji dokładnie tak samo jak reszta lokalnych danych.
- `PocketBaseAuthService` (`infrastructure/remote/pocketbase_auth_service.dart`) - cienka warstwa nad `PocketBase.authStore`: `isLoggedIn`, `currentUserEmail`, `currentUserId`, `login(email, password)` (`authWithPassword`), `logout()` (`authStore.clear()`). Nie trzyma własnego stanu - zawsze czyta ten sam `authStore`, którego używają serwisy synchronizacji.

### UI logowania

- Nowa karta "Konto" na ekranie "O aplikacji" (przed już istniejącą kartą "Synchronizacja"): pola e-mail/hasło i przycisk "Zaloguj się", gdy nikt nie jest zalogowany; e-mail zalogowanego użytkownika i przycisk "Wyloguj", gdy jest.

### Stemplowanie właściciela i blokada synchronizacji

- Przy pushu `Client`/`Project` (`_push` w odpowiednim serwisie synchronizacji): jeśli lokalny rekord nie ma jeszcze `ownerId`, zostaje on ustawiony na `PocketBase.authStore.record?.id` (aktualnie zalogowany użytkownik), zapisany lokalnie (targetowany update Companion), i dopiero potem wysłany w ciele requestu jako pole `owner`. Rekord utworzony offline, zanim ktokolwiek się zalogował, staje się więc własnością tego, kto pierwszy go zsynchronizuje.
- `SyncCoordinator.syncAll()` sprawdza `PocketBase.authStore.isValid` **przed** wywołaniem któregokolwiek z pięciu serwisów synchronizacji - brak logowania zwraca od razu `SyncSummary(errors: ['Zaloguj się, aby zsynchronizować dane.'])` zamiast pięciu serwisów zwracających po kolei zagłos błędów 403 z tym samym, mniej czytelnym efektem. To realizuje decyzję "praca lokalna działa normalnie, sync po prostu czeka" - appka sama w sobie nigdy nie sprawdza stanu logowania poza tym jednym miejscem.

Uzasadnienie:

- Reużycie domyślnej kolekcji `users` zamiast tworzenia nowej unika duplikatu i jest zgodne z tym, jak PocketBase faktycznie działa od pierwszego startu - nowy programista czytający migracje "updated_users" od razu wie, że kolekcja już istniała.
- Podział wspólne/prywatne (katalog/lokacje/presety kontra klienci/projekty) odzwierciedla rzeczywisty podział pracy ekipy, który użytkownik jawnie określił, zamiast arbitralnej decyzji "wszystko prywatne" albo "wszystko wspólne".
- `AsyncAuthStore` zamiast ręcznego zarządzania tokenem: SDK już rozwiązuje serializację, wygasanie (`isValid` sprawdza `exp` w JWT) i normalizację base64 - odtwarzanie tego ręcznie byłoby zbędnym, podatnym na błędy duplikatem.
- Stemplowanie właściciela dopiero przy pushu (nie przy tworzeniu rekordu) pozwala nadal tworzyć klientów/projekty offline, przed pierwszym logowaniem - zgodnie z ADR-002 (offline-first od pierwszego dnia), które ta decyzja w pełni respektuje.

Konsekwencje:

- **Rekordy `clients`/`projects` utworzone przed tą decyzją (bez `owner`) stają się niedostępne do edycji/synchronizacji przez kogokolwiek** - `ownerRule` wymaga ścisłej zgodności `owner = @request.auth.id`, a pusty `owner` nie jest równy żadnemu zalogowanemu użytkownikowi. Zweryfikowano to bezpośrednio: próba push takich rekordów (stare dane demo z ADR-026, `sync_demo_client`/`demo_project`) kończy się błędem 403, podczas gdy nowy rekord z tym samym użytkownikiem synchronizuje się poprawnie. To jednorazowy koszt migracji - każdy realny klient/projekt sprzed tej decyzji wymaga ręcznego przypisania `owner` przez superusera (przez API albo panel admina PocketBase) zanim będzie znów synchronizowalny; appka lokalnie nadal ma te dane bez zmian, tylko przestają się synchronizować.
- `tool/sync_demo_data.dart` wymaga teraz zmiennych środowiskowych `SYNC_DEMO_EMAIL`/`SYNC_DEMO_PASSWORD` (istniejące konto) przed uruchomieniem - narzędzie samo w sobie nie zakłada kont (`createRule` jest superuser-only).
- Zweryfikowano ręcznie pełny przepływ logowanie -> push (ze stemplowaniem właściciela) -> pull do nowej, pustej bazy lokalnej -> odmowa dostępu dla niezalogowanego klienta, na tymczasowym koncie testowym utworzonym i usuniętym wyłącznie na czas tej weryfikacji.
- `revision` nadal nie jest używane (patrz ADR-026) - ta decyzja tego nie zmienia.
- Założenia pod wieloosobowość są teraz realne (osobne konta, właściciel na rekordzie), ale nadal brak: UI do zarządzania kontami (zakłada je superuser ręcznie), przenoszenia własności między użytkownikami, i jakiegokolwiek podglądu "kto jest zalogowany na innym urządzeniu" - żaden z tych scenariuszy nie został poproszony, więc zostają przyszłym, osobnym krokiem, gdy pojawi się realna potrzeba.

## ADR-027: Eksport raportu do PDF

Status: accepted

Kontekst:

- ADR-021 świadomie wybrała raport tekstowy zamiast PDF dla MVP - `docs/FEATURE_SCOPE.md` wprost dopuszcza "eksport danych... w prostszej formie", a PDF wymagał nowej zależności i realnej pracy nad układem. Ten dług został teraz spłacony jako dodatkowa opcja eksportu, nie zamiennik raportu tekstowego.

Decyzja:

- `ProjectPdfReportService` (`features/projects/domain/services/project_pdf_report_service.dart`) generuje PDF przez pakiet `pdf` (widgets API), używając dokładnie tych samych serwisów domenowych co `ProjectReportService` i UI (`ProjectTotalsService`, `PowerCalculationService`, `PatchValidationService`, `TrussLoadService`) - ta sama zasada ADR-014, że raport nie powiela logiki obliczeń.
- Układ: nagłówek z nazwą projektu i akcentem GreenCrew (`#00C853`), sekcje Podsumowanie/Grupy urządzeń/Rozdzielnice/Kratownice jako tabele (`pw.TableHelper.fromTextArray`), stopka z numeracją stron. Treść sekcji 1:1 odpowiada raportowi tekstowemu (te same ostrzeżenia: gniazdo użyte wielokrotnie, przeciążone wejście/gniazdo, cykl połączeń, przekroczony limit kratownicy).
- Domyślne fonty PDF (Helvetica przez bazę 14 fontów standardu PDF) zamiast własnego pliku Roboto - PDF jest dodatkową opcją eksportu, nie głównym UI aplikacji, więc brak pełnego brandingu typograficznego jest akceptowalny na start; pakiet `pdf` ostrzega w konsoli, że te fonty nie mają pełnego wsparcia Unicode, ale cały tekst w aplikacji jest już pisany bez polskich znaków diakrytycznych, więc w praktyce nie ma to znaczenia.
- Zapis do pliku przez rozszerzenie wspólnego `local_file_writer` (ADR-021) o `writeLocalBytesFile` - PDF to pierwszy binarny plik do zapisania lokalnie, więc funkcja przyjmująca `String content` nie wystarczała; dodano siostrzaną funkcję zamiast zmieniać istniejący, już używany podpis.
- Ikona "Eksportuj raport PDF" w AppBar edytora projektu, obok istniejącej "Eksportuj raport tekstowy" - obie opcje dostępne równolegle.

Uzasadnienie:

- Ta sama treść co już sprawdzony raport tekstowy (te same dane, te same ostrzeżenia) minimalizuje ryzyko rozjazdu między formatami i pozwala poddać PDF tej samej weryfikacji regresyjnej co resztę projektu.
- Pakiet `pdf` jest czystym Dartem (działa na Windows/Android/Web bez natywnych zależności), spójnie z resztą stosu (Drift, PocketBase - żadnych platformowych pluginów ponad już istniejące).

Konsekwencje:

- Testy PDF (`project_pdf_report_service_test.dart`) nie mogą sprawdzać treści - pakiet `pdf` nie ma API do odczytu z powrotem - więc asercje ograniczają się do poprawności pliku (niepusty, zaczyna się od sygnatury `%PDF-`) dla tych samych kształtów projektu, które sprawdza test raportu tekstowego (duplikat gniazda, przeciążona kratownica, pusty projekt, projekt wielostronicowy).
- Jeśli w przyszłości pojawi się realna potrzeba pełnego brandingu PDF (font Roboto, logo StageCalc), to osobny, następny krok - nie zablokował tego pierwszego działającego eksportu. **Aktualizacja (ADR-033): font Roboto został dodany, brakuje już tylko logo.**

## ADR-026: Dwukierunkowa synchronizacja z PocketBase

Status: accepted

Kontekst:

- ADR-017 dała tylko jednokierunkowy, no-conflict push jednego `Project` - "dowód, że połączenie i mapowanie modelu działają", jawnie nie sync engine. Etap 10 (`docs/MIGRATION_PLAN.md`) miał nadal do zrobienia: kolejkę synchronizacji, strategię konfliktów, realne statusy sync (`syncState`/`lastSyncedAt` istniały w schemacie, ale nic ich nie zmieniało poza `localOnly`), i sync dla katalogu/klientów/lokacji/presetów (nie tylko projektu).
- Zdecydowano wspólnie z użytkownikiem: konflikty rozwiązuje "ostatni zapis wygrywa" po `updatedAt` (bez UI do ręcznego scalania), wyzwalacz to ustawienie w "O aplikacji" (automatyczny w tle albo przycisk "Synchronizuj teraz" w trybie ręcznym), a zakres to wszystkie pięć agregatów (projekty, katalog, klienci, lokacje, presety), nie tylko projekty.

Decyzja:

### Silnik synchronizacji

- `decideSyncDirection` (`infrastructure/sync/sync_direction.dart`) - czysta funkcja: porównuje `updatedAt` lokalnego i zdalnego rekordu, zwraca `push`/`pull`/`none`. Rekord istniejący tylko po jednej stronie zawsze trafia na drugą, niezależnie od kierunku.
- Pięć serwisów (`PocketBase{Client,Location,PowerPreset,Catalog,Project}SyncService`, po jednym per agregat, wzorowane na już istniejących repozytoriach Drift) łączy się z PocketBase i dla każdego rekordu (dopasowanego po `local_id`) wykonuje `decideSyncDirection`, potem push lub pull. `SyncCoordinator.syncAll()` uruchamia wszystkie pięć po kolei (klienci/lokacje/presety/katalog przed projektami, żeby `Project.client`/`location` miały już co rozwiązać zdalnie) i zapisuje `lastSyncedAt`.
- **Reconciliacja na poziomie całego drzewa, nie pojedynczych rekordów potomnych**: tak jak `saveProject`/`saveLocation` itd. już działają lokalnie (jeden zapis = cały agregat, znaczkowany jednym `updatedAt` korzenia), sync też traktuje np. całą kratownicę grup/pozycji/haków projektu jako jedną jednostkę - wygrywa/przegrywa razem z korzeniem. Bez tego mergowanie pojedynczych zmienionych elementów z obu stron byłoby prawdziwym problemem 3-way merge, którego ten krok świadomie unika.
- **Nic nigdy nie jest twardo usuwane, ani lokalnie, ani zdalnie** (`pocketbase_child_sync.dart`, `upsertRemoteChildren`): appka już wszędzie soft-deletuje (`deletedAt`, ADR-011), więc sync po prostu upsertuje każdy rekord - lokalny czy zdalny - wraz z jego flagą `deleted`/`deleted_at`. To dużo prostsze niż kaskadowe twarde usuwanie (np. usunięcie grupy pociągające usunięcie jej pozycji i haków po drugiej stronie) i spójne z resztą architektury.
- Powiązania `client`/`location` na `Project` (lokalne ID, nie relacje PocketBase) są rozwiązywane do zdalnego ID przez wyszukanie po `local_id` w danej kolekcji (`_findRemoteId`/`_findLocalId`) - nie są duplikowane wewnątrz `PocketBaseProjectSyncService`, bo klienci/lokacje mają już własny serwis synchronizujący.
- Znane, świadome ograniczenie: `project_distros.catalog_device`/`preset` (relacje PocketBase) nie są jeszcze wypełniane przy pushu - nic ich dziś nie czyta z powrotem, więc rozwiązywanie tych relacji zostaje przyszłym, osobnym krokiem, gdy pojawi się realny powód.

### Migracja schematu PocketBase

- Brakujące pola/kolekcje z ADR-020/ADR-024/ADR-025 (dodane do lokalnego schematu Drift po tym, jak ADR-017 już zamroziła zdalny schemat) dopisano do PocketBase na LXC 113 jako pliki migracji w `/opt/pocketbase/pb_migrations/` (dokładnie ten mechanizm, którego ADR-017 już używała) i zastosowano restartem usługi: `catalog_devices.rigging_points`, `project_items.rigging_points_snapshot`, `project_trusses.truss_catalog_device_id`, `project_distros.manual_input_max_current_a`, oraz dwie nowe kolekcje `project_group_hook_assignments` i `truss_load_chart_entries`.
- Wykonano kopię `pb_data` na serwerze przed migracją (`/root/pb_data_backup_*.tar.gz`) i zweryfikowano każde nowe pole/kolekcje przez publiczne API (puste `listRule` z ADR-017) zamiast logowania się jako superuser, żeby nie tworzyć/przekazywać żadnych poświadczeń bez potrzeby.
- **Wszystkie pliki migracji PocketBase są teraz w repozytorium** (`pocketbase/pb_migrations/`) - do tej pory cały schemat zdalny istniał tylko na serwerze, bez śladu w repo. To pierwszy krok do tego, żeby historia schematu była odtwarzalna, a nie tylko pamiętana przez serwer.

### Ustawienia i automatyzacja

- Nowa tabela `AppSettings` (pojedynczy wiersz `id='app'`) zamiast generycznego key-value store - `ADR-011` już odrzuciła `shared_preferences` na rzecz jawnego schematu relacyjnego, a appka ma na razie jedno ustawienie (`autoSyncEnabled` + `lastSyncedAt`).
- Ekran "O aplikacji" ma nową kartę "Synchronizacja": przełącznik "Automatyczna synchronizacja" + (widoczny tylko gdy przełącznik jest wyłączony) przycisk "Synchronizuj teraz" + tekst statusu (czas ostatniej synchronizacji albo wynik ostatniej próby).
- `StageCalcShell` (nie `AboutScreen`) trzyma `Timer.periodic` (co 15 minut, plus jedno wywołanie od razu przy starcie), bo tylko wybrany ekran nawigacji jest w drzewie widgetów - `AboutScreen` znika przy zmianie zakładki. Timer za każdym razem na nowo czyta `autoSyncEnabled` z bazy zamiast cache'ować je w pamięci, więc przełączenie w Ustawieniach działa od następnego tyknięcia bez żadnego dodatkowego kanału komunikacji między ekranami. Błędy synchronizacji w tle są celowo ciche (offline-first: nieudana synchronizacja to normalny stan, nie błąd przerywający pracę) - ekran Ustawień pokazuje czas ostatniej udanej synchronizacji dla kogoś, kto chce sprawdzić.

### Weryfikacja

- Logika decyzyjna (`decideSyncDirection`) i `AppSyncSettings`/`DriftAppSyncSettingsRepository` są w pełni pokryte testami jednostkowymi. Sprostowanie: pierwsza wersja tego ADR twierdziła, że `insertOnConflictUpdate` z częściowym companionem resetuje pominięte kolumny (rzekomo przez `excluded.col` w SQLite) - to nieprawda, Drift jawnie dokumentuje, że kolumny nieobecne w companionie zostają niezmienione przy konflikcie. Prawdziwy błąd złapany przez test był inny: `AppSyncSettings.copyWith` używa `??`, więc jawne przekazanie `null` (np. przy czyszczeniu sesji logowania) jest nieodróżniane od "nic nie zmieniaj" i po prostu zachowuje starą wartość zamiast ją wyczyścić - stąd `withAuthSessionData`/`withAuthSession`-owe metody nie-scalające, zamiast `copyWith`, tam gdzie trzeba faktycznie wyczyścić pole do `null`.
- Same wywołania sieciowe do PocketBase nie są mockowane (jak w ADR-017) - `tool/sync_demo_data.dart` (uruchamiane przez `flutter test tool/sync_demo_data.dart`, nie `dart run`: `AppDatabase` importuje `path_provider`, które samo importuje `package:flutter`, więc zwykła maszyna wirtualna Dart tego nie skompiluje) sieje dane demo do bazy w pamięci i synchronizuje je z prawdziwym serwerem w obie strony: push nowych danych, drugi przebieg pokazujący pełną idempotentność (same "unchanged"), i osobny test pull do zupełnie pustej bazy lokalnej z asercjami na treść (nazwa klienta, grupy/pozycje projektu) - zweryfikowane realnie działające dla klientów, lokacji, presetów, katalogu i projektów (wraz z zagnieżdżonymi grupami/pozycjami).
- Ścieżki dla dystrybutorów/gniazd/połączeń/kratownic/haków używają dokładnie tego samego wzorca co już zweryfikowane grupy/pozycje, ale nie są osobno ćwiczone przez dane demo (`DemoProjectFactory` nie ma jeszcze rozdzielnic ani kratownic) - kolejny kandydat do rozszerzenia `tool/sync_demo_data.dart`, jeśli okażą się potrzebne wcześniej niż przy pierwszym realnym użyciu.

Uzasadnienie:

- "Ostatni zapis wygrywa" jest jedyną strategią, która nie wymaga nowego UI do ręcznego scalania - dokładnie to, o co poprosił użytkownik, i spójne z tym, że to nadal małe, LAN-owe narzędzie, nie system wieloosobowej edycji w czasie rzeczywistym.
- Upsert zamiast twardego usuwania po obu stronach oznacza zero nowej logiki kaskadowego kasowania - i tak już nigdzie w tej appce nic nie jest usuwane na twardo.
- Migracje PocketBase w repozytorium (zamiast tylko na serwerze) to jedyny sposób, żeby schemat zdalny był odtwarzalny i przeglądalny w code review, tak jak już jest schemat lokalny (`app_database.dart`).

Konsekwencje:

- Każda przyszła zmiana lokalnego schematu, która ma się synchronizować, wymaga również nowego pliku migracji w `pocketbase/pb_migrations/` (lokalnie i wgranego na serwer) - łatwo o tym zapomnieć, tak jak stało się to między ADR-017 a ADR-020/024/025.
- Reguły dostępu kolekcji PocketBase są nadal puste/publiczne (ADR-017) - nic w tej ADR tego nie zmienia; prawdziwa autoryzacja zostaje przyszłym, osobnym krokiem (zaadresowane w ADR-028).
- `revision` (pole w każdej tabeli od ADR-011) nadal nic nie inkrementuje - "ostatni zapis wygrywa" po `updatedAt` go nie potrzebuje. Zostaje nieużywane, chyba że pojawi się powód na bardziej wyrafinowaną strategię konfliktów.

## ADR-025: Interpolacja tabel nośności kratownic

Status: accepted

Kontekst:

- Druga (i ostatnia) rzecz odłożona przez ADR-020 przy pierwszej wersji modułu kratownic. `ProjectTruss` miał dotychczas tylko ręcznie wpisywane `maxTotalLoadKg`/`maxDistributedLoadKgPerM` - bez żadnego powiązania z konkretnym modelem kratownicy i jego rzeczywistą tabelą nośności od producenta.
- Legacy (`legacy/firebase/src/components/truss/truss-calculator.tsx`, `getInterpolatedLimits`/`interpolate`) trzyma tabelę nośności (`loadChart`) na urządzeniu-kratownicy w katalogu i interpoluje liniowo limit punktowy/rozłożony po długości; poza zakresem tabeli ekstrapoluje z dwóch najbliższych punktów i oznacza wynik jako ekstrapolację. Logika przeniesiona 1:1 (`docs/MIGRATION_PLAN.md`: "Co przepisać 1:1 - Interpolacje kratownic").

Decyzja:

- `ProjectTruss.trussCatalogDeviceId` (`String?`) - opcjonalny link do `CatalogDevice` reprezentującego model kratownicy. Wybierany z listy urządzeń kategorii "Rigging" w dialogu kratownicy (`_TrussDialog`), niezależny od istniejącego, wciąż nieużywanego w UI pola `trussSystemId`.
- `CatalogDevice.loadChart` (`List<TrussLoadChartEntry>`, nowa tabela `truss_load_chart_entries`) - punkty `{lengthM, pointLoadKg, distributedLoadKgPerM}` wpisywane w formularzu katalogu, widoczne tylko dla kategorii "Rigging". Bez pól ugięcia (`deflection*`) z legacy - nieużywane przez żadną kalkulację ani tam, ani tutaj; jeśli okażą się potrzebne, to osobny, później dodany krok.
- `TrussLoadService._interpolateLimits` - port `getInterpolatedLimits`/`interpolate` z legacy: dokładne trafienie, interpolacja między dwoma najbliższymi punktami, ekstrapolacja z dwóch skrajnych gdy długość jest poza tabelą, `no-data` gdy urządzenie nie ma tabeli.
- Reguła override: `maxTotalLoadKg`/`maxDistributedLoadKgPerM` na `ProjectTruss` pozostają ręcznym nadpisaniem, dokładnie jak `manualInputMaxCurrentA` dla limitu wejścia rozdzielnicy (ta sama zasada "domyślnie wyliczone + możliwość ustalenia" z wcześniejszej decyzji użytkownika w tej sesji) - każde z obu pól działa niezależnie: gdy puste, brany jest wynik interpolacji; gdy wypełnione, wygrywa wartość ręczna.
- `TrussLoad` ma teraz `totalLimitFromChart`/`distributedLimitFromChart` (czy dany limit pochodzi z tabeli) i `hasInterpolatedLimits`/`isChartExtrapolated` do pokazania w UI. `_TrussCard` pokazuje chip "Limity z tabeli producenta" albo ostrzegawczy "Długość poza tabelą producenta (ekstrapolacja)".
- Schemat bazy podniesiony do wersji `12`.

Uzasadnienie:

- Zgodność z `docs/MIGRATION_PLAN.md` ("Co przepisać 1:1") - sama matematyka interpolacji nie ma powodu różnić się od sprawdzonej w legacy.
- Reużycie wzorca "wyliczone + ręczny override" (zamiast np. blokowania ręcznego pola, gdy jest tabela) jest spójne z ADR z Etapu 6 i nie wymaga nowej decyzji produktowej.
- `trussCatalogDeviceId` jako osobne pole (zamiast przeciążania `trussSystemId`) unika nadania nowego znaczenia polu, które już istnieje w schemacie i bazie danych użytkowników.

Konsekwencje:

- Etap 7 (`docs/MIGRATION_PLAN.md`) jest zrealizowany w całości dla zakresu MVP - haki (ADR-024) i interpolacja (ta ADR).
- `ProjectEditorController` cache'uje teraz `catalogDevices` (ładowane w `loadReferences()`, jak `clients`/`locations`/`powerPresets`) - potrzebne do synchronicznego liczenia `trussLoad()` w `build()`. Ten cache ma tę samą, już zaakceptowaną wcześniej niedoskonałość co pozostałe trzy: może się zdezaktualizować, jeśli katalog zmieni się w tle podczas edycji projektu.
- Ewentualne dodanie ugięcia (`deflectionPointLoadMm`/`deflectionDistributedLoadMm`) z `docs/DATA_MODEL.md` zostaje przyszłym, osobnym krokiem, gdy pojawi się realna potrzeba go pokazać.

## ADR-024: Haki kratownic (riggingPoints)

Status: accepted

Kontekst:

- Etap 7 (`docs/MIGRATION_PLAN.md`) zostawił dwie rzeczy poza pierwszą wersją modułu kratownic (ADR-020): haki (`riggingPoints`) i interpolację tabel nośności producenta. Ta ADR realizuje pierwszą z nich; interpolacja zostaje nadal poza zakresem, bo wymaga dodatkowo powiązania `ProjectTruss` z konkretnym urządzeniem katalogowym (`trussCatalogDeviceId` z `docs/DATA_MODEL.md` też jeszcze nie istnieje) i tabeli `TrussLoadChartEntry`.
- Logika w legacy (`legacy/firebase/src/components/truss/truss-calculator.tsx`, `getGroupWeight`): wymagana liczba haków to suma `device.riggingPoints * item.quantity` po pozycjach grupy z katalogu; przypisane haki to osobna lista `{hookId, quantity}` per grupa, której waga dolicza się do całkowitej wagi grupy (a więc i do obciążenia kratownicy, do której grupa jest przypisana).

Decyzja:

- `CatalogDevice.riggingPoints` (`int?`) - liczba punktów zaczepienia potrzebnych na sztukę urządzenia. Pole w formularzu katalogu, opcjonalne, widoczne jako chip na karcie urządzenia gdy ustawione.
- `ProjectItem.riggingPointsSnapshot` (`int?`) - snapshot `riggingPoints` w momencie dodania pozycji z katalogu, zgodnie z ADR-008 (snapshoty katalogowe) - zmiana `riggingPoints` w katalogu później nie zmienia już policzonych wymagań istniejących projektów.
- `ProjectGroupHookAssignment` (nowa tabela `project_group_hook_assignments`, analogiczna do `ProjectItems`): `id`, `hookCatalogDeviceId`, `hookNameSnapshot`, `hookWeightKgSnapshot`, `quantity`. Lista `hookAssignments` na `ProjectGroup`. Hak to zwykle urządzenie z katalogu (kategoria "Rigging" w praktyce, ale nie wymuszone strukturalnie) wybierane przez ten sam `_CatalogSelectionDialog`, którego używa dodawanie pozycji do grupy - bez nowego pola "podkategoria" w katalogu, którego DATA_MODEL nie definiuje.
- `TrussLoadService.hookRequirement(ProjectGroup)` liczy `requiredHooks` (suma `riggingPointsSnapshot * quantity`, zaokrąglona w górę), `assignedHooks` (suma ilości przypisanych haków) i `hooksWeightKg`. `calculateLoad` dolicza `hooksWeightKg` do masy każdej przypisanej grupy - haki są własnością grupy, nie kratownicy, więc liczą się niezależnie od tego, do której kratownicy grupa trafi.
- Nowa sekcja "Haki grup urządzeń" w widoku "Kratownice" edytora projektu: lista grup z `requiredHooks > 0`, chip "Wymagane: X / Przypisane: Y" (czerwony gdy niewystarczające), lista przypisanych haków z kontrolkami ilości i usuwaniem, przycisk "Dodaj hak".
- Schemat bazy podniesiony do wersji `11`: `catalog_devices.rigging_points`, `project_items.rigging_points_snapshot`, nowa tabela `project_group_hook_assignments`.

Uzasadnienie:

- Snapshot zamiast live-lookup (w odróżnieniu od legacy, które czytało `device.riggingPoints` na bieżąco z katalogu) jest spójny z resztą aplikacji (ADR-008) i unika niespodziewanej zmiany wymagań istniejącego projektu po edycji katalogu.
- Reużycie `_CatalogSelectionDialog` zamiast nowego pickera dla haków unika duplikacji UI i nie wymaga decyzji o nowym polu "podkategoria" w katalogu, której DATA_MODEL nie przewiduje.
- Wymagania haków są własnością grupy (fizyczne haki wpięte w urządzenia), nie kratownicy - stąd `hookRequirement` przyjmuje `ProjectGroup`, a nie `ProjectTruss`, i działa tak samo niezależnie od przypisania.

Konsekwencje:

- Interpolacja tabel nośności producenta i `trussCatalogDeviceId` pozostają kolejnym, osobnym krokiem Etapu 7.
- Każda przyszła zmiana liczącą masę grupy (np. eksport raportu) powinna pamiętać, że `ProjectTotalsService.calculateGroup(...).weightKg` **nie** zawiera wagi haków - to celowe, bo haki mają sens tylko w kontekście kratownic, nie w ogólnym sumowaniu projektu; `TrussLoadService` jest jedynym miejscem, które je dolicza.

## ADR-023: File picker dla importu backupu

Status: accepted

Kontekst:

- Import backupu (ADR-019) wymagał ręcznego wklejenia pełnej ścieżki do pliku JSON - niewygodne i podatne na literówki, zwłaszcza na Androidzie, gdzie ścieżki do `Documents/StageCalc/backups/` nie są widoczne w typowym eksploratorze plików bez wpisania ich z pamięci.

Decyzja:

- Dodano zależność `file_picker` (`^12.3.0`) i przycisk "Wybierz plik" (ikona folderu) obok istniejącego pola na ścieżkę w ekranie "O aplikacji". Przycisk otwiera natywny wybór pliku (`FilePicker.pickFile`, filtr `.json`) i wypełnia pole ścieżki wynikiem.
- Ręczne pole na ścieżkę zostaje - to nie jest zamiennik, tylko dodatkowy, wygodniejszy sposób jej wypełnienia. Cały przepływ walidacji/importu (ADR-019) się nie zmienia.
- `file_picker` na Androidzie (`android_file_picker`) działa przez Storage Access Framework/`GET_CONTENT` intent, więc nie wymaga żadnego dodatkowego uprawnienia w `AndroidManifest.xml` - zgodne z ADR-012E (minimalne uprawnienia). Zweryfikowano treść `AndroidManifest.xml` paczki `android_file_picker`: deklaruje tylko `<queries>` (widoczność pakietów), zero `<uses-permission>`.
- Na Windows używany jest natywny dialog plików (`windows_file_picker`), również bez dodatkowych uprawnień.

Uzasadnienie:

- Mała, samodzielna poprawka UX bez wpływu na model danych czy logikę importu.
- Brak nowego uprawnienia systemowego utrzymuje zasadę ADR-012E.

Konsekwencje:

- Testy widgetowe importu podmieniają `FilePickerPlatform.instance` na fake (`_FakeFilePickerPlatform` w `widget_test.dart`) zamiast klikać prawdziwy natywny dialog, którego `flutter test` i tak nie potrafi wyświetlić.
- `file_picker` nie jest jeszcze używany do eksportu (backup/raport zapisują zawsze do ustalonego katalogu `Documents/StageCalc/...`) - to osobna, nie zadana jeszcze zmiana.

## ADR-022: Uprawnienie INTERNET i skrypt pakowania release

Status: accepted

Kontekst:

- Przy przeglądzie Etapu 11 (`docs/MIGRATION_PLAN.md`) okazało się, że `AndroidManifest.xml` nie deklarował `android.permission.INTERNET`, mimo że `PocketBaseProjectSyncService` (ADR-017) już łączy się z serwerem PocketBase. Zweryfikowano w scalonym manifeście release builda (`build/app/.../processReleaseMainManifest/AndroidManifest.xml`) - uprawnienia INTERNET nie było tam ani z aplikacji, ani z żadnej biblioteki. Na Androidzie brak tego uprawnienia kończy każde połączenie sieciowe `SecurityException`, niezależnie od trybu builda (debug/release) - to nie była jeszcze zauważona regresja, bo dotychczasowa synchronizacja była testowana tylko z `dart run tool/push_demo_project.dart` na Windows, nie z samej aplikacji na telefonie.
- ADR-012F (nazewnictwo release, `StageCalc-vX_Y_Z-platform.ext`) i pozycja "Przygotować nazwy artefaktów" w Etapie 11 były zdecydowane, ale nie miały jeszcze żadnej automatyzacji - nazwa musiałaby być nadawana ręcznie po każdym `flutter build`.

Decyzja:

- Dodano `<uses-permission android:name="android.permission.INTERNET" />` do `android/app/src/main/AndroidManifest.xml`, z komentarzem odsyłającym do ADR-017 jako powodu.
- Dodano `tool/package_release.dart` (`dart run tool/package_release.dart [--platform=android|windows|all]`), który:
  - czyta wersję z `pubspec.yaml` (`version: X.Y.Z+build`, numer builda pomijany w nazwie pliku - zgodnie z przykładami w ADR-012F),
  - uruchamia `flutter build apk --release` / `flutter build windows --release`,
  - kopiuje/pakuje wynik do `dist/StageCalc-vX_Y_Z-android.apk` i `dist/StageCalc-vX_Y_Z-windows.zip`.
- Do pakowania Windows użyto `Compress-Archive` z PowerShell zamiast dodawania zależności `archive` do `pubspec.yaml` - pakowanie Windows i tak działa tylko na maszynie z Windows (tam, gdzie można skompilować `.exe`), więc PowerShell jest zawsze dostępny.
- `dist/` dodany do `.gitignore` - to są artefakty builda, nie źródła.

Uzasadnienie:

- To dokładnie ten typ błędu, który user prosił zgłaszać od razu: "dlaczego coś działa tak jak działa, a nie inaczej" — tu odpowiedzią było "bo jeszcze nikt nie sprawdził, że telefon w ogóle może wykonać zapytanie sieciowe".
- Automatyzacja nazewnictwa usuwa ręczny, łatwy do pomylenia krok przed każdym udostępnieniem builda.

Konsekwencje:

- Etap 11 (`Przygotować nazwy artefaktów`) jest zrealizowany dla Android/Windows. Podpisywanie APK własnym kluczem (obecnie release używa klucza debug) i ewentualny CI pozostają poza zakresem tej zmiany.
- Każda przyszła platforma (np. iOS) powinna dostać własną funkcję `_packageX` w tym samym skrypcie, zamiast osobnego narzędzia.

## ADR-021: Raport tekstowy zamiast PDF, plus wspólny zapis plików

Status: accepted

Kontekst:

- ADR-014 (proposed) zakłada `ProjectReportService` osobny od widoków, używający tych samych serwisów domenowych co UI - ale nie przesądził formatu.
- `docs/FEATURE_SCOPE.md` (Zakres MVP) explicite dopuszcza prostszy format: "eksport danych lub PDF w prostszej formie, jeśli PDF opóźnia MVP".
- PDF wymagałby nowej, większej zależności (`pdf`/`printing`) i osobnej pracy nad układem/stylem zgodnym z GreenCrew branding - nie jest to małe rozszerzenie.
- Przy okazji: trzeci raz z rzędu (połączenie z bazą - ADR-016, backup - ADR-018, teraz raport) potrzebny był niemal identyczny trójkąt plików native/web/stub do zapisu czegoś na dysku.

Decyzja:

- `ProjectReportService.buildTextReport(Project)` generuje czytelny raport tekstowy (podsumowanie mocy/prądu/masy, grupy z pozycjami, rozdzielnice z obciążeniem faz i ostrzeżeniami - przeciążenie, duplikat gniazda, cykl - kratownice z masą i ostrzeżeniami o limicie), używając dokładnie tych samych serwisów co UI edytora (`ProjectTotalsService`, `PowerCalculationService`, `PatchValidationService`, `TrussLoadService`), więc liczby w raporcie nigdy nie różnią się od tego, co pokazuje aplikacja.
- Akcja "Eksportuj raport tekstowy" jako ikona w AppBar edytora projektu (raport jest per-projekt, nie aplikacyjny jak backup).
- Wydzielono `infrastructure/files/local_file_writer/` (`writeLocalFile({subfolder, fileName, content})`) jako jedyny mechanizm zapisu lokalnych plików tekstowych/JSON, zapisujący do `Documents/StageCalc/<subfolder>/`. `AppBackupService` i `ProjectReportService`/ekran edytora korzystają z niego zamiast z własnych kopii tego samego trójkąta plików. Odczyt backupu (`backup_file_reader/`) zostaje osobno, bo ma inny kształt (czyta po ścieżce) i na razie tylko jeden użytkownik.
- PDF pozostaje możliwym następnym krokiem (Etap 9 planu migracji), ale nie blokuje posiadania czytelnego, dającego się skopiować/wysłać raportu już teraz.

Uzasadnienie:

- Trzeci niemal identyczny trójkąt plików to dokładnie ten próg, po którym duplikacja przestaje być "trzy proste linie" i staje się realnym kosztem utrzymania (każda przyszła zmiana - np. dodanie prawdziwego file pickera - musiałaby powtórzyć się w trzech miejscach zamiast jednym).

## ADR-020: Pierwszy silnik i UI kratownic (bez haków i interpolacji)

Status: accepted

Kontekst:

- `ProjectTruss` miał już model danych i tabele Drift od początku (`assignedGroupIds`, `manualLoadKg`, `maxTotalLoadKg`, `maxDistributedLoadKgPerM`), ale `TrussLoadService` z Etapu 3 planu migracji nigdy nie powstał, i nie było żadnego UI - moduł kratownic był niewidoczny dla użytkownika.
- Pełny docelowy model z `docs/DATA_MODEL.md` obejmuje też `ProjectTrussLoad` (pozycje punktowe/UDL), `ProjectGroupHookAssignment` (haki) i tabele nośności producenta (`TrussLoadChartEntry`, `TrussWeightChartEntry`) z interpolacją liniową - **żadna z tych czterech rzeczy jeszcze nie istnieje** w schemacie.

Decyzja:

- Dodano `TrussLoadService` działający wyłącznie na obecnym modelu `ProjectTruss`: `totalMassKg = suma masy przypisanych grup (ProjectTotalsService) + manualLoadKg`, `distributedLoadKgPerM = totalMassKg / lengthM` (0, nie dzielenie przez zero, gdy `lengthM == 0`). Porównuje to z `maxTotalLoadKg`/`maxDistributedLoadKgPerM` (progi near-limit 90%, jak `PowerCalculationService`) i wystawia `hasKnownLimits`, żeby brak zdefiniowanych limitów czytał się jako "nieznane", a nie milcząco jako "OK".
- Dodano trzeci widok w edytorze projektu ("Kratownice", obok "Sprzęt"/"Patcher"): lista kratownic, dialog dodawania/edycji (nazwa, długość, ręczne obciążenie, opcjonalne limity, notatki, wybór przypisanych grup checkboxami), usuwanie.
- Naprawiono przy okazji ten sam wzorzec osieroconych referencji co ADR-015 (dla połączeń), zanim zdążył się powtórzyć: usunięcie grupy usuwa teraz jej ID także z `assignedGroupIds` każdej kratownicy.

Świadomie pominięte (nowy schemat, nie architektoniczne "nie da się" - patrz `docs/DATA_MODEL.md` "Kratownice"):

- Haki (`ProjectGroupHookAssignment`, liczenie z `riggingPoints`) - wymaga pola `riggingPoints` w katalogu urządzeń, którego jeszcze nie ma.
- Rozbicie obciążenia na pozycje punktowe/UDL (`ProjectTrussLoad`) - obecny model liczy jedną zagregowaną masę, nie rozkład wzdłuż kratownicy.
- Interpolacja tabel nośności producenta (`TrussLoadChartEntry`) i ostrzeganie o ekstrapolacji - `maxTotalLoadKg`/`maxDistributedLoadKgPerM` są na razie zwykłymi polami wpisywanymi ręcznie przez użytkownika, nie wartościami odczytanymi z tabeli producenta dla konkretnej długości.

Uzasadnienie:

- Ten zakres realizuje dokładnie to, co `docs/FEATURE_SCOPE.md` opisuje jako część MVP ("obliczanie masy grup z urządzeń, ręcznych pozycji" i "kontrola całkowitego limitu obciążenia, obciążenia rozłożonego kg/m"), bez projektowania schematu pod haki/tabele nośności, które nie mają jeszcze żadnego źródła danych w katalogu.
- Dodanie tych czterech rzeczy później nie wymaga przebudowy `TrussLoadService` - to rozszerzenia, nie zmiana istniejącego kontraktu (`ProjectTruss`/`TrussLoad` zostają, przybywa nowych pól/serwisów).

## ADR-019: Import backupu JSON

Status: accepted

Kontekst:

- ADR-018 dostarczył eksport (`AppBackupService`), ale import został tam świadomie wyłączony z zakresu.
- `docs/DATA_MODEL.md` ("Backup") wymaga, żeby "Import backupu... walidował dane przed zapisem".

Decyzja:

- Dodano `AppBackupImportService` z dwoma odrębnymi krokami:
  1. `validate(String jsonContent) -> BackupImportPreview` — czysta funkcja, nic nie zapisuje. Sprawdza: poprawność JSON, obecność sekcji `manifest`/`data`, `schemaVersion` (odrzuca backup z **nowszego** formatu niż `appBackupFormatVersion` obsługiwany przez tę wersję aplikacji), oraz parsuje każdy rekord w każdej sekcji przez odpowiadające `fromJson`. Pierwszy niepoprawny rekord przerywa całą walidację z komunikatem wskazującym sekcję i numer rekordu — **zero rekordów** trafia do bazy, jeśli cokolwiek jest złe.
  2. `import(BackupImportPreview) -> Future<void>` — zapisuje już zwalidowane dane przez istniejące repozytoria (`save*`), które wszystkie robią upsert po `id`. Rekordy o pasującym ID są nadpisywane; nic, czego nie ma w backupie, nie jest usuwane.
- Wczytanie pliku idzie przez kolejny conditional-import writer/reader (`backup_file_reader/`, analogicznie do ADR-016/ADR-018): native czyta plik z podanej ścieżki, web/stub rzuca czytelny `UnsupportedError`.
- UI (ekran "O aplikacji"): pole tekstowe na ścieżkę pliku (bez file pickera — patrz "Świadomie pominięte" niżej), przycisk "Wczytaj i zwaliduj", a po udanej walidacji dialog potwierdzenia pokazujący liczby rekordów per sekcja i jawne ostrzeżenie "Rekordy o tych samych ID... zostaną nadpisane... Tej operacji nie można cofnąć" przed faktycznym zapisem.

Świadomie pominięte (mniejszy zakres, nie architektoniczne "nie da się"):

- Brak prawdziwego file pickera (`file_picker`/`file_selector`) — użytkownik wkleja ścieżkę, którą i tak zobaczył po eksporcie. Dodanie file pickera to osobna, przyszła decyzja o nowej zależności, nie blokuje pierwszego działającego importu.
- Brak importu na Web, spójnie z eksportem (ADR-018) i statusem Web jako platformy warunkowej.
- Import nie łączy się z odczytem/scalaniem "inteligentnym" (np. wykrywaniem konfliktów wersji `revision`) - to należy do przyszłego Etapu 10 (sync), nie do prostego przywracania z lokalnego pliku.

Uzasadnienie:

- Rozdzielenie "waliduj" od "zapisz" na dwie osobne, jawne metody wprost realizuje wymóg z `DATA_MODEL.md` i daje UI naturalne miejsce na krok potwierdzenia między nimi.
- Merge-by-upsert (zamiast pełnego zastąpienia lokalnej bazy) jest bezpieczniejszym domyślnym zachowaniem: przywrócenie starszego backupu nie kasuje danych dodanych po jego utworzeniu, chyba że mają to samo ID.

## ADR-018: Pierwszy backup JSON

Status: accepted

Kontekst:

- ADR-012D i `docs/DATA_MODEL.md` ("Backup") wymagały eksportu JSON niezależnego od legacy, oddzielonego od raportów PDF/CSV/XLSX. `IMPLEMENTATION_STATUS.md` miał to jako pkt 2 "Następny krok".
- Część encji (`Client`, `Location` + `LocationContact`/`LocationPowerConnector`, `PowerPreset` + `PowerOutletTemplate`) nie miała jeszcze `toJson`/`fromJson` — tylko `Project` (z pełnym drzewem) i `CatalogDevice` je miały.

Decyzja:

- Dodano `toJson`/`fromJson` do wszystkich encji, których brakowało, żeby każdy top-level agregat dało się zserializować.
- Dodano `AppBackupService` (`infrastructure/backup/`): buduje jeden JSON z `BackupManifest` (`schemaVersion`, `appName`, `appVersion`, `createdAt`, `workspaceId`, `recordCounts`) i sekcją `data` z pełnymi projektami, klientami, lokacjami, katalogiem i presetami.
- `schemaVersion` w manifeście (`appBackupFormatVersion`) jest **niezależny** od wersji schematu Drift — wersjonuje sam format pliku backupu, nie wewnętrzny schemat SQLite. Nie mają obowiązku być równoległe.
- Zapis pliku idzie przez conditional import (`backup_file_writer_native.dart` / `_web.dart` / `_stub.dart`), analogicznie do połączenia z bazą danych (ADR-016): native zapisuje do `Documents/StageCalc/backups/`, web na razie rzuca `UnsupportedError` z czytelnym komunikatem zamiast próbować niepewnego mechanizmu pobierania w przeglądarce.
- Wejście do funkcji: przycisk "Utwórz kopię zapasową (JSON)" na ekranie "O aplikacji" (`AboutScreen`) — to funkcja aplikacyjna, nie projektowa, więc pasuje tam zgodnie z `docs/DATA_MODEL.md` ("ekran O aplikacji jako funkcja aplikacyjna").
- To jest **eksport-only**. Import backupu (z walidacją przed zapisem, jak wymaga `DATA_MODEL.md`) jest świadomie poza zakresem tej decyzji.

Uzasadnienie:

- Backup jest podstawowym zabezpieczeniem przed utratą danych i ma powstać przed sync (ADR-012D) — to zostało zachowane w kolejności prac.
- Rozdzielenie wersji formatu backupu od wersji schematu Drift pozwala później zmieniać jedno bez wymuszania zmiany drugiego (np. dodanie pola do backupu bez migracji SQLite).
- Ten sam wzorzec conditional-import co połączenie z bazą (ADR-016) utrzymuje spójność w sposobie obsługi różnic platformowych w projekcie.

Znane ograniczenie:

- Backup na Web nie działa. Wymagałby albo mechanizmu pobierania pliku w przeglądarce (Blob + link), albo zaakceptowania, że na Web funkcja jest niedostępna do czasu realnej potrzeby.

## ADR-017: Pierwsza integracja z PocketBase (push, bez syncu)

Status: accepted

Kontekst:

- LXC 113 (`stagecalc`, 192.168.0.113) ma działający PocketBase 0.40.4 za Caddy (`/api`, `/_`), bez żadnego schematu i bez konta admina. ADR-012 zostawiał backend syncu jako otwarty wybór (PocketBase/Supabase/własne API) - PocketBase jest tym, co realnie jest już postawione.
- Użytkownik poprosił o pełny schemat kolekcji według `docs/DATA_MODEL.md` oraz o pierwszy prawdziwy push lokalnego `Project` do PocketBase, bez UI i bez obsługi konfliktów.

Decyzja:

- Utworzono w PocketBase 13 kolekcji odzwierciedlających 1:1 obecne tabele Drift (nie hipotetyczny przyszły model): `clients`, `locations`, `location_contacts`, `location_power_connectors`, `catalog_devices`, `power_presets`, `power_outlet_templates`, `projects`, `project_groups`, `project_items`, `project_distros`, `project_outlets`, `power_connections`, `project_trusses`. Każda ma pole `local_id` (unikalny klucz lokalny, nie ten sam co PocketBase `id`) plus `created_at`/`updated_at`/`deleted_at`/`revision`/`deleted` gdzie ma to sens.
- Encje nie mające jeszcze implementacji w aplikacji (Workspace/AppUser, ConnectorTypeDefinition jako kolekcja, tabele nośności kratownic, haki grup) **nie zostały utworzone** - `ConnectorTypeDefinition` pozostaje stałym słownikiem w kodzie (`ConnectorTypes` w `power_models.dart`), zgodnie z tym co `DATA_MODEL.md` już sugerował ("na start może być seedowany jako dane stałe aplikacji").
- Dodano `PocketBaseProjectSyncService` (`features/projects/data/pocketbase_project_sync_service.dart`): jednokierunkowy push jednego `Project` z pełnym drzewem (grupy, pozycje, rozdzielnice, gniazda, połączenia, kratownice) plus opcjonalny `Client`/`Location`. Upsert po `local_id` (idempotentny - ponowny push aktualizuje te same rekordy zamiast tworzyć duplikaty), ale **bez wykrywania konfliktów** i **bez odczytu z powrotem do lokalnej bazy**.
- Adres backendu (`PocketBaseClientProvider`) jest na razie zahardkodowany na `http://192.168.0.113` - nie ma jeszcze ekranu ustawień do jego konfiguracji.
- Dowód działania: `flutter/tool/push_demo_project.dart` (`dart run tool/push_demo_project.dart`) - pushuje projekt demo i wypisuje zdalne ID. Zweryfikowano ręcznie w PocketBase, że rekordy i relacje (`project` -> `project_groups` -> `project_items` itd.) są poprawne, oraz że podwójne uruchomienie nie tworzy duplikatów.

Uzasadnienie:

- Schemat 1:1 z obecnymi tabelami Drift, a nie z pełnym `DATA_MODEL.md`, unika projektowania kolekcji pod funkcje które jeszcze nie istnieją w aplikacji (kratownice - haki/tabele nośności, konta/role) - dokładnie ten typ przedwczesnej abstrakcji, którego projekt ma unikać.
- Push zamiast pełnego dwukierunkowego syncu jest świadomie minimalnym pierwszym krokiem: dowodzi, że połączenie i mapowanie modelu działają, bez podejmowania jeszcze decyzji o strategii rozwiązywania konfliktów (to osobna, większa decyzja projektowa).

Ryzyka i znane ograniczenia (do adresowania, zanim to wyjdzie poza prywatną sieć LAN):

- **Wszystkie reguły dostępu kolekcji są puste (publiczne)** - każdy z dostępem do `http://192.168.0.113` może czytać/tworzyć/edytować/usuwać dowolny rekord bez logowania. Akceptowalne tylko w obecnej, prywatnej sieci LAN, do czasu zaprojektowania prawdziwego modelu autoryzacji.
- Push nie usuwa po stronie PocketBase rekordów, które lokalnie zostały soft-deleted (`deletedAt`) - `deleted`/`deleted_at` istnieją w schemacie, ale serwis jeszcze ich nie ustawia.
- Brak odczytu/importu z PocketBase - to tylko kierunek lokalne -> zdalne.

## ADR-016: Wsparcie lokalnej bazy na Web (Drift + sqlite3 wasm)

Status: accepted

Kontekst:

- `flutter build web` nie kompilował się w ogóle: `app_database.dart` używał `dart:io` (`File`, `getApplicationDocumentsDirectory`) i `NativeDatabase` z Drift, co pod spodem wymaga `dart:ffi` - niedostępnego w kompilacji na web (dart2js/wasm). Aplikacja nigdy nie miała działającej ścieżki bazy danych na Web, mimo że ADR-011 to przewidywał ("Web pozostaje platformą warunkową... adapter Drift web").

Decyzja:

- Rozdzielono połączenie z bazą na trzy pliki w `infrastructure/local_database/connection/` wybierane przez conditional import (`connection_stub.dart` / `connection_native.dart` / `connection_web.dart`), spinane przez `connection/connection.dart`. `app_database.dart` nie zawiera już żadnego kodu specyficznego dla platformy.
- Native (`dart.library.io`): bez zmian, `NativeDatabase.createInBackground` na pliku w katalogu dokumentów.
- Web (`dart.library.js_interop`): `drift/wasm.dart` (`WasmDatabase.open`) z `sqlite3.wasm` i `drift_worker.js` skopiowanymi do `web/` (pliki binarne, nie są częścią źródeł Dart - trzeba je podmieniać przy każdej istotnej podmianie wersji `drift`/`sqlite3`).
- Dodano `sqlite3` jako bezpośrednią zależność (wymagane przez `package:sqlite3/wasm.dart`), usunięto `sqlite3_flutter_libs` (od wersji 0.6.0 pakiet jest pustym no-opem, jego własny README zaleca usunięcie po migracji na `sqlite3` v3.x).

Uzasadnienie:

- Zgodnie z ADR-011: web ma działać przez Drift + sqlite3 wasm, nie osobna implementacja IndexedDB.
- Podział przez conditional import pozwala trzymać jeden model domenowy i jeden `AppDatabase`, bez duplikowania logiki tabel/migracji per platforma.

Znane ograniczenie (do rozwiązania później, patrz PS niżej):

- `WasmDatabase.open` próbuje wybrać najbardziej trwałą implementację storage (OPFS), ale OPFS/`SharedArrayBuffer` wymagają bezpiecznego kontekstu przeglądarki (HTTPS lub `localhost`). Serwer LXC 113 (`stagecalc`, 192.168.0.113) obecnie nie ma domeny ani TLS, więc przeglądarka spada do `sharedIndexedDb` - działa, ale zapisy mogą zostać utracone przy twardym odświeżeniu/awarii karty tuż po zapisie (zweryfikowane empirycznie: nowo dodany projekt znikał po `location.reload()` mimo widocznego komunikatu "Projekt zapisany lokalnie"). Użytkownik świadomie zaakceptował to ryzyko do czasu, aż pojawi się domena i możliwość automatycznego Let's Encrypt w Caddy. Gdy domena będzie dostępna, dodać w bloku SPA Caddyfile nagłówki `Cross-Origin-Opener-Policy: same-origin` i `Cross-Origin-Embedder-Policy: require-corp`, co odblokuje OPFS.

## ADR-015: Rozbicie ProjectEditorScreen na kontroler i widoki

Status: accepted

Kontekst:

- `project_editor_screen.dart` urósł do ok. 3900 linii i stał się dokładnie tym "nadmiernie dużym komponentem kalkulatora", który ADR-001 i `FEATURE_SCOPE.md` (sekcja "Elementy do pominięcia lub przeprojektowania") wskazują jako wzorzec do unikania przy migracji z legacy.
- Plik łączył w jednym miejscu: stan UI (`_view`, `_hasChanges`), ładowanie referencji (klienci, lokacje, presety) bezpośrednio z repozytoriów Drift, wszystkie mutacje projektu (dodawanie/edycja/usuwanie grup, pozycji, rozdzielnic, połączeń), wywołania serwisów obliczeniowych w `build()` i ok. 15 prywatnych klas dialogów/kart.
- Brak wydzielonej warstwy sprawił, że błąd "osieroconych połączeń" (usunięcie grupy bez usunięcia jej `PowerConnection`, dokładnie ten sam problem co w legacy, opisany w `docs/legacy_stagecalc_debug_context.md`) przeszedł niezauważony: logika usuwania grupy i rozdzielnicy była zduplikowana w dwóch miejscach zamiast żyć w jednym testowalnym miejscu.

Decyzja:

- Wprowadzić `ProjectEditorController` (`ChangeNotifier`) w `features/projects/presentation/project_editor_controller.dart`, który:
  - trzyma stan edytora: bieżący `Project`, listę klientów/lokacji/presetów, flagę `hasChanges`, tryb widoku,
  - ładuje referencje z repozytoriów,
  - wykonuje wszystkie mutacje projektu (dodaj/edytuj/usuń grupę, pozycje, rozdzielnice, gniazda, połączenia) i zapisuje przez `ProjectRepository`,
  - udostępnia jako gettery wyniki `ProjectTotalsService`, `PowerCalculationService` i `PatchValidationService` przeliczone z bieżącego stanu.
- `ProjectEditorScreen` zostaje cienkim widokiem: pokazuje dialogi (bo tylko widok ma `BuildContext`), a wynik dialogu przekazuje do metody kontrolera. Widok nie wykonuje już samodzielnie logiki czyszczenia powiązanych rekordów.
- Klasy dialogów i kart (`_DistroCreateDialog`, `_ConnectionDialog`, `_OutletEditDialog`, `_GroupCard`, `_ConnectionCard` itd.) zostają przeniesione z jednego pliku do osobnych plików w `features/projects/presentation/project_editor/`, pogrupowane tematycznie (rozdzielnice, połączenia, grupy/pozycje, metadane projektu), zamiast żyć w jednym pliku 1:1 z ekranem.
- Nie wprowadzamy nowej zależności do zarządzania stanem (np. Riverpod/Bloc) na tym etapie — `ChangeNotifier` z Fluttera wystarcza i nie zwiększa powierzchni zależności projektu.

Uzasadnienie:

- Zgodność z ADR-001: rozdzielenie `domain`/`data`/`presentation` miało dotyczyć również największego ekranu aplikacji, nie tylko nowych funkcji.
- Logika mutacji projektu (np. "usunięcie grupy usuwa też jej połączenia") staje się możliwa do przetestowania niezależnie od drzewa widgetów i bez duplikacji między operacjami.
- Mniejsze, tematyczne pliki prezentacji łatwiej przeglądać i code-review'ować niż jeden plik na 3900 linii.

Konsekwencje:

- Widoki nie mogą już zakładać, że mają bezpośredni dostęp do repozytoriów — wywołują metody kontrolera.
- Każda nowa operacja na projekcie (dodanie kolejnego typu mutacji) powinna trafiać do `ProjectEditorController`, nie bezpośrednio do widgetu ekranu.
- Testy widgetowe edytora projektu pozostają aktualne, ponieważ zachowanie UI (teksty, dialogi, przepływ) się nie zmienia — zmienia się tylko miejsce, w którym żyje logika.

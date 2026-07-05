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

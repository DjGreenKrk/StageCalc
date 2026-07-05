# Changelog

Wszystkie istotne zmiany w projekcie StageCalc Flutter będą opisywane w tym pliku.

Format jest oparty o Keep a Changelog, a wersjonowanie docelowo powinno używać schematu `MAJOR.MINOR.PATCH+BUILD`.

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

# Changelog

Wszystkie istotne zmiany w projekcie StageCalc Flutter będą opisywane w tym pliku.

Format jest oparty o Keep a Changelog, a wersjonowanie docelowo powinno używać schematu `MAJOR.MINOR.PATCH+BUILD`.

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

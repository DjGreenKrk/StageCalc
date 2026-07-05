# StageCalc

StageCalc to techniczny kalkulator wydarzenia z ekosystemu GreenCrew Tools. Aplikacja jest migrowana do Flutter + Dart jako czystsza, lokalna wersja offline-first dla pracy terenowej na Androidzie i Windows.

Obecna wersja w tym repozytorium jest w trakcie budowy. Legacy StageCalc jest źródłem wymagań domenowych, ale nowy Flutter nie zachowuje kompatybilności ze starymi formatami danych, trasami ani strukturą PocketBase.

## Status

Aktualnie działa:

- aplikacja Flutter w katalogu `flutter/`,
- responsywny shell GreenCrew Tools,
- tryb ciemny i zielony akcent GreenCrew,
- ekrany: Projekty, Katalog, Lokacje, Klienci, Info,
- lokalna baza Drift/SQLite,
- projekty z grupami i pozycjami,
- ręczne pozycje sprzętowe,
- dodawanie pozycji z katalogu,
- wyszukiwanie i filtrowanie katalogu,
- klienci i lokacje jako dane lokalne,
- presety rozdzielnic,
- rozdzielnice runtime w projekcie,
- podstawowy patcher z połączeniami grupa -> gniazdo,
- liczenie obciążeń gniazd i faz `L1/L2/L3`,
- walidacja wielokrotnego użycia gniazda,
- testy domenowe, repozytoryjne i widgetowe.

Jeszcze nie jest gotowe:

- pełny wizualny patcher,
- moduł kratownic,
- backup JSON,
- eksport PDF,
- synchronizacja z hostowaną bazą,
- konta użytkowników i role.

Szczegółowy stan prac jest w [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md).

## Założenia produktu

- Offline-first: lokalna baza jest źródłem prawdy.
- Android i Windows są platformami priorytetowymi.
- Web/iOS są możliwe później, ale nie blokują modelu offline-first.
- Synchronizacja zostanie dodana jako osobna warstwa.
- Podstawowa praca nie wymaga logowania.
- UI ma być zgodny z GreenCrew Tools: techniczny, terenowy, krótki w komunikatach i domyślnie ciemny.

## Struktura repozytorium

```text
.
├── docs/
│   ├── DATA_MODEL.md
│   ├── DECISIONS.md
│   ├── FEATURE_SCOPE.md
│   ├── IMPLEMENTATION_STATUS.md
│   ├── MIGRATION_PLAN.md
│   └── greencrew_docs/
└── flutter/
    ├── lib/
    ├── test/
    ├── pubspec.yaml
    └── README.md
```

## Wymagania deweloperskie

- Flutter SDK `3.44.3` lub zgodny z projektem,
- Dart z Flutter SDK,
- Visual Studio z narzędziami C++ do buildu Windows,
- Android toolchain, jeśli budujesz APK.

Na tej maszynie Flutter jest dostępny po dodaniu do sesji PowerShell:

```powershell
$env:PATH = "C:\Users\julek\SDK\flutter_windows_3.44.3-stable\flutter\bin;$env:PATH"
```

## Uruchomienie

```powershell
cd flutter
flutter pub get
flutter run -d windows
```

Android:

```powershell
cd flutter
flutter run -d android
```

## Testy i analiza

```powershell
cd flutter
dart format .
flutter analyze
flutter test
```

Build Windows:

```powershell
cd flutter
flutter build windows
```

Plik wynikowy:

```text
flutter/build/windows/x64/runner/Release/stagecalc.exe
```

## Dokumentacja

- [Plan migracji](docs/MIGRATION_PLAN.md)
- [Model danych](docs/DATA_MODEL.md)
- [Zakres funkcji](docs/FEATURE_SCOPE.md)
- [Decyzje architektoniczne](docs/DECISIONS.md)
- [Status implementacji](docs/IMPLEMENTATION_STATUS.md)
- [Changelog](CHANGELOG.md)

## Release

Nazewnictwo artefaktów:

- `StageCalc-vX_Y_Z-android.apk`
- `StageCalc-vX_Y_Z-windows.zip`

Przed wydaniem release należy uruchomić:

```powershell
cd flutter
dart format .
flutter analyze
flutter test
flutter build windows
```

## Licencja

Projekt prywatny / wewnętrzny GreenCrew Tools. Licencja publiczna nie została jeszcze określona.

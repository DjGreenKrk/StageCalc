# StageCalc

StageCalc to techniczny kalkulator wydarzeń dla ekipy GreenCrew Tools — pomaga zaplanować zasilanie, masę i infrastrukturę techniczną (oświetlenie, nagłośnienie, multimedia, rigging) dla konkretnego wydarzenia, zanim sprzęt trafi na plac budowy.

Działa **offline-first**: wszystkie dane są zapisywane lokalnie na urządzeniu, więc aplikacja działa bez internetu w hali, w terenie czy w trasie. Dostępna na **Androida** i **Windows**.

## Co potrafi

- **Projekty** — dla każdego wydarzenia lista grup sprzętu z pozycjami, automatyczne sumowanie mocy, prądu (z rozbiciem na fazy L1/L2/L3) i masy.
- **Katalog urządzeń** — biblioteka sprzętu z kategoriami (oświetlenie, nagłośnienie, multimedia, rozdzielnia, kabel, rigging, inne), gotowa do użycia w dowolnym projekcie.
- **Import GDTF** — wczytanie jednego lub wielu plików `.gdtf` (branżowy format opisu urządzeń oświetleniowych) prosto do katalogu, z podglądem przed zapisem.
- **Import z Gremium Panel** — wczytanie listy sprzętu z eksportu Gremium do projektu, z panelem wyboru, co faktycznie zaimportować.
- **Rozdzielnice i patcher** — tworzenie rozdzielnic z gniazdami, wizualne łączenie grup sprzętu z gniazdami, kontrola obciążenia i wielokrotnego użycia gniazda.
- **Kratownice (rigging)** — dobór udźwigu kratownicy na podstawie danych producenta i przypisanych haków/grup.
- **Lokacje i klienci** — dane obiektu (w tym dostępna moc z przyłączy energetycznych) i baza klientów, wielokrotnego użytku między projektami.
- **Raporty** — eksport podsumowania projektu do PDF lub tekstu, gotowe do wysłania klientowi albo wydruku.
- **Kopia zapasowa** — eksport/import całej bazy do jednego pliku JSON.
- **Tryb offline z opcjonalną synchronizacją** — praca lokalna nie wymaga konta; synchronizacja z serwerem zespołu jest opcjonalna, dla ekip pracujących na wspólnych danych.

Pełna lista zmian w kolejnych wersjach: [CHANGELOG.md](CHANGELOG.md).

## Pobieranie

Najnowsza wersja jest zawsze dostępna na stronie [Releases](https://github.com/DjGreenKrk/StageCalc/releases/latest):

- **Android** — pobierz `StageCalc-vX_Y_Z-android.apk`, otwórz plik na telefonie/tablecie i zainstaluj (może być potrzebne włączenie instalacji z nieznanych źródeł dla przeglądarki/menedżera plików, z którego pobierasz).
- **Windows** — pobierz `StageCalc-vX_Y_Z-windows.zip`, rozpakuj do dowolnego folderu i uruchom `stagecalc.exe`. Nie wymaga instalacji.

## Pierwsze kroki

1. Utwórz nowy projekt na ekranie **Projekty**.
2. Dodaj grupy i pozycje sprzętu — ręcznie, z **Katalogu**, albo importem z pliku GDTF/Gremium.
3. Sprawdź podsumowanie mocy, prądu i masy na bieżąco aktualizowane w projekcie.
4. Jeśli sprzęt wymaga podłączenia — utwórz rozdzielnicę i połącz grupy z gniazdami w patcherze.
5. Wyeksportuj gotowy raport (PDF/tekst) albo zrób kopię zapasową danych z ekranu **Info**.

## Licencja

StageCalc jest udostępniany na warunkach [PolyForm Shield License 1.0.0](https://polyformproject.org/licenses/shield/1.0.0) - pełny tekst w pliku [LICENSE](LICENSE), a co to oznacza w praktyce (co wolno, czego nie, marki/branding, stan historyczny sprzed wersji 0.4.0) w [LICENSING.md](LICENSING.md).

---

## Dla deweloperów

### Struktura repozytorium

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

### Wymagania

- Flutter SDK `3.44.x` lub nowszy (Dart dołączony w SDK),
- Visual Studio z narzędziami C++ do buildu Windows,
- Android toolchain, jeśli budujesz APK.

Na tej maszynie Flutter jest dostępny po dodaniu do sesji PowerShell:

```powershell
$env:PATH = "C:\Users\julek\SDK\flutter_windows_3.44.3-stable\flutter\bin;$env:PATH"
```

### Uruchomienie

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

### Testy i analiza

```powershell
cd flutter
dart format .
flutter analyze
flutter test
```

### Build

```powershell
cd flutter
flutter build windows
flutter build apk --release
```

Podpisywanie release APK własnym kluczem wymaga lokalnego `android/key.properties` (nieobecnego w repo, patrz `docs/DECISIONS.md`) — bez niego build automatycznie wraca do klucza debug.

Plik wynikowy (Windows):

```text
flutter/build/windows/x64/runner/Release/stagecalc.exe
```

### Release

Nazewnictwo artefaktów:

- `StageCalc-vX_Y_Z-android.apk`
- `StageCalc-vX_Y_Z-windows.zip`

Budowane jednym poleceniem:

```powershell
cd flutter
dart run tool/package_release.dart
```

Przed wydaniem release należy upewnić się, że przechodzą testy i analiza (patrz "Testy i analiza" wyżej).

### Dokumentacja projektowa

- [Plan migracji](docs/MIGRATION_PLAN.md)
- [Model danych](docs/DATA_MODEL.md)
- [Zakres funkcji](docs/FEATURE_SCOPE.md)
- [Decyzje architektoniczne](docs/DECISIONS.md)
- [Status implementacji](docs/IMPLEMENTATION_STATUS.md)

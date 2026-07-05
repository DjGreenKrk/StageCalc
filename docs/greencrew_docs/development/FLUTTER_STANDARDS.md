# GreenCrew Tools Flutter Standards

## Cel dokumentu

Ten dokument opisuje zalecenia techniczne dla aplikacji GreenCrew Tools tworzonych we Flutterze.

Nie jest pełną architekturą konkretnej aplikacji, ale wspólnym punktem startowym dla nowych projektów.

---

# 1. Założenia

Aplikacje GreenCrew Tools powinny być:

- offline first,
- multiplatformowe,
- możliwe do uruchomienia na Androidzie,
- możliwe do rozbudowy na Windows / Web,
- proste w utrzymaniu,
- gotowe do pracy terenowej.

---

# 2. Platformy

Priorytet:

1. Android / telefon
2. Android / tablet
3. Windows
4. Web
5. iOS / macOS, jeśli projekt tego wymaga

---

# 3. UI

Bazą jest Material Design.

Zalecenia:

- dark mode jako domyślny,
- wspólny motyw GreenCrew,
- jeden kolor akcentu,
- komponenty zgodne z `DESIGN_SYSTEM.md`,
- brak zbędnych animacji.

---

# 4. Font

Domyślnie używać Roboto.

Jeśli projekt używa innego fontu, musi on być dołączony jako asset.

Nie zakładać, że font jest zainstalowany w systemie użytkownika.

---

# 5. Ikony

Domyślnie używać:

- Material Icons,
- Material Symbols,
- `MaterialIcons-Regular`, jeśli projekt już z tego korzysta.

Nie mieszać wielu bibliotek ikon bez potrzeby.

---

# 6. Struktura projektu

Zalecana struktura:

```text
lib/
  main.dart
  app/
    app.dart
    theme/
    router/
  core/
    constants/
    errors/
    utils/
    widgets/
  features/
    feature_name/
      data/
      domain/
      presentation/
  shared/
    widgets/
    models/
    services/
```

Dla małych aplikacji struktura może być prostsza, ale powinna dać się rozbudować.

---

# 7. Wspólne komponenty

Nowe aplikacje powinny korzystać z komponentów GreenCrew.

Przykłady:

- GreenCrewAppScaffold
- GreenCrewCard
- GreenCrewButton
- GreenCrewTextField
- GreenCrewSearchBar
- GreenCrewEmptyState
- GreenCrewErrorState
- GreenCrewOfflineBanner
- GreenCrewConfirmDialog

---

# 8. Stan aplikacji

Dopuszczalne rozwiązania:

- Riverpod,
- Provider,
- Bloc,
- ChangeNotifier dla prostych aplikacji.

Ważniejsze od wyboru biblioteki jest konsekwentne użycie jednego podejścia w projekcie.

---

# 9. Dane lokalne

Aplikacje offline first powinny mieć lokalną bazę danych.

Możliwe rozwiązania:

- Drift,
- Isar,
- Hive,
- SQLite.

Wybór zależy od aplikacji.

Dane krytyczne nie powinny istnieć tylko w pamięci aplikacji.

---

# 10. Synchronizacja

Synchronizacja powinna być zaprojektowana jako osobna warstwa.

Aplikacja powinna działać bez synchronizacji.

Zalecane stany:

- zapisano lokalnie,
- oczekuje na synchronizację,
- zsynchronizowano,
- konflikt,
- błąd synchronizacji.

---

# 11. Eksport

Jeśli aplikacja generuje dane techniczne, powinna obsługiwać eksport.

Preferowane formaty:

- PDF,
- CSV,
- JSON backup,
- XLSX, jeśli dane są tabelaryczne.

---

# 12. Routing

Routing powinien być przewidywalny.

Dla większych aplikacji zalecane:

- go_router.

Dla małych aplikacji można użyć prostszego Navigatora.

---

# 13. Responsywność

Ekrany powinny reagować na szerokość.

Przykładowe progi:

- telefon: do 600 px,
- tablet: 600-1024 px,
- desktop: powyżej 1024 px.

---

# 14. Komunikaty i błędy

Błędy powinny być mapowane na komunikaty użytkownika.

Nie wyświetlać surowych wyjątków.

Log techniczny może istnieć osobno.

---

# 15. Testy

Zalecane minimum:

- testy logiki obliczeniowej,
- testy parserów,
- testy eksportów,
- testy krytycznych walidacji.

Dla StageCalc szczególnie ważne są testy obliczeń.

---

# 16. Build i release

Releasy powinny mieć spójne nazewnictwo.

Preferowany format artefaktów:

```text
NazwaAplikacji-vX_Y_Z-platform.ext
```

Przykłady:

```text
CableListTool-v2_0_0-windows.zip
StageCalc-v1_0_0-android.apk
```

---

# 17. Zasady dla AI

AI pracujące nad projektem powinno:

- najpierw czytać dokumenty z katalogu `branding/`,
- przestrzegać `DESIGN_SYSTEM.md`,
- nie tworzyć nowego stylu UI bez potrzeby,
- nie zmieniać architektury bez uzasadnienia,
- preferować prostotę,
- zachowywać offline first.

---

# 18. Zasada końcowa

Flutter ma być narzędziem do tworzenia praktycznych aplikacji technicznych, a nie celem samym w sobie.

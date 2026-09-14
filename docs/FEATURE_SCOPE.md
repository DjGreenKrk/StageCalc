# StageCalc Flutter Migration - Feature Scope

## Cel dokumentu

Ten dokument opisuje aktualny zakres funkcjonalny StageCalc na podstawie wersji legacy w `legacy/pwa/app` oraz wskazuje, co powinno wejść do pierwszej czystej wersji Flutter + Dart.

## Aktualna aplikacja

StageCalc jest aplikacją do planowania technicznego produkcji eventowych. Obecna wersja jest zbudowana jako PWA w Next.js/React/TypeScript z PocketBase jako backendem. Najważniejszym bytem domenowym jest `Calculation`, czyli zapisany projekt techniczny. Jeden projekt jest używany przez moduł zasilania i moduł kratownic.

Na etapie migracji Flutter obecna aplikacja legacy jest źródłem wymagań domenowych, ale nie jest kontraktem kompatybilności. Nowa aplikacja nie musi zachowywać starych tras, nazw pól, formatów JSON ani backward compatibility z historycznymi strukturami danych.

## Kontekst GreenCrew Tools

StageCalc jest częścią ekosystemu GreenCrew Tools. Nowa aplikacja Flutter powinna być projektowana zgodnie z dokumentami:

- `docs/greencrew_docs/branding/GREENCREW_BRANDING.md`
- `docs/greencrew_docs/branding/DESIGN_SYSTEM.md`
- `docs/greencrew_docs/branding/ICONOGRAPHY.md`
- `docs/greencrew_docs/branding/WRITING_GUIDELINES.md`
- `docs/greencrew_docs/project/BRANDING_STAGECALC.md`
- `docs/greencrew_docs/development/ARCHITECTURE.md`
- `docs/greencrew_docs/development/FLUTTER_STANDARDS.md`
- `docs/greencrew_docs/development/CODING_STANDARDS.md`

Najważniejsze konsekwencje:

- domyślny dark mode,
- paleta GreenCrew: `#00C853`, `#00E676`, `#00B248`, czarne tło i neutralne powierzchnie,
- techniczny, terenowy charakter UI,
- telefon jako platforma referencyjna,
- Material Design i Material Icons/Symbols,
- krótkie, konkretne polskie komunikaty,
- brak stylistyki lifestyle, CAD, ERP i korporacyjnych dashboardów,
- ikona StageCalc: heksagon GreenCrew z geometryczną błyskawicą.

## Aktualne funkcje

### Autoryzacja i profil

To jest funkcjonalność obecnej aplikacji legacy, nie wymaganie MVP Flutter.

- Logowanie, rejestracja i reset hasła przez PocketBase.
- Role użytkownika: `admin`, `technician`, `viewer`.
- Profil użytkownika z nazwą, avatarem i ulubionymi urządzeniami.
- Obecna warstwa profilu nosi ślady migracji z Firebase, więc w Flutterze powinna być uproszczona.

W Flutter MVP podstawowa praca lokalna nie wymaga logowania. Konto, role i synchronizacja mogą zostać dodane później jako osobna warstwa.

### Kalkulacje zasilania

- Tworzenie nowej kalkulacji i edycja zapisanej kalkulacji.
- Grupowanie urządzeń w grupy robocze.
- Dodawanie urządzeń katalogowych do grup.
- Scalanie ilości dla zwykłych urządzeń i osobne traktowanie kabli jako pozycji metrażowych.
- Ręczne pozycje wagowe używane głównie w module kratownic.
- Obliczanie sum:
  - moc `W`,
  - prąd `A`,
  - masa `kg`.
- Typ zasilania grupy:
  - `1F`,
  - `3F_sym`.
- Przypisywanie grup do gniazd starszym sposobem przez `assignedConnectorIds`.
- Eksport kalkulacji do PDF.

### Rozdzielnice, przyłącza i patchowanie

- Wybieranie lokalizacji i import jej grup przyłączy do kalkulacji.
- Dodawanie rozdzielnic z katalogu.
- Dodawanie szybkich rozdzielnic tymczasowych:
  - gniazdo 16A,
  - przedłużacz/listwa 4x16A,
  - rozdzielnica 32A na 6x16A.
- Tworzenie i zarządzanie presetami gniazd rozdzielnic.
- Wizualny patcher:
  - pokazuje gniazda rozdzielnicy,
  - łączy gniazdo z grupą urządzeń,
  - łączy gniazdo z inną rozdzielnicą,
  - wybiera fazy `L1/L2/L3` dla grup 1F podłączanych do gniazda `All`,
  - wykrywa zajętość faz,
  - pozwala dodawać notatki do połączeń.
- Rekurencyjne liczenie obciążenia rozdzielnic i globalnego obciążenia faz.
- Ostrzeganie przed przeciążeniem faz/gniazd.

### Katalog urządzeń

- Kategorie:
  - oświetlenie,
  - dźwięk,
  - multimedia,
  - okablowanie i dystrybucja,
  - rigging,
  - inne.
- CRUD katalogu w zależności od roli.
- Pola wspólne:
  - nazwa,
  - producent,
  - podkategoria,
  - moc,
  - prąd,
  - masa,
  - IP rating,
  - notatki.
- Pola specjalistyczne, np. DMX, jasność, rozdzielczość, typ kabla, wejścia/wyjścia dystrybucji, dane kratownic, WLL, typ sterowania wciągarki.

### Lokacje

- Lista i formularz lokacji.
- Dane podstawowe: nazwa, adres, pojemność, notatki.
- Kontakty lokacji.
- Linkowane dokumenty.
- Grupy przyłączy energetycznych lokacji.
- Obliczanie dostępnej mocy lokacji z przyłączy:
  - 1F: `230 V * A`,
  - 3F: `400 V * A * sqrt(3)`.
- Historyczna obsługa starszego pola `powerConnectors` nie jest wymaganiem Flutter MVP.

### Klienci

- Lista i formularz klientów.
- Dane: nazwa, osoba kontaktowa, email, telefon, adres, NIP, notatki.
- Klienci są przypisani do właściciela/użytkownika.

### Kratownice

- Moduł kratownic otwiera tę samą kalkulację co moduł zasilania.
- Dodawanie kratownic do projektu.
- Przypisywanie grup urządzeń do kratownic.
- Dodawanie obciążeń ręcznych.
- Obliczanie masy grup z urządzeń, ręcznych pozycji i haków.
- Liczenie wymaganej liczby haków na podstawie `riggingPoints`.
- Interpolacja tabeli nośności producenta po długości kratownicy.
- Ostrzeganie, gdy długość wymaga ekstrapolacji albo brakuje danych.
- Kontrola:
  - całkowitego limitu obciążenia,
  - obciążenia rozłożonego `kg/m`,
  - informacyjnego limitu punktowego.

### Ustawienia, i18n i shell aplikacji

- Sidebar i nawigacja.
- Motyw i podstawowa internacjonalizacja PL/EN.
- Strony ustawień/profilu.
- Istnieją też trasy eventów, ale są placeholderami lub kodem historycznym i nie powinny wyznaczać MVP Fluttera.

## Zakres MVP Flutter

Pierwsza wersja Flutter powinna objąć:

- lokalna baza offline-first,
- lista projektów/kalkulacji,
- edycja projektu,
- katalog urządzeń,
- klienci,
- lokacje,
- grupy urządzeń,
- rozdzielnice i presety gniazd,
- wizualne patchowanie w wersji funkcjonalnej,
- silnik obliczeń mocy/prądu/masy,
- moduł kratownic na poziomie obecnej funkcjonalności,
- eksport danych lub PDF w prostszej formie, jeśli PDF opóźnia MVP.
- ekran "O aplikacji" zgodny z GreenCrew Tools,
- bazowy motyw GreenCrew i komponenty wspólne.
- backup JSON w nowym formacie aplikacji,
- praca bez konta i bez Internetu,
- obsługa stanów: pusty, błąd, offline, brak wyników.

## Poza MVP

- Synchronizacja między urządzeniami.
- Pełny system kont i uprawnień online.
- Współdzielenie projektów.
- Zaawansowane konflikty sync.
- Import historycznej bazy PocketBase jako automatyczny migrator produkcyjny.
- Pełny model `Gniazdo -> konkretne pozycje z grupy`, jeśli nie jest wymagany od razu.
- Kompatybilność z formatami danych legacy.
- Zachowanie starych tras, nazw kolekcji i nazw pól PocketBase.
- Wymagane logowanie do podstawowej pracy lokalnej.
- Uprawnienia systemowe niezwiązane z konkretną funkcją.

## Elementy do zachowania jako wymagania

- Jedna kalkulacja/projekt jako wspólny kontener dla zasilania i kratownic.
- Katalog jako źródło danych technicznych.
- Lokacje jako źródło infrastruktury energetycznej.
- Presety rozdzielnic jako wielokrotnego użytku definicje gniazd.
- Połączenia jako osobne byty domenowe, a nie tylko stan UI.
- Obliczenia fazowe `L1/L2/L3` z obsługą `All`.
- Pole na przyszłe fazy projektu, ale bez implementowania workflow faz teraz.

## Elementy do pominięcia lub przeprojektowania

- Dziedzictwo Firebase/Firestore.
- Nazwy katalogów i hooków sugerujące Firestore.
- Eventy jako osobny stary moduł, dopóki nie zostanie zdefiniowany od nowa.
- Nadmiernie duży komponent kalkulatora jako wzorzec architektoniczny.
- Pełne kasowanie i odtwarzanie wszystkich połączeń przy zapisie.
- Mieszanie ID katalogowych, ID runtime i ID połączeń w jednym znaczeniu.
- Backward compatibility ze starymi polami i formatami danych, o ile nie zostanie osobno zamówiona.

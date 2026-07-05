# StageCalc Flutter Migration - Feature Scope

## Cel dokumentu

Ten dokument opisuje aktualny zakres funkcjonalny StageCalc na podstawie wersji legacy w `legacy/pwa/app` oraz wskazuje, co powinno wejsc do pierwszej czystej wersji Flutter + Dart.

## Aktualna aplikacja

StageCalc jest aplikacja do planowania technicznego produkcji eventowych. Obecna wersja jest zbudowana jako PWA w Next.js/React/TypeScript z PocketBase jako backendem. Najwazniejszym bytem domenowym jest `Calculation`, czyli zapisany projekt techniczny. Jeden projekt jest uzywany przez modul zasilania i modul kratownic.

Na etapie migracji Flutter obecna aplikacja legacy jest zrodlem wymagan domenowych, ale nie jest kontraktem kompatybilnosci. Nowa aplikacja nie musi zachowywac starych tras, nazw pol, formatow JSON ani backward compatibility z historycznymi strukturami danych.

## Kontekst GreenCrew Tools

StageCalc jest czescia ekosystemu GreenCrew Tools. Nowa aplikacja Flutter powinna byc projektowana zgodnie z dokumentami:

- `docs/greencrew_docs/branding/GREENCREW_BRANDING.md`
- `docs/greencrew_docs/branding/DESIGN_SYSTEM.md`
- `docs/greencrew_docs/branding/ICONOGRAPHY.md`
- `docs/greencrew_docs/branding/WRITING_GUIDELINES.md`
- `docs/greencrew_docs/project/BRANDING_STAGECALC.md`
- `docs/greencrew_docs/development/ARCHITECTURE.md`
- `docs/greencrew_docs/development/FLUTTER_STANDARDS.md`
- `docs/greencrew_docs/development/CODING_STANDARDS.md`

Najwazniejsze konsekwencje:

- domyslny dark mode,
- paleta GreenCrew: `#00C853`, `#00E676`, `#00B248`, czarne tlo i neutralne powierzchnie,
- techniczny, terenowy charakter UI,
- telefon jako platforma referencyjna,
- Material Design i Material Icons/Symbols,
- krotkie, konkretne polskie komunikaty,
- brak stylistyki lifestyle, CAD, ERP i korporacyjnych dashboardow,
- ikona StageCalc: heksagon GreenCrew z geometryczna blyskawica.

## Aktualne funkcje

### Autoryzacja i profil

To jest funkcjonalnosc obecnej aplikacji legacy, nie wymaganie MVP Flutter.

- Logowanie, rejestracja i reset hasla przez PocketBase.
- Role uzytkownika: `admin`, `technician`, `viewer`.
- Profil uzytkownika z nazwa, avatarem i ulubionymi urzadzeniami.
- Obecna warstwa profilu nosi slady migracji z Firebase, wiec w Flutterze powinna byc uproszczona.

W Flutter MVP podstawowa praca lokalna nie wymaga logowania. Konto, role i synchronizacja moga zostac dodane pozniej jako osobna warstwa.

### Kalkulacje zasilania

- Tworzenie nowej kalkulacji i edycja zapisanej kalkulacji.
- Grupowanie urzadzen w grupy robocze.
- Dodawanie urzadzen katalogowych do grup.
- Scalanie ilosci dla zwyklych urzadzen i osobne traktowanie kabli jako pozycji metrazowych.
- Reczne pozycje wagowe uzywane glownie w module kratownic.
- Obliczanie sum:
  - moc `W`,
  - prad `A`,
  - masa `kg`.
- Typ zasilania grupy:
  - `1F`,
  - `3F_sym`.
- Przypisywanie grup do gniazd starszym sposobem przez `assignedConnectorIds`.
- Eksport kalkulacji do PDF.

### Rozdzielnice, przylacza i patchowanie

- Wybieranie lokalizacji i import jej grup przylaczy do kalkulacji.
- Dodawanie rozdzielnic z katalogu.
- Dodawanie szybkich rozdzielnic tymczasowych:
  - gniazdo 16A,
  - przedluzacz/listwa 4x16A,
  - rozdzielnica 32A na 6x16A.
- Tworzenie i zarzadzanie presetami gniazd rozdzielnic.
- Wizualny patcher:
  - pokazuje gniazda rozdzielnicy,
  - laczy gniazdo z grupa urzadzen,
  - laczy gniazdo z inna rozdzielnica,
  - wybiera fazy `L1/L2/L3` dla grup 1F podlaczanych do gniazda `All`,
  - wykrywa zajetosc faz,
  - pozwala dodawac notatki do polaczen.
- Rekurencyjne liczenie obciazenia rozdzielnic i globalnego obciazenia faz.
- Ostrzeganie przed przeciazeniem faz/gniazd.

### Katalog urzadzen

- Kategorie:
  - oswietlenie,
  - dzwiek,
  - multimedia,
  - okablowanie i dystrybucja,
  - rigging,
  - inne.
- CRUD katalogu w zaleznosci od roli.
- Pola wspolne:
  - nazwa,
  - producent,
  - podkategoria,
  - moc,
  - prad,
  - masa,
  - IP rating,
  - notatki.
- Pola specjalistyczne, np. DMX, jasnosc, rozdzielczosc, typ kabla, wejscia/wyjscia dystrybucji, dane kratownic, WLL, typ sterowania wciagarki.

### Lokacje

- Lista i formularz lokacji.
- Dane podstawowe: nazwa, adres, pojemnosc, notatki.
- Kontakty lokacji.
- Linkowane dokumenty.
- Grupy przylaczy energetycznych lokacji.
- Obliczanie dostepnej mocy lokacji z przylaczy:
  - 1F: `230 V * A`,
  - 3F: `400 V * A * sqrt(3)`.
- Historyczna obsluga starszego pola `powerConnectors` nie jest wymaganiem Flutter MVP.

### Klienci

- Lista i formularz klientow.
- Dane: nazwa, osoba kontaktowa, email, telefon, adres, NIP, notatki.
- Klienci sa przypisani do wlasciciela/uzytkownika.

### Kratownice

- Modul kratownic otwiera te sama kalkulacje co modul zasilania.
- Dodawanie kratownic do projektu.
- Przypisywanie grup urzadzen do kratownic.
- Dodawanie obciazen recznych.
- Obliczanie masy grup z urzadzen, recznych pozycji i hakow.
- Liczenie wymaganej liczby hakow na podstawie `riggingPoints`.
- Interpolacja tabeli nosnosci producenta po dlugosci kratownicy.
- Ostrzeganie, gdy dlugosc wymaga ekstrapolacji albo brakuje danych.
- Kontrola:
  - calkowitego limitu obciazenia,
  - obciazenia rozlozonego `kg/m`,
  - informacyjnego limitu punktowego.

### Ustawienia, i18n i shell aplikacji

- Sidebar i nawigacja.
- Motyw i podstawowa internacjonalizacja PL/EN.
- Strony ustawien/profilu.
- Istnieja tez trasy eventow, ale sa placeholderami lub kodem historycznym i nie powinny wyznaczac MVP Fluttera.

## Zakres MVP Flutter

Pierwsza wersja Flutter powinna objac:

- lokalna baza offline-first,
- lista projektow/kalkulacji,
- edycja projektu,
- katalog urzadzen,
- klienci,
- lokacje,
- grupy urzadzen,
- rozdzielnice i presety gniazd,
- wizualne patchowanie w wersji funkcjonalnej,
- silnik obliczen mocy/pradu/masy,
- modul kratownic na poziomie obecnej funkcjonalnosci,
- eksport danych lub PDF w prostszej formie, jesli PDF opoznia MVP.
- ekran "O aplikacji" zgodny z GreenCrew Tools,
- bazowy motyw GreenCrew i komponenty wspolne.
- backup JSON w nowym formacie aplikacji,
- praca bez konta i bez Internetu,
- obsluga stanow: pusty, blad, offline, brak wynikow.

## Poza MVP

- Synchronizacja miedzy urzadzeniami.
- Pelny system kont i uprawnien online.
- Wspoldzielenie projektow.
- Zaawansowane konflikty sync.
- Import historycznej bazy PocketBase jako automatyczny migrator produkcyjny.
- Pelny model `Gniazdo -> konkretne pozycje z grupy`, jesli nie jest wymagany od razu.
- Kompatybilnosc z formatami danych legacy.
- Zachowanie starych tras, nazw kolekcji i nazw pol PocketBase.
- Wymagane logowanie do podstawowej pracy lokalnej.
- Uprawnienia systemowe niezwiązane z konkretna funkcja.

## Elementy do zachowania jako wymagania

- Jedna kalkulacja/projekt jako wspolny kontener dla zasilania i kratownic.
- Katalog jako zrodlo danych technicznych.
- Lokacje jako zrodlo infrastruktury energetycznej.
- Presety rozdzielnic jako wielokrotnego uzytku definicje gniazd.
- Polaczenia jako osobne byty domenowe, a nie tylko stan UI.
- Obliczenia fazowe `L1/L2/L3` z obsluga `All`.
- Pole na przyszle fazy projektu, ale bez implementowania workflow faz teraz.

## Elementy do pominiecia lub przeprojektowania

- Dziedzictwo Firebase/Firestore.
- Nazwy katalogow i hookow sugerujace Firestore.
- Eventy jako osobny stary modul, dopoki nie zostanie zdefiniowany od nowa.
- Nadmiernie duzy komponent kalkulatora jako wzorzec architektoniczny.
- Pelne kasowanie i odtwarzanie wszystkich polaczen przy zapisie.
- Mieszanie ID katalogowych, ID runtime i ID polaczen w jednym znaczeniu.
- Backward compatibility ze starymi polami i formatami danych, o ile nie zostanie osobno zamowiona.

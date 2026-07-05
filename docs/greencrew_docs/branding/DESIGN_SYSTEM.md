# GreenCrew Tools Design System

## Cel dokumentu

Ten dokument opisuje wspólny system projektowania aplikacji GreenCrew Tools.

Ma być używany przez:

- Codex,
- Claude,
- ChatGPT,
- programistów,
- przyszłych współtwórców,
- autora projektu.

Dokument opisuje nie tylko wygląd interfejsu, ale też sposób myślenia o aplikacjach GreenCrew Tools.

---

# 1. Filozofia projektowania

## Główna zasada

Aplikacje GreenCrew Tools nie mają być tylko ładne.

Mają być:

- czytelne,
- szybkie,
- odporne na stres,
- praktyczne,
- niezawodne,
- użyteczne w terenie,
- możliwe do obsługi na telefonie.

## Zdanie przewodnie

**Projektujemy narzędzia techniczne, nie aplikacje lifestyle.**

---

# 2. Priorytet platform

## Platforma referencyjna

Platformą referencyjną jest telefon.

Każdy ekran najpierw powinien działać dobrze na telefonie.

Dopiero później należy dopasowywać go do:

- tabletu,
- desktopu,
- webu.

Chyba że wewnętrzne instrukcje do aplikacji twierdzą inaczej.

## Zasada

Jeśli coś działa dobrze na telefonie, zwykle da się to rozszerzyć na większy ekran.

Jeśli coś powstało wyłącznie pod desktop, często będzie niewygodne w terenie.

---

# 3. Offline first

Każda aplikacja GreenCrew Tools powinna być projektowana z założeniem, że Internet może nie działać.

## Zasady

- użytkownik może tworzyć dane offline,
- użytkownik może edytować dane offline,
- aplikacja nie powinna blokować podstawowej pracy bez Internetu,
- synchronizacja jest dodatkiem, nie fundamentem działania,
- brak Internetu musi być jasno komunikowany,
- dane lokalne są traktowane poważnie.

## Pytanie kontrolne

Przy każdej funkcji należy zadać pytanie:

**Co się stanie, jeśli użytkownik straci Internet?**

---

# 4. Kolorystyka UI

## Tryb domyślny

Domyślnym trybem jest dark mode.

## Paleta

Background:

`#000000`

Surface:

`#121212`

Surface Variant:

`#1E1E1E`

Border:

`#2A2A2A`

Primary:

`#00C853`

Primary Light:

`#00E676`

Primary Dark:

`#00B248`

Text Primary:

`#FFFFFF`

Text Secondary:

`#B0B0B0`

Text Disabled:

`#666666`

Warning:

`#FFD54F`

Error:

`#FF5252`

Info:

`#64B5F6`

---

# 5. Zasada akcentu

Każda aplikacja powinna mieć maksymalnie jeden główny akcent kolorystyczny.

Domyślnym akcentem jest GreenCrew Green.

Kolory ostrzegawcze i błędu są dozwolone, ale nie są częścią dekoracji.

Nie należy tworzyć pstrokatego interfejsu.

---

# 6. Typografia

## Domyślna rodzina fontów

Zalecany font:

**Roboto**

Powody:

- dostępny w ekosystemie Android / Flutter,
- neutralny,
- techniczny,
- czytelny,
- bezpieczny między platformami,
- nie wymaga ręcznej instalacji na komputerach użytkowników.

Alternatywa:

**Inter**

Może być użyty, jeśli projekt świadomie zdecyduje się dołączyć font do aplikacji.

## Zasada

Nie polegać na fontach zainstalowanych w systemie użytkownika.

Jeżeli używany jest niestandardowy font, musi być dołączony do aplikacji.

---

# 7. Skala tekstu

Zalecane rozmiary:

| Element | Rozmiar |
|---|---|
| Tytuł ekranu | 22-24 |
| Tytuł sekcji | 18-20 |
| Tytuł karty | 16-18 |
| Tekst główny | 14-16 |
| Tekst pomocniczy | 12-14 |
| Etykiety techniczne | 11-13 |

Tekst techniczny może być mniejszy, ale nie powinien tracić czytelności.

---

# 8. Kształty i zaokrąglenia

Styl bazuje na Material Design.

Zalecane wartości:

| Element | Radius |
|---|---|
| Małe pola / chipy | 8 dp |
| Karty | 12 dp |
| Dialogi | 16 dp |
| Duże panele | 16-20 dp |
| Przyciski | 10-12 dp |

Unikać ostrych, niezaokrąglonych bloków, chyba że aplikacja świadomie udaje panel przemysłowy.

---

# 9. Odstępy

Interfejs ma dobrze wykorzystywać ekran, ale nie może być przeładowany.

## Zasada

**Maksymalnie praktyczny, ale nie nadźgany.**

Zalecane odstępy:

| Kontekst | Odstęp |
|---|---|
| Minimalny odstęp wewnętrzny | 8 dp |
| Standardowy padding karty | 12-16 dp |
| Odstęp między sekcjami | 16-24 dp |
| Margines ekranu telefonu | 12-16 dp |
| Margines desktop | 24-32 dp |

---

# 10. Nawigacja

## Telefon

Preferowane:

- Bottom Navigation dla głównych sekcji,
- Floating Action Button dla głównej akcji,
- AppBar z tytułem i najważniejszymi akcjami.

## Tablet

Preferowane:

- Navigation Rail,
- układy dwukolumnowe,
- lista po lewej, szczegóły po prawej.

## Desktop / web

Preferowane:

- Sidebar,
- szersze tabele,
- panele boczne,
- układy master-detail.

## Zasada

Nawigacja ma być przewidywalna.

Nie należy mieszać kilku różnych modeli nawigacji w jednej aplikacji bez powodu.

---

# 11. Przyciski

## Główna akcja

Główna akcja powinna być zielona.

Przykłady:

- dodaj,
- zapisz,
- rozpocznij,
- wygeneruj,
- zatwierdź.

## Akcje drugorzędne

Akcje drugorzędne powinny być neutralne.

## Akcje destrukcyjne

Akcje destrukcyjne powinny być czerwone i wymagać jasnego potwierdzenia.

## Floating Action Button

FAB służy do najważniejszej akcji na ekranie.

Przykład:

- dodaj wpis,
- dodaj urządzenie,
- dodaj kabel,
- rozpocznij pomiar.

Nie używać wielu FAB na jednym ekranie.

---

# 12. Karty i listy

## Karty

Karty są zalecane dla obiektów, które mają kilka istotnych informacji.

Przykłady:

- projekt,
- zlecenie,
- urządzenie,
- rozdzielnia,
- kabel,
- wpis czasu pracy,
- wydarzenie.

## Listy

Listy są zalecane dla prostych danych.

Przykłady:

- słowniki,
- typy urządzeń,
- szybkie wybory,
- ustawienia.

## Zasada

Forma zależy od funkcji.

Nie każdy ekran musi być kartami.

Nie każdy ekran musi być tabelą.

---

# 13. Formularze

Formularze powinny być przede wszystkim czytelne.

## Zasady

- grupować pola w sekcje,
- unikać bardzo długich ekranów bez nagłówków,
- stosować czytelne etykiety,
- pokazywać jednostki przy polach liczbowych,
- walidować dane od razu,
- nie ukrywać błędów,
- używać sensownych wartości domyślnych.

## Dane techniczne

Pola techniczne muszą mieć jednostki w systemie metrycznym.

Przykłady:

- W,
- A,
- kg,
- m,
- mm,
- V,
- h.

---

# 14. Tabele

Tabele są dozwolone, ale należy uważać na małe ekrany.

## Telefon

Na telefonie zamiast tabeli preferować:

- karty,
- listy,
- rozwijane szczegóły,
- układ pionowy.

## Desktop

Na desktopie tabele są wskazane dla dużych zestawień.

---

# 15. Wyszukiwanie i filtrowanie

Każda istotna lista powinna mieć wyszukiwanie.

Jeżeli lista może mieć więcej niż około 20 elementów, wyszukiwanie jest obowiązkowe.

Filtry powinny być proste i możliwe do wyczyszczenia jednym kliknięciem.

---

# 16. Stany aplikacji

Każdy ekran powinien obsługiwać:

- stan ładowania,
- pusty stan,
- błąd,
- brak Internetu,
- brak wyników wyszukiwania,
- sukces operacji.

## Puste stany

Pusty stan powinien mówić użytkownikowi, co może zrobić dalej.

Przykład:

„Brak urządzeń. Dodaj pierwsze urządzenie, aby rozpocząć kalkulację.”

---

# 17. Komunikaty

Komunikaty powinny być krótkie i konkretne.

Zamiast:

„Wystąpił nieoczekiwany błąd.”

Lepsze:

„Nie udało się zapisać projektu. Dane pozostały lokalnie.”

---

# 18. Animacje

Animacje powinny być krótkie, szybkie i funkcjonalne.

## Zasada

Jeżeli animacja nie pomaga użytkownikowi, nie powinna istnieć.

Dozwolone:

- delikatne przejścia,
- feedback kliknięcia,
- rozwinięcie sekcji,
- zmiana stanu.

Unikać:

- długich animacji,
- ozdobnych efektów,
- animacji blokujących pracę,
- przesadnych przejść ekranów.

---

# 19. Dostępność

Minimalny rozmiar obszaru dotykowego:

44×44 px

Zalecany:

48×48 px

Kontrast musi być wystarczający dla pracy w ciemnym i jasnym otoczeniu.

Nie przekazywać informacji wyłącznie kolorem.

Przykład:

Błąd powinien mieć kolor, ikonę i tekst.

---

# 20. Ikony

Preferowany styl:

Material Icons / Material Symbols.

Ikony powinny być:

- proste,
- liniowe lub wypełnione zgodnie z projektem,
- czytelne przy małych rozmiarach,
- konsekwentne w całej aplikacji.

Nie mieszać wielu rodzin ikon bez potrzeby.

---

# 21. Responsywność

## Telefon

Jedna kolumna.

## Tablet

Dwie kolumny lub Navigation Rail.

## Desktop

Sidebar, master-detail, tabele i szersze panele.

## Web

Web powinien zachowywać się jak wersja desktopowa lub tabletowa zależnie od szerokości.

---

# 22. Komponenty wspólne

Docelowo aplikacje GreenCrew Tools powinny korzystać ze wspólnych komponentów.

Przykłady:

- GreenCrewAppScaffold,
- GreenCrewCard,
- GreenCrewButton,
- GreenCrewFab,
- GreenCrewTextField,
- GreenCrewSearchBar,
- GreenCrewEmptyState,
- GreenCrewErrorState,
- GreenCrewOfflineBanner,
- GreenCrewDataTile,
- GreenCrewConfirmDialog,
- GreenCrewSectionHeader.

W istniejących aplikacjach migracja może być stopniowa.

Nowe aplikacje powinny startować od wspólnych komponentów.

---

# 23. Hierarchia informacji

Najważniejsze dane powinny być widoczne bez wchodzenia w szczegóły.

Przykłady:

StageCalc:

- suma mocy,
- suma masy,
- przekroczenia limitów.

WorkLog:

- czas pracy,
- projekt,
- status wpisu.

CableListTool:

- punkt A,
- punkt B,
- typ kabla,
- oznaczenie.

---

# 24. Zasada dwóch kliknięć

Najważniejsze akcje powinny być dostępne maksymalnie w dwóch kliknięciach / tapnięciach.

Jeżeli funkcja jest często używana w terenie, nie powinna być ukryta głęboko w menu.

---

# 25. Bezpieczeństwo danych

Aplikacje powinny chronić użytkownika przed przypadkową utratą danych.

Zalecane:

- autosave,
- cofanie operacji tam, gdzie ma sens,
- potwierdzenie usuwania,
- lokalna kopia danych,
- eksport,
- jasne komunikaty synchronizacji.

---

# 26. Eksport

Jeżeli aplikacja generuje dane techniczne, powinna docelowo obsługiwać eksport.

Preferowane formaty:

- PDF,
- CSV,
- XLSX, jeśli ma sens,
- JSON dla backupu lub migracji.

---

# 27. Zasady dla AI i programistów

## Nie projektuj od zera, jeśli istnieje wzorzec

Najpierw sprawdź istniejące komponenty i ekrany.

## Nie dodawaj koloru bez powodu

Każdy kolor musi mieć funkcję.

## Nie komplikuj ekranów

Jeżeli ekran robi zbyt wiele rzeczy, podziel go na sekcje lub osobne widoki.

## Projektuj offline first

Internet nie może być wymagany do podstawowej pracy.

## Zachowuj spójność

Nowa aplikacja ma wyglądać jak część GreenCrew Tools.

---

# 28. Definicja sukcesu

Ekran jest dobrze zaprojektowany, jeśli technik może z niego skorzystać:

- szybko,
- na telefonie,
- w stresie,
- w ciemności,
- bez Internetu,
- bez czytania instrukcji.

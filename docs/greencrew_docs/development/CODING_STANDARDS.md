# GreenCrew Tools Coding Standards

## Cel dokumentu

Ten dokument opisuje ogólne zasady pisania kodu w projektach GreenCrew Tools.

Dotyczy głównie aplikacji Flutter / Dart, ale część zasad można stosować również w innych technologiach.

---

# 1. Główna zasada

Kod ma być prosty, czytelny i możliwy do utrzymania.

Nie optymalizować przedwcześnie.

Nie komplikować architektury bez realnej potrzeby.

---

# 2. Nazewnictwo

Nazwy powinny jasno opisywać funkcję.

Dobre:

- `PowerCalculator`
- `CableRepository`
- `WorkEntry`
- `ProjectSummary`
- `OfflineSyncStatus`

Słabe:

- `Manager`
- `Helper`
- `DataThing`
- `Utils2`
- `NewClass`

---

# 3. Struktura funkcji

Funkcja powinna robić jedną rzecz.

Jeśli funkcja wymaga długiego komentarza wyjaśniającego, prawdopodobnie trzeba ją podzielić.

---

# 4. Komentarze

Komentarze powinny wyjaśniać dlaczego coś istnieje, a nie przepisywać kod.

Dobre:

```dart
// Nie usuwamy lokalnych zmian po błędzie synchronizacji,
// bo użytkownik mógł pracować offline podczas wydarzenia.
```

Słabe:

```dart
// zwiększ i o 1
i++;
```

---

# 5. Logika biznesowa

Logika biznesowa nie powinna być ukryta w widgetach UI.

Przykład:

Obliczenia StageCalc powinny być w osobnych klasach / serwisach, nie bezpośrednio w ekranie.

---

# 6. Walidacja

Walidacja danych powinna być blisko modelu lub logiki domenowej.

Nie polegać wyłącznie na walidacji formularza.

---

# 7. Obsługa błędów

Nie ignorować błędów.

Nie wyświetlać użytkownikowi surowych wyjątków.

Każdy istotny błąd powinien mieć:

- log techniczny,
- komunikat użytkownika,
- bezpieczne zachowanie aplikacji.

---

# 8. Dane lokalne

Dane lokalne są ważne.

Nie traktować cache jako śmietnika.

Jeśli dane są potrzebne offline, powinny być zapisane w przewidywalny sposób.

---

# 9. Synchronizacja

Synchronizacja nie powinna niszczyć danych lokalnych.

Konflikty powinny być jawne.

Stan synchronizacji powinien być możliwy do sprawdzenia.

---

# 10. Testowalność

Logika obliczeniowa, eksporty i importy muszą być możliwe do testowania bez uruchamiania UI.

---

# 11. Stałe

Nie wpisywać magicznych wartości w środku kodu.

Dobre:

```dart
const maxSchukoCurrent = 16;
```

Słabe:

```dart
if (current > 16) {}
```

---

# 12. Jednostki

Wartości techniczne powinny mieć jasne jednostki.

Jeżeli zmienna przechowuje waty, ampery albo kilogramy, nazwa powinna to sugerować.

Przykłady:

- `powerW`
- `currentA`
- `weightKg`
- `lengthM`

---

# 13. Formatowanie

Używać standardowego formatowania Dart:

```bash
dart format .
```

Nie walczyć z formatterem.

---

# 14. Analiza statyczna

Projekt powinien korzystać z `flutter_lints` lub równoważnego zestawu reguł.

Nie wyłączać reguł bez powodu.

---

# 15. Importy

Unikać nieużywanych importów.

Nie tworzyć ogromnych plików eksportujących wszystko bez potrzeby.

---

# 16. Rozmiar plików

Jeżeli plik staje się trudny do czytania, należy go podzielić.

Typowe sygnały:

- kilka niezależnych widgetów w jednym pliku,
- bardzo długa metoda `build`,
- wiele różnych odpowiedzialności.

---

# 17. UI

Widgety powinny być składane z mniejszych elementów.

Nie tworzyć ogromnych ekranów w jednym pliku.

---

# 18. Migracje

Zmiany w istniejących aplikacjach mogą być stopniowe.

Nie trzeba przepisywać całego projektu tylko po to, aby dostosować go do nowych standardów.

Nowe funkcje powinny już korzystać z aktualnych zasad.

---

# 19. Release

Każdy release powinien mieć:

- numer wersji,
- changelog,
- opis zmian,
- artefakty z konsekwentnym nazewnictwem,
- tag GitHub.

---

# 20. Zasady dla AI

AI nie powinno:

- usuwać istniejących funkcji bez polecenia,
- zmieniać stylu UI bez uzasadnienia,
- przepisywać całej aplikacji bez potrzeby,
- ukrywać błędów,
- dodawać zależności bez uzasadnienia.

AI powinno:

- robić małe, logiczne zmiany,
- zachowywać kompatybilność,
- aktualizować dokumentację,
- wyjaśniać ważne decyzje,
- pisać kod możliwy do utrzymania.

---

# 21. Zasada końcowa

Kod ma służyć aplikacji, a aplikacja ma służyć pracy w terenie.

# Wsad do katalogu urządzeń StageCalc - instrukcja dla GPT

## Cel dokumentu

Ten dokument jest przeznaczony do wklejenia jako instrukcja/wiedza dla modelu
GPT (np. custom GPT w ChatGPT), którego zadaniem jest wygenerowanie pliku JSON
z listą urządzeń do katalogu StageCalc ("wsad"). Wygenerowany plik użytkownik
importuje ręcznie przez aplikację - GPT nie ma bezpośredniego dostępu do bazy
danych StageCalc i niczego nie zapisuje sam.

## Jak wynik trafia do aplikacji

1. GPT zwraca **jeden plik JSON** zgodny z formatem opisanym niżej.
2. Użytkownik zapisuje ten JSON jako plik `.json` na dysku.
3. W aplikacji StageCalc: ekran "O aplikacji" -> pole "Ścieżka do pliku kopii
   zapasowej" (albo przycisk "Wybierz plik") -> wskazuje ten plik -> przycisk
   "Wczytaj i zwaliduj".
4. Aplikacja pokazuje dialog "Zaimportować kopię zapasową?" z liczbą
   znalezionych rekordów - po potwierdzeniu urządzenia trafiają do lokalnego
   katalogu.
5. Import działa jako **upsert po polu `id`**: urządzenie o `id`, które już
   istnieje w katalogu, zostanie **nadpisane** nowymi danymi; nowe `id`
   tworzy nowy wpis. Nic innego w aplikacji (projekty, klienci, lokacje,
   presety) nie jest ruszane, jeśli te sekcje są puste/pominięte w pliku.

Z tego wynika najważniejsza zasada dla GPT: **każde `id` w wygenerowanym
pliku musi być unikalne** (w obrębie pliku i - jeśli użytkownik o tym
wspomni - w obrębie tego, co już ma w katalogu), inaczej dojdzie do
przypadkowego nadpisania istniejącego urządzenia.

## Format pliku (wymagany)

Plik to jeden obiekt JSON z dwiema sekcjami: `manifest` i `data`. Jedyne pole
`manifest`, które aplikacja faktycznie sprawdza, to `schemaVersion` (musi być
liczbą całkowitą `1`) - reszta poniżej jest opcjonalna, ale warto ją dodać.
Sekcja `data` może zawierać **tylko** `catalogDevices` - inne sekcje
(`projects`, `clients`, `locations`, `powerPresets`) można całkiem pominąć,
aplikacja wtedy ich po prostu nie rusza.

Minimalny szkielet:

```json
{
  "manifest": {
    "schemaVersion": 1,
    "appName": "StageCalc",
    "createdAt": "2026-09-13T12:00:00.000Z"
  },
  "data": {
    "catalogDevices": [
      { "...": "tu lista urządzeń, patrz niżej" }
    ]
  }
}
```

## Schemat pojedynczego urządzenia (`catalogDevices[]`)

| Pole | Typ | Wymagane | Domyślnie | Opis |
|---|---|---|---|---|
| `id` | string | **tak** | - | Unikalny identyfikator. Klucz upsertu - patrz wyżej. Zalecana konwencja: `snake_case` z ASCII, bez spacji i polskich znaków diakrytycznych, np. `robe_bmfl_spot`, `distro_32a_5p_cee`. Musi być niepowtarzalne w całym pliku. |
| `name` | string | **tak** | - | Nazwa urządzenia widoczna w katalogu i na liście pozycji projektu, np. `"BMFL Spot"`. |
| `manufacturer` | string lub `null` | nie | `null` | Producent, np. `"Robe"`. Można pominąć pole zamiast wpisywać `null`. |
| `category` | string (enum) | nie | `"lighting"` | Jedna z: `lighting`, `sound`, `multimedia`, `distribution`, `cable`, `rigging`, `other` - patrz tabela kategorii niżej. |
| `powerW` | liczba | nie | `0` | Moc pobierana w watach, przy założeniu 230 V (1 faza). Dla urządzeń bez poboru mocy (rozdzielnice, kable, akcesoria riggingowe) wpisz `0`. |
| `currentA` | liczba | nie | `0` | Prąd w amperach. Aplikacja normalnie przelicza to automatycznie z `powerW` przy 230 V (`A = W / 230`) - **przelicz to samodzielnie w wygenerowanych danych**, żeby oba pola były spójne: `currentA = powerW / 230`, zaokrąglone do 1 miejsca po przecinku. |
| `weightKg` | liczba | nie | `0` | Masa w kg. Używana m.in. do liczenia obciążenia kratownic. |
| `connectorTypeIds` | tablica stringów (enum) | nie | `[]` | **Lista złącz urządzenia - urządzenie może mieć ich kilka naraz** (np. fixture z wejściem powerCON i wejściem DMX XLR5 ma obie wartości). Każdy element musi być jedną z wartości z tabeli "Typy złącz" niżej - to zamknięta lista wielokrotnego wyboru, NIE wolny tekst. Nie mylić z typami złącz zasilania rozdzielnic w projekcie (`schuko_16a`, `cee_16a_3p`, `cee_16a_5p`, `cee_32a_5p`, `cee_63a_5p`, `cee_125a_5p`, `powerlock_200a`, `powerlock_400a` jako osobne, pojedyncze pole `connectorTypeId` gdzie indziej w aplikacji) - to inny, większy słownik obejmujący też złącza sygnałowe, używany tylko w katalogu urządzeń. |
| `riggingPoints` | liczba całkowita lub `null` | nie | `null` | Liczba punktów zaczepienia (haków) potrzebnych, gdy urządzenie wisi na kratownicy, np. `2` dla ruchomej głowy z dwoma oczkami. Zostaw puste/`null`, jeśli nieznane lub nie dotyczy (większość urządzeń). |
| `loadChart` | tablica obiektów | nie | `[]` | **Tylko dla `category: "rigging"` reprezentujących model kratownicy** (nie akcesoria typu zacisk). Każdy wpis: `{ "id": string, "lengthM": liczba, "pointLoadKg": liczba, "distributedLoadKgPerM": liczba }` - punkt tabeli nośności producenta dla danej długości przęsła. Dla urządzeń niebędących kratownicą zostaw pustą tablicę `[]` lub pomiń pole. |
| `quantityUnit` | string (enum) | nie | `"pcs"` | `"pcs"` (sztuki) albo `"meters"` (metry, np. dla kabli sprzedawanych/liczonych na metry). |
| `createdAt` | string ISO 8601 | **tak** | - | Musi być poprawnym ISO 8601, np. `"2026-09-13T12:00:00.000Z"`. Dla wsadu wygenerowanego jednorazowo wystarczy ta sama wartość dla wszystkich urządzeń (np. aktualna data). |
| `updatedAt` | string ISO 8601 | **tak** | - | Jak wyżej. Zwykle ta sama wartość co `createdAt`. |
| `syncStatus` | string (enum) | nie | `"localOnly"` | Zostaw pominięte - aplikacja i tak potraktuje nowo zaimportowane urządzenia jako lokalne, gotowe do synchronizacji. |

### Kategorie (`category`)

| Wartość | Etykieta w UI | Kiedy używać |
|---|---|---|
| `lighting` | Oświetlenie | Reflektory, konsole i akcesoria oświetleniowe - domyślna kategoria dla nowego urządzenia w aplikacji. |
| `sound` | Nagłośnienie | Głośniki, mikrofony, konsole audio i inny sprzęt nagłośnieniowy. |
| `multimedia` | Multimedia | Projektory, ekrany, przełączniki wizji i inny sprzęt multimedialny. |
| `distribution` | Rozdzielnia | Rozdzielnice/skrzynki zasilające jako pozycje katalogowe (nie tworzy to automatycznie funkcjonalnej rozdzielnicy w projekcie - to tylko wpis inwentarzowy). |
| `cable` | Kabel | Przewody i kable, często z `quantityUnit: "meters"`. W formularzu aplikacji ta kategoria nie pokazuje pól Moc/Prąd/Producent/Punkty zaczepienia - nie są dla kabli sensowne. |
| `rigging` | Rigging | Konstrukcje wsporcze, zaciski, kratownice (kratownice mogą dodatkowo mieć `loadChart`). W formularzu aplikacji ta kategoria nie pokazuje pól Moc/Prąd/typy złącz/punkty zaczepienia. |
| `other` | Inne | Wszystko, co nie pasuje do powyższych. |

Starsza wartość `device` (sprzed podziału na `lighting`/`sound`/`multimedia`)
nie jest już poprawną wartością - GPT powinien zawsze wybrać właściwą,
bardziej szczegółową kategorię z tabeli powyżej. Aplikacja i tak zmapuje
każdą nierozpoznaną wartość `category` (w tym starą `device`) na `other` przy
wczytywaniu, więc lepiej wybrać trafną kategorię niż polegać na tym
zachowaniu.

### Typy złącz (`connectorTypeIds[]`)

Zamknięta lista - każdy element `connectorTypeIds` musi być dokładnie jedną z
tych wartości (pisownia ma znaczenie):

| Wartość | Etykieta w UI |
|---|---|
| `schuko16a` | 16 A Schuko |
| `cee16a3p` | 16 A CEE 3P |
| `cee16a5p` | 16 A CEE 5P |
| `cee32a3p` | 32 A CEE 3P |
| `cee32a5p` | 32 A CEE 5P |
| `cee63a5p` | 63 A CEE 5P |
| `cee125a5p` | 125 A CEE 5P |
| `powerlock200a` | Powerlock 200 A |
| `powerlock400a` | Powerlock 400 A |
| `powerCon` | powerCON |
| `powerConTrue1` | powerCON TRUE1 |
| `powerConTrue1Top` | powerCON TRUE1 TOP |
| `xlr3` | XLR 3-pin |
| `xlr5` | XLR 5-pin (DMX) |
| `speakonNl4` | SpeakON NL4 |
| `speakonNl8` | SpeakON NL8 |
| `etherCon` | EtherCON (RJ45) |
| `bnc` | BNC |
| `jack63` | Jack 6.3 mm |
| `rca` | RCA (Cinch) |
| `hdmi` | HDMI |
| `sdi` | SDI |
| `usb` | USB |
| `other` | Inne |

Jeśli urządzenie faktycznie nie ma żadnego istotnego złącza do zaznaczenia
(albo nieznane), zostaw `connectorTypeIds` jako pustą tablicę `[]` zamiast
zgadywać - wartość, która nie jest z tej listy, zostanie **po cichu
pominięta** przy imporcie, więc lepiej nie dodawać złącza w ogóle niż dodać
źle nazwane.

## Przykładowe pełne wpisy

```json
{
  "manifest": { "schemaVersion": 1 },
  "data": {
    "catalogDevices": [
      {
        "id": "robe_bmfl_spot",
        "name": "BMFL Spot",
        "manufacturer": "Robe",
        "category": "lighting",
        "powerW": 2000,
        "currentA": 8.7,
        "weightKg": 36,
        "connectorTypeIds": ["powerConTrue1", "xlr5"],
        "riggingPoints": 2,
        "quantityUnit": "pcs",
        "createdAt": "2026-09-13T12:00:00.000Z",
        "updatedAt": "2026-09-13T12:00:00.000Z"
      },
      {
        "id": "cable_dmx_5p_10m",
        "name": "Kabel DMX 5-pin 10m",
        "manufacturer": null,
        "category": "cable",
        "powerW": 0,
        "currentA": 0,
        "weightKg": 0.4,
        "connectorTypeIds": ["xlr5"],
        "quantityUnit": "meters",
        "createdAt": "2026-09-13T12:00:00.000Z",
        "updatedAt": "2026-09-13T12:00:00.000Z"
      },
      {
        "id": "truss_qx30_2m",
        "name": "Kratownica QX30 2m",
        "manufacturer": "Generic",
        "category": "rigging",
        "powerW": 0,
        "currentA": 0,
        "weightKg": 8,
        "quantityUnit": "pcs",
        "loadChart": [
          { "id": "qx30_2m_1", "lengthM": 1, "pointLoadKg": 500, "distributedLoadKgPerM": 300 },
          { "id": "qx30_2m_2", "lengthM": 2, "pointLoadKg": 300, "distributedLoadKgPerM": 180 },
          { "id": "qx30_2m_3", "lengthM": 3, "pointLoadKg": 150, "distributedLoadKgPerM": 90 }
        ],
        "createdAt": "2026-09-13T12:00:00.000Z",
        "updatedAt": "2026-09-13T12:00:00.000Z"
      }
    ]
  }
}
```

## Checklist, którą GPT powinien sam sobie odhaczyć przed zwróceniem wyniku

1. Plik jest poprawnym JSON-em (bez komentarzy, bez końcowych przecinków).
2. Każdy obiekt w `data.catalogDevices` ma unikalne `id` w obrębie całego
   pliku.
3. Każdy obiekt ma `name`, `createdAt`, `updatedAt` (te trzy są wymagane).
4. `category`, `quantityUnit` i każdy element `connectorTypeIds` (jeśli
   podane) używają wyłącznie wartości z tabel powyżej - nic innego, nie po
   polsku, dokładnie taka pisownia (wielkość liter ma znaczenie dla
   `connectorTypeIds`).
5. `currentA` jest spójne z `powerW` (`currentA = powerW / 230`), chyba że
   użytkownik podał inną wartość wprost.
6. `loadChart` występuje tylko przy urządzeniach `category: "rigging"`,
   które faktycznie reprezentują model kratownicy z tabelą nośności - nie
   przy zaciskach czy innych akcesoriach riggingowych.
7. Liczby (`powerW`, `currentA`, `weightKg`, `riggingPoints`, wartości w
   `loadChart`) są >= 0.

## Czego nie robić

- Nie wpisywać do `connectorTypeIds` niczego spoza tabeli "Typy złącz"
  powyżej (np. wolnego tekstu jak dawniej, albo wartości wymyślonej na
  poczekaniu) - taka wartość zostanie po cichu odrzucona przy imporcie, więc
  lepiej pominąć złącze niż podać źle nazwane.
- Nie zmieniać ani nie zgadywać `id` już istniejących w katalogu
  użytkownika, chyba że celowo ma to być aktualizacja tego konkretnego
  wpisu (import nadpisuje po `id`).
- Nie dodawać sekcji `projects`/`clients`/`locations`/`powerPresets` do
  `data`, chyba że użytkownik wprost o to poprosi - w tym wsadzie chodzi
  wyłącznie o katalog urządzeń.

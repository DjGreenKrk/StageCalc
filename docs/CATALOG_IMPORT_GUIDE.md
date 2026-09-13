# Wsad do katalogu urzadzen StageCalc - instrukcja dla GPT

## Cel dokumentu

Ten dokument jest przeznaczony do wklejenia jako instrukcja/wiedza dla modelu
GPT (np. custom GPT w ChatGPT), ktorego zadaniem jest wygenerowanie pliku JSON
z lista urzadzen do katalogu StageCalc ("wsad"). Wygenerowany plik uzytkownik
importuje recznie przez aplikacje - GPT nie ma bezposredniego dostepu do bazy
danych StageCalc i niczego nie zapisuje sam.

## Jak wynik trafia do aplikacji

1. GPT zwraca **jeden plik JSON** zgodny z formatem opisanym nizej.
2. Uzytkownik zapisuje ten JSON jako plik `.json` na dysku.
3. W aplikacji StageCalc: ekran "O aplikacji" -> pole "Sciezka do pliku kopii
   zapasowej" (albo przycisk "Wybierz plik") -> wskazuje ten plik -> przycisk
   "Wczytaj i zwaliduj".
4. Aplikacja pokazuje dialog "Zaimportowac kopie zapasowa?" z liczba
   znalezionych rekordow - po potwierdzeniu urzadzenia trafiaja do lokalnego
   katalogu.
5. Import dziala jako **upsert po polu `id`**: urzadzenie o `id`, ktore juz
   istnieje w katalogu, zostanie **nadpisane** nowymi danymi; nowe `id`
   tworzy nowy wpis. Nic innego w aplikacji (projekty, klienci, lokacje,
   presety) nie jest ruszane, jesli te sekcje sa puste/pominiete w pliku.

Z tego wynika najwazniejsza zasada dla GPT: **kazde `id` w wygenerowanym
pliku musi byc unikalne** (w obrebie pliku i - jesli uzytkownik o tym
wspomni - w obrebie tego, co juz ma w katalogu), inaczej dojdzie do
przypadkowego nadpisania istniejacego urzadzenia.

## Format pliku (wymagany)

Plik to jeden obiekt JSON z dwiema sekcjami: `manifest` i `data`. Jedyne pole
`manifest`, ktore aplikacja faktycznie sprawdza, to `schemaVersion` (musi byc
liczba calkowita `1`) - reszta ponizej jest opcjonalna, ale warto ja dodac.
Sekcja `data` moze zawierac **tylko** `catalogDevices` - inne sekcje
(`projects`, `clients`, `locations`, `powerPresets`) mozna calkiem pominac,
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
      { "...": "tu lista urzadzen, patrz nizej" }
    ]
  }
}
```

## Schemat pojedynczego urzadzenia (`catalogDevices[]`)

| Pole | Typ | Wymagane | Domyslnie | Opis |
|---|---|---|---|---|
| `id` | string | **tak** | - | Unikalny identyfikator. Klucz upsertu - patrz wyzej. Zalecana konwencja: `snake_case` z ASCII, bez spacji i polskich znakow diakrytycznych, np. `robe_bmfl_spot`, `distro_32a_5p_ceE`. Musi byc niepowtarzalne w calym pliku. |
| `name` | string | **tak** | - | Nazwa urzadzenia widoczna w katalogu i na liscie pozycji projektu, np. `"BMFL Spot"`. |
| `manufacturer` | string lub `null` | nie | `null` | Producent, np. `"Robe"`. Mozna pominac pole zamiast wpisywac `null`. |
| `category` | string (enum) | nie | `"device"` | Jedna z: `device`, `distribution`, `cable`, `rigging`, `other` - patrz tabela kategorii nizej. |
| `powerW` | liczba | nie | `0` | Moc pobierana w watach, przy zalozeniu 230 V (1 faza). Dla urzadzen bez poboru mocy (rozdzielnice, kable, akcesoria riggingowe) wpisz `0`. |
| `currentA` | liczba | nie | `0` | Prad w amperach. Aplikacja normalnie przelicza to automatycznie z `powerW` przy 230 V (`A = W / 230`) - **przelicz to samodzielnie w wygenerowanych danych**, zeby oba pola byly spojne: `currentA = powerW / 230`, zaokraglone do 1 miejsca po przecinku. |
| `weightKg` | liczba | nie | `0` | Masa w kg. Uzywana m.in. do liczenia obciazenia kratownic. |
| `connectorTypeIds` | tablica stringow (enum) | nie | `[]` | **Lista zlacz urzadzenia - urzadzenie moze miec ich kilka naraz** (np. fixture z wejsciem powerCON i wejsciem DMX XLR5 ma obie wartosci). Kazdy element musi byc jedna z wartosci z tabeli "Typy zlacz" nizej - to zamknieta lista wielokrotnego wyboru, NIE wolny tekst. Nie mylic z typami zlacz zasilania rozdzielnic w projekcie (`schuko_16a`, `cee_16a_3p`, `cee_16a_5p`, `cee_32a_5p`, `cee_63a_5p`, `cee_125a_5p`, `powerlock_200a`, `powerlock_400a` jako osobne, pojedyncze pole `connectorTypeId` gdzie indziej w aplikacji) - to inny, wiekszy slownik obejmujacy tez zlacza sygnalowe, uzywany tylko w katalogu urzadzen. |
| `riggingPoints` | liczba calkowita lub `null` | nie | `null` | Liczba punktow zaczepienia (hakow) potrzebnych, gdy urzadzenie wisi na kratownicy, np. `2` dla ruchomej glowy z dwoma oczkami. Zostaw puste/`null`, jesli nieznane lub nie dotyczy (wiekszosc urzadzen). |
| `loadChart` | tablica obiektow | nie | `[]` | **Tylko dla `category: "rigging"` reprezentujacych model kratownicy** (nie akcesoria typu zacisk). Kazdy wpis: `{ "id": string, "lengthM": liczba, "pointLoadKg": liczba, "distributedLoadKgPerM": liczba }` - punkt tabeli nosnosci producenta dla danej dlugosci przesla. Dla urzadzen niebedacych kratownica zostaw pusta tablice `[]` lub pomin pole. |
| `quantityUnit` | string (enum) | nie | `"pcs"` | `"pcs"` (sztuki) albo `"meters"` (metry, np. dla kabli sprzedawanych/liczonych na metry). |
| `createdAt` | string ISO 8601 | **tak** | - | Musi byc poprawnym ISO 8601, np. `"2026-09-13T12:00:00.000Z"`. Dla wsadu wygenerowanego jednorazowo wystarczy ta sama wartosc dla wszystkich urzadzen (np. aktualna data). |
| `updatedAt` | string ISO 8601 | **tak** | - | Jak wyzej. Zwykle ta sama wartosc co `createdAt`. |
| `syncStatus` | string (enum) | nie | `"localOnly"` | Zostaw pominiete - aplikacja i tak potraktuje nowo zaimportowane urzadzenia jako lokalne, gotowe do synchronizacji. |

### Kategorie (`category`)

| Wartosc | Etykieta w UI | Kiedy uzywac |
|---|---|---|
| `device` | Urzadzenie | Domyslna kategoria: oswietlenie, naglosnienie, multimedia, wszystko co pobiera prad i jest "sprzetem produkcyjnym". |
| `distribution` | Rozdzielnia | Rozdzielnice/skrzynki zasilajace jako pozycje katalogowe (nie tworzy to automatycznie funkcjonalnej rozdzielnicy w projekcie - to tylko wpis inwentarzowy). |
| `cable` | Kabel | Przewody i kable, czesto z `quantityUnit: "meters"`. |
| `rigging` | Rigging | Konstrukcje wsporcze, zaciski, kratownice (kratownice moga dodatkowo miec `loadChart`). |
| `other` | Inne | Wszystko, co nie pasuje do powyzszych. |

### Typy zlacz (`connectorTypeIds[]`)

Zamknieta lista - kazdy element `connectorTypeIds` musi byc dokladnie jedna z
tych wartosci (pisownia ma znaczenie):

| Wartosc | Etykieta w UI |
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

Jesli urzadzenie faktycznie nie ma zadnego istotnego zlacza do zaznaczenia
(albo nieznane), zostaw `connectorTypeIds` jako pusta tablice `[]` zamiast
zgadywac - wartosc, ktora nie jest z tej listy, zostanie **po cichu
pominieta** przy imporcie, wiec lepiej nie dodawac zlacza w ogole niz dodac
zle nazwane.

## Przykladowe pelne wpisy

```json
{
  "manifest": { "schemaVersion": 1 },
  "data": {
    "catalogDevices": [
      {
        "id": "robe_bmfl_spot",
        "name": "BMFL Spot",
        "manufacturer": "Robe",
        "category": "device",
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

## Checklist, ktora GPT powinien sam sobie odhaczyc przed zwroceniem wyniku

1. Plik jest poprawnym JSON-em (bez komentarzy, bez koncowych przecinkow).
2. Kazdy obiekt w `data.catalogDevices` ma unikalne `id` w obrebie calego
   pliku.
3. Kazdy obiekt ma `name`, `createdAt`, `updatedAt` (te trzy sa wymagane).
4. `category`, `quantityUnit` i kazdy element `connectorTypeIds` (jesli
   podane) uzywaja wylacznie wartosci z tabel powyzej - nic innego, nie po
   polsku, dokladnie taka pisownia (wielkosc liter ma znaczenie dla
   `connectorTypeIds`).
5. `currentA` jest spojne z `powerW` (`currentA = powerW / 230`), chyba ze
   uzytkownik podal inna wartosc wprost.
6. `loadChart` wystepuje tylko przy urzadzeniach `category: "rigging"`,
   ktore faktycznie reprezentuja model kratownicy z tabela nosnosci - nie
   przy zaciskach czy innych akcesoriach riggingowych.
7. Liczby (`powerW`, `currentA`, `weightKg`, `riggingPoints`, wartosci w
   `loadChart`) sa >= 0.

## Czego nie robic

- Nie wpisywac do `connectorTypeIds` niczego spoza tabeli "Typy zlacz"
  powyzej (np. wolnego tekstu jak dawniej, albo wartosci wymyslonej na
  poczekaniu) - taka wartosc zostanie po cichu odrzucona przy imporcie, wiec
  lepiej pominac zlacze niz podac zle nazwane.
- Nie zmieniac ani nie zgadywac `id` juz istniejacych w katalogu
  uzytkownika, chyba ze celowo ma to byc aktualizacja tego konkretnego
  wpisu (import nadpisuje po `id`).
- Nie dodawac sekcji `projects`/`clients`/`locations`/`powerPresets` do
  `data`, chyba ze uzytkownik wprost o to poprosi - w tym wsadzie chodzi
  wylacznie o katalog urzadzen.

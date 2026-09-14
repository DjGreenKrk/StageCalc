# Import pack listy z Gremium Panel do StageCalc

## Cel integracji

Gremium Panel eksportuje planowaną listę sprzętu wydarzenia. StageCalc odpowiada za katalog parametrów technicznych, obliczenia zasilania i obciążenia konstrukcji oraz kreator danych dla urządzeń, których jeszcze nie zna.

Integracja działa przez jeden plik JSON w UTF-8. Nie wymaga połączenia sieciowego ani dostępu StageCalc do bazy Gremium.

## Rozpoznanie pliku

Importer powinien najpierw sprawdzić:

{
  "schema": "gremium.stagecalc.pack-list",
  "formatVersion": "1.0",
  "sourceApp": "Gremium Panel",
  "generatedAt": "2026-09-14T10:30:00.000Z"
}

- schema identyfikuje rodzaj dokumentu.
- formatVersion określa kontrakt danych, a nie wersję aplikacji.
- sourceAppVersion służy tylko diagnostyce i nie powinno sterować parserem.
- exportId identyfikuje konkretne wygenerowanie pliku.
- generatedAt jest datą ISO 8601 w UTC.

Importer powinien przyjmować wszystkie wydania 1.x, ignorować nieznane pola i odrzucać nieobsługiwaną wersję główną z czytelnym komunikatem.

## Pełny przykład

{
  "schema": "gremium.stagecalc.pack-list",
  "formatVersion": "1.0",
  "sourceApp": "Gremium Panel",
  "sourceAppVersion": "2.49.3",
  "exportId": "5ce29a37-f705-43ac-8f74-c24b95013a95",
  "generatedAt": "2026-09-14T10:30:00.000Z",
  "project": {
    "id": "event-2026-09-20",
    "name": "Dni Gminy",
    "startDate": "2026-09-20",
    "endDate": "2026-09-21",
    "location": "Rynek, Kraków",
    "environment": "outdoor"
  },
  "units": {
    "power": "W",
    "current": "A",
    "voltage": "V",
    "weight": "kg"
  },
  "items": [
    {
      "lineId": "line-audio-1",
      "inventoryItemId": "inventory-line-array-1",
      "name": "Moduł line array",
      "projectLabel": "Moduł line array",
      "manufacturer": null,
      "model": null,
      "category": "Nagłośnienie",
      "quantity": 8,
      "unit": "szt.",
      "sourceCase": {
        "id": "case-line-array-1",
        "name": "Case line array 1"
      },
      "technical": {
        "unitWeightKg": 27.5,
        "ratedPowerW": null,
        "ratedCurrentA": null,
        "voltageV": null,
        "phases": null,
        "powerConnectors": [],
        "riggingPoints": null
      }
    },
    {
      "lineId": "line-mixer-1",
      "inventoryItemId": "inventory-mixer-1",
      "name": "Mikser cyfrowy",
      "projectLabel": "Mikser cyfrowy",
      "manufacturer": null,
      "model": null,
      "category": "Nagłośnienie",
      "quantity": 1,
      "unit": "szt.",
      "sourceCase": null,
      "technical": {
        "unitWeightKg": 24,
        "ratedPowerW": null,
        "ratedCurrentA": null,
        "voltageV": null,
        "phases": null,
        "powerConnectors": [],
        "riggingPoints": null
      }
    },
    {
      "lineId": "line-custom-1",
      "inventoryItemId": null,
      "name": "Rozdzielnia zapewniana przez podwykonawcę",
      "projectLabel": "Rozdzielnia zapewniana przez podwykonawcę",
      "manufacturer": null,
      "model": null,
      "category": "Pozycja własna",
      "quantity": 1,
      "unit": "szt.",
      "sourceCase": null,
      "technical": {
        "unitWeightKg": null,
        "ratedPowerW": null,
        "ratedCurrentA": null,
        "voltageV": null,
        "phases": null,
        "powerConnectors": [],
        "riggingPoints": null
      }
    }
  ],
  "dataCompleteness": {
    "itemRows": 3,
    "catalogMatchedRows": 2,
    "customRows": 1,
    "rowsWithWeight": 2,
    "rowsRequiringElectricalSetup": 3
  }
}

Polskie znaki są zapisywane bezpośrednio w UTF-8. Nazwy pól pozostają angielskie i stabilne.

## Znaczenie danych projektu

project.id jest stabilnym identyfikatorem wydarzenia w Gremium. StageCalc powinien zaproponować aktualizację istniejącego projektu, jeśli ponownie zaimportowano plik z tym samym sourceApp i project.id.

environment przyjmuje indoor, outdoor, mixed albo null.

Eksport celowo nie zawiera danych klienta, telefonu, adresu e-mail, ceny, notatek wewnętrznych ani danych użytkowników Gremium.

## Znaczenie pozycji sprzętu

- lineId identyfikuje wpis checklisty w konkretnym wydarzeniu.
- inventoryItemId identyfikuje pozycję katalogową Gremium. null oznacza pozycję własną spoza magazynu.
- name jest nazwą urządzenia z katalogu, o ile pozycja nadal istnieje.
- projectLabel zachowuje nazwę widoczną na checkliście wydarzenia.
- quantity jest aktualną liczbą wymaganą w checkliście wydarzenia. Zmiana ilości w Gremium będzie widoczna w następnym eksporcie.
- unit jest jednostką ilości.
- sourceCase wskazuje case, z którego pochodzi urządzenie. Case nie jest osobnym odbiornikiem energii.

Zawartość case’ów jest zawsze rozwijana do rzeczywistych urządzeń. Case z ośmioma lampami tworzy wpis lampy z quantity: 8, a nie jedno urządzenie o nazwie case’a.

## Dane techniczne i jednostki

- unitWeightKg: masa jednej sztuki w kilogramach.
- ratedPowerW: znamionowy lub maksymalny pobór jednej sztuki w watach.
- ratedCurrentA: znamionowy prąd jednej sztuki w amperach.
- voltageV: napięcie znamionowe w woltach.
- phases: 1, 3 albo null.
- powerConnectors: lista złączy { type, direction, quantity }; direction to in, out albo null.
- riggingPoints: liczba punktów podwieszenia jednej sztuki.

Wartość null oznacza brak wiedzy. Nie wolno zamieniać jej na zero. Zero oznacza rzeczywistą wartość zerową tylko w polach, w których ma ona sens.

Gremium obecnie przekazuje przede wszystkim masę. Pozostałe dane techniczne mogą być puste i mają zostać uzupełnione w StageCalc.

## Dopasowanie katalogu StageCalc

Zalecana kolejność:

1. Znajdź zapisane powiązanie po sourceApp + inventoryItemId.
2. Jeśli powiązanie istnieje, użyj urządzenia z katalogu StageCalc.
3. Jeśli go nie ma, spróbuj podpowiedzieć dopasowanie po producencie, modelu i nazwie, ale wymagaj potwierdzenia użytkownika.
4. Jeśli nadal nie ma dopasowania, otwórz kreator nowego urządzenia.
5. Po zapisaniu urządzenia zachowaj powiązanie z inventoryItemId na potrzeby następnych importów.

Nie należy automatycznie łączyć urządzeń wyłącznie po podobnej nazwie. Może to połączyć dwa różne modele o innych parametrach elektrycznych lub masie.

Pozycje z inventoryItemId: null można mapować ręcznie albo tworzyć jako urządzenia projektowe. lineId nie jest globalnym identyfikatorem katalogu, ponieważ dotyczy tylko jednego wydarzenia.

## Kreator nieznanego urządzenia

Kreator powinien pokazać dane otrzymane z Gremium i poprosić przynajmniej o:

1. typ urządzenia: odbiornik jednofazowy, odbiornik trójfazowy, urządzenie pasywne albo element riggingowy,
2. napięcie i liczbę faz,
3. znamionową moc lub prąd,
4. masę jednej sztuki,
5. typ i liczbę złączy zasilających,
6. liczbę punktów podwieszenia, jeżeli urządzenie jest podwieszane.

StageCalc może wstępnie uzupełnić masę otrzymaną z Gremium, ale użytkownik powinien móc ją poprawić. Przed obliczeniami aplikacja powinna wyświetlić listę urządzeń bez wymaganych parametrów.

## Ponowny import

Ponowny import tego samego projektu powinien oferować:

- aktualizację ilości i listy pozycji,
- zachowanie parametrów technicznych zapisanych w StageCalc,
- oznaczenie pozycji usuniętych z nowej pack listy,
- podsumowanie dodanych, zmienionych i usuniętych urządzeń przed zatwierdzeniem.

exportId wykrywa ponowne wczytanie dokładnie tego samego pliku. Tożsamość projektu wynika z sourceApp + project.id, a urządzenia z sourceApp + inventoryItemId.

## Walidacja i komunikaty

Importer powinien przerwać import, gdy:

- plik nie jest poprawnym JSON-em,
- schema jest inne niż gremium.stagecalc.pack-list,
- główna wersja formatVersion nie jest obsługiwana,
- brakuje project.id, project.name lub tablicy items,
- pozycja nie ma nazwy albo ma ilość mniejszą lub równą zero.

Brak masy albo danych elektrycznych nie powinien przerywać importu. Pozycję należy dodać do kolejki kreatora i pokazać podsumowanie braków.

## Kryteria odbioru modułu StageCalc

- Importer rozpoznaje plik Gremium w wersji 1.0.
- Obsługuje polskie znaki i wydarzenia wielodniowe.
- Nie tworzy case’a jako odbiornika prądu.
- Otwiera kreator dla nieznanych pozycji i zapamiętuje mapowanie katalogowe.
- Nie traktuje pustych parametrów jako zera.
- Ponowny import aktualizuje projekt bez dublowania sprzętu.
- Użytkownik widzi podsumowanie zmian i brakujących danych przed obliczeniami.
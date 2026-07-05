# StageCalc Flutter Migration - Data Model

## Cel dokumentu

Ten dokument opisuje obecny model danych oraz proponuje docelowy model offline-first dla Flutter + Dart. Model docelowy zaklada lokalna baze jako zrodlo prawdy, z mozliwoscia dodania synchronizacji pozniej.

Obecny model legacy jest traktowany jako material analityczny. Nowy model nie musi byc kompatybilny ze starymi formatami PocketBase, `Calculation.data`, `tempId`, `assignedConnectorIds` ani historycznymi polami backward compatibility.

## Obecny model danych

Obecna wersja uzywa PocketBase. Czesc danych jest przechowywana w kolekcjach, a czesc w polach JSON.

### Kolekcje PocketBase

- `users`
- `lighting_devices`
- `sound_devices`
- `multimedia_devices`
- `cabling_devices`
- `rigging_devices`
- `other_devices`
- `locations`
- `clients`
- `calculations`
- `power_presets`
- `connections`

### Users

Pola:

- `id`
- `email`
- `name`
- `avatar`
- `role`
- `favorites`

Role:

- `admin`
- `technician`
- `viewer`

### Device

Obecny model ma wspolny typ TypeScript `Device`, ale w bazie jest rozbity na kilka kolekcji kategorii.

Pola wspolne:

- `id`
- `name`
- `manufacturer`
- `category`
- `subcategory`
- `powerW`
- `currentA`
- `weightKg`
- `ipRating`
- `notes`

Pola kategorii:

- oswietlenie: zrodlo swiatla, DMX, protokoly, zoom, kolor, camera ready, punkty riggingowe,
- dzwiek: SPL, srednia moc/prad, aktywne/pasywne, protokoly, montaz, wejscia zasilania,
- multimedia: technologia, jasnosc, rozdzielczosc, throw ratio, wejscia sygnalowe, parametry ekranow/LED,
- okablowanie/dystrybucja: typ kabla, przekroj, liczba zyl, wejscie rozdzielni, wyjscia, `presetId`,
- rigging: typ kratownicy, wymiary, tabele nosnosci, WLL, sterowanie wciagarki, haki,
- inne: glownie pola wspolne.

### PowerPreset

- `id`
- `name`
- `outlets`

`Outlet`:

- `id`
- `name`
- `phase`: `L1`, `L2`, `L3`, `All`
- `type`: typ zlacza energetycznego

### PowerConnectorType

Obecne wartosci:

- `16A Uni-Schuko`
- `16A CEE 3P`
- `16A CEE 5P`
- `32A CEE 3P`
- `32A CEE 5P`
- `63A CEE 5P`
- `125A CEE 5P`
- `Powerlock 200A`
- `Powerlock 400A`

Konfiguracja typu okresla:

- `maxCurrentA`
- liczbe faz: `1` lub `3`

### Location

- `id`
- `name`
- `address`
- `powerConnectorGroups`
- `powerConnectors` jako starszy format
- `capacity`
- `notes`
- `contacts`
- `documents`

`PowerConnectorGroup`:

- `id`
- `name`
- `connectors`
- `sourceInput`
- `inputConnectorType`
- `isLocationGroup`
- `deviceId`

`PowerConnector`:

- `id`
- `name`
- `type`
- `phases`
- `phase`
- `maxCurrentA`
- `quantity`
- `notes`
- `instanceId`
- `isManual`

Uwaga: pola `instanceId`, `isManual`, `isLocationGroup` i starsze warianty `powerConnectors` sa szczegolami implementacji legacy. Nie powinny byc przenoszone 1:1 do Fluttera.

### Client

- `id`
- `name`
- `ownerUserId`
- `contactPerson`
- `email`
- `phone`
- `address`
- `nip`
- `notes`

### Calculation

- `id`
- `name`
- `ownerUserId`
- `clientId`
- `locationId`
- `lastModified`
- `data`

`data` zawiera:

- `groups`
- `connectorGroups`
- `selectedLocationId`
- `trusses`

### CalculationGroup

- `tempId`
- `name`
- `items`
- `powerType`: `1F` lub `3F_sym`
- `assignedConnectorIds`
- `assignedTrussId`
- `assignedHooks`

`CalculationItem`:

- `tempId`
- `deviceId`
- `manualName`
- `manualWeight`
- `quantity`

### Connection

Obecnie osobna kolekcja `connections`.

- `id`
- `calculationId`
- `sourceDeviceId`
- `sourceOutletId`
- `targetDeviceId`
- `targetGroupId`
- `selectedPhases`
- `notes`

Uwaga: `sourceDeviceId` w praktyce czesto oznacza runtime ID rozdzielnicy w kalkulacji, nie tylko ID urzadzenia katalogowego.

### Truss

- `id`
- `name`
- `trussTypeId`
- `length`
- `supportMode`: `suspended` lub `supported`
- `udlLimit`
- `pointLoadLimit`
- `totalLoadLimit`
- `loads`

`TrussLoad`:

- `id`
- `calculationItemId`
- `deviceId`
- `manualName`
- `manualWeight`
- `quantity`
- `riggingWeight`
- `loadType`: `point` lub `udl`
- `position`

## Docelowe zalozenia offline-first

### Zasady

- Lokalna baza jest pierwszym i podstawowym zrodlem prawdy.
- Wszystkie ID powinny byc stabilne lokalnie i globalnie. Rekomendowane UUID/ULID.
- Kazdy rekord powinien miec pola synchronizacyjne, nawet jesli sync powstanie pozniej.
- Dane domenowe powinny byc rozdzielone na tabele/kolekcje zamiast jednego duzego JSON-a tam, gdzie potrzebne sa zapytania, walidacje i czesciowy zapis.
- Snapshoty danych katalogowych w projekcie sa potrzebne tam, gdzie historyczna kalkulacja nie powinna zmieniac wyniku po edycji katalogu.

### Wspolne pola systemowe

Kazda encja offline-first powinna miec:

- `id`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `revision`
- `syncState`: `localOnly`, `pendingSync`, `synced`, `syncError`, `conflict`
- `remoteId`
- `lastSyncedAt`

W MVP `remoteId`, `lastSyncedAt` i `syncState` moga byc technicznie obecne, ale nie musza byc widoczne w UI.

## Proponowany model docelowy

### AppUser / Workspace

Na start aplikacja moze dzialac bez logowania. Warto jednak zostawic model:

- `AppUser`
- `Workspace`
- `WorkspaceMember`

Minimalnie:

- `localUserId`
- `displayName`
- `email`
- `role`

Pozwoli to pozniej dodac sync i wspoldzielenie bez przebudowy wlascicieli rekordow.

### Project

Zastapienie `Calculation` bardziej czytelnym bytem `Project`. To jest nowy model domenowy, a nie kompatybilny wrapper na legacy `Calculation`.

Pola:

- `id`
- `workspaceId`
- `name`
- `clientId`
- `locationId`
- `status`
- `notes`
- `activePhaseId`
- `createdAt`
- `updatedAt`
- pola sync

Miejsce na przyszle fazy:

- `ProjectPhase`
  - `id`
  - `projectId`
  - `name`
  - `sortOrder`
  - `startsAt`
  - `endsAt`
  - `notes`

W MVP mozna tworzyc automatyczna faze `default`, ale nie budowac UI faz.

### ProjectGroup

Odpowiednik `CalculationGroup`.

- `id`
- `projectId`
- `phaseId`
- `name`
- `powerProfile`: `singlePhase`, `threePhaseSymmetric`, docelowo `custom`
- `sortOrder`
- `assignedTrussId`
- `createdAt`
- `updatedAt`

### ProjectItem

Odpowiednik `CalculationItem`.

- `id`
- `projectId`
- `phaseId`
- `groupId`
- `catalogDeviceId`
- `nameSnapshot`
- `manufacturerSnapshot`
- `categorySnapshot`
- `powerWSnapshot`
- `currentASnapshot`
- `weightKgSnapshot`
- `manualName`
- `manualWeightKg`
- `quantity`
- `unit`: `pcs`, `m`
- `sortOrder`

Snapshoty zabezpieczaja stare projekty przed zmianami katalogu.

### DeviceCatalogItem

Rekomendacja: jedna tabela `device_catalog_items` z polem `category` i JSON-em `categoryData`, zamiast wielu tabel kategorii. W Dart latwiej to utrzymac jako wspolny model + sealed/typed extensions. Brak wymogu kompatybilnosci z osobnymi kolekcjami `lighting_devices`, `sound_devices` itd.

Pola:

- `id`
- `workspaceId`
- `category`
- `subcategory`
- `name`
- `manufacturer`
- `powerW`
- `currentA`
- `weightKg`
- `ipRating`
- `notes`
- `categoryData`
- `favorite`
- pola sync

Alternatywa: osobne tabele per kategoria. Daje mocniejsza strukture SQL, ale utrudnia wyszukiwanie i wspolny katalog.

### ConnectorTypeDefinition

Slownik typow zlacz:

- `id`
- `label`
- `maxCurrentA`
- `phaseCount`
- `nominalVoltage`
- `sortOrder`

Na start moze byc seedowany jako dane stale aplikacji.

### PowerPreset / PowerOutletTemplate

`PowerPreset`:

- `id`
- `workspaceId`
- `name`
- `inputConnectorTypeId`
- `notes`
- pola sync

`PowerOutletTemplate`:

- `id`
- `presetId`
- `name`
- `connectorTypeId`
- `phase`: `L1`, `L2`, `L3`, `All`
- `sortOrder`

### ProjectDistro

Runtime instancja rozdzielnicy lub zrodla w projekcie. To rozdziela katalog od konkretnego egzemplarza w projekcie.

- `id`
- `projectId`
- `phaseId`
- `name`
- `sourceType`: `location`, `catalogDevice`, `quick`, `manual`
- `catalogDeviceId`
- `locationConnectorGroupId`
- `presetId`
- `inputConnectorTypeId`
- `isRootPowerSource`
- `sortOrder`

### ProjectOutlet

Runtime gniazdo nalezace do `ProjectDistro`.

- `id`
- `projectId`
- `phaseId`
- `distroId`
- `templateOutletId`
- `name`
- `connectorTypeId`
- `phase`
- `maxCurrentA`
- `sortOrder`

Wartosci sa snapshotem presetu, zeby zmiana presetu nie uszkodzila historycznego projektu.

### PowerConnection

Zastepuje obecne `Connection`.

- `id`
- `projectId`
- `phaseId`
- `sourceDistroId`
- `sourceOutletId`
- `targetType`: `group`, `distro`
- `targetGroupId`
- `targetDistroId`
- `selectedPhases`
- `notes`
- `createdAt`
- `updatedAt`

Opcjonalne pole na przyszly model precyzyjny:

- `targetItemIds`

Na start mozna zostawic puste. Daje droge do modelu `Gniazdo -> konkretne pozycje`.

### Location

- `id`
- `workspaceId`
- `name`
- `address`
- `capacity`
- `notes`
- pola sync

`LocationContact`:

- `id`
- `locationId`
- `name`
- `phone`
- `email`
- `notes`

`LocationDocument`:

- `id`
- `locationId`
- `name`
- `url`

`LocationPowerGroup`:

- `id`
- `locationId`
- `name`
- `sortOrder`

`LocationPowerConnector`:

- `id`
- `locationPowerGroupId`
- `name`
- `connectorTypeId`
- `phase`
- `quantity`
- `maxCurrentA`
- `notes`

### Client

- `id`
- `workspaceId`
- `name`
- `contactPerson`
- `email`
- `phone`
- `address`
- `nip`
- `notes`
- pola sync

### TrussPlan

Mozna trzymac kratownice bezposrednio per projekt, ale semantycznie lepiej oddzielic plan:

`ProjectTruss`:

- `id`
- `projectId`
- `phaseId`
- `name`
- `trussCatalogDeviceId`
- `trussSystemId`
- `lengthM`
- `supportMode`
- `totalLoadLimitKg`
- `maxTotalLoadKg`
- `maxDistributedLoadKgPerM`
- `manualLoadKg`
- `assignedGroupIdsJson`
- `notes`
- `sortOrder`

Obecny Flutter ma juz pierwsza wersje `ProjectTruss` i tabele `project_trusses`. Punktowe obciazenia, haki i tabele nosnosci pozostaja nastepnym krokiem modulu kratownic.

`ProjectTrussLoad`:

- `id`
- `projectId`
- `phaseId`
- `trussId`
- `sourceType`: `projectItem`, `catalogDevice`, `manual`
- `projectItemId`
- `catalogDeviceId`
- `manualName`
- `manualWeightKg`
- `quantity`
- `riggingWeightKg`
- `loadType`: `point`, `udl`
- `positionM`

`ProjectGroupHookAssignment`:

- `id`
- `projectGroupId`
- `hookCatalogDeviceId`
- `quantity`

### Tabele producenta dla kratownic

W katalogu:

`TrussLoadChartEntry`:

- `id`
- `deviceId`
- `lengthM`
- `pointLoadKg`
- `deflectionPointLoadMm`
- `distributedLoadKgPerM`
- `deflectionDistributedLoadMm`

`TrussWeightChartEntry`:

- `id`
- `deviceId`
- `lengthM`
- `weightKg`

## Logika biznesowa do zachowania

### Sumy grup i projektu

- `groupPowerW = sum(item.powerW * quantity)`
- `groupCurrentA = sum(item.currentA * quantity)`
- `groupWeightKg = sum(item.weightKg * quantity + manualWeight * quantity)`
- suma projektu to suma grup.

### Obciazenie faz

- Rozdzielnica liczy obciazenie rekurencyjnie po polaczeniach wychodzacych.
- Dla polaczenia do grupy liczony jest prad grupy.
- Jesli grupa jest podlaczona do wielu gniazd, obecny model dzieli prad przez liczbe przypisan.
- Dla gniazda `L1/L2/L3` caly prad trafia na dana faze.
- Dla gniazda `All`:
  - `threePhaseSymmetric` dzieli prad po rowno na `L1/L2/L3`,
  - `singlePhase` uzywa `selectedPhases`,
  - rozdzielnica potomna przenosi swoje obciazenia fazowe w gore.
- Nalezy blokowac cykle w grafie rozdzielnic.

### Pojemnosc i przeciazenia

- Limit fazy wynika z wejscia rozdzielnicy albo sumy gniazd.
- Przekroczenie limitu fazy powinno byc stanem walidacji, nie tylko kolorem UI.

### Kratownice

- Interpolacja liniowa po dlugosci kratownicy.
- Ekstrapolacja powinna byc oznaczona jako ryzyko.
- Brak danych producenta powinien blokowac pewnosc wyniku.
- Masa grupy zawiera urzadzenia, pozycje reczne i haki.

## Wplyw GreenCrew Branding na model

Branding nie powinien zanieczyszczac encji domenowych, ale wymaga kilku danych aplikacyjnych:

- metadane aplikacji:
  - nazwa: `StageCalc`,
  - package id: `pl.greencrew.tools.stagecalc`,
  - autor: `Julian Szymanski`,
  - organizacja: `GreenCrew`,
  - licencja: `MIT`,
  - strona: `https://greencrew.pl`;
- ustawienia UI:
  - domyslny dark mode,
  - preferencje motywu,
  - ewentualny stan kompaktowego widoku terenowego;
- ekran "O aplikacji" jako funkcja aplikacyjna, nie element domeny projektu.

Paleta, ikony i teksty powinny mieszkac w warstwie `app/theme`, `shared/widgets` i lokalizacji, nie w modelach zasilania ani projektow.

## Ustawienia aplikacji

Ustawienia aplikacji powinny byc oddzielone od danych projektowych.

`AppSettings`:

- `id`
- `themeMode`: domyslnie `dark`
- `compactFieldMode`
- `defaultPowerVoltageV`
- `defaultExportFormat`
- `lastOpenedProjectId`
- `updatedAt`

Ustawienia nie powinny byc mieszane z `Project`, poniewaz projekt musi pozostac przenoszalny w backupie.

## Backup

Backup nie jest importem legacy. To format nowej aplikacji.

`BackupManifest`:

- `schemaVersion`
- `appName`
- `appVersion`
- `createdAt`
- `workspaceId`
- `recordCounts`

Preferowane formaty:

- JSON dla prostego eksportu,
- ZIP z JSON i zalacznikami, gdy aplikacja zacznie przechowywac pliki.

Import backupu musi walidowac dane przed zapisem.

## Elementy do migracji 1:1

- Slownik typow zlacz i konfiguracja pradu/faz.
- Kategorie i podkategorie katalogu, po korekcie kodowania polskich znakow.
- Pola katalogowe jako zakres danych.
- Pola klientow i lokacji.
- Presety gniazd.
- `selectedPhases` dla gniazd `All`.
- Algorytm interpolacji kratownic.
- Ogolny zakres funkcji wynikajacy z legacy, bez zachowywania formatow danych legacy.

## Elementy do przeprojektowania

- `Calculation.data` jako duzy JSON.
- Osobna kolekcja `connections` bez mocnej spojnosci transakcyjnej z kalkulacja.
- `sourceDeviceId` jako nazwa dla ID rozdzielnicy runtime.
- `tempId` jako glowne ID grupy.
- Snapshoty katalogowe, ktorych obecnie brakuje.
- Pelne kasowanie i odtwarzanie polaczen przy zapisie.
- Mieszanie legacy `assignedConnectorIds` z wizualnym patcherem.
- Historyczne pola backward compatibility, np. `powerConnectors`, `avatarUrl`, Firebase-style names.

## Rekomendowana lokalna baza

Najbezpieczniejszy kierunek dla Android + Windows + Web/iOS:

- Warstwa domenowa niezalezna od bazy.
- Repozytoria jako interfejsy.
- Implementacja lokalna:
  - Drift/SQLite dla Android, Windows i iOS.
  - Dla Web osobna implementacja IndexedDB albo Drift web, jesli ograniczenia sa akceptowalne.

Decyzje szczegolowe sa w `DECISIONS.md`.

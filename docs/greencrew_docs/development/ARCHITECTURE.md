# GreenCrew Tools Architecture Guidelines

## Cel dokumentu

Ten dokument opisuje ogólne zasady architektury aplikacji GreenCrew Tools.

Nie narzuca jednej sztywnej architektury, ale definiuje wspólny kierunek.

---

# 1. Główna zasada

Architektura ma wspierać prostotę, offline first i możliwość dalszego rozwoju.

Nie należy wybierać skomplikowanej architektury tylko dlatego, że jest popularna.

---

# 2. Warstwy aplikacji

Zalecany podział:

- Presentation
- Domain
- Data
- Infrastructure / Services

## Presentation

Zawiera:

- ekrany,
- widgety,
- kontrolery UI,
- widok stanu.

Nie powinna zawierać ciężkiej logiki biznesowej.

## Domain

Zawiera:

- modele domenowe,
- obliczenia,
- walidacje,
- przypadki użycia,
- reguły aplikacji.

## Data

Zawiera:

- repozytoria,
- lokalną bazę danych,
- modele zapisu,
- mapowanie danych.

## Infrastructure

Zawiera:

- synchronizację,
- eksport PDF / CSV,
- obsługę plików,
- integracje z API.

---

# 3. Offline first

Aplikacja powinna traktować lokalne dane jako podstawę działania.

Synchronizacja z chmurą jest dodatkową warstwą.

Nie należy projektować aplikacji tak, aby bez serwera była bezużyteczna.

---

# 4. Źródło prawdy

Dla aplikacji offline first źródłem prawdy w trakcie pracy użytkownika jest lokalna baza danych.

Serwer może być źródłem synchronizacji, ale nie powinien blokować pracy lokalnej.

---

# 5. Synchronizacja

Synchronizacja powinna być jawna i odporna na błędy.

Zalecane statusy:

- localOnly,
- pendingSync,
- synced,
- syncError,
- conflict.

---

# 6. Modele danych

Modele domenowe powinny być niezależne od UI.

Nie mieszać modeli formularzy, modeli bazy danych i modeli domenowych, jeśli zaczyna to utrudniać rozwój.

---

# 7. Obliczenia

Obliczenia techniczne powinny być wydzielone.

Przykład StageCalc:

- suma mocy,
- suma masy,
- obciążenia przyłączy,
- limity gniazd,
- walidacja konfiguracji.

Takie elementy powinny być testowalne bez UI.

---

# 8. Eksporty

Eksport PDF / CSV / JSON powinien być osobną warstwą.

Nie generować eksportów bezpośrednio z widgetów.

---

# 9. Importy

Import danych powinien walidować dane przed zapisem.

Nie ufać bezpośrednio plikom wejściowym.

---

# 10. Ustawienia

Ustawienia aplikacji powinny być oddzielone od danych projektowych.

Przykłady:

- motyw,
- domyślne jednostki,
- ostatnio używany projekt,
- preferencje eksportu.

---

# 11. Logowanie

Nie każda aplikacja musi mieć logowanie.

Jeśli aplikacja działa offline i lokalnie, logowanie nie powinno być wymagane do podstawowej pracy.

---

# 12. Uprawnienia

Aplikacja powinna prosić tylko o te uprawnienia, które są potrzebne.

Nie prosić o dostęp do zdjęć, lokalizacji albo plików bez konkretnego powodu.

---

# 13. Backup

Aplikacje przechowujące ważne dane powinny mieć możliwość eksportu / backupu.

Preferowany format backupu:

- JSON,
- ZIP z JSON i załącznikami,
- baza danych tylko jako opcja techniczna.

---

# 14. Migracje danych

Zmiany struktury danych powinny być migracją, nie resetem.

Nie usuwać danych użytkownika podczas aktualizacji.

---

# 15. Skalowanie

Architektura powinna dać się rozwijać, ale nie musi od pierwszego dnia obsługiwać ogromnej skali.

Najpierw prostota.

Potem rozbudowa.

---

# 16. Zasady dla AI

AI powinno:

- rozpoznać istniejącą architekturę,
- dopasować się do niej,
- nie mieszać wzorców bez powodu,
- wydzielać logikę techniczną z UI,
- tworzyć testowalne moduły,
- unikać wielkich refactorów bez polecenia.

---

# 17. Zasada końcowa

Dobra architektura to taka, która pozwala dodać funkcję bez strachu, że zepsuje się cała aplikacja.

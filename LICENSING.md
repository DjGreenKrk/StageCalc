# Licencjonowanie StageCalc

## Zakres

Ta licencja obejmuje wyłącznie oryginalny kod źródłowy StageCalc, do
którego prawa autorskie ma Julian Szymański (GreenCrew). Nie obejmuje
zależności ani komponentów zewnętrznych (pakiety Dart/Flutter, czcionki)
- każdy z nich pozostaje na własnej licencji. Pełna lista jest widoczna
w aplikacji: Info → „Licencje komponentów zewnętrznych”.

## Licencja: PolyForm Shield License 1.0.0

Pełny, wiążący tekst: [LICENSE](LICENSE) /
<https://polyformproject.org/licenses/shield/1.0.0>. Poniższe podsumowanie
nie zastępuje pełnego tekstu - w razie wątpliwości decyduje treść LICENSE.

- Możesz używać StageCalc prywatnie i zawodowo - także podczas płatnej
  realizacji wydarzeń.
- Firmy mogą używać go wewnętrznie.
- Możesz czytać kod, analizować go, modyfikować i rozpowszechniać -
  łącznie z publikowaniem własnego, zmodyfikowanego forka (sekcje
  „Copyright License”, „Distribution License” i „Changes and New Works
  License” licencji dają prawo do użycia, dystrybucji i tworzenia
  nowych dzieł w dowolnym dozwolonym celu).
- Jedyne ograniczenie (sekcje „Noncompete” i „Competition” licencji):
  **nie możesz** oferować - odpłatnie ani bezpłatnie - produktu lub
  usługi, która konkuruje ze StageCalc albo z innym produktem GreenCrew
  zbudowanym z wykorzystaniem tego kodu, bez osobnej zgody właściciela
  praw. Konkurowanie liczy się szeroko: również przy innym interfejsie
  lub platformie technicznej, i nawet jeśli produkt jest oferowany za
  darmo.
- PolyForm Shield **nie jest licencją open source** w rozumieniu OSI - to
  licencja typu „source-available” z ograniczonymi prawami. Właściciel
  praw autorskich zachowuje możliwość udzielania odrębnych,
  indywidualnych licencji na innych warunkach.

## Marki i branding

Nazwy **StageCalc**, **GreenCrew** i **GreenCrew Tools**, a także
konkretne pliki i katalogi identyfikacji wizualnej, **nie są objęte tą
licencją na kod** i pozostają zastrzeżone:

- `docs/logo/` - logo StageCalc (pliki PNG we wszystkich rozdzielczościach),
- `flutter/lib/shared/widgets/stagecalc_mark.dart` - kod rysujący znak
  (mark) StageCalc (`StageCalcMark`/`_StageCalcMarkPainter`) - mimo że
  jest to plik źródłowy, jego jedynym celem jest renderowanie logo, nie
  logika aplikacji,
- `flutter/android/app/src/main/res/mipmap-*/ic_launcher.png` - ikony
  aplikacji na Androida,
- `flutter/windows/runner/resources/app_icon.ico` - ikona aplikacji na
  Windows,
- `flutter/web/favicon.png` i `flutter/web/icons/` - favicon/ikony
  wersji web.

## Stan historyczny (informacyjnie)

Przed wersją 0.4.0 informacje licencyjne w tym repozytorium były
niespójne: repozytorium nie zawierało pliku LICENSE, README wskazywało,
że licencja nie została określona, natomiast aplikacja i dokumentacja
brandingowa wyświetlały „MIT”. Od wersji 0.4.0 warunki zostały
jednoznacznie określone jako PolyForm Shield License 1.0.0.

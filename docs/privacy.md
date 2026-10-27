# Privacy baseline

## Oddělené účely a souhlasy

1. Sdílený seznam nevyžaduje polohu ani senzory.
2. Jednorázový návrh pobočky vyžaduje srozumitelnou akci uživatele.
3. Crowdsourcing rozmístění má oddělený, předem nezaškrtnutý souhlas.
4. Budoucí analytika by vyžadovala samostatné rozhodnutí a dokumentaci.

Odvolání souhlasu okamžitě zastaví vznik nových pozorování. Historická data se
zpracují podle schválené retenční a výmazové politiky.

## Minimalizace

- Přesnou GPS neukládáme; po výpočtu kandidátů ji zahodíme.
- Neukládáme trasu, průběžné body, surový senzorový proud ani pohyb na pozadí.
- Pozorování používá hrubý časový a kvalitativní bucket.
- `device_installation_id` je náhodný pseudonym, ne fingerprint.
- Logy neobsahují tokeny, souřadnice, poznámky ani text položek.
- Veřejný odhad se zobrazí až po minimální diverzitě relací a instalací.

## Návrh retence k produktovému schválení

| Data                             |                                   Návrh | Důvod                            |
| -------------------------------- | --------------------------------------: | -------------------------------- |
| Nevyužitá pozvánka               | expirace nejvýše 7 dní, metadata 30 dní | bezpečnost a audit               |
| Idempotency záznam               |                                  30 dní | offline opakování                |
| Tombstone položky                |                                  30 dní | dorovnání dlouho offline klienta |
| Surové minimalizované pozorování |                                 180 dní | agregace a detekce anomálií      |
| Audit významných změn            |                                 365 dní | vyšetření zneužití               |
| Aplikační logy                   |                                  30 dní | provozní diagnostika             |
| Odvozené agregace                |         do nahrazení novou verzí modelu | produktová funkce                |

Lhůty jsou návrh, nikoli právní závěr. Před produkčním provozem je musí ověřit
kvalifikovaná osoba a musí vzniknout ověřitelný proces exportu a smazání.

## Free tier dopad

Supabase Free nemá automatické zálohy. Pro betu musí vzniknout pravidelný,
šifrovaný export s testem obnovy, nebo musí být před reálnými daty schválen
placený plán. Export nesmí být commitován ani ukládán do veřejného úložiště.

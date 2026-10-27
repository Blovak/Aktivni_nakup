# ADR 0004: Výběr pobočky a indoor omezení

- Stav: Přijato
- Datum: 2026-10-27

## Rozhodnutí

Poslední ručně potvrzenou pobočku nabídneme ihned. Jednorázová GPS po vysvětlení
vrátí pouze kandidáty podle PostGIS vzdálenosti, přesnosti a stáří měření. Ruční
volbu automaticky nepřepíšeme. Uložíme jen `store_id`, čas a zdroj volby.

MVP používá zóny a relativní pořadí, ne indoor souřadnice. Senzory budou pozdější
feature-flag experiment s runtime detekcí, explicitním oprávněním a ruční opravou.

## Důsledky

UI vždy uvede zdroj výběru a hrubou jistotu. Zamítnutí GPS či chybějící senzor
nesmí blokovat nákup. Přesné souřadnice se nesmí objevit v URL ani logu.

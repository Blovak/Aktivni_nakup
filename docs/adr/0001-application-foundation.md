# ADR 0001: Aplikační základ

- Stav: Přijato pro etapy 1–MVP
- Datum: 2026-10-27

## Rozhodnutí

Použijeme Next.js 16, React 19 a strict TypeScript s mobilně orientovaným App
Routerem. Doména a aplikační use cases budou mimo React komponenty. pnpm uzamkne
verze a Vitest s Playwrightem pokryjí jednotkové a end-to-end testy.

## Důvody

Next.js poskytne PWA UI i verzované serverové endpointy v jednom repozitáři.
Oddělená doména udrží testovatelnost a zabrání závislosti pravidel na frameworku.

## Důsledky

Service worker musí být navržen explicitně; serverové renderování samo offline
režim neřeší. Před instalací ověříme vzájemnou kompatibilitu aktuálních verzí.

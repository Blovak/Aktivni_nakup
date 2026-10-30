# Etapa 1 – malé úkoly

Každý úkol má skončit samostatně ověřitelným stavem. Vytvoření vzdáleného
Supabase projektu není podmínkou prvních úkolů.

## 1.1 Založení workspace — dokončeno

- Založit Next.js aplikaci s App Routerem, `src/` a strict TypeScriptem.
- Nastavit pnpm a uzamknout přesné kompatibilní verze v lockfile.
- Přidat `.nvmrc`/`engines` pro Node.js 22+.

Akceptace: čistá instalace projde a výchozí stránka se produkčně sestaví.

## 1.2 Statické kontroly a test runner — dokončeno

- Nastavit ESLint, Prettier, Vitest a Testing Library.
- Přidat skripty `format:check`, `lint`, `typecheck`, `test` a `build`.
- Přidat jeden test čisté doménové funkce bez Reactu.

Akceptace: všech pět příkazů projde lokálně bez varování.

## 1.3 Konfigurace prostředí — dokončeno

- Přidat `.env.example` s falešnými hodnotami.
- Validovat odděleně veřejné a serverové proměnné pomocí Zodu.
- Přidat test chybějící a chybně pojmenované konfigurace.

Akceptace: aplikace selže čitelně při chybné konfiguraci a tajemství není v bundle.

## 1.4 Cloudový Supabase — dokončeno

- Inicializovat a připnout Supabase CLI bez lokálního Docker stacku.
- Propojit repozitář s cloudovým Supabase Free projektem.
- Převést schválený návrh `0001_core` na SQL migraci.
- Zapnout RLS na každé klientsky dosažitelné tabulce.

Akceptace: `supabase db push` aplikuje migraci do propojeného cloudového projektu
bez ručních změn v Dashboardu.

## 1.5 Databázové testy — dokončeno

- Přidat pgTAP testy integritních omezení a výchozího deny-by-default RLS.
- Vytvořit testovací identity a dvě domácnosti bez produkčních osobních dat.

Akceptace: anonymní i cizí uživatel nedostanou data druhé domácnosti.

## 1.6 PWA shell

- Přidat manifest, bezpečné placeholder ikony a minimální service worker.
- Cacheovat jen aplikační shell a verzované statické assety, ne API odpovědi.
- Přidat stránku offline stavu a postup aktualizace service workeru.

Akceptace: manifest projde validací a shell se otevře offline po prvním načtení.

## 1.7 CI

- Přidat GitHub Actions pro frozen install, formát, lint, typy, testy a build.
- Nepoužívat produkční Supabase klíče; integrační DB běží lokálně v CI.

Akceptace: nový checkout projde CI pouze podle instrukcí v README.

## Doporučené pořadí

1.1 -> 1.2 -> 1.3 -> 1.4 -> 1.5 -> 1.6 -> 1.7.

Nejmenší další krok je 1.5: přidat databázové testy integritních omezení a
izolace dvou domácností pomocí RLS.

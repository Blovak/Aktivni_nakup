# Aktivní nákup

Mobilní PWA pro společné rodinné nákupní seznamy. Každý člen domácnosti vidí
stejný obsah seznamu, ale položky mohou být seřazené podle jeho aktuálně zvolené
pobočky. Základní práce musí fungovat bez GPS, senzorů i dočasně bez internetu.

## Stav projektu

Etapa 0 je dokončená. Etapa 1 má hotový spustitelný Next.js skeleton, připnuté
závislosti, statické kontroly, první jednotkové testy domény a validaci
konfigurace prostředí. Repozitář je propojený s cloudovým Supabase projektem a
migrace `0001_core` je nasazená. Všech 17 veřejných tabulek má zapnuté RLS;
integritní omezení a výchozí deny-by-default přístup pokrývají pgTAP testy.
PWA shell obsahuje manifest, offline fallback a řízenou aktualizaci service
workeru bez cacheování API odpovědí.

## Navržený technologický základ

- Next.js 16 s Reactem a TypeScriptem v přísném režimu
- Supabase Free (PostgreSQL, Auth a Realtime)
- PostGIS pro hledání blízkých poboček
- Dexie nad IndexedDB pro lokální cache a outbox
- Zod pro runtime validaci a sdílené kontrakty
- Vitest a Playwright pro testy

Projekt nyní používá Node.js 24.14.1, pnpm 12.15.0, Next.js 16.4.3,
React 19.3.0, TypeScript 5.9.3, Vitest 5.0.5, Zod 4.6.7 a Supabase CLI 2.122.0.
Přesné verze jsou uzamčené v lockfilu. Verze budoucích závislostí Supabase JS,
Dexie a Playwright se znovu ověří a připnou až v kroku, který je skutečně zavede.

## Cloudová databáze a hosting

Pro rodinnou betu použijeme Supabase Free provozovaný v cloudu. Aktuální
bezplatný tarif zahrnuje
500 MB databáze, 50 000 MAU, 2 miliony realtime zpráv měsíčně a 200 špičkových
realtime spojení. Bezplatný projekt se po týdnu neaktivity pozastaví a nemá
automatické databázové zálohy, proto nejde bez dalších opatření o vhodný základ
pro garantovaný produkční provoz.

Zdroje limitů: [Supabase Billing](https://supabase.com/docs/guides/platform/billing-on-supabase),
[Supabase Pricing](https://supabase.com/pricing) a
[Realtime Pricing](https://supabase.com/docs/guides/realtime/pricing).

Architektura zachovává PostgreSQL migrace a doménovou logiku mimo React i
provider-specific API, aby bylo možné přejít na vlastní PostgreSQL nebo placený
provoz bez přepisování produktu.

Webová aplikace bude nasazená na Vercelu a dostupná z internetu. Notebook
vývojáře není součástí produkčního běhu. Supabase CLI se používá pouze k aplikaci
verzovaných migrací do cloudového projektu; Docker není pro běžný vývoj ani
provoz projektu vyžadován.

## Lokální start

Projekt obsahuje konfiguraci `mise`, která připne správnou verzi Node.js:

```bash
mise install
corepack enable
pnpm install --frozen-lockfile
pnpm dev
```

Kontroly:

```bash
pnpm format:check
pnpm lint
pnpm typecheck
pnpm test
pnpm test:db
pnpm build
```

Cloudový Supabase projekt není podmínkou pro běh jednotkových testů. Příkaz
`pnpm test:db` spouští transakční pgTAP testy proti propojenému projektu; používá
jen syntetická data a každou sadu na konci vrátí. Pro aplikaci migrací je potřeba
jednorázově propojit repozitář s projektem pomocí
`pnpm supabase link --project-ref <project-ref>` a poté spustit
`pnpm supabase db push`.

Service worker se registruje jen v produkčním sestavení. Offline shell proto
ověřujte přes `pnpm build` a `pnpm start`, ne přes vývojový server. Při změně
cache strategie nebo souborů shellu zvyšte `CACHE_VERSION` v `public/sw.js`.

### Konfigurace prostředí

Pro lokální vývoj zkopírujte `.env.example` do `.env.local` a nahraďte pouze
zástupné hodnoty údaji svého Supabase projektu. Soubor `.env.local` je ignorován
Gitem a nesmí se commitovat.

- `NEXT_PUBLIC_SUPABASE_URL` a `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` jsou
  veřejné hodnoty dostupné klientovi.
- `SUPABASE_SERVICE_ROLE_KEY` a `DATABASE_URL` jsou serverová tajemství a smějí
  se načítat pouze v serverovém kódu.

Konfiguraci lze ověřit samostatně příkazem `pnpm env:check`. Produkční sestavení
ji kontroluje automaticky před spuštěním Next.js buildu. Chybová hlášení uvádějí
jen názvy chybných proměnných, nikdy jejich hodnoty.

## Dokumentace

- [Produkt a rozsah](docs/product.md)
- [Architektura](docs/architecture.md)
- [Datový model a návrh první migrace](docs/database-schema.md)
- [Soukromí a retence](docs/privacy.md)
- [Bezpečnost a threat model](docs/security.md)
- [Backlog etapy 1](docs/stage-1-backlog.md)
- [OpenAPI kostra](openapi/openapi.yaml)
- [Architektonická rozhodnutí](docs/adr/)

## Navržená struktura

```text
src/app/                Next.js routy, stránky a route handlers
src/components/         prezentační komponenty
src/domain/             doménové typy a čistá pravidla
src/application/        use cases a porty
src/infrastructure/     Supabase, IndexedDB, realtime a geolokační adaptéry
src/schemas/            runtime validační schémata
public/                 manifest, ikony a statické prostředky
supabase/migrations/    verzované PostgreSQL migrace a RLS
supabase/tests/         databázové a RLS testy
openapi/                verzovaný API kontrakt
tests/                  integrační a end-to-end testy
docs/adr/               architektonická rozhodnutí
```

## Zásady

- Členství v domácnosti se vynucuje na serveru a pomocí RLS.
- Přesná GPS slouží jen k jednorázovému návrhu pobočky a neukládá se.
- Crowdsourcing má samostatný opt-in souhlas a ukládá jen minimalizované údaje.
- Realtime je upozornění; autoritativní stav se po reconnectu vždy dosynchronizuje.
- Indoor funkce nikdy netvrdí přesnost na regál a neblokuje nákup.

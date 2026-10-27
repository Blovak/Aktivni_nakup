# Aktivní nákup

Mobilní PWA pro společné rodinné nákupní seznamy. Každý člen domácnosti vidí
stejný obsah seznamu, ale položky mohou být seřazené podle jeho aktuálně zvolené
pobočky. Základní práce musí fungovat bez GPS, senzorů i dočasně bez internetu.

## Stav projektu

Projekt je v etapě 0: jsou zaznamenána produktová a architektonická rozhodnutí,
návrh datového modelu, bezpečnostní a privacy baseline, OpenAPI kostra a plán
založení aplikace. Spustitelná aplikace ani databázové migrace zatím neexistují.

## Navržený technologický základ

- Next.js 16 s Reactem a TypeScriptem v přísném režimu
- Supabase Free (PostgreSQL, Auth a Realtime)
- PostGIS pro hledání blízkých poboček
- Dexie nad IndexedDB pro lokální cache a outbox
- Zod pro runtime validaci a sdílené kontrakty
- Vitest a Playwright pro testy

Před instalací budou konkrétní kompatibilní verze uzamčeny lockfilem. K
27. 10. 2026 byly ověřeny aktuální verze Next.js 16.4.3, React 19.3.1,
`@supabase/supabase-js` 2.118.0, Dexie 4.4.7, Zod 4.6.7, Vitest 5.0.5 a
Playwright 1.64.1. Supabase klient vyžaduje Node.js 22 nebo novější.

## Databáze zdarma

Pro rodinnou betu použijeme Supabase Free. Aktuální bezplatný tarif zahrnuje
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

## Předpokládaný lokální start (etapa 1)

Příkazy níže jsou cílové a začnou fungovat po založení aplikace v etapě 1:

```bash
corepack enable
pnpm install --frozen-lockfile
cp .env.example .env.local
pnpm supabase:start
pnpm dev
```

Kontroly:

```bash
pnpm format:check
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

Lokální Supabase bude vyžadovat Docker. Cloudový Free projekt nebude podmínkou
pro běh jednotkových testů.

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
app/                    Next.js routy, stránky a route handlers
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

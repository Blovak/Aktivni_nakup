# Architektura

## Kontext

```text
Next.js PWA
  UI -> aplikační use cases -> doménová pravidla
   |             |                 |
IndexedDB     API / realtime    čisté typy
outbox           |
                 v
        Supabase Auth + PostgreSQL/PostGIS
                 |
          RLS, transakce, audit
```

## Hranice

- `domain` neimportuje React, Next.js, Supabase ani Dexie.
- `application` definuje porty pro úložiště, synchronizaci, čas, UUID,
  geolokaci a realtime upozornění.
- `infrastructure` porty implementuje pomocí Supabase a IndexedDB.
- Serverové route handlers validují vstup a výstup sdílenými schématy.
- Přímý klientský přístup k databázi je povolen jen tam, kde je RLS snadno
  auditovatelné; citlivé transakce používají serverovou funkci/RPC.

## Datové toky

### Mutace položky

1. Klient před změnou UI zapíše operaci s `operation_id` do IndexedDB.
2. Lokálně aplikuje optimistický výsledek.
3. Server v transakci ověří identitu, členství, payload a `expected_version`.
4. Záznam v `client_operations` zajistí idempotenci.
5. Po commitu realtime událost pouze upozorní ostatní klienty.
6. Klient načte změny od poslední známé revize a dorovná autoritativní stav.

### Volba pobočky

Poslední ručně potvrzená pobočka se otevře ihned. GPS se vyžádá jednorázově až
po gestu uživatele. Souřadnice a přesnost se použijí k nalezení kandidátů a
následně se zahodí. Ukládá se pouze vybrané `store_id`, čas a zdroj volby.

## Cílové nasazení

- Web/PWA: poskytovatel podporující Next.js; konkrétní volba není v etapě 0 nutná.
- Data/Auth/Realtime: Supabase Free pro vývoj a omezenou rodinnou betu.
- Lokální vývoj: Supabase CLI a Docker.
- CI: GitHub Actions bez produkčních tajemství.

## Provider nezávislost

SQL migrace jsou zdrojem pravdy pro schéma. Geolokace, realtime a úložiště mají
porty. Supabase Auth identitu poskytuje, ale doménové role a členství zůstávají
v aplikačních tabulkách. Tím lze infrastrukturu vyměnit bez změny domény.

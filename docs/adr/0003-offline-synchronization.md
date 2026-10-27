# ADR 0003: Offline synchronizace

- Stav: Přijato pro návrh
- Datum: 2026-10-27

## Rozhodnutí

Dexie/IndexedDB uchová lokální projekci otevřených seznamů a perzistentní outbox.
Každá mutace má UUID `operation_id` a u verzovaného záznamu `expected_version`.
Realtime pouze spustí delta synchronizaci od serverové revize. Outbox se zpracuje
při startu, návratu do popředí, události `online` a ručním opakování.

## Konflikty

Server vrátí stabilní konflikt 409 s aktuální verzí. Nezávislé operace pokračují,
závislé se pozastaví. Významově neslučitelné hodnoty UI nezahodí bez upozornění.

## Důsledky

Background Sync je pouze doplněk. Odhlášení a odebrání členství musí vyčistit
lokální citlivá data. Tombstones a idempotency záznamy vyžadují retenci.

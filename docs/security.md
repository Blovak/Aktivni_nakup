# Bezpečnostní baseline a stručný threat model

## Bezpečnostní hranice

- Každý dotaz ověřuje autentizovaného uživatele a členství v domácnosti.
- Všechny klientsky dostupné tabulky mají zapnuté RLS a negativní testy.
- Service-role klíč nikdy nevstupuje do klientského bundle.
- Privilegované operace jsou transakční serverové funkce s omezeným `search_path`.
- Runtime schémata omezují typ, délku, počet položek a velikost dávek.
- Text uživatele se vykresluje pouze jako text, ne jako HTML.

## Hrozby a opatření

| Hrozba                | Primární opatření                                        | Povinný test                        |
| --------------------- | -------------------------------------------------------- | ----------------------------------- |
| Převzetí pozvánky     | pouze hash tokenu, expirace, limit použití, revokace     | expirovaný a opakovaný token selže  |
| Cizí domácnost        | RLS odvozené z `auth.uid()` a členství                   | izolace dvou domácností             |
| Únik polohy           | POST, redakce logů, souřadnice neukládat                 | log neobsahuje lat/lon              |
| XSS                   | žádné raw HTML, CSP, validace délek                      | škodlivý label se zobrazí jako text |
| Offline zneužití      | verze, limity dávky, autorizace každé operace            | cizí a přerostlá dávka selže        |
| Replay mutace         | unikátní `operation_id` vázané na uživatele              | duplicita má jeden účinek           |
| Konflikt verzí        | `expected_version`, odpověď 409, ruční oprava            | souběžná změna se neztratí tiše     |
| Falešná pozorování    | aktivní relace, rate limit, diverzita, robustní agregace | anomálie zásadně neposune odhad     |
| Zneužití administrace | oddělená role, server-only operace, audit                | běžný člen import neprovede         |

## HTTP ochrany

Produkce musí nastavit CSP, HSTS, `frame-ancestors 'none'`,
`X-Content-Type-Options: nosniff`, striktní `Referrer-Policy` a minimální
`Permissions-Policy`. Model CSRF se stanoví podle finálního uložení session;
stav měnící endpoint nesmí spoléhat pouze na implicitně posílanou cookie.

## Tajemství

Repozitář obsahuje pouze názvy proměnných a falešné příklady. Produkční tajemství
patří do správy prostředí. Supabase publishable/anon klíč není autorizační
hranice; bezpečnost zajišťuje RLS. Service-role a databázové heslo jsou server-only.

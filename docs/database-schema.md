# Návrh první databázové migrace

Tento dokument je konzistenčně zkontrolovaný logický návrh. Spustitelná migrace
vznikne až v etapě 1 spolu s lokálním Supabase a databázovými testy.

## Rozsah migrace `0001_core`

### Rozšíření a společné typy

- `pgcrypto` pro UUID a hashovací funkce
- `postgis` pro `geography(Point, 4326)`
- enumy `household_role`, `item_status`, `store_selection_source`,
  `observation_source` a hrubé quality buckety
- společná funkce pro bezpečnou změnu `updated_at`

### Identita a přístup

- `profiles`: `id` odkazuje na `auth.users`, `display_name`, `locale`, timestamps
- `households`: vlastník, název, timestamps
- `household_members`: složený PK, role, `joined_at`
- `household_invites`: pouze `token_hash`, expirace, počty použití a revokace

### Seznamy a synchronizace

- `shopping_lists`: domácnost, název, archivace, tvůrce, `version`
- `shopping_items`: seznam, volitelný produkt/kategorie, původní a normalizovaný
  label, množství, jednotka, poznámka, stav, nákupní metadata, tombstone, `version`
- `list_revisions`: monotónní revize na seznam pro delta synchronizaci
- `client_operations`: UUID operace, uživatel, instalační pseudonym, typ a cíl,
  timestamp; payload se standardně neukládá

`operation_id` je globálně unikátní. Server při opakování vrátí dřívější
výsledek nebo aktuální reprezentaci, ale neprovede vedlejší účinek znovu.

### Katalog a pobočky

- `product_categories`, `products`, `store_chains`, `stores`, `store_zones`
- `store_product_estimates` s verzí modelu, hrubou jistotou a počty nezávislých
  relací a instalací
- prostorový GiST index na `stores.location`

### Relace, pozorování a souhlasy

- `shopping_sessions`: uživatel, seznam, pobočka, zdroj výběru, začátek/konec,
  souhlas platný při vzniku relace a omezený seznam capabilities
- `purchase_observations`: relace, pobočka, produkt nebo kategorie, volitelná
  zóna, pořadí, hrubý čas a quality buckety, zdroj a stav agregace
- `privacy_consents`: účel, verze zásad, udělení a odvolání
- `audit_events`: server-only, bez citlivého payloadu

## Integritní pravidla

- Množství je kladné a má rozumný horní limit.
- Je zadán nejvýše jeden z `product_id` a čistě kategoriálního odhadu.
- Zakoupená položka má konzistentní `purchased_by` a `purchased_at`.
- Aktivní session má `ended_at IS NULL`; konec nesmí předcházet začátku.
- Pozorování patří do stejné pobočky jako relace a vznikne nejvýše jednou pro
  kombinaci klientské operace a účelu.
- Textové sloupce mají databázové i aplikační limity.

## RLS model

- Profil čte a mění jeho vlastník v povoleném rozsahu.
- Data domácnosti čte člen dané domácnosti.
- Seznamy a položky mění člen; správu členů a pozvánek řídí vlastník.
- Session čte a mění její uživatel, pokud je stále členem domácnosti seznamu.
- Pozorování se vkládá pouze přes validovanou transakční funkci.
- Katalog a aktivní pobočky jsou pro přihlášené čitelné; zápis je administrativní.
- Audit a surová pozorování nejsou přímo čitelné běžným klientem.

## Otevřené body před SQL

1. Potvrdit, zda delta synchronizace použije jednu revizi na seznam, nebo globální
   sekvenci domácnosti. Doporučení: revize na seznam, protože klient synchronizuje
   právě otevřený seznam.
2. Upřesnit návratovou hodnotu idempotentních operací bez ukládání payloadu.
3. Vybrat databázový test runner pro RLS; preferovaný je pgTAP v Supabase CLI.
4. Potvrdit retenční lhůty z `docs/privacy.md`.

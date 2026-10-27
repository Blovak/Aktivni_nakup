# ADR 0002: Autentizace a autorizace

- Stav: Přijato pro návrh
- Datum: 2026-10-27

## Rozhodnutí

Identitu poskytne Supabase Auth. Oprávnění určí aplikační tabulky členství a
PostgreSQL RLS založené na `auth.uid()`. Vlastník spravuje členy a pozvánky;
běžný člen pracuje se seznamy domácnosti. Citlivé více-krokové operace provedou
transakční serverové funkce.

## Důvody

Bezplatný tarif pokryje rodinnou betu a autorizace zůstane u dat, nikoli jen v UI.

## Důsledky

Každá politika potřebuje pozitivní i negativní test. Service-role klíč zůstává
výhradně na serveru. E-mailové limity a produkční doručování bude nutné ověřit
před otevřenou betou.

# Produktový základ

## Cíl MVP

Rodina bezpečně sdílí nákupní seznam. Obsah a stav položek jsou společné,
zatímco zvolená pobočka, nákupní relace a výsledné pořadí jsou uživatelské.
Hlavním přínosem je praktické pořadí položek pro konkrétní pobočku, nikoli
navigace s přesností na metry.

## Základní scénáře

1. Uživatel se přihlásí, založí domácnost nebo přijme omezenou pozvánku.
2. Členové přidávají a mění položky a změny se téměř v reálném čase dorovnají.
3. Každý člen může zvolit jinou pobočku a vidět jiné pořadí stejného seznamu.
4. Offline změny se uloží do outboxu a po návratu online provedou právě jednou.
5. GPS pouze navrhne pobočku. Ruční volba zůstává dostupná a má přednost.
6. Minimalizované pozorování vznikne jen při aktivním samostatném souhlasu.

## Slovník

- **Domácnost:** uzavřená skupina uživatelů.
- **Seznam:** sdílený seznam jedné domácnosti.
- **Položka:** uživatelský požadavek, například „mléko“.
- **Produkt:** normalizovaný katalogový pojem, volitelně s EAN.
- **Pobočka:** konkrétní prodejna s vlastními zónami a uspořádáním.
- **Zóna:** hrubá část prodejny, nikoli přesná souřadnice regálu.
- **Nákupní relace:** návštěva jednoho uživatele v jedné pobočce.
- **Pozorování:** minimalizovaná událost pro agregovaný odhad pořadí či zóny.

## MVP versus později

MVP obsahuje účty, domácnosti, pozvánky, sdílené seznamy, offline outbox,
realtime dorovnání, pobočky, zónové řazení a crowdsourcing bez senzorů.
Čárové kódy, editor mapy, optimalizovaná trasa, push notifikace a senzorový
indoor experiment jsou až následné etapy.

## Produktová pravidla

- Stav položky je pro domácnost autoritativně společný.
- Pro MVP použijeme stavy `active`, `purchased` a `removed`; `claimed` odložíme.
- `removed` je během synchronizační retence tombstone.
- Jedna klientská operace má stabilní UUID `operation_id`.
- Ruční výběr pobočky se automaticky nepřepisuje návrhem GPS.
- Nejistota je viditelná jako hrubý stupeň a lze ji ručně opravit.

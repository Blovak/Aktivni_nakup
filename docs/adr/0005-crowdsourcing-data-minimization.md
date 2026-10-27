# ADR 0005: Minimalizace crowdsourcingových dat

- Stav: Přijato pro návrh
- Datum: 2026-10-27

## Rozhodnutí

Pozorování vznikne jen při aktivním samostatném souhlasu, aktivní nákupní relaci
a dostatečné kvalitě. Uloží produkt nebo kategorii, pobočku, volitelnou zónu,
pořadí, hrubý časový a kvalitativní bucket a zdroj. Neukládá GPS, trasu, surové
senzory ani obsah celého seznamu.

Agregace vyžaduje více nezávislých relací a instalací, používá časový útlum a
omezuje vliv jedné relace. Klientem zaslané confidence skóre se ignoruje.

## Důsledky

Pseudonym instalace slouží jen k deduplikaci a diverzitě, ne k fingerprintingu.
Surová pozorování nejsou běžnému klientu čitelná a mají omezenou retenci.

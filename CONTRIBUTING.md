# Přispívání

Pracujte po malých vertikálních řezech. Před změnou ověřte stav pracovního stromu
a nepřepisujte nesouvisející práci. Každá změna musí mít testy odpovídající riziku
a aktualizovanou dokumentaci.

## Definice hotové změny

- splňuje akceptační kritérium;
- projde formátem, lintem, typy, testy a produkčním buildem;
- vynucuje autorizaci na serveru/RLS, nejen v UI;
- počítá s offline, prázdným, načítacím a chybovým stavem;
- neukládá tajemství ani citlivé údaje do logů;
- je ovladatelná klávesnicí a má přístupné názvy a focus stavy;
- uvádí známá omezení a případné nové architektonické rozhodnutí.

Commity nemají obsahovat `.env`, databázové exporty, produkční osobní údaje ani
snímky autentizačních tokenů.

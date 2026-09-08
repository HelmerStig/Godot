# Animazioni nel progetto attuale

Aggiornato l'8 settembre 2026.

`AnimatedSprite2D` e i componenti di collisione sono già presenti in `scenes/Fighter.tscn`. `Arianna.tscn` e `Mangler.tscn` ereditano da questa scena. Non occorre aggiungere un secondo sprite o ricreare i nodi del fighter.

## Dove intervenire

| Aspetto | File |
|---|---|
| Slicing e sequenze di Arianna | `scripts/AriannaAnimationCatalog.gd` |
| Slicing e sequenze di Mangler | `scripts/ManglerAnimationCatalog.gd` |
| Ingresso compatibile del catalogo Mangler | `scripts/ManglerAnimationSetup.gd` |
| Frame attivi, hitbox e comportamento Arianna | `scripts/Arianna.gd` |
| Comportamenti specifici Mangler | `scripts/Mangler.gd` |
| Timing delle varianti dichiarate | `data/attacks/*.tres` |
| Stato e comportamento condiviso | `scripts/Fighter.gd`, `scripts/FighterCombat.gd` |

I cataloghi ricostruiscono gli SpriteFrames a runtime. Una modifica manuale ai frame nell'Inspector può quindi essere sostituita all'avvio. Usare il catalogo del personaggio per sequenza, FPS e loop; verificare separatamente i frame attivi nel controller o nella risorsa della variante.

Molti fogli usano celle 512×512: questa è la dimensione del fotogramma, non dell'intero atlas. Griglia, conteggio e intervalli sorgente devono corrispondere all'immagine effettiva. Le costanti dei controller usano indici zero-based; nei documenti i fotogrammi visibili sono generalmente numerati da 1.

Per le mosse di Arianna il ciclo condiviso passa da `begin_animation_attack()`, `finish_animation_attack()` e `resolve_attack_overlap()`. Il controller conserva le finestre dei frame attivi e delle combo. Evitare di duplicare manualmente flag e contatori del combat.

Dopo una modifica verificare la suite del personaggio e, per variazioni a danni, collisioni o ciclo condiviso, tutte le suite. I comandi sono in [tests/README.md](tests/README.md); i dati dichiarati e le eccezioni runtime sono in [FRAME_DATA.md](FRAME_DATA.md).

Gli [esempi didattici precedenti](docs/archive/TUTORIAL_ANIMAZIONI.md) restano disponibili come archivio: usano nodi, funzioni e dimensioni generiche che non descrivono l'architettura corrente.

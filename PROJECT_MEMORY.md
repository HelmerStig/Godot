# Memoria del progetto

Ultimo aggiornamento: 15 settembre 2026.

## Obiettivo e baseline

Sanmo è un picchiaduro 2D in Godot 4.7, concentrato sul training locale. Il flusso parte da `TitleScreen`, passa per `CharacterSelect` e `LoadingScreen`, quindi apre `MainArena`; `CharacterSelection` conserva la scelta globale dei due fighter. Il roster attuale comprende Arianna e Mangler, selezionabili per entrambi i giocatori. Entrambi hanno animazioni e moveset articolati; combo, speciali, evocazioni e alcuni suoni sono già presenti. Timer a 99 secondi, timeout e best-of-three disabilitati. IA e online restano da sviluppare.

La baseline headless del 15 settembre 2026 è di **682 asserzioni superate, zero fallimenti**, in cinque suite: input 14, Arianna 218, Mangler 359, combat 83 e arena 8. Comandi e organizzazione sono in [tests/README.md](tests/README.md). I precedenti conteggi con fallimenti risalgono a versioni storiche.

## Architettura da preservare

- `Arianna` e `Mangler` derivano direttamente da `Fighter`, anche nelle scene; Arianna non dipende dal controller o dai nodi delle prese di Mangler.
- `Fighter` gestisce inizializzazione, segnali, stato, collisioni, ombra, reazioni standard e reset comune. Mangler estende le parti specifiche con `super` e `_apply_state_movement()`.
- `FighterCombat` gestisce vita, guardie, hitbox e ciclo delle azioni; `FighterCombatReactions` contiene danno, parata, hitstun, knockdown e KO. `action_generation` invalida coroutine e controlli di sovrapposizione tardivi; le reazioni verificano anche che fighter e componente siano ancora validi dopo ogni attesa.
- Arianna usa `begin_animation_attack()`, `finish_animation_attack()` e `resolve_attack_overlap()`. Frame attivi, animazioni e concatenazioni restano nel suo controller.
- `attack_started`, `attack_finished` e `attack_cancelled` distinguono avvio, conclusione naturale e interruzione. Le interruzioni ripuliscono i flag locali e liberano i bersagli delle speciali non ancora lanciate.
- Il flusso pubblico è `FighterCombat → Fighter → MainArena → ArenaUI`; la UI osserva i segnali dell'arena.
- `MainArena._ready()` applica sempre `CharacterSelection`: fixture e scene di test devono impostare la selezione globale, non sostituire manualmente i nodi fighter prima dell'ingresso nello SceneTree.
- Texture, dimensioni e timing delle barre vita sono in `ArenaUIConfig`; `ArenaUI` conserva soltanto costruzione, stato e reazione ai segnali. Le barre raggiungono il valore destinazione con un tween di 0,34 secondi, quindi i test non devono aspettarsi l'aggiornamento visivo nello stesso frame del segnale.
- `AttackData` contiene identità, danno e stun; `AttackVariantData` descrive timing, animazione e geometria. Ci sono otto risorse in `data/attacks/`. Il profilo `CharacterData` predefinito è ancora creato a runtime.
- I cataloghi animazioni costruiscono gli atlas dei due personaggi separatamente. Non assumere dimensione dell'intero foglio o scala comune: usare celle, sequenze e scale del catalogo/controller.

## Regole di combattimento

- LOW richiede giù + indietro; HIGH e MID si parano con indietro, anche da accovacciati. Si para solo a terra e con l'attaccante davanti. Danno parato: zero.
- `take_damage()` restituisce `IGNORED`, `BLOCKED`, `HIT` o `KNOCKOUT`. Il pugno forte accovacciato di Mangler lancia soltanto sul risultato `HIT`.
- Le hitbox devono infliggere un solo impatto per bersaglio, salvo mosse esplicitamente multi-hit. Le forme vengono duplicate per istanza.
- Input dei giocatori separati; direzioni relative al facing; `record_input_snapshot()` permette di testare il buffer senza dipendere dal dispositivo fisico.
- Il blocco dei controlli dell'arena è distinto da quello imposto dallo stato del fighter.
- Le pose di KO/vittoria non vanno riavviate ogni frame; il reset deve poterle abbandonare.

## Test e manutenzione

`tests/suite_catalog.gd` è l'unica lista dei casi, usata dai cinque entry point e dalla suite completa. I casi ricevono `SceneTree` e callback di asserzione; `tests/support/suite_runner.gd` azzera input e scala temporale tra i moduli. Gli scenari storici di Arianna e Mangler restano sequenziali per preservare setup e attese; i nuovi comportamenti indipendenti vanno in file dedicati.

Usare le risorse e gli SpriteFrames per le attese di comportamento. I valori esatti degli atlas vanno verificati nei test di slicing. Dopo una modifica al comportamento condiviso eseguire tutte le cinque suite; quando cambia l'orchestrazione verificare anche `smoke_tests.gd` nello stesso processo.

## Riferimenti

- [README](README.md): avvio, controlli e mappa dei file.
- [Frame data](FRAME_DATA.md): dati dichiarati e comportamento runtime.
- [Triage storico](SMOKE_TEST_TRIAGE.md): cause dei fallimenti del settembre 2026 già risolti.
- [Memoria precedente](docs/archive/PROJECT_MEMORY.md): note dettagliate e scelte storiche, da verificare contro il codice corrente prima di riutilizzarle.

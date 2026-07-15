# Memoria del progetto

Ultimo aggiornamento: 15 luglio 2026

## Obiettivo attuale

Sanmo è un prototipo didattico di picchiaduro 2D realizzato con Godot 4.7. La priorità corrente è mantenere stabile il combattimento locale in modalità training prima di introdurre animazioni complete, `AttackData`, IA, combo, menu o round competitivi.

## Baseline funzionante

- Due fighter controllabili contemporaneamente.
- Player 1 usa tastiera o gamepad 0; Player 2 usa tastierino numerico o gamepad 1.
- Movimento, salto, accovacciamento e guardia direzionale.
- Sei attacchi a terra: pugni e calci leggeri, medi e pesanti.
- Hitbox diversa per ogni attacco e tre hurtbox per fighter.
- La guardia riuscita annulla completamente il danno.
- Hit-stun, reazione di blocco, KO e reset con `R`.
- Timer da 99 secondi visibile, con timeout intenzionalmente disabilitato.
- Camera condivisa, limiti visibili dello stage e attraversamento dei fighter in aria.
- Overlay collisioni con `F3` e slow motion con `F4`.
- Stage con sfondo ed effetti ambientali.
- Sprite personaggi ridotti a PNG RGBA 512×512; scala della scena condivisa impostata a `0.7`.
- Rimossi lo scaffolding vuoto `node_2d.tscn` e lo script parallasse non collegabile `ParallaxStage.gd`.

## Architettura corrente

- `scenes/MainArena.tscn`: composizione di arena, stage, fighter, camera e UI.
- `scenes/Mangler.tscn`: scena condivisa del fighter.
- `scenes/stages/DefaultStage.tscn`: stage predefinito.
- `scripts/Mangler.gd`: coordinatore del fighter; gestisce input, movimento, orientamento e stato.
- `scripts/FighterCombat.gd`: attacchi, hitbox, vita, danno, guardia, reazioni e KO.
- `scripts/FighterInputBuffer.gd`: snapshot input, direzioni relative, consumo attacchi e sequenze recenti.
- `scripts/CharacterData.gd`: statistiche del fighter e parametri base degli attacchi.
- `scripts/MainArena.gd`: ciclo del training, countdown, reset, camera e fine per KO.
- `scripts/ArenaUI.gd`: unico componente che modifica barre vita, timer e messaggi.
- `scripts/FighterDebugOverlay.gd`: disegno diagnostico delle collisioni.
- `scripts/StageAmbientEffects.gd`: movimento degli effetti ambientali.
- `tests/smoke_tests.gd`: suite headless permanente.

Il flusso degli eventi è:

```text
FighterCombat → Mangler → MainArena → ArenaUI
```

`Mangler` riemette vita, KO, cambi di stato e ciclo degli attacchi. `MainArena` pubblica vita per giocatore, timer, messaggi, inizio e fine training. `ArenaUI` osserva questi segnali e non viene modificata direttamente dal gameplay.

## Decisioni progettuali attive

- Mantenere per ora una modalità training semplice; timeout e best-of-three restano segnaposto.
- Separare il blocco dei controlli imposto dall'arena da quello imposto dallo stato del fighter.
- Conservare `Mangler` come autorità sulle transizioni tramite `change_state()`.
- Isolare il combattimento in `FighterCombat`, evitando per ora una classe separata per ogni stato.
- Usare `CharacterData` come fonte di movimento, vita, danni e durata totale degli attacchi.
- Proteggere coroutine di attacco, hit-stun e block-stun con un contatore di generazione.
- Usare segnali tra combattimento, fighter, arena e UI.
- Mantenere input separati per i due giocatori.
- Esporre `record_input_snapshot()` per rendere input buffer, replay e test indipendenti dal backend fisico.
- Mantenere gli sprite a 512×512 e compensare con scala `0.7` nella scena del fighter.

## Smoke test

Esecuzione Windows:

```powershell
.\tests\run_smoke_tests.cmd
```

Esecuzione diretta:

```text
godot --headless --path . --script res://tests/smoke_tests.gd
```

La suite corrente esegue 28 verifiche e copre:

- conversione delle direzioni in base all'orientamento;
- memorizzazione e consumo singolo degli attacchi;
- riconoscimento di sequenze direzionali;
- danno normale e hit-stun;
- guardia senza danno e block-stun;
- propagazione della vita alla UI;
- KO, blocco dei controlli e messaggio del vincitore;
- reset di vita, stato, UI e training.

Ultimo risultato noto: `SMOKE_TESTS_OK`, codice di uscita `0`.

## Controlli attuali

### Player 1

- Movimento: `A`/`D` oppure frecce sinistra/destra.
- Salto: `W`, freccia su o `Spazio`.
- Accovacciamento: `S` o freccia giù.
- Pugni leggero/medio/pesante: `J`/`H`/`U`.
- Calci leggero/medio/pesante: `K`/`L`/`I`.
- Gamepad: device 0.

### Player 2

- Movimento: tastierino `4`/`6`.
- Salto: tastierino `8`.
- Accovacciamento: tastierino `5`.
- Pugni leggero/medio/pesante: tastierino `1`/`2`/`3`.
- Calci leggero/medio/pesante: tastierino `7`/`9`/`0`.
- Gamepad: device 1.

### Comuni

- Guardia: tenere la direzione opposta all'avversario.
- Reset training: `R`.
- Overlay collisioni: `F3`.
- Slow motion: `F4`.

## Debito tecnico noto

- Danno e durata risiedono in `CharacterData`, mentre hitbox e suddivisione startup/active/recovery risiedono in `FighterCombat`.
- Startup, active e recovery sono percentuali fisse 30/40/30 della durata totale.
- Non esiste ancora una risorsa `AttackData`.
- `CharacterData` viene creato in memoria e non esistono profili `.tres` per i personaggi.
- Le animazioni non sono collegate agli stati o agli attacchi.
- Gli asset di Arianna, Bue, Mileto, Peirolo e Torpe non sono ancora collegati a fighter giocabili.
- `end_round_timeout()`, `next_round()` ed `end_match()` sono segnaposto.
- Il timer continua a essere visualizzato in training, ma non termina il round.
- Combo e mosse speciali non usano ancora le sequenze riconosciute dall'input buffer.
- Non sono presenti IA, audio, menu, selezione personaggio, salvataggi o multiplayer online.
- `original_images/` contiene materiale sorgente non usato a runtime e viene conservato intenzionalmente.

## Priorità successive

1. Introdurre `AttackData` con danno, startup, active, recovery, hit-stun e hitbox.
2. Collegare stati e attacchi ad animazioni e feedback visivi.
3. Creare risorse `CharacterData` dedicate ai personaggi.
4. Aggiungere un secondo tipo di fighter o una IA basilare.
5. Implementare round, timeout, punteggio e best-of-three.
6. Collegare combo e mosse speciali all'input buffer.

## Nota per la prossima sessione

Prima di nuove modifiche eseguire `tests/run_smoke_tests.cmd`. Il prossimo intervento tecnico consigliato è introdurre una risorsa `AttackData`.

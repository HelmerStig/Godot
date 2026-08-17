# Memoria del progetto

Ultimo aggiornamento: 10 agosto 2026

## Obiettivo attuale

Sanmo è un prototipo didattico di picchiaduro 2D realizzato con Godot 4.7. La priorità corrente è mantenere stabile il combattimento locale in modalità training prima di introdurre animazioni complete, IA, combo, menu o round competitivi.

## Baseline funzionante

- Due fighter controllabili contemporaneamente.
- Player 1 usa tastiera o gamepad 0; Player 2 usa tastierino numerico o gamepad 1.
- Movimento, salto, accovacciamento e guardia direzionale.
- Sei attacchi a terra: pugni e calci leggeri, medi e pesanti.
- Sei risorse `AttackData` con timing, stun e hitbox espliciti.
- Hitbox diversa per ogni attacco e tre hurtbox per fighter.
- La guardia riuscita annulla completamente il danno.
- Hit-stun, reazione di blocco, KO e reset con `R`.
- Timer da 99 secondi visibile, con timeout intenzionalmente disabilitato.
- Camera condivisa, limiti visibili dello stage e attraversamento dei fighter in aria.
- Overlay collisioni con `F3` e slow motion con `F4`.
- Stage con sfondo ed effetti ambientali.
- Sprite personaggi ridotti a PNG RGBA 512×512; scala della scena condivisa impostata a `0.7`.
- Mangler dispone di animazioni per locomozione, attacchi, guardia, reazioni e KO.
- Le varianti delle mosse sono risorse `AttackVariantData` embedded nei sei attacchi `.tres`.

## Architettura corrente

- `scenes/MainArena.tscn`: composizione di arena, stage, fighter, camera e UI.
- `scenes/Mangler.tscn`: scena condivisa del fighter.
- `scenes/stages/DefaultStage.tscn`: stage predefinito.
- `scripts/Mangler.gd`: coordinatore del fighter; gestisce input, movimento, orientamento e stato.
- `scripts/AttackData.gd`: schema dati di un attacco.
- `scripts/AttackVariantData.gd`: frame data e geometria delle varianti contestuali.
- `data/attacks/*.tres`: risorse dei sei attacchi base.
- `scripts/FighterCombat.gd`: ciclo degli attacchi, vita, danno, guardia, reazioni e KO.
- `scripts/FighterInputBuffer.gd`: snapshot input, direzioni relative, consumo attacchi e sequenze recenti.
- `scripts/CharacterData.gd`: statistiche del fighter e parametri base degli attacchi.
- `scripts/MainArena.gd`: ciclo del training, countdown, reset, camera e fine per KO.
- `scripts/ArenaUI.gd`: unico componente che modifica barre vita, timer e messaggi.
- `scripts/FighterDebugOverlay.gd`: disegno diagnostico delle collisioni.
- `scripts/StageAmbientEffects.gd`: movimento degli effetti ambientali.
- `scripts/ManglerAnimationSetup.gd`: registro centrale delle animazioni runtime.
- `scripts/ManglerVisualConfig.gd`: profili degli effetti di movimento.
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
- Usare `CharacterData` come fonte di movimento, vita e lista degli attacchi disponibili.
- Usare `AttackData` per identità/danno/stun e `AttackVariantData` per animazione, frame attivi, timing, hitbox, altezza e knockdown.
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

La suite corrente esegue oltre 200 verifiche e copre:

- configurazione, autoplay e orientamento dell'animazione idle;
- caricamento, lookup e validazione delle sei risorse `AttackData`;
- selezione della risorsa e completamento del ciclo startup/active/recovery;
- conversione delle direzioni in base all'orientamento;
- memorizzazione e consumo singolo degli attacchi;
- riconoscimento di sequenze direzionali;
- danno normale e hit-stun;
- guardia senza danno e block-stun;
- propagazione della vita alla UI;
- KO, blocco dei controlli e messaggio del vincitore;
- reset di vita, stato, UI e training.

Ultimo risultato noto (10 agosto 2026): caricamento senza errori di parsing e `SMOKE_TESTS_FAILED` con 25 asserzioni, contro le 26 della baseline precedente al refactoring.

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
- Presa di Mangler: pugno leggero + calcio leggero a terra; `grab_tentative` è saltato e la portata viene verificata immediatamente.
- Se l'avversario è in portata parte `Mangler2-headbut_mangler_mangler.png`: foglio combinato 7×7, 49 frame a 48 FPS, spostato di 80 px in avanti e non ciclico, con esplosione giallo-arancio al frame 19. Durante la sequenza vittima e ombra sono nascoste; alla fine entrambi avanzano di 30 px nella direzione della testata e tornano visibili in `IDLE`.
- La testata separata resta configurata ma il suo avvio automatico è temporaneamente disattivato per controllare le posizioni della presa.
- Follow-up presa: `testata-rear.png` e `testata-front.png`, 25 frame sincronizzati a 25 FPS, impatto high non parabile al frame 17 per 15 danni; la vittima resta immobilizzata fino alla fine.
- Effetto testata: scia dorata rear/front attiva circa dai frame 11–19, con intensità da mossa potente.
- Impatto testata: flash additivo e 34 scintille giallo-arancio sul volto della vittima al frame 17.
- Reazione vittima presa: `grabbed.png`, sequenza sorgente 10–25–10 a 24 FPS; un impatto interrompe la sequenza e avvia `hurt_high`.
- Reazione colpo aereo: `assets/sprites/characters/mangler/11-hurted_in_jump.png`, 25 frame a 24 FPS; frame 25 a terra per 1 secondo, poi `knockdown_recovery`.
- Reset training: `R`.
- Overlay collisioni: `F3`.
- Slow motion: `F4`.

## Debito tecnico noto

- `CharacterData` viene creato in memoria e non esistono profili `.tres` per i personaggi.
- Le funzioni di slicing degli atlas sono ancora fisicamente in `Mangler.gd`, anche se registrazione e profili effetti sono stati estratti.
- Venticinque aspettative della suite non sono allineate agli atlas e timing correnti.
- Gli asset di Arianna, Bue, Mileto, Peirolo e Torpe non sono ancora collegati a fighter giocabili.
- `end_round_timeout()`, `next_round()` ed `end_match()` sono segnaposto.
- Il timer continua a essere visualizzato in training, ma non termina il round.
- Combo e mosse speciali non usano ancora le sequenze riconosciute dall'input buffer.
- Non sono presenti IA, audio, menu, selezione personaggio, salvataggi o multiplayer online.
- `original_images/` contiene materiale sorgente non usato a runtime e viene conservato intenzionalmente.

## Priorità successive

1. Riallineare atlas, frame attivi e smoke test fino a `SMOKE_TESTS_OK`.
2. Migrare per gruppi le funzioni di slicing da `Mangler.gd` al componente animazioni.
3. Creare risorse `CharacterData` dedicate ai personaggi.
4. Implementare round, timeout, punteggio e best-of-three.
5. Collegare combo e mosse speciali all'input buffer.

## Nota per la prossima sessione

Prima di nuove modifiche eseguire `tests/run_smoke_tests.cmd`. Il prossimo intervento è risolvere le 25 discrepanze della baseline e proseguire l'estrazione dello slicing da `Mangler.gd`.

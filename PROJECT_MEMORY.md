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
- Se l'avversario è in portata parte `Mangler2-headbut_mangler_mangler.png`: foglio combinato 7×7, usa solo i frame sorgente 1–29 a 48 FPS, spostato di 80 px in avanti e non ciclico, con la stessa esplosione rossa del light punch al frame 19. Durante la sequenza vittima e ombra sono nascoste; dopo il frame 29 entrambi avanzano di 15 px nella direzione della testata e tornano visibili in `IDLE`.
- Supermossa: mezzaluna in avanti `BACK, DOWN_BACK, DOWN, DOWN_FORWARD, FORWARD` + calcio leggero e medio. Tutte le quattro fasi sono a 48 FPS. `super_start.png` usa 25 frame e al frame 19 genera l'aura gialla; `rotate-super_run.png` usa 25 frame e dal frame 20 avanza, poi `run_only.png` usa 24 frame in loop. L'avvicinamento è a 480 px/s, lascia afterimage giallo-arancioni e termina alla distanza di contatto di 130 px. All'avvio del rullo la super applica una sola volta danno pari al 25% della vita massima. `drum_roll_only.png` usa 24 frame per due esecuzioni con quattro esplosioni rosse per ciclo, ancorate alla posizione globale della `HeadHurtbox`; durante entrambe il bersaglio è in `State.HIT` e ripete i frame sorgente 4–13 di `hurt-high.png` tramite `super_drum_hurt` a 48 FPS e scala legacy `0.7`. Dopo il secondo rullo, se non è KO, il bersaglio esegue `super_drum_knockdown` con i frame sorgente 11–25 di `ko.png` a 24 FPS, poi la normale `knockdown_recovery` e infine `IDLE`. Durante la sequenza l'attaccante ha z-index superiore; prima del rullo l'avversario resta senza controlli ma continua `idle`, salvo la posa congelata di `block_high` se stava già parando.
- Tolleranza motion input: cronologia 60 frame, buffer pulsante 10 frame, quarti di luna 36 frame e mezzaluna della super 48 frame. Il buffer ricostruisce i passaggi bassi e diagonali saltati dallo stick rapido.
- Ordine grafico attacchi: ogni fighter che avvia un attacco passa a `opponent.z_index + 1`, sia come Player 1 sia come Player 2. Lo z-index predefinito viene ripristinato alla conclusione, alla cancellazione o al reset dell'attacco.
- Pulizia asset Mangler: rimossi 20 PNG senza riferimenti runtime/documentali e i relativi 20 `.import` (circa 40,2 MB). Gli sprite ancora pre-caricati da `Mangler.gd`, comprese implementazioni storiche, restano conservati finché il relativo codice non viene rimosso. `original_images` è esclusa dalla pulizia.
- Arianna: `scenes/Arianna.tscn` eredita temporaneamente l'infrastruttura di `Mangler.tscn`, con `SpriteFrames` duplicato per istanza. `idle.png` usa 24 frame a 24 FPS in loop; `01-walk.png` misura 3584×3584 e usa 48 frame da 512×512 a 24 FPS. `walk` li riproduce 1→48 per avanzare, `backwalk` 48→1 per arretrare mantenendo il facing; entrambi usano la `walk_speed` e tornano in idle al rilascio. Il pugno leggero riproduce a 48 FPS i frame sorgente 1→9 e il recupero 9→1 prima dell'idle. La hitbox high misura 160×50 px, è centrata a `(85, -170)`, resta attiva sui frame animazione 7–9 e usa i 5 danni del light punch. Scala `0.85`, posizione sprite `(0, -120)`. `MainArena` usa Arianna come Player 1 e Mangler come Player 2.
- Salto Arianna: `basic-moves/jump.png` misura 4096×4096, griglia 8×8 da 512 px, 64 frame a 48 FPS non ciclici. Lo stacco avviene al frame 6; usa velocità verticale `character_data.jump_velocity`, gravità Arianna `1400 px/s²` e conserva soltanto la direzione orizzontale scelta a terra. All'atterraggio torna in idle.
- Collisioni salto Arianna: esclusivamente in `JUMP_STARTUP/JUMPING` la pushbox è 120×90 px a `(0, -90)` e la maschera fisica conserva soltanto il layer del terreno. Non si usa `not is_on_floor()` per scegliere il profilo, perché nei primi frame di caricamento Godot non ha ancora registrato il pavimento e ridurrebbe erroneamente la pushbox in idle. In aria Arianna attraversa la pushbox avversaria e non può atterrarvi sopra; al suolo vengono ripristinati layer e profilo standard. Gli input `light_punch` ricevuti in aria vengono consumati senza avviare il pugno terrestre, in attesa della variante aerea dedicata.
- Facing salto Arianna: `start_jump()` memorizza il lato iniziale rispetto all'avversario e blocca il flip durante la capriola. Il facing può aggiornarsi soltanto dopo l'ultimo frame di `jump` (oppure all'atterraggio che chiude fisicamente il salto) e solo se la posizione globale ha attraversato il centro dell'avversario.
- Corsa Arianna: doppio tap avanti nella finestra comune di 15 frame; `basic-moves/run.png` è 3584×3584, griglia 7×7 da 512 px, primi 48 frame in loop a 24 FPS. La direzione viene fissata all'avvio e la corsa prosegue a `character_data.run_speed × 2` fino a una collisione orizzontale con un fighter/ostacolo o al limite dello stage, quindi passa a idle.
- Back jump Arianna: doppio tap indietro nella finestra comune di 15 frame. `basic-moves/back-jump.png` è una griglia 7×7 da 512 px e `arianna_back_jump` usa i 22 frame sorgente 28→49 a 48 FPS, senza loop. Non applica impulso né gravità verticale: la quota iniziale viene mantenuta per tutta la sequenza. Un timer fisico interpola la posizione iniziale verso il target di 50 px in 1 s (`50 px/s`), limitato ai bordi dello stage. Concluso il frame 49, passa immediatamente a `idle` senza mantenere la posa finale; il timer completa in background l'eventuale movimento residuo e poi chiude il back jump.
- Crouch Arianna: `basic-moves/crouched.png` è 2560×2048, griglia 5×4 da 512 px con 19 celle. `crouch` usa 1→19 a 48 FPS e mantiene il frame 19 finché giù resta premuto; al rilascio `arianna_crouch_recovery` usa sorgente 18→1 a 48 FPS e conclude in idle. Il profilo collisioni interpola anche durante la recovery invece di tornare subito all'altezza standing.
- Guardia alta Arianna: `basic-moves/guard_high.png` è 2048×2048, griglia 4×4 da 512 px con 16 frame. Tenere indietro senza un attacco avversario conserva la normale `backwalk`; quando `opponent.combat.is_attacking` diventa vero, `block_high` esegue 1→16 a 48 FPS e mantiene la posa finale. Al rilascio oppure quando l'attacco termina, `block_high_recovery` usa sorgente 15→1 a 48 FPS, poi idle. La predisposizione logica alla parata resta legata all'input indietro, così il primo impatto può essere bloccato. Il secondo tap indietro durante guardia/recovery conserva la priorità e avvia il back jump.
- Guardia media Arianna: `basic-moves/guard_middle.png` è 2048×2048, griglia 4×4 da 512 px con 13 celle occupate. Quando l'attacco attivo dell'avversario ha `HitHeight.MID`, `block_mid` usa sorgente 1→13 a 48 FPS e mantiene il frame 13; al rilascio o a fine attacco, `block_mid_recovery` usa 12→1 a 48 FPS e conclude in idle. `_start_guard_for_incoming_attack()` legge l'altezza effettiva dall'`AttackData`/variante corrente e lascia gli attacchi `HIGH` sulla guardia alta.
- Guardia bassa Arianna: `basic-moves/guard_low.png` è 2048×2048, griglia 4×4 da 512 px con 16 frame. Con giù + indietro mentre l'avversario esegue un attacco `LOW`, `block_low_crouched` usa 1→16 a 48 FPS e mantiene il frame 16; al rilascio o a fine attacco `block_low_recovery` usa 15→1 a 48 FPS. La verifica low precede il normale ramo crouch; senza attacco basso attivo, giù conserva il comportamento di accovacciamento.
- Pugno leggero basso Arianna: `basic-moves/light-punch/ligth-punch-low.png` è 2560×2560, griglia 5×5 da 512 px; vengono usati soltanto i frame 1→15 e la recovery 14→1, entrambe a 48 FPS. Hitbox 165×45 a `(87.5, -115)`, attiva sui frame visibili 12–15. All'attivazione `_resolve_low_light_punch_overlap()` attende un physics frame e passa le aree sovrapposte a `_apply_hit_to_area()`; `hit_targets` mantiene il colpo singolo. Una variante runtime forza `HitHeight.MID`, ottenendo `hurt_mid` sul colpo e `block_mid` in parata; danno invariato del light punch. A fine recovery, se giù resta premuto, passa direttamente al frame finale di `crouch` e lo mantiene; altrimenti idle.
- Pugno medio Arianna: `basic-moves/medium-punch/medium-punch.png` è 2560×2560, griglia 5×5 da 512 px con 25 frame. `arianna_medium_punch` usa 1→25 e la recovery 24→1 a 48 FPS. Hitbox high 190×45 a `(100, -195)`, attiva sui frame visibili 21–25; `_resolve_medium_punch_overlap()` garantisce il controllo al physics tick e `hit_targets` limita a un impatto. Usa i 10 danni e `HitHeight.HIGH` del medium punch, quindi `hurt_high` o `block_high`.
- Pugno medio basso Arianna: `basic-moves/medium-punch/medium-punch-low.png` è 2560×1536, griglia 5×3 da 512 px con 12 frame. `arianna_low_medium_punch` usa 1→12 e la recovery 11→4 a 24 FPS. Hitbox MID 200×48 a `(105, -120)`, attiva sui frame visibili 10–12, con controllo overlap al physics tick e profilo afterimage delle strong move. Genera `hurt_mid` o `block_mid`; a fine recovery mantiene la posa finale di crouch se giù è ancora premuto, altrimenti torna in idle.
- Pugno forte Arianna: `basic-moves/strong-punch/strong-punch.png` è 3584×3584, griglia 7×7 da 512 px con 49 frame tutti utilizzati. `arianna_strong_punch` riproduce 1→49 a 48 FPS senza loop e conclude direttamente in idle. Hitbox HIGH 110×65 a `(100, -180)`, attiva sui frame visibili 23–28; una variante runtime forza `HitHeight.HIGH`, producendo `hurt_high` o `block_high`. La sequenza usa il profilo afterimage HEAVY delle mosse forti di Mangler.
- Effetto rosso d'impatto: `_apply_hit_to_area()` genera `spawn_hit_effect()` per il light punch in piedi soltanto se `_target_will_block(target)` è falso. Una parata riuscita non crea particelle rosse; l'effetto resta riservato ai colpi realmente subiti.
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
- Arianna è collegata come Player 1 con il solo idle; Bue, Mileto, Peirolo e Torpe non sono ancora collegati a fighter giocabili.
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

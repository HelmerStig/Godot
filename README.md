# Sanmo

Prototipo didattico di picchiaduro 2D sviluppato con Godot 4.7 e GDScript. Il progetto è attualmente concentrato sulla modalità training locale e sulla stabilizzazione del combattimento di base.

## Stato attuale

Il prototipo comprende:

- due fighter controllabili contemporaneamente;
- movimento orizzontale, salto e accovacciamento;
- sei attacchi a terra: pugni e calci leggeri, medi e pesanti;
- input buffer con direzioni relative all'avversario;
- hitbox specifiche per ogni attacco e hurtbox separate per testa, torso e gambe;
- guardia ottenuta tenendo la direzione opposta all'avversario;
- nessuna perdita di vita quando un colpo viene parato correttamente;
- hit-stun, reazione di blocco, KO e reset del training;
- camera centrata tra i fighter con limiti visibili dello stage;
- barre della vita, timer e messaggi aggiornati tramite segnali;
- debug di hitbox e hurtbox e modalità slow motion;
- stage con sfondo ed effetti ambientali;
- smoke test headless per risorse, varianti, animazioni, input buffer e combattimento.

Il timer è visualizzato e scende da 99, ma il timeout e il sistema best-of-three sono intenzionalmente disabilitati in modalità training.

## Controlli

La guardia non usa un pulsante dedicato: bisogna tenere la direzione opposta all'avversario mentre il colpo entra a contatto.

### Player 1 — tastiera

| Azione | Tasto |
|---|---|
| Sinistra / destra | `A` / `D` oppure frecce |
| Salto | `W`, freccia su o `Spazio` |
| Accovacciamento | `S` o freccia giù |
| Pugno leggero / medio / pesante | `J` / `H` / `U` |
| Calcio leggero / medio / pesante | `K` / `L` / `I` |

### Player 2 — tastierino numerico

| Azione | Tasto |
|---|---|
| Sinistra / destra | `4` / `6` |
| Salto | `8` |
| Accovacciamento | `5` |
| Pugno leggero / medio / pesante | `1` / `2` / `3` |
| Calcio leggero / medio / pesante | `7` / `9` / `0` |

Player 1 supporta anche il gamepad 0 e Player 2 il gamepad 1.

### Training e debug

| Azione | Tasto |
|---|---|
| Reset training | `R` |
| Mostra/nascondi collisioni | `F3` |
| Slow motion | `F4` |

## Esecuzione

1. Aprire la cartella del progetto con Godot Engine 4.7.
2. Premere `F5` oppure avviare `res://scenes/MainArena.tscn`.
3. Attendere il countdown iniziale.

La scena principale è configurata in `project.godot` come `res://scenes/MainArena.tscn`.

## Smoke test headless

Su Windows:

```powershell
.\tests\run_smoke_tests.cmd
```

Il runner cerca prima il percorso configurato in `.vscode/settings.json`, poi i comandi `godot` e `godot4` nel `PATH`. È possibile specificare manualmente l'eseguibile:

```powershell
.\tests\run_smoke_tests.cmd -GodotPath "C:\percorso\Godot_v4.7-stable_win64.exe"
```

Esecuzione diretta, valida anche su altri sistemi:

```text
godot --headless --path . --script res://tests/test_input.gd
```

Gli altri entry point sono `test_arianna.gd`, `test_mangler.gd`, `test_combat.gd` e `test_arena.gd`. Il file `smoke_tests.gd` resta eseguibile come suite completa di compatibilità.

Le cinque suite verificano 516 condizioni relative ad animazioni, `AttackData`, `AttackVariantData`, input buffer, combattimento, UI, KO e reset. Ogni processo pubblica il proprio risultato e il runner aggregato termina con `SMOKE_TESTS_OK`.

> Baseline del 1 settembre 2026: 516 asserzioni superate in cinque suite, nessun fallimento e risultato aggregato `SMOKE_TESTS_OK` con Godot 4.7.

## Architettura

```text
FighterCombat
    ↓ segnali di combattimento
Mangler
    ↓ segnali pubblici del fighter
MainArena
    ↓ segnali di stato del training
ArenaUI
```

- `scenes/MainArena.tscn`: stage, terreno, due fighter, camera e nodi UI.
- `scenes/Mangler.tscn`: corpo fisico, sprite, hitbox, hurtbox e componente combat.
- `scenes/stages/DefaultStage.tscn`: sfondo ed effetti ambientali.
- `scripts/Fighter.gd`: contratto neutrale condiviso per stato, segnali, collisioni e componenti dei fighter.
- `scripts/Mangler.gd`: input, movimento, orientamento e transizioni di stato.
- `scripts/AttackData.gd`: schema di danno, timing, stun e hitbox di un attacco.
- `scripts/AttackVariantData.gd`: frame data, animazione e hitbox delle varianti contestuali.
- `data/attacks/*.tres`: sei risorse di attacco modificabili dall'Inspector.
- `scripts/FighterCombat.gd`: esecuzione degli attacchi, danno, guardia, reazioni e KO.
- `scripts/ManglerAnimationSetup.gd`: punto di ingresso compatibile per inizializzare le animazioni di Mangler.
- `scripts/ManglerAnimationCatalog.gd`: catalogo dedicato allo slicing degli atlas e ai frame runtime di Mangler.
- `scripts/AriannaAnimationCatalog.gd`: catalogo dedicato allo slicing degli atlas e ai frame runtime di Arianna.
- `scripts/ManglerVisualConfig.gd`: profili degli effetti di movimento e afterimage.
- `scripts/FighterInputBuffer.gd`: cronologia input, direzioni relative e riconoscimento sequenze.
- `scripts/CharacterData.gd`: statistiche e configurazione del personaggio.
- `scripts/MainArena.gd`: ciclo del training, camera, countdown, KO e reset.
- `scripts/ArenaUI.gd`: barre vita, timer e messaggi.
- `scripts/FighterDebugOverlay.gd`: visualizzazione di corpo, hitbox e hurtbox.
- `scripts/StageAmbientEffects.gd`: effetti ambientali dello stage.
- `tests/smoke_tests.gd`: fixture e scenari condivisi delle suite headless.
- `tests/test_input.gd`, `test_arianna.gd`, `test_mangler.gd`, `test_combat.gd`, `test_arena.gd`: entry point indipendenti per area funzionale.
- `tests/run_smoke_tests.cmd`: esegue tutte le suite in processi separati e aggrega l'esito.

## Stati del fighter

- `IDLE`
- `WALKING`
- `JUMPING`
- `CROUCHING`
- `ATTACKING`
- `BLOCKING`
- `HIT`
- `KNOCKED_DOWN`

Le transizioni sono centralizzate in `Mangler.change_state()`. Le coroutine di attacco e reazione vengono invalidate durante hit, KO e reset per evitare completamenti tardivi.

## Collisioni

| Layer | Utilizzo |
|---:|---|
| 1 | Terreno |
| 2 | Hitbox offensive |
| 4 | Hurtbox vulnerabili |
| 8 | Corpo fisico dei fighter |

In aria il corpo del fighter attraversa l'altro fighter, continuando però a collidere con il terreno.

## Parametri attuali

| Attacco | Danno | Startup | Active | Recovery | Totale |
|---|---:|---:|---:|---:|---:|
| Pugno leggero | 5 | 11f | 3f | 3f | 17f / 48 FPS |
| Pugno medio | 10 | 17f | 6f | 19f | 42f / 48 FPS |
| Pugno pesante | 15 | 38f | 4f | 28f | 70f / 48 FPS |
| Calcio leggero | 8 | 14f | 3f | 14f | 31f / 48 FPS |
| Calcio medio | 12 | 26f | 2f | 5f | 33f / 48 FPS |
| Calcio pesante | 20 | 24f | 4f | 5f | 33f / 48 FPS |

- Vita massima: 100 HP.
- Velocità a terra: 200 px/s.
- Velocità aerea: 280 px/s.
- Velocità iniziale del salto: -850 px/s.
- Gravità: 1400 px/s².
- Guardia riuscita: 0 danni.
- Hit-stun: 0,30 s.
- Reazione di blocco: 0,15 s.

La tabella descrive le varianti in piedi. Ogni `AttackData` contiene risorse `AttackVariantData`; `FRAME_DATA.md` documenta tutte le varianti.

## Asset dei personaggi

Gli sprite in `assets/sprites/characters/` sono PNG RGBA 512×512. La scena condivisa `Mangler.tscn` usa una scala di `0.7`, equivalente alla precedente resa visiva degli asset 1024×1024 scalati a `0.35`.

Sono presenti asset per Arianna, Bue, Mangler, Mileto, Peirolo e Torpe. Nell'arena Arianna occupa Player 1 con il solo idle, mentre Mangler occupa Player 2 con il moveset completo.

## Limiti noti e prossime priorità

- Il progetto offre training locale, non ancora round completi o best-of-three.
- Mangler dispone di animazioni per locomozione, guardia, reazioni, KO e attacchi; alcune aspettative della suite devono ancora essere riallineate agli atlas correnti.
- Il pugno leggero aereo usa i fotogrammi sorgente 6–20, mantiene il 20 e la hitbox mentre il tasto resta premuto, quindi recupera con 24–6 al rilascio.
- `CharacterData` usa ancora un profilo personaggio creato in memoria, anche se gli attacchi sono risorse `.tres` dedicate.
- La speciale `720 Punch` di Mangler si esegue premendo pugno leggero e pugno medio insieme; durante la rotazione permette un lento movimento avanti/indietro.
- Il `Sonic Boom` si esegue con `↓ ↘ → + pugno leggero, medio o pesante`: al frame 23 genera i piatti animati a 48 FPS con scia gialla e scintille. Il proiettile diventa progressivamente più veloce passando dal pugno leggero al medio e al pesante.
- La presa si esegue a terra con `pugno leggero + calcio leggero`: `grab_tentative` viene saltato e, se l'avversario è nella portata immediata, parte direttamente lo sprite unico `Mangler2-headbut_mangler_mangler.png`.
- La presa diretta usa i frame sorgente 1–29 a 48 FPS, è spostata di 80 px in avanti e genera al frame 19 la stessa esplosione rossa del light punch; sprite e ombra della vittima vengono nascosti durante la sequenza. Dopo il frame 29 entrambi i personaggi avanzano di 15 px nella direzione della testata e tornano in `IDLE`.
- La supermossa si esegue con `← ↙ ↓ ↘ → + calcio leggero + calcio medio`: tutti e quattro gli sprite sono riprodotti a 48 FPS. `super_start.png` genera al frame 19 un'aura esplosiva gialla; `rotate-super_run.png` e `run_only.png` avvicinano rapidamente Mangler all'avversario a 480 px/s lasciando una scia. Al contatto viene sottratto una sola volta il 25% della vita massima, poi `drum_roll_only.png` viene eseguito due volte con esplosioni rosse sul volto; per tutta questa fase il bersaglio ripete a 48 FPS i fotogrammi 4–13 di `hurt-high.png`. Alla fine il bersaglio cade con i frame 11–25 di `ko.png` a 24 FPS, quindi esegue `knockdown_recovery.png` e torna in `IDLE`; un danno letale conserva invece il vero KO. L'attaccante resta davanti all'avversario nello z-order; prima del contatto l'avversario congelato continua a riprodurre `IDLE`, oppure mantiene la parata alta se stava già parando.
- Quarto e mezzaluna hanno una tolleranza maggiore: rispettivamente 36 e 48 frame, con 10 frame per associare il pulsante finale. I passaggi diagonali saltati da uno stick analogico rapido vengono ricostruiti dal buffer.
- Durante qualsiasi attacco il fighter attivo viene portato a uno `z_index` superiore a quello dell'avversario, indipendentemente dal numero del giocatore; al termine o all'interruzione della mossa viene ripristinato il suo ordine grafico normale.
- Arianna dispone di una scena autonoma, `scenes/Arianna.tscn`: `basic-moves/idle.png` usa 24 frame a 24 FPS in loop. `basic-moves/01-walk.png` usa 48 frame a 24 FPS: in ordine normale per avanzare e in ordine inverso per arretrare, sempre mantenendo il busto rivolto verso l'avversario. Entrambe le direzioni muovono fisicamente il personaggio e tornano in idle al rilascio. Il pugno leggero usa a 48 FPS i frame 1–9 di `light-punch/light-punch.png`, poi torna da 9 a 1 e rientra in idle; la hitbox alta da 160×50 px segue il braccio disteso ed è attiva sui frame 7–9.
- Il salto neutro di Arianna usa tutti i 49 frame della griglia 7×7 di `basic-moves/custom_jump.png`, senza loop e senza fotogrammi congelati. FPS e stacco sono configurabili indipendentemente in `scripts/Arianna.gd` tramite `ARIANNA_JUMP_FPS` e `ARIANNA_JUMP_TAKEOFF_FRAME`. Lo stacco è zero-based: al valore configurato va aggiunto 1 per ottenere il fotogramma visibile. Torna in idle esclusivamente al contatto col suolo.
- Il light punch in salto usa la parte finale della griglia 7×3 di `light-punch/jump_light_punch.png` a 48 FPS: esegue i frame sorgente 14→19, mantiene il frame 19 per sette intervalli complessivi e torna 18→14. Poiché il soggetto nel foglio è rasterizzato più grande del salto, usa una scala dedicata `0.78` e ripristina `0.85` al termine. La hitbox light è attiva durante il mantenimento. Finita la recovery in aria riprende `custom_jump` dal frame visibile 32; al suolo passa immediatamente in idle.
- Il medium punch in salto usa `medium-punch/jump_medium_punch.png` a 48 FPS: avanza dal fotogramma sorgente 5 al 25, quindi torna 23→21→19→…→7 saltando un fotogramma ogni due. Usa una scala dedicata `0.78`; conclusa la recovery in aria, Arianna riprende `custom_jump` dal fotogramma visibile 29, mentre al suolo torna direttamente in idle.
- Lo strong punch in salto usa tutti i 27 fotogrammi di `strong-punch/strong_jump_punch.png` a 48 FPS e scala `0.78`. Il doppio pugno attiva una hitbox high inclinata verso il basso; finita la mossa in aria, Arianna riprende `custom_jump` dal fotogramma visibile 40, mentre al suolo torna direttamente in idle.
- Il light kick in salto usa `light-kick/light_kick_jump.png` a 48 FPS: esegue i 15 fotogrammi in avanti, poi torna da 14 a 1. La hitbox MID resta attiva dai fotogrammi visibili 9 a 15 e genera `hurt_mid` o `block_mid`; conclusa la recovery in aria, Arianna riprende `custom_jump` dal fotogramma visibile 40, mentre al suolo torna direttamente in idle.
- Durante il salto la pushbox fisica di Arianna viene ridotta verticalmente a 120×90 px e collide soltanto con il terreno: può quindi oltrepassare l'avversario e non può restare sospesa sulla sua collisione. Il light punch terrestre viene scartato in aria; il futuro light punch aereo sarà una mossa separata.
- La collisione aerea è centrata a `(0, -45)`: il suo bordo inferiore coincide con quello della collisione standing. Il cambio di profilo allo stacco e all'atterraggio non sposta quindi verticalmente l'origine dello sprite.
- Il facing di Arianna resta bloccato per tutta la sequenza del salto neutro. Viene specchiato soltanto dopo l'ultimo frame e solo se nel frattempo Arianna ha oltrepassato il centro dell'avversario.
- La corsa di Arianna si attiva con un doppio tap avanti entro 15 frame e usa i primi 48 frame di `basic-moves/run.png` in loop a 24 FPS. Continua a velocità doppia (`run_speed × 2`) anche dopo il rilascio e termina in idle soltanto quando incontra la collisione dell'avversario o un limite dello stage.
- Il doppio tap indietro entro 15 frame avvia il back jump leggero: `basic-moves/back-jump.png` usa i frame sorgente 28→49 della griglia 7×7 a 48 FPS. Un timer Godot indipendente dagli FPS interpola 50 px all'indietro in circa 1 secondo, senza spostamento verticale. Terminato il frame 49 passa immediatamente all'animazione idle, che continua mentre si completa l'eventuale tempo residuo dello spostamento.
- Tenendo premuto giù, Arianna esegue i 19 frame di `basic-moves/crouched.png` a 48 FPS e mantiene la posa finale. Al rilascio riproduce una recovery dedicata dai frame sorgente 18→1, quindi torna in idle; pushbox e hurtbox seguono progressivamente l'altezza della posa.
- Tenere indietro a terra, da solo, fa arretrare Arianna senza mostrare la guardia. `basic-moves/guard_high.png` si attiva soltanto quando l'avversario sta attaccando: esegue 16 frame a 48 FPS e mantiene il frame 16 finché l'attacco resta attivo. Al rilascio di indietro o alla fine dell'attacco riproduce i frame sorgente 15→1 a ritroso e torna in idle; un secondo tap indietro conserva la priorità e avvia il back jump.
- Contro un attacco di altezza `MID`, Arianna seleziona `basic-moves/guard_middle.png`: frame 1→13 a 48 FPS, mantenimento del frame 13 durante l'attacco e recovery 12→1 al rilascio o alla fine dell'offensiva, quindi idle. Gli attacchi `HIGH` continuano a usare `guard_high.png`.
- Con giù + indietro contro un attacco `LOW`, Arianna usa `basic-moves/guard_low.png`: frame 1→16 a 48 FPS, mantenimento del frame 16 e recovery 15→1 al rilascio o alla fine dell'attacco. Senza un attacco basso attivo, giù continua ad avviare il normale crouch.
- Giù + pugno leggero usa `light-punch/ligth-punch-low.png`: frame 1→15 e recovery 14→1, tutto a 48 FPS. L'hitbox segue il braccio sui frame visibili 12–15 e verifica esplicitamente le sovrapposizioni al successivo tick fisico, garantendo un singolo impatto; il colpo ha altezza `MID`, quindi genera `hurt_mid` se entra e `block_mid` se viene parato. Terminata la recovery, mantenendo giù Arianna resta direttamente sulla posa finale di crouch; torna in idle soltanto se giù è stato rilasciato.
- Il pugno medio in piedi usa `medium-punch/medium-punch.png`: frame 1→25 e recovery 24→1 a 48 FPS. La hitbox alta segue il braccio sui frame visibili 21–25 e infligge i 10 danni del medium punch, generando `hurt_high` sul colpo oppure `block_high` se parato.
- Giù + pugno medio usa `medium-punch/medium-punch-low.png`: frame 1→12 e recovery 11→4 a 24 FPS. Sui frame visibili 10–12 la hitbox segue il braccio disteso e il profilo di scia è quello delle strong move; il colpo è `MID`, quindi genera `hurt_mid` oppure `block_mid`. Se giù resta premuto, la recovery termina direttamente sulla posa accovacciata.
- Il pugno forte di Arianna usa tutti i 49 frame della griglia 7×7 di `strong-punch/strong-punch.png`, una volta a 48 FPS, quindi torna in idle. La hitbox alta è attiva sui frame visibili 23–28 e genera `hurt_high` oppure `block_high`; durante il caricamento e il colpo usa lo stesso profilo di scia Godot delle mosse forti di Mangler.
- Giù + pugno forte usa `strong-punch/strong-punch-crouched.png` a 48 FPS, saltando i frame sorgente 22–35: la sequenza risultante riproduce 1→21 e poi 36→49. Hitbox e scia strong sono attive durante il doppio pugno (posizioni animazione 8–21); il colpo è `HIGH`, quindi genera `hurt_high` o `block_high`. Mantenendo giù, alla fine torna direttamente alla crouch pose.
- L'esplosione rossa del light punch viene generata soltanto su un colpo realmente entrato: se il bersaglio sta parando correttamente, resta visibile solo la reazione di guardia senza effetto rosso.
- Il calcio leggero in piedi di Arianna usa i frame sorgente 11→23 e torna 22→11 a 48 FPS prima dell'idle. La hitbox segue la gamba distesa e il colpo è medio: `hurt_mid` se entra, `block_mid` se viene parato.
- Con giù + calcio leggero Arianna usa il nuovo `light_kick_low.png` 7×7: frame 1→21 e ritorno 20→1 a 60 FPS. Il colpo è basso (`hurt_low`/`block_low`) e mantenendo giù termina nella crouch pose.
- Il calcio medio in piedi usa `medium_kick.png`, sorgenti 8→28 e ritorno 27→8 a 48 FPS. La hitbox segue la gamba alta e genera `hurt_mid` oppure `block_mid`.
- In salto il calcio medio usa `medium_kick_jump.png`: esegue i 35 fotogrammi e recupera da 34 a 22 a 60 FPS; la hitbox è attiva dal fotogramma runtime 28 fino alla fine e genera `hurt_high` o `block_high`. Poi riprende `custom_jump` dal fotogramma visibile 30 (oppure torna in idle se Arianna è già atterrata).
- Lo strong kick in salto usa tutti i 30 fotogrammi di `strong_kick_jump_2.png` a 48 FPS, senza ritorno inverso; quindi riprende `custom_jump` dal fotogramma visibile 35 oppure torna in idle se Arianna è già a terra.
- La speciale baseball di Arianna si esegue con `DOWN → DOWN_FORWARD → FORWARD + punch` e accetta tutti e tre i pugni. L'animazione usa 49 frame a 48 FPS e genera il tornado al frame visibile 24. La variante light viaggia a 420 px/s e infligge 10 danni; medium viaggia a 560 px/s, infligge 14 danni e usa effetti 1,35×; heavy viaggia a 700 px/s, infligge 18 danni e usa effetti 1,70×. Tutte generano `hurt_medium`, esplodono in azzurro sulla pancia e scompaiono al primo contatto.
- La reazione `hurt_medium` di Arianna usa i primi 8 fotogrammi di `basic-moves/hurt_medium.png`: li esegue 1→8 e poi torna 7→1 a 48 FPS, con rinculo orizzontale Godot ridotto al 45%, prima di rientrare in idle.
- La reazione `hurt_high` di Arianna usa i primi 7 fotogrammi di `basic-moves/hurt_high.png` a 24 FPS e poi torna in idle. `hurt_low` mantiene temporaneamente la posa Arianna dedicata, senza riutilizzare sprite di Mangler.
- Ogni reazione `hurt_medium` o `hurt_low`, per qualsiasi fighter, genera un'esplosione azzurra con 64 scintille: sullo stomaco per `hurt_medium`, sulle gambe per `hurt_low`.
- Con giù + calcio medio Arianna usa `medium_kick_low.png`, sorgenti 8→21 e ritorno 20→8 a 48 FPS. Genera `hurt_low` o `block_low` e mantenendo giù torna alla crouch pose.
- Lo strong kick di Arianna usa `strong_kick.png` a 48 FPS, omettendo i sorgente 13–24 e 44–52; i 43 frame rimanenti vengono riprodotti una volta con l'effetto movimento/afterimage delle mosse potenti e poi la mossa torna in idle.
- Il follow-up con la vecchia testata separata resta configurato, ma non viene avviato automaticamente durante questa anteprima.
- Anche la testata usa livelli sincronizzati: `testata-rear.png` dietro alla vittima e `testata-front.png` davanti.
- Durante l'affondo della testata, i livelli `rear` e `front` generano una breve scia dorata sincronizzata.
- Al contatto della testata compare un'esplosione giallo-arancio compatta sul volto della vittima.
- La vittima riproduce `grabbed.png` a 24 FPS nella sequenza sorgente 10→25→10; quando riceve la testata passa immediatamente a `hurt_high`.
- Un personaggio colpito mentre è in salto riproduce `hurted_in_jump` a 24 FPS, mantiene il frame 25 a terra per un secondo e poi esegue `knockdown_recovery`.
- Non sono ancora presenti IA, audio, menu, selezione personaggio o multiplayer online.
- `original_images/` conserva materiale sorgente e non fa parte del flusso runtime.

Per il dettaglio dei timing consultare `FRAME_DATA.md`; per il futuro collegamento delle animazioni consultare `TUTORIAL_ANIMAZIONI.md`.

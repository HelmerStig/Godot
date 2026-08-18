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
godot --headless --path . --script res://tests/smoke_tests.gd
```

La suite verifica oltre 200 condizioni relative ad animazioni, `AttackData`, `AttackVariantData`, input buffer, combattimento, UI, KO e reset. Il successo è indicato da `SMOKE_TESTS_OK`.

> Baseline del 10 agosto 2026: il progetto viene caricato senza errori di parsing, ma restano 25 asserzioni non allineate alle animazioni correnti. Non considerare verde il runner finché il log contiene `SMOKE_TESTS_FAILED`.

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
- `scripts/Mangler.gd`: input, movimento, orientamento e transizioni di stato.
- `scripts/AttackData.gd`: schema di danno, timing, stun e hitbox di un attacco.
- `scripts/AttackVariantData.gd`: frame data, animazione e hitbox delle varianti contestuali.
- `data/attacks/*.tres`: sei risorse di attacco modificabili dall'Inspector.
- `scripts/FighterCombat.gd`: esecuzione degli attacchi, danno, guardia, reazioni e KO.
- `scripts/ManglerAnimationSetup.gd`: punto unico di registrazione delle animazioni runtime.
- `scripts/ManglerVisualConfig.gd`: profili degli effetti di movimento e afterimage.
- `scripts/FighterInputBuffer.gd`: cronologia input, direzioni relative e riconoscimento sequenze.
- `scripts/CharacterData.gd`: statistiche e configurazione del personaggio.
- `scripts/MainArena.gd`: ciclo del training, camera, countdown, KO e reset.
- `scripts/ArenaUI.gd`: barre vita, timer e messaggi.
- `scripts/FighterDebugOverlay.gd`: visualizzazione di corpo, hitbox e hurtbox.
- `scripts/StageAmbientEffects.gd`: effetti ambientali dello stage.
- `tests/smoke_tests.gd`: suite headless senza addon esterni.

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
- Il salto di Arianna usa tutti i 64 frame della griglia 8×8 di `basic-moves/jump.png` a 48 FPS, senza loop. Lo stacco fisico avviene al frame 6, può conservare la direzione scelta a terra e torna in idle all'atterraggio.
- Durante il salto la pushbox fisica di Arianna viene ridotta verticalmente a 120×90 px e collide soltanto con il terreno: può quindi oltrepassare l'avversario e non può restare sospesa sulla sua collisione. Il light punch terrestre viene scartato in aria; il futuro light punch aereo sarà una mossa separata.
- Il facing di Arianna resta bloccato per tutta la rotazione del salto. Viene specchiato soltanto dopo il completamento della capriola e solo se nel frattempo Arianna ha oltrepassato il centro dell'avversario.
- La corsa di Arianna si attiva con un doppio tap avanti entro 15 frame e usa i primi 48 frame di `basic-moves/run.png` in loop a 24 FPS. Continua a velocità doppia (`run_speed × 2`) anche dopo il rilascio e termina in idle soltanto quando incontra la collisione dell'avversario o un limite dello stage.
- Il doppio tap indietro entro 15 frame avvia il back jump leggero: `basic-moves/back-jump.png` usa i frame sorgente 28→49 della griglia 7×7 a 48 FPS. Un timer Godot indipendente dagli FPS interpola 50 px all'indietro in circa 1 secondo, senza spostamento verticale. Terminato il frame 49 passa immediatamente all'animazione idle, che continua mentre si completa l'eventuale tempo residuo dello spostamento.
- Tenendo premuto giù, Arianna esegue i 19 frame di `basic-moves/crouched.png` a 48 FPS e mantiene la posa finale. Al rilascio riproduce una recovery dedicata dai frame sorgente 18→1, quindi torna in idle; pushbox e hurtbox seguono progressivamente l'altezza della posa.
- Il follow-up con la vecchia testata separata resta configurato, ma non viene avviato automaticamente durante questa anteprima.
- Anche la testata usa livelli sincronizzati: `testata-rear.png` dietro alla vittima e `testata-front.png` davanti.
- Durante l'affondo della testata, i livelli `rear` e `front` generano una breve scia dorata sincronizzata.
- Al contatto della testata compare un'esplosione giallo-arancio compatta sul volto della vittima.
- La vittima riproduce `grabbed.png` a 24 FPS nella sequenza sorgente 10→25→10; quando riceve la testata passa immediatamente a `hurt_high`.
- Un personaggio colpito mentre è in salto riproduce `hurted_in_jump` a 24 FPS, mantiene il frame 25 a terra per un secondo e poi esegue `knockdown_recovery`.
- Non sono ancora presenti IA, audio, menu, selezione personaggio o multiplayer online.
- `original_images/` conserva materiale sorgente e non fa parte del flusso runtime.

Per il dettaglio dei timing consultare `FRAME_DATA.md`; per il futuro collegamento delle animazioni consultare `TUTORIAL_ANIMAZIONI.md`.

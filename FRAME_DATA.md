# Sanmo — frame data

Verifica delle risorse: 15 settembre 2026. Special 1 di Oscare aggiornata il 19 ottobre 2026.

## Oscare: Special 1 — sigaretta

Controller: `scripts/Oscare.gd`; proiettile: `scripts/OscareCigaretteProjectile.gd`.

| Parte | Frame | FPS | AutoSprite sheet ID |
|---|---:|---:|---|
| Special 1 - Light Cigarette | 20 | 60 | cmvf44j5e006a10h5cywi9i25 |
| Special 1 - Cigarette Flick - Smoking Hand v2 | 29 | 60 | cmvf4pva6000k3p27mmhm83pe |
| Proiettile siga (ciclo) | 25 | 60 | cmvf4om5y0071g6zj2ig2xwbv |

Le due parti del fighter usano 7 colonne di celle 512×512; il proiettile usa 5 colonne. Al frame visivo 19 della seconda parte nasce un solo proiettile dalla mano, nella direzione fissata all'avvio. Lo stesso frame contiene una sigaretta disegnata in volo: il runtime riusa la posa pulita del frame 20 al suo posto, conservando 29 frame di durata e i PNG originali. La sequenza totale dura 49/60 s, poi torna in idle. Nessuna hitbox corpo a corpo durante la preparazione.

Al frame visivo 6 dell'accensione parte `assets/sounds/sfx/siga-accensione.wav`, una sola volta per esecuzione. Il suono completa la propria coda dopo la recovery naturale; interruzione e reset lo fermano.

Un impatto riuscito o KO riproduce `assets/sounds/sfx/crepitio.wav` una volta. Parata, contatto ignorato e colpo a vuoto restano silenziosi. Il player appartiene all'arena per completare il suono dopo la rimozione del proiettile; viene liberato alla fine della clip o al reset del proprietario.

Comando: giù → giù-avanti → avanti + pugno. Finestra 36 tick (600 ms), buffer pulsante 10 tick, diagonale finale accettata; il buffer esistente ricostruisce la diagonale durante un passaggio giù → avanti tra due tick. Funziona anche durante il rialzarsi; non in aria, hitstun o guardia.

Velocità LP/MP/SP: 520/720/920 px/s. Danno iniziale invariato fra le versioni: 10. Durata massima proiettile: 3 s; collisione continua 26×10, con esclusione del proprietario e del fumo. Un solo impatto; hurt_high/parata media sul bersaglio in piedi, hurt accovacciato/parata bassa sul bersaglio in basso se intercettato. La reazione del proiettile resta indipendente da altre mosse iniziate nel frattempo dal proprietario. Conserva reazioni aeree e KO del combattimento condiviso. L'interruzione prima del rilascio annulla il lancio; il reset elimina i proiettili del proprietario.

## Timing dichiarati nelle risorse

Questa tabella riporta le varianti contenute negli otto file `data/attacks/*.tres`, con i valori predefiniti di `AttackVariantData` quando un campo non è scritto nel file. I frame sono misurati agli FPS della variante, non ai tick fisici. **Sono timing dichiarati, non necessariamente la durata finale della mossa a runtime**: mantenimenti, concatenazioni e animazioni possono prolungarli.

Il danno è quello base della risorsa. Il codice può suddividerlo in più impatti o applicarlo tramite un proiettile. Le varianti runtime di Arianna sono descritte nella sezione successiva.

| Risorsa | Variante | Animazione | FPS | Startup | Active | Recovery | Totale | Danno base | Altezza dichiarata | Knockdown |
|---|---|---|---:|---:|---:|---:|---:|---:|---|---|
| `light_punch` | `standing` | `light_punch_single` | 48 | 11 | 3 | 3 | 17 | 5 | HIGH | no |
| `light_punch` | `crouched` | `crouched_punch` | 48 | 10 | 3 | 5 | 18 | 5 | MID | no |
| `light_punch` | `crouched_held` | `crouched_punch_crouched` | 48 | 4 | 3 | 5 | 12 | 5 | MID | no |
| `light_punch` | `airborne` | `jump_light_punch` | 48 | 14 | 1 | 19 | 34 | 5 | HIGH | no |
| `medium_punch` | `standing` | `medium_open_hand_slap` | 48 | 17 | 6 | 19 | 42 | 10 | HIGH | no |
| `medium_punch` | `crouched` | `crouched_medium_punch` | 48 | 11 | 4 | 5 | 20 | 10 | MID | no |
| `medium_punch` | `crouched_held` | `crouched_medium_punch_crouched` | 48 | 7 | 4 | 5 | 16 | 10 | MID | no |
| `medium_punch` | `airborne` | `jump_medium_punch` | 48 | 12 | 3 | 19 | 34 | 10 | HIGH | no |
| `heavy_punch` | `standing` | `heavy_punch` | 48 | 38 | 4 | 28 | 70 | 15 | MID | no |
| `heavy_punch` | `crouched` | `crouched_power_punch` | 48 | 8 | 6 | 5 | 19 | 15 | HIGH | no |
| `heavy_punch` | `airborne` | `jump_heavy_punch` | 48 | 8 | 4 | 4 | 16 | 15 | HIGH | no |
| `light_kick` | `standing` | `light_kick` | 48 | 14 | 3 | 14 | 31 | 8 | LOW | no |
| `light_kick` | `crouched` | `crouched_light_kick` | 48 | 13 | 3 | 15 | 31 | 8 | LOW | no |
| `light_kick` | `airborne` | `jump_light_kick` | 48 | 15 | 5 | 19 | 39 | 8 | HIGH | no |
| `medium_kick` | `standing` | `medium_kick` | 48 | 26 | 2 | 5 | 33 | 12 | LOW | no |
| `medium_kick` | `crouched` | `crouched_medium_kick` | 48 | 22 | 3 | 24 | 49 | 12 | MID | no |
| `medium_kick` | `airborne` | `jump_medium_kick` | 48 | 15 | 5 | 19 | 39 | 12 | HIGH | no |
| `heavy_kick` | `standing` | `heavy_kick` | 48 | 24 | 4 | 5 | 33 | 20 | HIGH | no |
| `heavy_kick` | `crouched` | `crouched_heavy_kick` | 48 | 22 | 7 | 20 | 49 | 20 | LOW | sì |
| `heavy_kick` | `airborne` | `jump_heavy_kick` | 48 | 15 | 5 | 19 | 39 | 20 | HIGH | no |
| `special_720_punch` | `standing` | `special_720_punch` | 48 | 9 | 34 | 6 | 49 | 6 | HIGH | no |
| `special_sonic_boom` | `standing` | `special_sonic_boom` | 48 | 24 | 1 | 24 | 49 | 0 | HIGH | no |

## Differenze introdotte dal runtime

- `FighterCombat.try_attack()` usa i timing della variante e può attendere la conclusione dell'animazione. Per alcuni attacchi aerei mantiene una posa mentre il pulsante è premuto e interrompe la mossa all'atterraggio: non usare la somma della tabella come durata fissa di questi casi.
- Il calcio medio in piedi di Mangler divide i 12 danni in due impatti da 6: il primo HIGH, il secondo MID. L'altezza LOW della risorsa è quindi un dato di configurazione, non l'altezza effettiva di entrambi gli impatti.
- 720 Punch esegue tre impulsi da 6 danni. Sonic Boom ha danno di lancio zero: il proiettile gestisce il proprio impatto.
- Il pugno forte accovacciato di Mangler applica il lancio solo a un bersaglio colpito e non in KO; parata e invulnerabilità lo impediscono.
- LOW richiede giù + indietro per la parata; HIGH e MID accettano indietro anche da accovacciati. `HitHeight` descrive anche l'animazione di reazione e non introduce una categoria separata di overhead.

## Arianna

Le sequenze sono costruite in `scripts/AriannaAnimationCatalog.gd`. I frame attivi e le geometrie sono definiti in `scripts/Arianna.gd`; le varianti create a runtime usano identificatori come `arianna_standing`, `arianna_low` e `arianna_airborne`. I fotogrammi visibili sono numerati da 1, mentre le costanti del controller sono zero-based.

| Animazione | Sequenza / durata visiva | FPS |
|---|---|---:|
| `idle` | Primi 24 frame, loop | 24 |
| `walk` / `backwalk` | 48 frame in avanti / a ritroso | 24 |
| `run` | 48 frame, loop fino a collisione | 24 |
| `jump` | 49 frame, stacco al frame visibile 10 | 32 |
| `arianna_back_jump` | Sorgenti 28→49; spostamento di 50 px in 1 s | 48 |
| `crouch` / recovery | 1→19, mantiene 19; rilascio 18→1 | 48 |
| `arianna_light_punch` / recovery | 1→9, poi 9→1 | 48 |
| `arianna_medium_punch` / recovery | 1→25, poi 24→1 | 48 |
| `arianna_strong_punch` | 49 frame | 48 |
| `arianna_strong_kick` | 36 frame; attiva sui frame visibili 15–21, HIGH | 32 |
| `arianna_low_strong_kick` | 49 frame, LOW e knockdown | 48 |
| `hurt_mid` | 1→8, poi 7→1: 15 frame | 48 |
| `hurt_high` | 1→7, poi il primo frame: 8 frame | 24 |
| `hurt_low` | 1→6, poi il primo frame: 7 frame | 24 |

La tabella è un riferimento per le sequenze principali, non un elenco completo delle mosse. Il catalogo contiene anche gli attacchi bassi e aerei, LP-MP-MK, baseball/tornado, fischio/Bateau e la super con i gatti. I test in `tests/cases/arianna_moveset.gd` verificano gli atlas e il comportamento di queste sequenze.

## Fighter con idle e camminata

Questi personaggi usano temporaneamente `IdleRosterFighter`. Gli idle hanno celle da 512×512, 8 colonne e loop a 18 FPS. Ogni `walk-spritesheet.png` usa 49 frame in una griglia 7×7 da 512×512: `walk` avanza a 24 FPS e `backwalk` riproduce gli stessi frame al contrario a 24 FPS. La velocità di spostamento predefinita è 200 px/s.

| Personaggio | Spritesheet idle | Frame idle | Frame walk |
|---|---|---:|---:|
| Bue | `bue/idle-spritesheet.png` | 63 | 49 |
| Mileto | `mileto/idle-spritesheet.png` | 63 | 49 |
| Oscare | `oscare/idle-spritesheet.png` | 63 | 49 |
| Peirò | `peirolo/idle_spritesheet.png` | 63 | 49 |
| Torpe | `torpe/idle-spritesheet.png` | 61 | 49 |

## Medium kick in piedi del roster

Frame visivi 1-based, sequenza soltanto avanti a 48 FPS (60 FPS per Mileto), senza loop. Hitbox e danno vengono gestiti dalla variante `roster_standing_medium_kick`; il recupero termina in idle.

| Personaggio | Frame totali | Startup | Frame attivi visivi | Active | Recovery |
|---|---:|---:|---|---:|---:|
| Oscare | 33 | 17 | 18-20 | 3 | 13 |
| Mileto | 38 | 17 | 18-20 | 3 | 18 |
| Torpe | 23 | 13 | 14-16 | 3 | 7 |
| Peirolo | 24 | 13 | 14-16 | 3 | 8 |
| Bue | 22 | 8 | 9-11 | 3 | 11 |

Fonte AutoSprite: `Light kick` per Oscare e Mileto, `Medium kick` per gli altri. Oscare usa i primi 33 dei 34 frame disponibili. Un singolo impatto da 12 danni seleziona hurt medio/parata media in piedi e hurt accovacciato/parata bassa da accovacciati.

## Movimento

`CharacterData` predefinito: 100 HP, camminata 200 px/s, corsa 320 px/s, velocità aerea 280 px/s e impulso salto -850 px/s. I controller applicano modificatori: Mangler moltiplica l'impulso del salto per 1,5 e usa gravità 3150 px/s²; Arianna usa gravità 1800 px/s² e corsa a `run_speed × 2`. Scala e offset degli sprite dipendono dall'animazione.

## Verifica

Baseline corrente: 709 asserzioni superate nelle cinque suite headless (input 14, Arianna 218, Mangler 359, combat 83, arena 35); vedere [tests/README.md](tests/README.md). Le vecchie tabelle che mescolavano timing dichiarati, pose mantenute e dati non più aggiornati sono conservate in [archivio](docs/archive/FRAME_DATA.md).

## Calcio forte in piedi del roster (14 ottobre 2026)

`heavy_kick` avvia `strong_kick`: solo avanti a 48 FPS, senza loop o reverse, poi idle. Frame visivi 1-based, estremi inclusi. Si riproducono i primi N frame del foglio AutoSprite 7x7; i PNG e atlas originali conservano tutti i 49 frame.

| Fighter | Frame | Attivi | Startup / Active / Recovery | AutoSprite | Spritesheet ID |
|---|---:|---|---|---|---|
| Oscare | 48 | 16-21 | 15 / 6 / 27 | Strong Kick v3 - Chest Facing Camera | cmv7tsx2200c111efd1z6ojp5 |
| Mileto | 48 | 16-21 | 15 / 6 / 27 | Strong Kick - Spinning High Kick | cmv7u79al001t5kpzv3mwl62y |
| Torpe | 37 | 13-18 | 12 / 6 / 19 | Strong Kick v3 - Chest Facing Camera | cmv7uibu00041dr60ygpk4mx9 |
| Peirolo | 43 | 14-18 | 13 / 5 / 25 | Strong Kick - Spinning High Kick | cmv7uimby0045dr60cuksy2aa |
| Bue | 27 | 11-14 | 10 / 4 / 13 | Strong Kick | cmv7uihws0012qmjlo56st6zh |

Altezza HIGH, danno base 20, nessun knockdown. Sul bersaglio eretto: `hurt_high` se colpito, `block_high` se parato. Un solo impatto per esecuzione. Suoni condivisi con Arianna: `kick_long_whoosh_19.wav` alla partenza e `body_hit_large_76.wav` soltanto su HIT/KO. La hitbox alta segue l'orientamento del fighter; cancellazione e reset la disattivano.

Test dedicato: `godot --headless --path . --script res://tests/test_strong_kick.gd`.

## Pugno leggero in salto del roster (14 ottobre 2026)

Fonte AutoSprite: **Jump Light Punch v3 - Diagonal Down**. Sequenza solo avanti a 24 FPS, senza loop o reverse. Frame visivi 1-based, estremi inclusi.

| Fighter | Frame | Attivi | Startup / Active / Recovery | Spritesheet ID |
|---|---:|---|---|---|
| Oscare | 10 | 4-6 | 3 / 3 / 4 | cmv7xq1o00007kiv2y07cxhdd |
| Mileto | 13 | 6-8 | 5 / 3 / 5 | cmv7xti3j00anmm2ltf80pgmt |
| Torpe | 13 | 4-7 | 3 / 4 / 6 | cmv7xw5x200clmm2ltk9v9sr8 |
| Peirolo | 13 | 6-9 | 5 / 4 / 4 | cmv7xxxpc00f8mm2ld7op0a6z |
| Bue | 10 | 4-6 | 3 / 3 / 4 | cmv7xnq1c004i2sp1ccs3xl9k |

I fogli hanno celle 512x512 e 5 colonne. Per Bue si riproducono i primi 10 dei 24 frame disponibili; gli altri fogli sono le esportazioni accorciate. La posa aerea ferma usa il primo frame trasparente della mossa, corrispondente alla Jump Pose.

Input light punch durante JUMPING, una mossa per salto, con velocità orizzontale e gravità conservate. Alla fine si resta in jump pose finché si atterra; l'atterraggio durante qualsiasi fase interrompe subito attacco e hitbox e torna in idle. Danno base 5, un solo impatto per esecuzione, nessun knockdown sul bersaglio a terra. La variante TARGET_STANCE_HIGH seleziona hurt_high/block_high in piedi e hurt_crouched/parata accovacciata in basso (block_low nel roster, block_low_crouched dove previsto dal controller). Mantiene le regole esistenti per bersagli aerei e KO.

Suoni condivisi con Arianna: punch_short_whoosh_30.wav alla partenza e light-punch.wav solo su HIT/KO. Interruzione e reset disattivano la hitbox e fermano il whoosh.

Test dedicato: `godot --headless --path . --script res://tests/test_jump_light_punch.gd`.

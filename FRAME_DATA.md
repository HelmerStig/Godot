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

L'esplosione sull'avversario usa scintille e bagliore arancioni, specifici del proiettile. Le reazioni degli altri attacchi mantengono il blu predefinito; la tinta non persiste sul bersaglio dopo il contatto.

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

Questi personaggi usano temporaneamente `IdleRosterFighter`. Gli idle hanno celle da 512×512, 8 colonne e loop a 18 FPS. Le camminate usano 49 frame in una griglia 7×7 da 512×512, tranne Torpe: `Torpe-walk-trimmed.png` contiene 21 frame in una griglia 7×3. `walk` avanza in loop a 24 FPS e `backwalk` riproduce gli stessi frame al contrario, sempre in loop a 24 FPS. La velocità di spostamento predefinita è 200 px/s.

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

## Oscare Special 2: soffio di fumo (19 ottobre 2026)

Input relativo: giù, giù-indietro, indietro + LP/MP/SP; finestra movimento 36 tick (600 ms), pugno 10 tick. Accetta la diagonale finale e il passaggio rapido giù-indietro. Le tre intensità condividono attualmente gli stessi parametri.

Personaggio: `special_2_blow_candidate.png`, celle 512x512, 7 colonne, frame 1-49 solo avanti a 60 FPS, non loop, poi idle. Prima del soffio si esegue `Special 1 - Light Cigarette`: 20 frame a 60 FPS e `siga-accensione.wav` al frame 6, poi passaggio diretto ai 49 frame del soffio senza idle o lancio della sigaretta.

Fumo: `special_2_smoke_candidate.png`, stessa griglia, esclusivamente frame 1-26 a 60 FPS. Compare al frame visivo 21 di Oscare, segue la bocca e termina al frame 46; i frame 47-49 sono recupero senza proiettile. Dissolvenza iniziale 3 frame, finale 6 frame; l'ultimo frame è soltanto visivo. Durata totale (20+49)/60 = 1,15 s; il fumo comincia quindi al frame complessivo 41. Scala fumo: 0,7 volte quella dello sprite del personaggio.

Collisione convessa per frame ricavata dalla sagoma del fumo, speculare al facing. Danno complessivo di 10 per bersaglio, applicato una sola volta; hitstun 0,3 s e blockstun 0,18 s. In piedi il primo colpo usa hurt_medium e la reazione riparte solo dopo aver completato tutti i frame di andata e di eventuale ritorno, esclusivamente mentre il bersaglio interseca il cono attivo. Si rinnova anche l'hitstun; l'ultimo hurt termina normalmente. Uscita dal cono, fine del fumo e interruzione fermano le ripetizioni. Da accovacciato produce hurt_crouched; la parata è media/bassa secondo la postura. Mantiene KO e reazioni aeree, senza raffica medium su accovacciati, bersagli aerei, in parata o KO.

`soffio.wav` parte alla comparsa del cono, una sola volta; la registrazione può finire dopo il recupero naturale, mentre interruzioni e reset la fermano. Nessun audio di impatto; particelle arancioni su HIT/KO e sui hurt_medium ripetuti. Il cono continua fino alla fine anche dopo un impatto, ma scompare su interruzione, KO del proprietario o reset.

Test dedicato: `godot --headless --path . --script res://tests/test_oscare_smoke.gd`; entrambe le speciali: `res://tests/test_oscare_special.gd`.

## Vittoria di Bue, Peirolo, Oscare, Torpe e Mileto (19 ottobre 2026)

Fonte AutoSprite: `Victory`. Tutti i 49 frame di ciascun foglio, celle 512x512, 7 colonne, a 24 FPS, solo avanti e senza loop. Durata 49/24 = circa 2,04 secondi. L'ultimo frame resta fermo nello stato VICTORY fino al reset del training.

Il segnale `MainArena.round_ended` avvia la sequenza soltanto sul vincitore, sia Player 1 sia Player 2. Cancella attacchi e movimento in corso; in aria conserva la caduta e attende il contatto col suolo. Reset e nuovo round annullano anche una vittoria ancora in attesa dell'atterraggio. Scala, offset e orientamento usano quelli del fighter.

PNG, atlas e provenienza sono nelle cartelle dei cinque personaggi: `victory.png`, `victory.atlas.json`, `victory_autosprite.json`. Nessuna nuova generazione o spesa di crediti.

Test dedicato: `godot --headless --path . --script res://tests/test_roster_victory.gd`.

## Torpe Special 1: lancio birra (19 ottobre 2026)

`special_1_beer_throw_candidate.png`: 56 celle native 512x512, 8 colonne. `special_1_beer_throw_64_frames.tres` conserva la sequenza di 64 frame con 8 ripetizioni registrate in `special_1_beer_throw_candidate.autosprite.json`. Riproduzione aggiornata a 64 FPS, durata 1 secondo, solo avanti e poi idle. Ai frame runtime 38/39, corrispondenti ai sorgenti 33/34, un ritaglio runtime dei primi 40 pixel elimina la bottiglia già disegnata in volo; il margine dell'atlas mantiene il canvas virtuale 512x512. PNG originale invariato.

Comando QCF + LP/MP/SP con finestra 36 tick (600 ms), diagonale finale e transizione rapida giù/avanti accettate. Rilascio unico al frame runtime 38, dita in coordinate canvas (390,62), posizione speculare e direzione bloccata dall'avvio. L'attacco può essere interrotto prima del rilascio; nessuna hitbox corpo a corpo durante la preparazione.

`beer_bottle.png` è una copia del Moretti fornito: canvas 1024x1536, rettangolo visibile (320,51,389,1400). Lunghezza visibile 81,6 pixel del personaggio, circa 73,44 pixel nel mondo alla scala 0,9 di Torpe, ingrandita del 20% dopo la prima integrazione. Velocità orizzontale 520/720/920 px/s; velocità verticale iniziale -150 px/s, gravità 600 px/s²; rotazione 1,8/2,2/2,6 giri/s speculare secondo il pugno. La collisione usa una capsula orientata e sweep sul passo fisico completo.

Un solo impatto da 10 danni: hurt_high in piedi o hurt_crouched in basso, parata media/bassa secondo postura e intersezione con hurtbox. Collisione con bersaglio, parata o terreno: 12 frammenti fisici ritagliati tramite UV dalla texture e spruzzo di birra; collisioni dei frammenti solo col terreno, nessun danno secondario, dissolvenza ed eliminazione in 1,4 secondi. `sibilo.wav` parte una volta al rilascio e si ferma all'impatto; `bottiglia-rotta.wav` parte una volta alla rottura con player indipendente dal proiettile. Scia Line2D ambrata in coordinate mondo: ultimi 0,12 secondi di traiettoria, larghezza 5 pixel, dissolvenza in 0,14 secondi all'impatto. Reset elimina proiettili, frammenti, scie e suoni del proprietario; i proiettili residui spariscono a fine round.

Controller `scripts/Torpe.gd`; volo `scripts/TorpeBeerBottleProjectile.gd`; rottura `scripts/TorpeBeerShatter.gd`. Test dedicato `res://tests/test_torpe_beer.gd`, incluso nella suite combat. Nessuna nuova generazione o spesa di crediti per l'integrazione.

## Torpe Special 2: saldatura (19 ottobre 2026)

Fonte AutoSprite `Special 2 - Welding Lunge`, sheet `cmvfcfza300cdup7ovl9a63fz`, celle 512x512, 8 colonne e 56 frame nativi. La sequenza `special_2_welding_64_frames.tres` conserva i 64 frame con 8 ripetizioni documentate nel relativo `.autosprite.json`. Nel gioco usa 60 FPS, non loop, durata 64/60 secondi, poi idle. Attivazione QCB + LP/MP/SP: 36 tick di tolleranza (600 ms), accetta anche diagonale finale e giù/indietro rapido. Direzione fissata all'avvio; l'attacco interrompe guardia e movimento.

Scintille attive ai frame runtime 43-64 (native 38-56), cioè per tutta la durata dell'arco presente nello sprite. La punta è tracciata sul canvas del personaggio e trasformata con scala, offset e facing. Ogni scintilla percorre una traiettoria indipendente dal personaggio, orizzontale in partenza e discendente per gravità 850 px/s²: velocità 1040 px/s, portata 300 pixel, vita massima 300/1040 secondi. Le scie sono linee orizzontali con bagliore, colori alternati blu, rosso e giallo; in più tre CPUParticles2D producono punti luminosi degli stessi colori con gravità e portata coerenti.

| Variante | Scie al secondo | Particelle per colore | Danno per esecuzione |
|---|---:|---:|---:|
| LP | 600 | 60 | 10 |
| MP | 1000 | 100 | 15 |
| SP | 1400 | 140 | 20 |

Le collisioni interrogano il segmento effettivo percorso da ciascuna scintilla contro le sole hurtbox, escludendo il proprietario. Un bersaglio subisce danno una sola volta per esecuzione; i punti aggiuntivi sono decorativi. Su HIT a terra si esegue hurt_high anche contro un bersaglio accovacciato; ogni ciclo completo, incluso un eventuale ritorno, può ripetersi al successivo contatto con una scintilla, senza altro danno. Il tracciamento della generazione dell’azione impedisce di sovrascrivere reset o azioni successive. La reazione breve di Oscare resta così visibile per il getto, conservando 8 frame a 48 FPS. Guardia media in piedi e bassa da accovacciato. In aria resta la normale reazione aerea. `saldatore.wav` inizia con l'emissione, può ripetersi senza modificare il WAV condiviso e si ferma insieme al getto. Le particelle residue possono terminare il volo dopo la recovery naturale; interruzione, KO e reset eliminano getto e audio.

Controller `scripts/Torpe.gd`, effetto e proiettili `scripts/TorpeWeldingSparks.gd`, test `res://tests/test_torpe_welding.gd` nella suite combat. Nessuna generazione o spesa AutoSprite durante l'integrazione.


## Mileto Special 1: Shoulder Snap v3 (20 ottobre 2026)

Esportazione aggiornata AutoSprite `cmvgcqy0d009kacycgzr8kxv8`, video `cmvgcng2500kalryxxq9lknhk`: 40 frame nativi, celle 512x512, 8 colonne. `special_1_shoulder.png` viene eseguito a 48 FPS senza duplicazioni. QCF + LP/MP/HP a terra: finestra movimento 36 tick (600 ms), pulsante 10 tick, diagonale finale e passaggio rapido giu/avanti accettati. Le normali cedono la priorita alla special.

Caricamento frame 1-12; avanzamento dal frame 13. Il frame originale 31 resta fermo finche la spalla incontra una hurtbox. Dopo contatto, anche parato, avanzamento fermo e recovery frame 32-40, poi idle. Un colpo ricevuto interrompe la special con normale hurt; KO, vittoria e reset eliminano aura e scia. A vuoto, muro o bordo arena avviano recovery per evitare un blocco permanente.

| Pulsante | Velocita | Aura e scia |
|---|---:|---|
| LP | 800 px/s | azzurro |
| MP | 1100 px/s | arancione |
| HP | 1400 px/s | rosso |

Singolo danno provvisorio 15 per ogni forza; reazione media in piedi, hurt_crouched da accovacciato, parata media/bassa secondo postura e contatto effettivo. ShapeCast2D sulla spalla (80x95, centro locale 55/-195, specchiato) verifica tutto lo spostamento consentito dalle collisioni fisiche e dai limiti del campo. Nessuna invulnerabilita. Aura procedurale con anello esplosivo iniziale, particelle e bagliore pulsante; scia di sprite colorati in coordinate mondo. `assets/sounds/sfx/scossa.wav` parte una volta all'attivazione (tutte le forze, -4 dB), si ferma a fine mossa, interruzione, KO o reset; il file condiviso non viene modificato. A contatto riuscito si riproduce una sola volta `strong-punch.wav` (-3 dB), anche su KO; su parata o mancato contatto resta silenzioso. Il reset ferma anche questo player, mentre una normale fine mossa lascia terminare il suono di impatto.

Controller `scripts/Mileto.gd`, effetto `scripts/MiletoShoulderAura.gd`, test dedicato `tests/test_mileto_shoulder.gd` incluso nella suite combat. Download gratuito, nessuna nuova generazione AutoSprite.


## Risposta del salto (20 ottobre 2026)

Tutti i sette fighter comprimono la sola anticipazione a terra in `Fighter.JUMP_STARTUP_SECONDS = 4/60 s` (circa 66,7 ms). `configure_jump_startup_timing` riduce la durata dei frame precedenti allo stacco; indici e texture restano invariati. Gli FPS base, le durate dei frame dal decollo in poi, la gravita, l'impulso verticale e la velocita orizzontale restano quelli del personaggio. Gli attacchi aerei e il salto indietro non cambiano timing.

| Fighter | Anticipazione precedente | Nuova anticipazione |
|---|---:|---:|
| Arianna | 281 ms | 67 ms |
| Mangler | 208 ms | 67 ms |
| Bue | 375 ms | 67 ms |
| Peirolo | 500 ms | 67 ms |
| Oscare | 333 ms | 67 ms |
| Torpe | 375 ms | 67 ms |
| Mileto | 458 ms | 67 ms |

Il tempo effettivo fra la registrazione dell'input e il primo spostamento include anche i tick fisici e di animazione: i test misurano al massimo 7 tick (117 ms a 60 Hz). `tests/test_jump_response.gd`, incluso nella suite arena, esercita input veri per salto verticale, avanti e indietro su tutto il roster e controlla altezza e atterraggio di ogni fighter.

## Mileto Special 2: Lightning Guitar (22 ottobre 2026)

QCB + LP/MP/HP, relativo al facing, solo a terra. Stessa tolleranza della Special 1: 36 tick per il movimento, 10 per il pulsante, diagonale finale o passaggio rapido giu/indietro accettati. Caricamento locale `Mileto-special_2_-_lightning_guitar_windup.png`: 45 frame, seguito dal foglio aggiornato `special_2_guitar_throw.png` (AutoSprite `Special 2 - Guitar Rotary Throw v3`, 23 frame). Caricamento a 100 FPS, lancio a 60 FPS, entrambi solo avanti senza loop, poi idle: durata complessiva circa 833 ms.

Il proiettile compare al frame 21 del lancio, prima posa senza chitarra, una sola volta. `guitar-projectile.png`: 25 celle 256x256, griglia 5x5, loop a 100 FPS, scala 2,0 (+14% rispetto alla prima integrazione), con collisione adattata alla nuova dimensione. Velocita LP/MP/HP: 600/800/1000 px/s, danno singolo 15 per tutte le forze. Hurt high in piedi, hurt crouched da abbassato; parata media/bassa secondo postura e intersezione effettiva della hurtbox. ShapeCast2D specchiato e dimensionato sulla sagoma di ogni fotogramma evita il tunneling e le collisioni sul margine trasparente.

Scia azzurra in coordinate mondo; al contatto, anche parato, il proiettile scompare in un'esplosione elettrica procedurale con bagliore, anello e particelle. Scadenza a 3 secondi. Una ferita prima del rilascio annulla la mossa, mentre un proiettile gia lanciato prosegue; reset e fine round ripuliscono gli effetti. `chitarra-electricity.wav` parte una volta al frame 12 del caricamento (primo contorno elettrico), si interrompe al rilascio o su annullamento. Al rilascio parte `boomerang.wav`, interrotto al contatto, anche parato. Solo HIT/KO riproducono `sound-libraries/body_hit_large_76.wav`, condiviso con il calcio potente, una sola volta e fino a fine suono anche dopo la scomparsa del proiettile. Reset ripulisce tutti i player della mossa. Controller `Mileto.gd`, proiettile `MiletoGuitarProjectile.gd`, effetto `MiletoGuitarExplosion.gd`, test `tests/test_mileto_guitar.gd` incluso nella suite combat. Download gratuito, nessuna nuova generazione.

## Bue Special 1: evocazione Tom Waits (29 ottobre 2026)

QCF + LP/MP/HP, solo a terra e relativo al facing; movimento entro 36 tick (600 ms), pulsante entro 10 tick. Diagonale finale e passaggio rapido giu/avanti accettati. Tutte le forze usano velocita 480 px/s e tre colpi da 5 danni, 15 totali. Una nuova evocazione e bloccata finche il Tom precedente non e effettivamente scomparso, comprese materializzazione, attacco e corsa in uscita; il reset libera il blocco.

`special_1_summon_lightning.png`: 30 frame, celle 512x512, 7 colonne, 60 FPS non loop; al frame 10 compare Tom a 170 px davanti a Bue, con offset verticale +26 px per allineare i piedi a Bue (sprite e collisione insieme). Bue completa Summon e torna idle. Tom usa `tom_electric_materialize.png` (AutoSprite "electric materializa", 30 frame) a 60 FPS, fermo. Poi `tom_run_singing.png` (49 frame) in loop a 48 FPS e movimento orizzontale Godot. Al contatto con una hurtbox si ferma ed esegue `tom_hat_slaps.png` (foglio da 49 frame) a 60 FPS fino al terzo impatto; salta la coda ferma finale. L'utente ha chiarito che "electric hit" indica Hat slaps: non esiste una fase elettrica aggiuntiva da duplicare.

I tre cappelli estesi ai frame 16/29/42 richiedono nuovamente contatto con la hurtbox. In piedi: hurt_high o block_high. Da abbassato: hurt_crouched o block_low se in traiettoria. I tre hurt si attivano ai rispettivi frame del cappello anche se la reazione precedente e ancora in corso: nessuna attesa dell'hurt puo ritardare la corsa in uscita. Danno senza pushback, per non allontanare artificialmente il bersaglio dai tre colpi; chi riesce a uscire dalla traiettoria evita i successivi. Subito dopo il terzo colpo, Run Singing riprende verso la direzione iniziale, senza ulteriori collisioni offensive, fino all'uscita oltre il campo. KO/interruzioni del bersaglio fermano i colpi restanti. Un normale hurt a Bue prima del frame 10 annulla l'evocazione; Tom gia materializzato prosegue. Reset, proprietario KO o controlli disabilitati eliminano Tom. `scossa.wav` parte subito all'attivazione della special e si ferma alla fine di electric materialize. Durante Run Singing, `assets/sounds/tom waits.mp3` parte dal secondo 25 e continua senza pause o riavvii durante Hat slaps, sovrapponendosi ai suoni hit fino all'uscita dallo schermo. Ogni HIT/KO riproduce `light-punch.wav` una volta (tre su un bersaglio che sopravvive); su parata o mancato contatto nessun suono hit. Il player del brano appartiene a Tom e scompare con lui; reset ripulisce anche i singoli audio di impatto.

Controller `scripts/Bue.gd`, evocazione `scripts/BueSingerProjectile.gd`, test `tests/test_bue_singer.gd` incluso nella suite combat. Scala Tom 0,85, origine piedi comune, collisione 70x150 specchiata, centro locale 30/-150. Fonti e atlas nelle cartelle di Bue, metadati AutoSprite senza URL firmati. Download gratuito, zero crediti spesi.

## Bue Special 2: evocazione Baglioni (29 ottobre 2026)

QCB + LP/MP/HP, relativo al facing e solo a terra, con la stessa tolleranza di 600 ms della Special 1. Usa Summon lightning a 60 FPS; al frame 10 compare Baglioni a 170 px davanti e 26 px sotto l'origine di Bue. In questa variante `scossa.wav` parte al frame 10 e termina con la materializzazione (Tom conserva l'avvio immediato della scossa).

Fonti AutoSprite del personaggio Baglioni `cmvt9n13y00j3msrqyr3g7ec6`, celle 512x512 e 7 colonne: Electric materialize `cmvtdzope002oogrjgy0ztrg6`, 28 frame a 60 FPS non loop; run singing `cmvt9wd1401nux7r43t51pyk9`, 49 frame in loop a 48 FPS; Slap flurry `cmvta0djo00gpf7eheasb5k6g`, 49 frame a 60 FPS non loop. File `baglioni_electric_materialize.png`, `baglioni_run_singing.png`, `baglioni_slap_flurry.png` nella cartella di Bue, con atlas e metadati sanitizzati. Nessuna nuova generazione: zero crediti spesi.

Il movimento Godot procede a 480 px/s durante la corsa, si arresta sulla hurtbox e avvia Slap flurry. I frame 24/36/41 producono tre colpi da 5 danni, senza pushback: hurt_high/block_high in piedi, hurt_crouched/block_low da accovacciato se in traiettoria. Ogni colpo richiede ancora contatto. Completati tutti i 49 frame, Baglioni riprende la corsa verso la direzione iniziale senza ulteriori hitbox e scompare oltre la camera. La variante di Tom conserva invece l'uscita immediata al terzo colpo.

`assets/sounds/baglioni.mp3` parte a 132 secondi (2:12) quando comincia la corsa e continua senza pause sotto i tre `light-punch.wav` di HIT/KO fino all'uscita del proiettile. Entrambe le special condividono il blocco per proprietario: nessuna seconda evocazione di Tom o Baglioni mentre il cantante precedente e presente. Reset, KO del proprietario e fine round ripuliscono sprite e audio. `BueBaglioniProjectile.gd` condivide collisioni, danno e ciclo audio con `BueSingerProjectile.gd`; `Bue.gd` seleziona la variante dal quarto di luna. Test `tests/test_bue_baglioni.gd` nella suite combat, insieme alla regressione di Tom.

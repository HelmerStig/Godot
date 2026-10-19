# Sanmo

Prototipo didattico di picchiaduro 2D in Godot 4.7 e GDScript. Il roster selezionabile comprende **Arianna, Mangler, Bue, Peirò, Oscare, Torpe e Mileto**. Arianna e Mangler dispongono del moveset completo; gli altri cinque hanno idle e camminata mentre vengono costruite le mosse.

## Stato attuale

Entrambi i personaggi dispongono di locomozione, attacchi a terra, accovacciati e aerei, guardie, reazioni e KO. Sono presenti combo e speciali, proiettili, effetti visivi e alcuni suoni. Il training comprende countdown, barre vita, timer, reset, camera condivisa, debug delle collisioni e slow motion.

Il timer scende da 99; timeout e best-of-three sono intenzionalmente disabilitati. Il flusso di avvio comprende title screen, selezione locale dei due personaggi e caricamento dell'arena. IA e multiplayer online non sono implementati.

## Avvio e controlli

Aprire `project.godot` con Godot 4.7 e premere **F5**. La scena principale è `scenes/TitleScreen.tscn`; da lì si passa alla selezione dei personaggi e quindi all'arena.

| Azione | Player 1 | Player 2 (tastierino) |
|---|---|---|
| Sinistra / destra | A / D oppure frecce | 4 / 6 |
| Salto | W, freccia su o Spazio | 8 |
| Accovacciamento | S o freccia giù | 5 |
| Pugni leggero / medio / pesante | J / H / U | 1 / 2 / 3 |
| Calci leggero / medio / pesante | K / L / I | 7 / 9 / 0 |

Player 1 supporta anche il gamepad 0, Player 2 il gamepad 1. **R** ripristina il training, **F3** mostra/nasconde le collisioni, **F4** alterna velocità normale e slow motion.

La guardia richiede la direzione opposta all'avversario. I colpi **LOW richiedono giù + indietro**; HIGH e MID si parano con indietro anche da accovacciati. La parata funziona a terra e contro un attaccante davanti al fighter, annullando il danno.

Bue, Peirò, Oscare, Torpe e Mileto possono correre premendo due volte avanti entro 15 frame fisici e mantenendo avanti, come Mangler. `run` riproduce in loop a 24 FPS i rispettivi 31, 33, 31, 30 e 32 fotogrammi. Rilasciare avanti o cambiare direzione termina la corsa; salto, accovacciamento e reazioni al danno la interrompono. La velocità usa `CharacterData.run_speed`. In F2 puoi provarla con un doppio tap sulla freccia avanti.

Bue, Peirò, Oscare, Torpe e Mileto riproducono `death` come animazione KO quando la vita arriva a zero: tutti i 49 fotogrammi a 24 FPS, senza loop, mantenendo la posa finale fino al reset. Gli spritesheet e gli atlas AutoSprite sono nelle rispettive cartelle dei personaggi come `death.png` e `death_atlas.json`.

Bue, Peirò, Oscare, Torpe e Mileto reagiscono al calcio basso potente con `sweep_knockdown`: 42 frame a 24 FPS, pausa di 0,3 secondi sull'ultimo frame, poi `knockdown_recovery` (17 frame a 24 FPS) e ritorno in idle. I relativi PNG e atlas sono nelle cartelle dei personaggi. La sequenza completa dura circa 2,76 secondi. Nella scena **F2**, **S+K** prova caduta e rialzata su tutti i personaggi senza infliggere danno; Arianna e Mangler usano i propri fogli esistenti con la stessa pausa finale di 0,3 secondi.

Un colpo ricevuto in salto sostituisce `jump` con `hurted_in_jump`: per Bue, Peirò, Oscare, Torpe e Mileto usa i 20 frame di `fall.png` a 24 FPS, senza loop. La sequenza completa tutti i frame e attende l’atterraggio, tiene la posa finale di `sweep_knockdown` per 0,3 secondi, quindi esegue `knockdown_recovery` (17 frame a 24 FPS per i cinque fighter) e torna in idle. In **F2**, **H+G durante il salto** prova la reazione senza danno; a terra mantiene la preview hurt_crouched. Arianna e Mangler sono inclusi con i rispettivi fogli aerei (17 e 25 frame a 24 FPS) e recovery esistenti.

**F2** apre la scena di confronto del roster. Qui **D** prova contemporaneamente il KO di tutti i sette personaggi senza togliere vita e torna in idle al termine di ciascuna animazione. Le cinque death durano 49/24 = circa 2,04 secondi; Arianna e Mangler usano i rispettivi KO con i timing originali. D è riservato alla preview in questa scena; per muoversi a destra si possono usare le frecce. Tab e le preview hurt interrompono death; F2 torna al titolo.

Il pugno forte accovacciato di Mangler lancia il bersaglio soltanto su un colpo entrato e non letale. Parata, rialzata invulnerabile e KO impediscono il lancio.

Il medium kick in piedi dei cinque fighter usa `medium_kick_standing.png`, solo avanti a 48 FPS (60 FPS per Mileto), senza loop o ritorno inverso, poi idle. Oscare esegue i frame 1-33 del foglio AutoSprite `Light kick` da 34 frame; Mileto usa `Light kick` da 38 frame. Torpe, Peirolo e Bue usano i rispettivi `Medium kick` da 23, 24 e 22 frame. La hitbox resta attiva solo nei frame visivi 18-20 (Oscare/Mileto), 14-16 (Torpe/Peirolo), 9-11 (Bue). Il colpo produce hurt medio o parata media su un bersaglio in piedi, hurt accovacciato o parata bassa su uno accovacciato. La mossa usa un singolo impatto da 12 danni; giu + calcio medio conserva la variante accovacciata.

### Special 1 di Torpe: lancio della birra

Giù, giù-avanti, avanti + LP/MP/SP, con la stessa tolleranza di 600 ms di Oscare. Per Player 1 rivolto a destra: S → S+D → D+J/H/U. La sequenza dura un secondo: 64 frame a 64 FPS, poi idle. La bottiglia nasce dalla mano al frame visivo 38; velocità orizzontale 520/720/920 px/s, arco con gravità e rotazione gestiti da Godot. La dimensione visibile è circa 73 pixel alla scala attuale di Torpe, ingrandita del 20% rispetto alla prima integrazione.

La bottiglia lascia una scia ambrata che segue l'arco senza ruotare con lo sprite e svanisce rapidamente all'impatto. `sibilo.wav` parte al rilascio e si ferma alla rottura. All'impatto con avversario, parata o terreno la bottiglia si frantuma in dodici pezzi della propria texture, con rimbalzo e spruzzo di birra; `bottiglia-rotta.wav` può completarsi anche dopo la scomparsa del proiettile. I frammenti sono decorativi e scompaiono dopo 1,4 secondi. Danno iniziale 10; hurt_high in piedi, hurt_crouched da accovacciato, solo se la traiettoria interseca la hurtbox. Parata media in piedi e bassa da accovacciato. Reset elimina proiettili, scie, suoni ed effetti; a fine round spariscono i proiettili rimasti.

### Special 2 di Torpe: saldatura

Giù, giù-indietro, indietro + LP/MP/SP, relativo al lato dell'avversario; finestra di 600 ms, con diagonale finale e passaggio rapido giù/indietro accettati. `Special 2 - Welding Lunge` esegue 64 frame a 60 FPS, senza loop, poi idle. Dal frame 43 al 64, durante l'arco AutoSprite, dalla punta del saldatore partono scie orizzontali e particelle luminose blu, rosse e gialle. Il getto avanza fino a 300 pixel a 1040 px/s e scende per gravità; segue la punta soltanto all'emissione, poi ogni scintilla continua nel mondo. `saldatore.wav` accompagna l'emissione e si ferma al termine o all'interruzione.

LP/MP/SP emettono rispettivamente 600/1000/1400 scie al secondo, più 60/100/140 particelle per ciascun colore, con danno 10/15/20. Ogni avversario subisce il danno una sola volta per esecuzione, solo se una scintilla attraversa la hurtbox; i punti luminosi aggiuntivi sono decorativi. Un HIT a terra produce hurt_high, anche da accovacciato; i cicli completi si ripetono finché altre scintille raggiungono il bersaglio, senza ulteriori danni. Una nuova azione, un reset o la fine dei contatti interrompono la ripetizione. Parata media in piedi e bassa da accovacciato. I bersagli aerei mantengono la reazione aerea. Le scintille già in volo si esauriscono in meno di 0,3 secondi dopo il termine naturale. Hurt, KO e reset del proprietario eliminano il getto e fermano l'audio.

### Special 1 di Oscare: sigaretta

Giù, giù-avanti, avanti + LP/MP/SP, relativo al lato dell'avversario. La finestra del movimento è di 36 tick fisici (600 ms); accetta anche il pugno sulla diagonale finale e il passaggio rapido da giù ad avanti. Per Player 1 rivolto a destra: S → S+D → D+J/H/U.

Accensione (20 frame) e lancio (29 frame) si concatenano a 60 FPS, poi idle. Il proiettile nasce al frame 19 del lancio e viaggia a 520/720/920 px/s secondo il pugno usato. Danno iniziale: 10 per tutte le varianti; la collisione considera la sigaretta, non il fumo. Un colpo entrato produce hurt_high in piedi o hurt accovacciato in basso, se la traiettoria interseca la hurtbox; parata media/bassa secondo la postura.

### Special 2 di Oscare: soffio di fumo

Giù, giù-indietro, indietro + LP/MP/SP, relativo all'avversario, con la stessa tolleranza di 600 ms della Special 1. In F2 usare frecce o joypad: D è riservato alla preview KO.

`Special 1 - Light Cigarette` (20 frame) precede `Special 2 - Violent Smoke Breath` (49 frame): tutto a 60 FPS, poi idle. L'accensione riproduce `siga-accensione.wav` al frame 6, come nella Special 1. Dal frame 21 del soffio si aggancia alla bocca il cono di fumo: solo i primi 26 frame del foglio, sempre a 60 FPS, con comparsa e dissolvenza gestite da Godot. Il cono segue il busto e resta orientato nella direzione iniziale. La collisione segue la sagoma del fumo. Sul bersaglio in piedi ripete hurt_medium soltanto dopo ogni ciclo completo, incluso il ritorno, finché resta nel cono attivo; da accovacciato produce hurt_crouched. Il danno complessivo resta di 10 per bersaglio; parate, KO e bersagli aerei mantengono le proprie reazioni. L'impatto usa particelle arancioni. `soffio.wav` parte quando compare il fumo; nessun suono aggiuntivo al contatto con l'avversario. Interruzione e reset eliminano il cono.

### Vittoria del roster

Bue, Peirolo, Oscare, Torpe e Mileto riproducono `Victory` quando vincono il round: 49 fotogrammi a 24 FPS, senza loop, mantenendo l'ultimo fotogramma fino al reset. La vittoria annulla l'attacco in corso e blocca i comandi; se il vincitore è in aria, completa l'atterraggio prima di festeggiare. Gli spritesheet e gli atlas originali sono salvati come `victory.png` e `victory.atlas.json` nelle cartelle dei personaggi.

## Test

```powershell
.\tests\run_smoke_tests.cmd
```

Il runner usa il percorso Godot di `.vscode/settings.json`, poi cerca `godot` o `godot4` nel `PATH`. È possibile passare `-GodotPath "C:\percorso\Godot.exe"`.

```text
godot --headless --path . --script res://tests/test_combat.gd
godot --headless --path . --script res://tests/smoke_tests.gd
```

Baseline del **25 settembre 2026: 709 asserzioni, zero fallimenti**, in cinque suite: input 14, Arianna 218, Mangler 359, combat 83, arena 35. La suite completa esegue gli stessi nove moduli dei test separati.

Gli scenari sono in `tests/cases/`, il catalogo comune è `tests/suite_catalog.gd` e il runner condiviso è `tests/support/suite_runner.gd`. I riepiloghi vengono calcolati dall'esecuzione, senza conteggi fissati nel codice. Comandi, struttura e criteri per aggiungere casi sono in [tests/README.md](tests/README.md).

## Architettura

```text
FighterCombat → Fighter (Arianna / Mangler) → MainArena → ArenaUI
```

| File o cartella | Responsabilità |
|---|---|
| `scenes/TitleScreen.tscn`, `scenes/CharacterSelect.tscn`, `scenes/LoadingScreen.tscn` | Avvio, selezione locale e passaggio all'arena |
| `scripts/CharacterSelection.gd` | Roster e selezione globale dei fighter per Player 1 e Player 2 |
| `scenes/MainArena.tscn`, `scripts/MainArena.gd` | Arena, countdown, camera, KO e reset |
| `scenes/Fighter.tscn`, `scripts/Fighter.gd` | Corpo, componenti, stato, segnali, collisioni e reazioni comuni |
| `scenes/Arianna.tscn`, `scripts/Arianna.gd` | Scena e controller di Arianna, derivati direttamente da Fighter |
| `scenes/Mangler.tscn`, `scripts/Mangler.gd` | Scena e controller di Mangler, prese e speciali |
| `scenes/{Bue,Mileto,Oscare,Peirolo,Torpe}.tscn` | Fighter iniziali con idle a 18 FPS e camminata a 24 FPS |
| `scripts/IdleRosterFighter.gd` | Controller condiviso dei fighter con idle, walk e backwalk |
| `scenes/MovementTest.tscn` | Scena di confronto che istanzia automaticamente l'intero roster |
| `scripts/FighterCombat.gd`, `scripts/FighterCombatReactions.gd` | Ciclo degli attacchi, danni, parate, hitbox e reazioni asincrone con invalidazione delle attese |
| `scripts/FighterInputBuffer.gd` | Input relativi all'avversario, buffer e riconoscimento delle sequenze |
| `scripts/CharacterData.gd` | Statistiche e profilo predefinito creato a runtime |
| `scripts/AttackData.gd`, `scripts/AttackVariantData.gd` | Identità, danno, stun, timing e geometria delle varianti |
| `data/attacks/` | Otto risorse: sei attacchi base, 720 Punch e Sonic Boom |
| `scripts/*AnimationCatalog.gd` | Slicing degli atlas e costruzione degli SpriteFrames |
| `scripts/*Projectile.gd` | Proiettili ed evocazioni dei personaggi |
| `scripts/ArenaUI.gd`, `scripts/ArenaUIConfig.gd` | UI aggiornata dai segnali dell'arena e configurazione visiva delle barre vita |
| `scripts/FighterDebugOverlay.gd` | Visualizzazione delle collisioni |
| `scenes/stages/`, `scripts/StageAmbientEffects.gd` | Stage ed effetti ambientali |

`Fighter.change_state()` centralizza le transizioni. Mangler personalizza il movimento tramite `_apply_state_movement()` e mantiene i comportamenti specifici di salto, prese e speciali. Collisioni, ombra, inizializzazione, reset comune e creazione degli effetti sono condivisi.

Le mosse animate di Arianna usano `begin_animation_attack()`, `finish_animation_attack()` e `resolve_attack_overlap()` del combat. Il controller conserva frame attivi, recovery e concatenazioni. Avvio, conclusione e annullamento emettono segnali; ogni colpo della combo ha un ciclo distinto. Hit, KO e reset invalidano le attese e ripuliscono i flag delle mosse interrotte.

Gli stati comprendono idle, camminata, corsa, preparazione e svolgimento di salto/back hop, crouch e rialzata, attacco, guardia e recovery, hit, knockdown, KO e vittoria. L'elenco esatto è `Fighter.State`.

| Bit della collisione | Uso |
|---:|---|
| 1 | Terreno |
| 2 | Hitbox offensive |
| 4 | Hurtbox |
| 8 | Corpo dei fighter |

In aria i fighter attraversano il corpo dell'avversario, continuando a collidere con il terreno.

## Asset e documentazione

Gli atlas runtime sono in `assets/`; molti usano celle da 512×512, ma il foglio completo contiene più celle. Scala e offset dipendono dal personaggio e dall'animazione: non esiste una scala unica di scena. `original_images/` conserva materiale sorgente.

- [FRAME_DATA.md](FRAME_DATA.md): timing delle risorse e differenze introdotte dal runtime.
- [PROJECT_MEMORY.md](PROJECT_MEMORY.md): decisioni attive e punti da preservare nello sviluppo.
- [TUTORIAL_ANIMAZIONI.md](TUTORIAL_ANIMAZIONI.md): indicazioni per orientarsi tra cataloghi e vecchi esempi didattici.
- [SMOKE_TEST_TRIAGE.md](SMOKE_TEST_TRIAGE.md): resoconto storico del riallineamento dei test.
- [docs/archive/](docs/archive/): note precedenti, conservate come archivio e non come specifica corrente.

Restano da sviluppare round competitivi, IA e multiplayer online. Sul piano tecnico, i due scenari storici dei moveset restano sequenze di integrazione lunghe; i nuovi casi indipendenti hanno moduli dedicati.

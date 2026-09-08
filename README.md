# Sanmo

Prototipo didattico di picchiaduro 2D in Godot 4.7 e GDScript. L'arena propone training locale con **Arianna (Player 1)** e **Mangler (Player 2)**.

## Stato attuale

Entrambi i personaggi dispongono di locomozione, attacchi a terra, accovacciati e aerei, guardie, reazioni e KO. Sono presenti combo e speciali, proiettili, effetti visivi e alcuni suoni. Il training comprende countdown, barre vita, timer, reset, camera condivisa, debug delle collisioni e slow motion.

Il timer scende da 99; timeout e best-of-three sono intenzionalmente disabilitati. IA, menu, selezione del personaggio e multiplayer online non sono implementati.

## Avvio e controlli

Aprire `project.godot` con Godot 4.7 e premere **F5**. La scena principale è `scenes/MainArena.tscn`.

| Azione | Player 1 | Player 2 (tastierino) |
|---|---|---|
| Sinistra / destra | A / D oppure frecce | 4 / 6 |
| Salto | W, freccia su o Spazio | 8 |
| Accovacciamento | S o freccia giù | 5 |
| Pugni leggero / medio / pesante | J / H / U | 1 / 2 / 3 |
| Calci leggero / medio / pesante | K / L / I | 7 / 9 / 0 |

Player 1 supporta anche il gamepad 0, Player 2 il gamepad 1. **R** ripristina il training, **F3** mostra/nasconde le collisioni, **F4** alterna velocità normale e slow motion.

La guardia richiede la direzione opposta all'avversario. I colpi **LOW richiedono giù + indietro**; HIGH e MID si parano con indietro anche da accovacciati. La parata funziona a terra e contro un attaccante davanti al fighter, annullando il danno.

Il pugno forte accovacciato di Mangler lancia il bersaglio soltanto su un colpo entrato e non letale. Parata, rialzata invulnerabile e KO impediscono il lancio.

## Test

```powershell
.\tests\run_smoke_tests.cmd
```

Il runner usa il percorso Godot di `.vscode/settings.json`, poi cerca `godot` o `godot4` nel `PATH`. È possibile passare `-GodotPath "C:\percorso\Godot.exe"`.

```text
godot --headless --path . --script res://tests/test_combat.gd
godot --headless --path . --script res://tests/smoke_tests.gd
```

Baseline dell'**8 settembre 2026: 677 asserzioni, zero fallimenti**, in cinque suite: input 14, Arianna 216, Mangler 359, combat 83, arena 5. La suite completa esegue gli stessi casi, inclusi i cinque controlli dell'arena.

Gli scenari sono in `tests/cases/`, il catalogo comune è `tests/suite_catalog.gd` e il runner condiviso è `tests/support/suite_runner.gd`. I riepiloghi vengono calcolati dall'esecuzione, senza conteggi fissati nel codice. Comandi, struttura e criteri per aggiungere casi sono in [tests/README.md](tests/README.md).

## Architettura

```text
FighterCombat → Fighter (Arianna / Mangler) → MainArena → ArenaUI
```

| File o cartella | Responsabilità |
|---|---|
| `scenes/MainArena.tscn`, `scripts/MainArena.gd` | Arena, countdown, camera, KO e reset |
| `scenes/Fighter.tscn`, `scripts/Fighter.gd` | Corpo, componenti, stato, segnali, collisioni e reazioni comuni |
| `scenes/Arianna.tscn`, `scripts/Arianna.gd` | Scena e controller di Arianna, derivati direttamente da Fighter |
| `scenes/Mangler.tscn`, `scripts/Mangler.gd` | Scena e controller di Mangler, prese e speciali |
| `scripts/FighterCombat.gd`, `scripts/FighterCombatReactions.gd` | Ciclo degli attacchi, danni, parate, hitbox e reazioni asincrone con invalidazione delle attese |
| `scripts/FighterInputBuffer.gd` | Input relativi all'avversario, buffer e riconoscimento delle sequenze |
| `scripts/CharacterData.gd` | Statistiche e profilo predefinito creato a runtime |
| `scripts/AttackData.gd`, `scripts/AttackVariantData.gd` | Identità, danno, stun, timing e geometria delle varianti |
| `data/attacks/` | Otto risorse: sei attacchi base, 720 Punch e Sonic Boom |
| `scripts/*AnimationCatalog.gd` | Slicing degli atlas e costruzione degli SpriteFrames |
| `scripts/*Projectile.gd` | Proiettili ed evocazioni dei personaggi |
| `scripts/ArenaUI.gd` | UI aggiornata dai segnali dell'arena |
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

Restano da sviluppare round competitivi, IA e selezione del personaggio. Sul piano tecnico, i due scenari storici dei moveset restano sequenze di integrazione lunghe; i nuovi casi indipendenti hanno moduli dedicati.

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
- smoke test headless per input buffer e flusso di combattimento.

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

La suite verifica 28 condizioni relative a input buffer, danno, hit-stun, guardia, segnali UI, KO e reset. Il successo è indicato da `SMOKE_TESTS_OK` e codice di uscita `0`.

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
- `scripts/FighterCombat.gd`: attacchi, hitbox, danno, guardia, hit-stun e KO.
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

| Attacco | Danno | Durata totale |
|---|---:|---:|
| Pugno leggero | 5 | 0,30 s |
| Pugno medio | 10 | 0,45 s |
| Pugno pesante | 15 | 0,60 s |
| Calcio leggero | 8 | 0,40 s |
| Calcio medio | 12 | 0,50 s |
| Calcio pesante | 20 | 0,70 s |

- Vita massima: 100 HP.
- Velocità a terra: 200 px/s.
- Velocità aerea: 280 px/s.
- Velocità iniziale del salto: -850 px/s.
- Gravità: 1400 px/s².
- Guardia riuscita: 0 danni.
- Hit-stun: 0,30 s.
- Reazione di blocco: 0,15 s.

I timing reali degli attacchi sono attualmente suddivisi in startup 30%, active 40% e recovery 30%. `FRAME_DATA.md` contiene le specifiche di riferimento per la futura risorsa `AttackData`.

## Asset dei personaggi

Gli sprite in `assets/sprites/characters/` sono PNG RGBA 512×512. La scena condivisa `Mangler.tscn` usa una scala di `0.7`, equivalente alla precedente resa visiva degli asset 1024×1024 scalati a `0.35`.

Sono presenti asset per Arianna, Bue, Mangler, Mileto, Peirolo e Torpe; al momento soltanto Mangler è collegato alla scena giocabile.

## Limiti noti e prossime priorità

- Il progetto offre training locale, non ancora round completi o best-of-three.
- Le animazioni non sono ancora collegate agli stati.
- I dati degli attacchi sono divisi tra `CharacterData` e `FighterCombat`; manca `AttackData`.
- `CharacterData` usa ancora un profilo predefinito creato in memoria, senza risorse `.tres` dedicate.
- Combo e mosse speciali non sono ancora collegate al gameplay, anche se l'input buffer riconosce sequenze.
- Non sono ancora presenti IA, audio, menu, selezione personaggio o multiplayer online.
- `original_images/` conserva materiale sorgente e non fa parte del flusso runtime.

Per il dettaglio dei timing consultare `FRAME_DATA.md`; per il futuro collegamento delle animazioni consultare `TUTORIAL_ANIMAZIONI.md`.

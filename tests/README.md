# Test headless

Eseguire `tests/run_smoke_tests.cmd` dalla radice del progetto per avviare cinque processi Godot separati. Il parametro `-GodotPath` permette di scegliere l'eseguibile; altrimenti il runner usa `.vscode/settings.json` oppure il `PATH`.

```powershell
.\tests\run_smoke_tests.cmd
```

Per una sola suite o per tutti i casi nello stesso processo:

```text
godot --headless --path . --script res://tests/test_combat.gd
godot --headless --path . --script res://tests/smoke_tests.gd
```

Per verificare soltanto gli errori di caricamento e le azioni di recupero:

```text
godot --headless --path . --script res://tests/test_loading.gd
```

Il caso `cases/loading_screen.gd` fa parte anche della suite arena. Copre errori della richiesta e del loader, risorse non valide, cambio scena fallito, riprova e ritorno al titolo tramite pulsante o annulla.

Per verificare KO dei cinque fighter del roster e preview con D di tutti i sette personaggi:

```text
godot --headless --path . --script res://tests/test_death.gd
```

`cases/roster_death.gd` è incluso nella suite arena e verifica slicing, riproduzione di tutti i 49 frame a 24 FPS, danno letale, posa finale, reset e shortcut D nella scena F2, comprese interruzioni e pressioni ripetute. La preview verifica anche la sequenza KO completa e il ritorno in idle di Arianna e Mangler con i rispettivi timing originali.

Per verificare calcio basso potente, sweep, pausa, recovery e shortcut S+K:

```text
godot --headless --path . --script res://tests/test_knockdown.gd
```

`cases/roster_knockdown.gd` è incluso nella suite combat. Verifica tutti i 42 e 17 frame a 24 FPS, pausa di 0,3 secondi, ritorno in idle, parata, KO, reset e interruzione della preview con Tab o D.

Per verificare i colpi aerei e H+G in salto su tutti i sette fighter:

```text
godot --headless --path . --script res://tests/test_airborne_hit.gd
```

`cases/airborne_hit.gd` fa parte della suite combat e verifica frame e FPS, priorità della reazione aerea, riproduzione completa anche vicino a terra, pausa finale, recovery, H+G in entrambi gli ordini, reset e KO.

## Organizzazione

| Suite | Casi in `tests/cases/` | Asserzioni della baseline |
|---|---|---:|
| `input` | `input_buffer.gd` | 14 |
| `arianna` | `arianna_moveset.gd`, `arianna_lifecycle.gd` | 218 |
| `mangler` | `mangler_moveset.gd` | 359 |
| `combat` | `attack_data.gd`, `guard_heights.gd`, `crouched_heavy_launch.gd` | 83 |
| `arena` | `arena_contract.gd`, `idle_roster_fighters.gd` | 105 |
| Totale | Nove moduli | 779 |

`suite_catalog.gd` è l'unico elenco dei moduli. Gli entry point singoli e `smoke_tests.gd` usano lo stesso catalogo: aggiungere un caso qui lo include anche nell'esecuzione completa.

`support/suite_runner.gd` gestisce asserzioni, conteggi, codice di uscita e pulizia degli input e della scala temporale tra i moduli. I file dei casi sono `RefCounted` con `static func run(tree: SceneTree, expect: Callable) -> bool`; ricevono esplicitamente il contesto e usano `expect.call(condizione, descrizione)`. Restituiscono `true` soltanto dopo aver completato lo scenario: un'interruzione runtime non deve produrre un falso esito positivo.

I due moduli `*_moveset.gd` conservano le sequenze di integrazione storiche, comprese le dipendenze tra preparazione, frame attivi e recovery. Quello di Mangler comprende anche propagazione alla UI, KO e reset dell'arena. I nuovi scenari indipendenti vanno aggiunti in moduli piccoli, come quelli dedicati alla guardia e al ciclo delle mosse di Arianna.

## Regole per aggiungere casi

- Preparare esplicitamente posizione, input, stato e collisioni prima del comportamento verificato.
- Liberare le scene create dal caso e invalidare le azioni ancora in attesa prima della rimozione.
- Usare i timing delle risorse o degli `SpriteFrames` nei test di comportamento. Verificare i valori esatti nei test dei dati o dello slicing.
- Per le collisioni, attendere il tick fisico necessario. Non assumere che un segnale di animazione abbia già aggiornato le sovrapposizioni.
- Verificare conseguenze osservabili: danno, movimento, segnali, animazione e ripristino dopo interruzione.

## Risultati e diagnosi

Ogni processo stampa `TEST_TOTAL: passed=N failed=M` e termina con `<SUITE>_TESTS_OK` oppure `<SUITE>_TESTS_FAILED`. Il runner Windows controlla codice di uscita, riepilogo, marker finale ed eventuali `SCRIPT ERROR`, poi stampa `SMOKE_TEST_TOTAL` e l'esito aggregato.

I log delle suite separate sono in `.godot/test-<suite>.log`. La baseline del 1 ottobre 2026 è di 779 asserzioni superate. Nell'ambiente Windows usato per verificarla, Godot segnala `Failed to read the root certificate store`; questo messaggio non impedisce l'esecuzione dei test locali.

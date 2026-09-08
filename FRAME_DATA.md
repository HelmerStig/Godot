# Sanmo — frame data

Verifica delle risorse: 8 settembre 2026.

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

## Movimento

`CharacterData` predefinito: 100 HP, camminata 200 px/s, corsa 320 px/s, velocità aerea 280 px/s e impulso salto -850 px/s. I controller applicano modificatori: Mangler moltiplica l'impulso del salto per 1,5 e usa gravità 3150 px/s²; Arianna usa gravità 1800 px/s² e corsa a `run_speed × 2`. Scala e offset degli sprite dipendono dall'animazione.

## Verifica

Baseline corrente: 677 asserzioni superate nelle cinque suite headless; vedere [tests/README.md](tests/README.md). Le vecchie tabelle che mescolavano timing dichiarati, pose mantenute e dati non più aggiornati sono conservate in [archivio](docs/archive/FRAME_DATA.md).

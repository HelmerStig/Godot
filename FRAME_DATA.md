# Sanmo — frame data corrente

Ultimo aggiornamento: 10 agosto 2026.

I valori seguenti provengono da `data/attacks/*.tres`. I frame sono misurati agli FPS della variante, non a 60 Hz.

| Attacco | Variante | Animazione | FPS | Startup | Active | Recovery | Totale | Danno | Altezza | KD |
|---|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Pugno leggero | standing | `light_punch_single` | 48 | 11 | 3 | 3 | 17 | 5 | high | no |
| Pugno leggero | crouched | `crouched_punch` | 48 | 10 | 3 | 5 | 18 | 5 | mid | no |
| Pugno leggero | crouched held | `crouched_punch_crouched` | 48 | 4 | 3 | 5 | 12 | 5 | mid | no |
| Pugno leggero | airborne | `jump_light_punch` | 48 | 14 | hold | 19 | variabile | 5 | high | no |
| Pugno medio | standing | `medium_open_hand_slap` | 48 | 17 | 6 | 19 | 42 | 10 | high | no |
| Pugno medio | crouched | `crouched_medium_punch` | 48 | 11 | 4 | 5 | 20 | 10 | mid | no |
| Pugno medio | crouched held | `crouched_medium_punch_crouched` | 48 | 7 | 4 | 5 | 16 | 10 | mid | no |
| Pugno medio | airborne | `jump_medium_punch` | 48 | 12 | hold | 19 | variabile | 10 | high | no |
| Pugno pesante | standing | `heavy_punch` | 48 | 38 | 4 | 28 | 70 | 15 | mid | no |
| Pugno pesante | crouched | `crouched_power_punch` | 48 | 8 | 6 | 5 | 19 | 15 | high | no |
| Pugno pesante | airborne | `jump_heavy_punch` | 48 | 8 | 4 | 4 | 16 | 15 | high | no |
| Calcio leggero | standing | `light_kick` | 48 | 14 | 3 | 14 | 31 | 8 | low | no |
| Calcio leggero | crouched | `crouched_light_kick` | 48 | 13 | 3 | 15 | 31 | 8 | low | no |
| Calcio leggero | airborne | `jump_light_kick` | 48 | 15 | hold | 19 | variabile | 8 | high | no |
| Calcio medio | standing | `medium_kick` | 48 | 26 | 2 | 5 | 33 | 12* | low/high | no |
| Calcio medio | crouched | `crouched_medium_kick` | 48 | 22 | 3 | 24 | 49 | 12 | mid | no |
| Calcio medio | airborne | `jump_medium_kick` | 48 | 15 | hold | 19 | variabile | 12 | high | no |
| Calcio pesante | standing | `heavy_kick` | 48 | 24 | 4 | 5 | 33 | 20 | high | no |
| Calcio pesante | crouched | `crouched_heavy_kick` | 48 | 22 | 7 | 20 | 49 | 20 | low | sì |
| Calcio pesante | airborne | `jump_heavy_kick` | 48 | 15 | hold | 19 | variabile | 20 | high | no |
| 720 Punch | standing | `special_720_punch` | 48 | 9 | 34 | 6 | 49 | 6×3 | high | no |
| Sonic Boom (lancio) | standing | `special_sonic_boom` | 48 | 24 | 1 | 24 | 49 | 0 | high | no |

\* Il calcio medio in piedi produce due impatti da 6 danni.

## Modello dati

- `AttackData`: identità, danno, hit-stun, block-stun e fallback compatibile.
- `AttackVariantData`: animazione, FPS, startup/active/recovery, frame attivo, hitbox, altezza, reazione e knockdown.
- Varianti riconosciute: `standing`, `crouched`, `crouched_held`, `airborne`.

I valori delle varianti non devono essere duplicati come costanti in `FighterCombat.gd`.

## Movimento

| Proprietà | Valore |
|---|---:|
| Vita | 100 HP |
| Camminata | 200 px/s |
| Corsa | 320 px/s |
| Controllo aereo | 280 px/s |
| Impulso salto | -850 px/s |
| Guardia corretta | 0 danni |

## Stato della baseline

Al 10 agosto 2026 il caricamento headless non presenta errori di parsing. La suite registra 25 asserzioni fallite, concentrate su slicing/FPS degli atlas e sincronizzazione di alcuni frame attivi. Prima del refactoring erano 26. Questa pagina descrive i dati runtime correnti.

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
| Presa diretta combinata | standing grab | `grab_headbow_combined` | 48 | 19 (esplosione rossa light punch) | — | 1 | 29 (sorgente 1–29) | 0 | grab | no |
| Supermossa (avvio) | standing super | `super_start` | 48 | 19 (aura gialla) | — | hold | 25 | 0 | super | no |
| Supermossa (corsa rotante) | standing super | `super_rotate_run` | 48 | 20 (movimento + scia) | — | hold | 25 | 0 | super | no |
| Supermossa (corsa) | standing super | `super_run_only` | 48 | scia continua | — | loop fino al contatto | 24 | 0 | super | sì |
| Supermossa (rullo) | standing super | `super_drum_roll` | 48 | 5, 11, 17, 23 (esplosioni rosse) | 25% vita massima, una volta al contatto | 2 esecuzioni, poi idle | 24 | 0 | super | no |
| Reazione al rullo | frozen hit | `super_drum_hurt` | 48 | — | — | loop per tutta la durata del rullo | 4-13 di `hurt-high.png` | 0 | super | sì |
| Caduta dopo il rullo | knockdown | `super_drum_knockdown` | 24 | — | — | poi `knockdown_recovery` | 11-25 di `ko.png` | 0 | super | no |
| Arianna idle | standing idle | `idle` | 24 | — | — | loop | 1-24 | 0 | base | sì |
| Arianna camminata avanti | standing walk | `walk` | 24 | — | — | loop finché si tiene avanti | 1-48 | 0 | base | sì |
| Arianna camminata indietro | standing backwalk | `backwalk` | 24 | — | — | loop finché si tiene indietro | 48-1 di `01-walk.png` | 0 | base | sì |
| Arianna corsa | double-tap forward | `run` | 24 | — | — | loop fino a collisione | 1-48 | 0 | movement | sì |
| Arianna salto indietro | double-tap back | `arianna_back_jump` | 48 | — | — | idle subito dopo frame 49 | 28-49 di `back-jump.png`; 50 px orizzontali in 1 s | 0 | movement | no |
| Arianna accovacciata | hold down | `crouch` → `arianna_crouch_recovery` | 48 | — | — | hold frame 19 | 1-19; rilascio 18-1 | 0 | stance | no |
| Arianna guardia alta | hold back durante attacco avversario | `block_high` → `block_high_recovery` | 48 | — | — | hold frame 16 finché l'attacco resta attivo | 1-16; fine attacco/rilascio 15-1 | 0 | high guard | no |
| Arianna salto | jump | `jump` | 48 | stacco al frame 6 | — | fino all'atterraggio | 64 | 0 | movement | no |
| Arianna pugno leggero | standing light punch | `arianna_light_punch` → `arianna_light_punch_recovery` | 48 | 6 | 3 | 9 | 18 (1-9, poi 9-1) | 5 | high | no |
| Testata da presa | grab follow-up | `grab_headbutt` | 25 | 16 | 1 | 8 | 25 | 15 | high/unblockable | no |
| Vittima afferrata | reaction | `grabbed` | 24 | — | — | — | 32 (sorgente 10–25–10) | 0 | reaction | no |
| Colpito in salto | airborne reaction | `hurted_in_jump` | 24 | — | — | — | 25 + 1 s hold | 0 | knockdown | sì |

> Presa diretta: `grab_tentative` viene saltato. Se la verifica immediata della portata riesce, parte `Mangler2-headbut_mangler_mangler.png` e la vittima viene nascosta; terminata la sequenza, entrambi avanzano di 15 px nella direzione della testata e tornano visibili in `IDLE`.

Il proiettile Sonic Boom viaggia a 520 px/s con pugno leggero, 676 px/s con pugno medio e 832 px/s con pugno pesante.

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

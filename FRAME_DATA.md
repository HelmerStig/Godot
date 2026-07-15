# Specifiche Tecniche - Sistema di Combattimento

## Frame Data

In un picchiaduro, ogni azione è misurata in "frame". A 60 FPS, 1 frame = 1/60 di secondo (circa 0.0167s).

### Attacchi Base - Frame Timing

| Attacco        | Startup | Active | Recovery | Totale | Danno | Velocità |
|----------------|---------|--------|----------|--------|-------|----------|
| Pugno Leggero  | 5f      | 8f     | 5f       | 18f    | 5     | 0.30s    |
| Calcio Leggero | 6f      | 10f    | 8f       | 24f    | 8     | 0.40s    |
| Pugno Pesante  | 10f     | 15f    | 11f      | 36f    | 15    | 0.60s    |
| Calcio Pesante | 15f     | 18f    | 9f       | 42f    | 20    | 0.70s    |

**Legenda:**
- **Startup**: Frame prima che l'hitbox diventi attiva
- **Active**: Frame in cui l'hitbox può colpire
- **Recovery**: Frame dopo l'attacco prima di poter agire di nuovo
- **Totale**: Durata totale dell'animazione

### Movimento

| Azione         | Valore         | Note                              |
|----------------|----------------|-----------------------------------|
| Velocità Base  | 200 px/s       | Movimento orizzontale             |
| Velocità Aerea | 280 px/s       | Controllo orizzontale durante il salto |
| Velocità Salto | -850 px/s      | Velocità iniziale verticale       |
| Gravità        | 1400 px/s²     | Accelerazione verso il basso      |
| Altezza Salto  | ~258 px        | Calcolata: v²/(2g)                |
| Durata Salto   | ~1.21s         | Tempo totale in aria              |

### Sistema di Danno

#### Vita Base
- **Vita massima**: 100 HP
- **Vita iniziale**: 100 HP

#### Modificatori Danno

| Condizione           | Modificatore | Note                                    |
|----------------------|--------------|----------------------------------------|
| Danno normale        | 100%         | Attacco va a segno                     |
| Con blocco           | 0%           | Nessuna perdita di vita                 |
| Counter Hit (futuro) | 125%         | Colpire durante startup avversario     |
| Combo scaling (fut.) | 90%-50%      | Danno ridotto nei combo                |

#### Calcolo Danno con Blocco
```
danno_finale = 0
```
Esempio: Pugno Pesante (15 danno) → 0 danni se bloccato

### Stati del Personaggio

| Stato        | Può muoversi | Può attaccare | Può bloccare | Note                    |
|--------------|--------------|---------------|--------------|-------------------------|
| IDLE         | ✓            | ✓             | ✓            | Stato neutrale          |
| WALKING      | ✓            | ✓             | ✓            | In movimento            |
| JUMPING      | ✓ (limitato) | ✓             | ✗            | In aria                 |
| CROUCHING    | ✗            | ✓ (futuro)    | ✓            | Accovacciato            |
| ATTACKING    | ✗            | ✗             | ✗            | Durante attacco         |
| BLOCKING     | ✗            | ✗             | ✓            | In difesa               |
| HIT          | ✗            | ✗             | ✗            | Stun dopo colpo (0.3s)  |
| KNOCKED_DOWN | ✗            | ✗             | ✗            | KO                      |

### Sistema di Collisioni

#### Collision Layers
```
Layer 1: CharacterBody2D (corpo fisico del personaggio)
Layer 2: Hitbox (attacchi)
Layer 4: Hurtbox (zone vulnerabili)
```

#### Collision Masks
- **CharacterBody2D**: Mask = Layer 1 (collide con altri personaggi e terreno)
- **Hitbox**: Mask = Layer 4 (collide con hurtbox avversari)
- **Hurtbox**: Mask = Layer 2 (collide con hitbox avversari)

### Hitbox/Hurtbox

```
Personaggio A attacca → Attiva Hitbox (Layer 2)
                        ↓
                   Collide con
                        ↓
Personaggio B Hurtbox (Layer 4) → take_damage()
```

### Sistema di Round

#### Regole
- **Durata round**: 99 secondi
- **Vittoria**: Best of 3 rounds
- **Condizioni vittoria**:
  - KO: Vita avversario = 0
  - Timeout: Chi ha più vita vince
  - Draw: Stessa vita allo scadere (nessun vincitore)

#### Sequenza Round
1. **Countdown**: "ROUND X" (1s) → "FIGHT!" (1s)
2. **Combattimento**: 99 secondi di gioco
3. **Vittoria**: "PLAYER X WINS!" (2-3s)
4. **Prossimo Round** o **Fine Match**

### Meccaniche da Implementare (Futuro)

#### Sistema Combo
- **Input Buffer**: 0.1s per collegare attacchi
- **Combo Counter**: Conteggio colpi consecutivi
- **Combo Scaling**: Riduzione danno progressiva
  - 2° colpo: 90% danno
  - 3° colpo: 80% danno
  - 4°+ colpi: 70% danno

#### Special Moves
- **Barra Super**: 0-100 punti
  - Guadagno: +5 per attacco inflitto, +3 per attacco subito
  - Costo mosse speciali: 25-50 punti
- **Input Motion**: 
  - Hadouken: ↓↘→ + Pugno
  - Shoryuken: →↓↘ + Pugno
  - Tatsumaki: ↓↙← + Calcio

#### Advanced Mechanics
- **Canceling**: Annullare recovery con special move
- **Juggle System**: Colpire avversario in aria
- **Throw System**: Presa non bloccabile
- **Parry**: Timing perfetto per contrattaccare
- **EX Moves**: Versione potenziata con costo super

## Riferimenti Frame Data Classici

### Street Fighter Frame Data Tipici

**Jab (Light Punch)**
- Startup: 3-4f
- Active: 2-3f
- Recovery: 5-7f
- Frame Advantage on block: +2 to -2

**Medium Punch**
- Startup: 5-7f
- Active: 3-4f
- Recovery: 8-12f

**Heavy Punch**
- Startup: 8-12f
- Active: 4-6f
- Recovery: 15-20f

### Note di Bilanciamento

1. **Triangolo Attacchi**:
   - Leggeri: Veloci, poco danno, sicuri
   - Medi: Bilanciati
   - Pesanti: Lenti, molto danno, rischiosi

2. **Risk vs Reward**:
   - Attacchi più forti = più rischio se mancano
   - Bloccare attacco pesante = opportunità di contrattacco

3. **Spacing**:
   - Range attacchi diverso per gameplay tattico
   - Pugno: Range corto
   - Calcio: Range medio-lungo

## Formule Utili

### Calcolo Frame da Secondi
```
frame = secondi * 60
secondi = frame / 60
```

### Calcolo Altezza Salto
```
altezza_max = velocità_iniziale² / (2 * gravità)
altezza_max = 850² / (2 * 1400) = 258.0 px
```

### Calcolo Tempo in Aria
```
tempo_totale = 2 * velocità_iniziale / gravità
tempo_totale = 2 * 850 / 1400 = 1.214 s
```

### Scaling Combo
```
danno_combo = danno_base * (0.9 ^ (n-1))
dove n = numero colpo nel combo
```

---

**Note**: Questi valori sono un punto di partenza. Playtest e iterazione sono essenziali per trovare il bilanciamento perfetto!

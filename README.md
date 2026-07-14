# 🥊 Sanmo - Picchiaduro 2D (Godot 4.7)

Un gioco picchiaduro 2D in stile Street Fighter sviluppato con Godot Engine 4.7 e GDScript.

## 📋 Stato del Progetto

### ✅ Funzionalità Implementate

- **Sistema di Movimento Completo**
  - Camminata destra/sinistra
  - Salto con fisica realistica
  - Accovacciamento (crouch)
  - Blocco difensivo

- **Sistema di Combattimento**
  - 4 tipi di attacchi (pugno leggero, pugno pesante, calcio leggero, calcio pesante)
  - Sistema hitbox/hurtbox per rilevamento colpi
  - Sistema di danno con riduzione quando si blocca (80% riduzione)
  - Reazione al colpo con stun temporaneo

- **Sistema di Round**
  - Best of 3 rounds
  - Timer di 99 secondi per round
  - Gestione vittoria per KO o timeout
  - Sistema di vita con barre UI
  - Countdown "FIGHT!" all'inizio del round

- **UI Base**
  - Barre vita per entrambi i giocatori
  - Timer del round
  - Indicatore round corrente
  - Messaggi di vittoria

## 🎮 Controlli

### Player 1

#### Movimento
- **W** o **Freccia Su** o **Spazio**: Salto
- **A** o **Freccia Sinistra**: Movimento a sinistra
- **S** o **Freccia Giù**: Accovacciamento
- **D** o **Freccia Destra**: Movimento a destra

#### Attacchi
- **J**: Pugno Leggero (5 danno, veloce)
- **U**: Pugno Pesante (15 danno, lento)
- **K**: Calcio Leggero (8 danno, medio)
- **I**: Calcio Pesante (20 danno, molto lento)

#### Difesa
- **Direzione opposta all'avversario**: Blocco (riduce danno dell'80%)

#### Debug
- **F3**: Mostra o nasconde corpo fisico, hurtbox e hitbox attive
- **F4**: Attiva o disattiva lo slow motion per osservare le hitbox

### Player 2
*Attualmente usa gli stessi controlli di Player 1 (per testing con 2 giocatori sulla stessa tastiera)*

## 🏗️ Struttura del Progetto

```
Godot/
├── scenes/
│   ├── Fighter.tscn          # Scena del personaggio
│   └── MainArena.tscn        # Scena principale dell'arena
├── scripts/
│   ├── Fighter.gd            # Script del personaggio con movimento e combattimento
│   └── MainArena.gd          # Script di gestione round e match
├── assets/
│   ├── sprites/
│   │   ├── characters/       # Sprite dei personaggi (da aggiungere)
│   │   └── backgrounds/      # Sfondi (da aggiungere)
│   └── sounds/
│       ├── sfx/              # Effetti sonori (da aggiungere)
│       └── music/            # Musica di sottofondo (da aggiungere)
└── ui/                       # Scene UI aggiuntive (future)
```

## 🚀 Come Eseguire

1. Apri il progetto con **Godot Engine 4.7+**
2. Premi **F5** o clicca su "Play" per avviare il gioco
3. La scena principale è `res://scenes/MainArena.tscn`

## 📝 Prossimi Passi Suggeriti

### 🎨 Grafica e Animazioni
- [ ] Aggiungere sprite sheet per i personaggi
- [ ] Creare AnimationPlayer con animazioni per:
  - Idle
  - Camminata
  - Salto
  - Attacchi (x4)
  - Blocco
  - Colpito
  - KO
- [ ] Aggiungere sfondi animati per l'arena
- [ ] Aggiungere effetti particellari per gli attacchi

### 🎵 Audio
- [ ] Suoni degli attacchi (punch, kick)
- [ ] Suoni di impatto quando si colpisce
- [ ] Suoni della voce dei personaggi
- [ ] Musica di sottofondo dell'arena
- [ ] Effetti sonori UI (countdown, KO, vittoria)

### 🤖 Intelligenza Artificiale
- [ ] Implementare IA base per Player 2
- [ ] Sistema di decisioni (quando attaccare, difendere, muoversi)
- [ ] Difficoltà regolabile (facile, normale, difficile)

### ⚔️ Sistema di Combattimento Avanzato
- [ ] Sistema di combo (sequenze di attacchi)
- [ ] Mosse speciali (hadouken style)
- [ ] Super mosse con barra energia
- [ ] Sistema di grab/throw
- [ ] Attacchi aerei
- [ ] Attacchi speciali da accovacciato

### 🎮 Gameplay
- [ ] Menu principale
- [ ] Selezione personaggi (roster multiplo)
- [ ] Modalità storia/arcade
- [ ] Modalità training
- [ ] Sistema di unlock e progressione
- [ ] Replay dei match

### 🌐 Multiplayer
- [ ] Input separati per Player 2
- [ ] Supporto gamepad
- [ ] Multiplayer online (opzionale)

### ⚙️ Sistema e Polish
- [ ] Menu pausa
- [ ] Opzioni (volume, controlli, grafica)
- [ ] Sistema di salvataggio
- [ ] Effetti screen shake
- [ ] Slow motion su colpi critici
- [ ] Transizioni tra scene

## 🔧 Note Tecniche

### Stati del Personaggio
Il personaggio può trovarsi in uno dei seguenti stati:
- `IDLE`: Fermo
- `WALKING`: In movimento
- `JUMPING`: In aria
- `CROUCHING`: Accovacciato
- `ATTACKING`: Eseguendo un attacco
- `BLOCKING`: In difesa
- `HIT`: Colpito (stun)
- `KNOCKED_DOWN`: KO

### Sistema di Collisioni
- **Layer 1**: Personaggi (CollisionShape2D)
- **Layer 2**: Hitbox (attacchi)
- **Layer 4**: Hurtbox (zone vulnerabili)

### Parametri Bilanciamento Attuale
```gdscript
WALK_SPEED = 200.0
JUMP_VELOCITY = -850.0
GRAVITY = 1400.0

Pugno Leggero:  5 danno, 0.3s durata
Pugno Pesante: 15 danno, 0.6s durata
Calcio Leggero:  8 danno, 0.4s durata
Calcio Pesante: 20 danno, 0.7s durata

Blocco: 80% riduzione danno
```

## 📚 Risorse Utili

- [Documentazione Godot 4.7](https://docs.godotengine.org/en/stable/)
- [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
- Tutorial Fighting Games con Godot: Cerca su YouTube "Godot fighting game tutorial"

## 🤝 Contributi

Questo è un progetto didattico. Sentiti libero di espandere e migliorare il codice!

---

**Developed with Godot Engine 4.7** 🎮

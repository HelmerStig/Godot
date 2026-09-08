# Tutorial: Aggiungere Animazioni ai Personaggi

Questa guida ti mostra come aggiungere sprite e animazioni ai tuoi personaggi.

## 📋 Prerequisiti

1. **Sprite Sheet** del personaggio (formato PNG consigliato)
2. **Editor Godot** aperto con il progetto
3. Conoscenza base dell'editor Godot

## 🎨 Formato Sprite Sheet Consigliato

### Struttura Tipica
```
┌─────────────────────────────────────────┐
│ IDLE (4 frame) │ WALK (6 frame)        │
├─────────────────────────────────────────┤
│ JUMP (6 frame) │ CROUCH (2 frame)      │
├─────────────────────────────────────────┤
│ LP (4 frame)   │ HP (6 frame)          │
├─────────────────────────────────────────┤
│ LK (4 frame)   │ HK (6 frame)          │
├─────────────────────────────────────────┤
│ BLOCK (2 f)    │ HIT (3 f) │ KO (5 f) │
└─────────────────────────────────────────┘
```

### Dimensioni Consigliate
- **Singolo frame**: 64x64 px o 128x128 px
- **Sprite sheet totale**: Dipende dal numero di frame
- **Risoluzione**: Pixel art (low-res) o HD (consigliato 2x scale)

## 🛠️ Step 1: Importare lo Sprite Sheet

1. **Copia** il file PNG in `assets/sprites/characters/`
   ```
   assets/sprites/characters/ryu_spritesheet.png
   ```

2. **Apri Godot** e naviga alla cartella nel FileSystem
3. **Clicca** sullo sprite importato per vedere le impostazioni
4. In **Import** (pannello destro), imposta:
   - **Filter**: `Nearest` (per pixel art) o `Linear` (per sprite smooth)
   - **Repeat**: `Disabled`
   - Clicca **Reimport**

## 🎬 Step 2: Configurare AnimatedSprite2D

### Opzione A: Sprite Sheet con Frame Uniformi

1. **Apri** `scenes/Fighter.tscn`
2. **Elimina** il nodo `Sprite2D/ColorRect` placeholder
3. **Aggiungi** nodo figlio a `Fighter`: `AnimatedSprite2D`
4. Nel pannello **Inspector** di `AnimatedSprite2D`:
   - Clicca **SpriteFrames** → **New SpriteFrames**
   - Clicca sulla risorsa creata per aprire l'editor

5. **Nell'editor SpriteFrames**:
   - Clicca **Add Animation** per ogni animazione necessaria:
     - `idle`
     - `walk`
     - `jump`
     - `crouch`
     - `light_punch`
     - `heavy_punch`
     - `light_kick`
     - `heavy_kick`
     - `block`
     - `hit`
     - `ko`

6. **Per ogni animazione**:
   - Seleziona l'animazione dalla lista
   - Clicca l'icona **Add frames from sprite sheet**
   - Seleziona il tuo sprite sheet
   - Imposta **Horizontal** e **Vertical** frame count
   - Seleziona i frame dell'animazione
   - Clicca **Add X Frame(s)**

7. **Imposta FPS** per ogni animazione (pannello sopra):
   - `idle`: 8 FPS
   - `walk`: 12 FPS
   - `jump`: 10 FPS
   - Attacchi: 15-20 FPS

### Opzione B: Sprite Separati

Se hai sprite individuali invece di uno sprite sheet:

1. Segui step 1-5 sopra
2. Per ogni frame, clicca **Add Frame** e seleziona l'immagine
3. Procedi con gli altri step

## 🔧 Step 3: Modificare lo Script Fighter.gd

### Aggiornare i Riferimenti

Cerca questa linea:
```gdscript
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
```

Sostituisci con:
```gdscript
@onready var animated_sprite = $AnimatedSprite2D
```

### Aggiungere Sistema di Animazioni

Aggiungi questo metodo dopo `update_facing_direction()`:

```gdscript
func update_animation():
	"""Aggiorna l'animazione in base allo stato"""
	if not animated_sprite:
		return
	
	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
		State.WALKING:
			animated_sprite.play("walk")
		State.JUMPING:
			if velocity.y < 0:
				animated_sprite.play("jump")
			else:
				animated_sprite.play("fall")  # Se hai animazione fall
		State.CROUCHING:
			animated_sprite.play("crouch")
		State.ATTACKING:
			# Gestito nel perform_attack()
			pass
		State.BLOCKING:
			animated_sprite.play("block")
		State.HIT:
			animated_sprite.play("hit")
		State.KNOCKED_DOWN:
			animated_sprite.play("ko")
```

### Chiamare update_animation

Nel metodo `_physics_process()`, aggiungi prima di `move_and_slide()`:
```gdscript
# Aggiorna animazione
update_animation()
```

### Aggiornare flip_character()

Modifica il metodo per usare AnimatedSprite2D:
```gdscript
func flip_character():
	"""Inverte la direzione del personaggio"""
	is_facing_right = !is_facing_right
	if animated_sprite:
		animated_sprite.flip_h = !is_facing_right
```

### Animazioni Attacchi

Collega il segnale pubblico `attack_started` di `Mangler` e usa l'identificatore proveniente da `AttackData`:
```gdscript
func _ready() -> void:
	attack_started.connect(_on_attack_started)


func _on_attack_started(attack_name: StringName) -> void:
	if animated_sprite:
		animated_sprite.play(attack_name)
```

## 🎯 Step 4: Test e Regolazioni

1. **Salva** tutto (Ctrl+S)
2. **Esegui** la scena (F6 per scena corrente, F5 per progetto)
3. **Verifica**:
   - Le animazioni si riproducono correttamente
   - Il flip orizzontale funziona
   - Le transizioni sono fluide

### Common Issues

**Animazioni non si vedono:**
- Controlla che `AnimatedSprite2D` sia figlio diretto di `Fighter`
- Verifica che le animazioni siano nominate correttamente
- Controlla l'offset dello sprite (potrebbe essere fuori schermo)

**Animazioni troppo veloci/lente:**
- Regola FPS nell'editor SpriteFrames
- Valori tipici: 8-12 FPS per idle/walk, 15-20 FPS per attacchi

**Sprite capovolto al contrario:**
- Inverti la logica in `flip_character()`:
  ```gdscript
  animated_sprite.flip_h = is_facing_right  # Invece di !is_facing_right
  ```

## 🎨 Risorse Sprite Gratuite

### Siti Consigliati
- **OpenGameArt.org**: Arte libera per giochi
- **Itch.io**: Molti asset gratuiti/pagamento volontario
- **Kenney.nl**: Asset gratuiti di alta qualità
- **Craftpix.net**: Sprite sheet per fighting games

### Keywords Ricerca
- "fighting game sprite sheet"
- "beat em up character sprite"
- "pixel art fighter"
- "2d fighting game assets"

### Strumenti per Creare Sprite
- **Aseprite**: Editor pixel art professionale (€)
- **Piskel**: Editor pixel art gratuito online
- **Krita**: Gratuito, ottimo per digital painting
- **GIMP**: Gratuito, editing generale

## 📊 Esempio Configurazione Completa

```gdscript
# Fighter.gd - Sezione animazioni aggiornata

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# ... codice esistente ...
	if animated_sprite:
		animated_sprite.play("idle")

func update_animation():
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	match current_state:
		State.IDLE:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")
		State.WALKING:
			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")
		State.JUMPING:
			if velocity.y < 0:
				if animated_sprite.animation != "jump":
					animated_sprite.play("jump")
		State.CROUCHING:
			if animated_sprite.animation != "crouch":
				animated_sprite.play("crouch")
		State.BLOCKING:
			if animated_sprite.animation != "block":
				animated_sprite.play("block")
		State.HIT:
			if animated_sprite.animation != "hit":
				animated_sprite.play("hit")
		State.KNOCKED_DOWN:
			if animated_sprite.animation != "ko":
				animated_sprite.play("ko")

func flip_character():
	is_facing_right = !is_facing_right
	if animated_sprite:
		animated_sprite.flip_h = !is_facing_right
```

## ✅ Checklist Finale

- [ ] Sprite sheet importato in `assets/sprites/characters/`
- [ ] AnimatedSprite2D aggiunto alla scena Fighter
- [ ] Tutte le animazioni configurate in SpriteFrames
- [ ] Script aggiornato con riferimenti AnimatedSprite2D
- [ ] Metodo `update_animation()` implementato
- [ ] `flip_character()` aggiornato
- [ ] Animazioni attacchi collegate in `perform_attack()`
- [ ] Test completo del movimento e attacchi
- [ ] FPS animazioni regolati

## 🚀 Prossimi Passi

Dopo le animazioni, puoi:
1. **Aggiungere effetti particellari** per gli attacchi
2. **Creare più personaggi** con sprite diversi
3. **Implementare mosse speciali** con animazioni uniche
4. **Aggiungere audio** sincronizzato con le animazioni

---

**Buon lavoro con le animazioni! 🎮✨**

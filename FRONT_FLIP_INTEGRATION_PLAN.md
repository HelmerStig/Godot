# Piano di Integrazione: Front-Flip Animation per Mangler

**Data creazione:** 2026-07-16  
**Target personaggio:** Mangler  
**Tipo animazione:** Forward Jump Somersault (one-shot, non-looping)  
**Tool pipeline:** AutoSprite.io → Godot 4.7

---

## 📋 Overview

Integrazione di un'animazione di salto con capriola in avanti (front-flip) per Mangler, attivabile tramite doppio-tap del comando salto. L'animazione sarà generata con AutoSprite.io e integrata nel sistema di stati esistente.

---

## FASE 1: Generazione con AutoSprite ✨

### Prompt AutoSprite

**File sorgente:** `Untitled-3` (già preparato)

**Specifiche tecniche:**
- **Canvas size:** 1024×1024 con padding generoso
- **Cell size target:** 512×512 (per consistenza con altri sprite)
- **Frame count:** 8-12 frame (da confermare post-generazione)
- **Rotation:** Esattamente 360° clockwise, pivot su pelvis/hip
- **Camera:** Fixed side-view, no translation
- **Character:** Face right, preserva identity/proportions/colors
- **Loop:** Primo frame = ultimo frame (stance identica)

**Key constraints:**
- ✅ No horizontal/vertical translation (movimento in-place)
- ✅ No perspective change o back view
- ✅ No kicks, attacks, o rotazioni extra
- ✅ No body deformation o scale changes
- ✅ Transparent background
- ✅ All body parts dentro frame boundaries

**Negative prompt suggerito:**
```
sliding feet, horizontal drift, vertical movement, camera rotation, 
perspective changes, scale changes, background, baked shadows, 
multiple rotations, kicks, attacks, stretched limbs, deformed body, 
cropped limbs, character back view, off-center composition
```

### Output atteso

```
assets/sprites/characters/mangler/
├── front-flip.png              ← Nuovo spritesheet generato
└── front-flip.png.import       ← Auto-generato da Godot
```

**Configurazione import Godot:**
- **Filter:** `Nearest` (pixel art consistency)
- **Compression:** `Lossless` o `VRAM Uncompressed`
- **Mipmaps:** `Disabled`
- **Repeat:** `Disabled`

---

## FASE 2: Configurazione SpriteFrames 🎨

### Resource da modificare

**File:** `assets/sprites/characters/mangler/idle_frames.tres`

### Nuova animazione da aggiungere

**Nome:** `front_flip`

**Parametri:**
- **Frame count:** 8-12 (verificare dopo import)
- **FPS:** 24 (più veloce di idle/walk/jump)
- **Loop:** `false` (one-shot animation)
- **Grid slicing:** Auto-detect o manual 512×512

**Procedura Godot Editor:**
1. Apri `idle_frames.tres` in SpriteFrames editor
2. Click "Add Animation" → Nome: `front_flip`
3. Click "Add frames from sprite sheet"
4. Seleziona `front-flip.png`
5. Configure grid: Horizontal × Vertical frames
6. Seleziona tutti i frame della sequenza
7. Set FPS a 24
8. Disabilita "Loop"
9. Salva resource

---

## FASE 3: Modifiche al Codice 🔧

### File da modificare: `scripts/Mangler.gd`

---

#### **A. Estendere State enum** (linea ~12)

```gdscript
enum State {
    IDLE,
    WALKING,
    RUNNING,
    JUMP_STARTUP,
    JUMPING,
    JUMPING_FLIP,      # ← NUOVO: Stato per salto con capriola
    CROUCHING,
    STANDING_UP,
    ATTACKING,
    BLOCKING,
    HIT,
    KNOCKED_DOWN
}
```

**Rationale:** Separare `JUMPING_FLIP` da `JUMPING` permette di gestire animazione e fisica differenziate.

---

#### **B. Aggiungere costanti** (dopo linea ~35)

```gdscript
const JUMP_TAKEOFF_FRAME := 11        # Frame stacco salto normale
const FLIP_TAKEOFF_FRAME := 8         # ← NUOVO: Stacco anticipato per front-flip
const FLIP_INPUT_WINDOW := 10         # ← NUOVO: Frame window per doppio-tap (0.167s @ 60fps)
```

**Rationale:** 
- Front-flip ha preparazione più corta (frame 8 vs 11)
- Window di 10 frame (~167ms) è standard per double-tap in fighting games

---

#### **C. Aggiungere variabili di stato** (dopo linea ~76)

```gdscript
var pending_jump_direction := 0.0
var last_jump_press_frame := -FLIP_INPUT_WINDOW - 1  # ← NUOVO: Tracking doppio-tap
var use_flip_animation := false                      # ← NUOVO: Flag per front-flip
```

**Rationale:** Tracking temporale per rilevare input sequenziali rapidi.

---

#### **D. Modificare `handle_input()`** (linea ~157)

**PRIMA:**
```gdscript
if Input.is_action_just_pressed(get_input_action("jump")) and is_on_floor():
    start_jump(input_buffer.get_horizontal_axis())
    return
```

**DOPO:**
```gdscript
if Input.is_action_just_pressed(get_input_action("jump")) and is_on_floor():
    var current_frame := Engine.get_physics_frames()
    use_flip_animation = (current_frame - last_jump_press_frame <= FLIP_INPUT_WINDOW)
    last_jump_press_frame = current_frame
    start_jump(input_buffer.get_horizontal_axis())
    return
```

**Rationale:** Rileva doppio-tap confrontando timestamp input corrente con ultimo press.

---

#### **E. Modificare `start_jump()`** (linea ~180)

**PRIMA:**
```gdscript
func start_jump(horizontal_direction: float) -> void:
    """Riproduce la preparazione e memorizza la direzione scelta allo stacco."""
    pending_jump_direction = signf(horizontal_direction)
    velocity = Vector2.ZERO
    change_state(State.JUMP_STARTUP)
    if not animated_sprite.sprite_frames.has_animation(&"jump"):
        begin_jump_ascent()
```

**DOPO:**
```gdscript
func start_jump(horizontal_direction: float) -> void:
    """Riproduce la preparazione e memorizza la direzione scelta allo stacco."""
    pending_jump_direction = signf(horizontal_direction)
    velocity = Vector2.ZERO
    change_state(State.JUMP_STARTUP)
    
    # Seleziona animazione basata su doppio-tap
    var anim_name := &"front_flip" if use_flip_animation else &"jump"
    if not animated_sprite.sprite_frames.has_animation(anim_name):
        begin_jump_ascent()
    # L'animazione verrà avviata da update_animation() dopo change_state
```

**Rationale:** Scelta dinamica tra salto normale e front-flip.

---

#### **F. Modificare `begin_jump_ascent()`** (linea ~189)

**PRIMA:**
```gdscript
func begin_jump_ascent() -> void:
    """Applica l'impulso quando l'animazione raggiunge il dodicesimo frame."""
    if current_state != State.JUMP_STARTUP:
        return
    velocity = Vector2(
        pending_jump_direction * character_data.air_speed,
        character_data.jump_velocity
    )
    change_state(State.JUMPING)
```

**DOPO:**
```gdscript
func begin_jump_ascent() -> void:
    """Applica l'impulso quando l'animazione raggiunge il frame di stacco."""
    if current_state != State.JUMP_STARTUP:
        return
    velocity = Vector2(
        pending_jump_direction * character_data.air_speed,
        character_data.jump_velocity
    )
    var next_state := State.JUMPING_FLIP if use_flip_animation else State.JUMPING
    change_state(next_state)
```

**Rationale:** Transizione allo stato corretto dopo stacco.

---

#### **G. Modificare `change_state()`** (linea ~200)

**Aggiungere nel match statement:**

```gdscript
match current_state:
    State.IDLE, State.WALKING, State.RUNNING, State.JUMPING, State.JUMPING_FLIP:  # ← Aggiungere JUMPING_FLIP
        can_move = true
    # ... resto del match ...
```

**Rationale:** `JUMPING_FLIP` ha stesso comportamento di `JUMPING` per movimento.

---

#### **H. Modificare `update_animation()`** (linea ~225)

**Aggiungere dopo gestione jump:**

```gdscript
# JUMP_STARTUP e JUMPING sono due fasi fisiche della stessa animazione.
if current_state == State.JUMPING and animated_sprite.animation == &"jump":
    return

# ← NUOVO: Gestione front-flip
if current_state == State.JUMPING_FLIP and animated_sprite.animation == &"front_flip":
    return

var next_animation: StringName = &"idle"
# ... resto del codice ...

# ← NUOVO: Selezione animazione front-flip
elif (
    current_state in [State.JUMP_STARTUP, State.JUMPING]
    and animated_sprite.sprite_frames.has_animation(&"jump")
):
    next_animation = &"jump"
elif (
    current_state == State.JUMPING_FLIP
    and animated_sprite.sprite_frames.has_animation(&"front_flip")
):
    next_animation = &"front_flip"
```

**Rationale:** Previene restart dell'animazione ogni frame durante la rotazione.

---

#### **I. Modificare `_on_animation_frame_changed()`** (linea ~451)

**PRIMA:**
```gdscript
func _on_animation_frame_changed() -> void:
    if animated_sprite.animation == &"crouch":
        update_collision_profile()
    elif (
        animated_sprite.animation == &"jump"
        and current_state == State.JUMP_STARTUP
        and animated_sprite.frame >= JUMP_TAKEOFF_FRAME
    ):
        begin_jump_ascent()
```

**DOPO:**
```gdscript
func _on_animation_frame_changed() -> void:
    if animated_sprite.animation == &"crouch":
        update_collision_profile()
    elif current_state == State.JUMP_STARTUP:
        # Determina frame di stacco basato su animazione attiva
        var takeoff_frame := FLIP_TAKEOFF_FRAME if use_flip_animation else JUMP_TAKEOFF_FRAME
        var current_anim := animated_sprite.animation
        if (
            (current_anim == &"front_flip" or current_anim == &"jump")
            and animated_sprite.frame >= takeoff_frame
        ):
            begin_jump_ascent()
```

**Rationale:** Frame di stacco diverso per front-flip (8) vs salto normale (11).

---

#### **J. Modificare `_on_animation_finished()`** (linea ~445)

**PRIMA:**
```gdscript
func _on_animation_finished() -> void:
    if current_state == State.STANDING_UP and animated_sprite.animation == &"crouch":
        change_state(State.IDLE)
```

**DOPO:**
```gdscript
func _on_animation_finished() -> void:
    if current_state == State.STANDING_UP and animated_sprite.animation == &"crouch":
        change_state(State.IDLE)
    elif current_state == State.JUMPING_FLIP and animated_sprite.animation == &"front_flip":
        # Capriola completata, transizione a caduta libera
        change_state(State.JUMPING)
        use_flip_animation = false  # Reset flag
```

**Rationale:** Dopo 360° rotazione, ritorna a falling state standard.

---

#### **K. Modificare `update_state()`** (linea ~260)

**Aggiungere `State.JUMPING_FLIP` nei check:**

```gdscript
func update_state() -> void:
    if current_state == State.JUMP_STARTUP:
        return
    if current_state in [
        State.STANDING_UP,
        State.ATTACKING,
        State.BLOCKING,
        State.HIT,
        State.KNOCKED_DOWN,
    ]:
        return

    if not is_on_floor():
        # ← MODIFICA: Non sovrascrivere se già in JUMPING_FLIP
        if current_state not in [State.JUMPING, State.JUMPING_FLIP]:
            change_state(State.JUMPING)
    elif current_state in [State.JUMPING, State.JUMPING_FLIP] and velocity.y >= 0.0:  # ← Aggiungere JUMPING_FLIP
        velocity.x = 0.0
        change_state(State.IDLE)
    elif is_zero_approx(velocity.x) and current_state in [State.WALKING, State.RUNNING]:
        change_state(State.IDLE)
```

**Rationale:** Preserva stato `JUMPING_FLIP` durante rotazione, gestisce atterraggio.

---

#### **L. Modificare `reset_fighter()`** (linea ~390)

**Aggiungere reset flag:**

```gdscript
func reset_fighter(spawn_position: Vector2) -> void:
    position = spawn_position
    velocity = Vector2.ZERO
    shadow_ground_y = spawn_position.y
    last_forward_tap_frame = -RUN_DOUBLE_TAP_WINDOW_FRAMES - 1
    pending_jump_direction = 0.0
    use_flip_animation = false                                    # ← NUOVO
    last_jump_press_frame = -FLIP_INPUT_WINDOW - 1               # ← NUOVO
    combat.reset()
    change_state(State.IDLE)
    can_move = true
    if input_buffer != null:
        input_buffer.clear()
    update_ground_shadow()
```

**Rationale:** Pulizia completa stato per reset training.

---

## FASE 4: Testing & Validation ✅

### Test Manuali

#### Test Case 1: Salto Normale
**Input:** Singolo tap `Spazio` (o `W`)  
**Atteso:**
- ✅ Animazione `jump` attivata
- ✅ Stato `JUMPING` (non `JUMPING_FLIP`)
- ✅ Stacco al frame 11
- ✅ Atterraggio normale

#### Test Case 2: Front-Flip
**Input:** Doppio tap `Spazio` entro 10 frame (~167ms)  
**Atteso:**
- ✅ Animazione `front_flip` attivata
- ✅ Stato `JUMPING_FLIP`
- ✅ Stacco al frame 8 (più veloce)
- ✅ Rotazione 360° completa
- ✅ Transizione a `JUMPING` al termine
- ✅ Atterraggio normale

#### Test Case 3: Window Timeout
**Input:** Doppio tap `Spazio` con delay > 10 frame  
**Atteso:**
- ✅ Secondo tap innesca salto normale (no flip)
- ✅ Nessun front-flip attivato

#### Test Case 4: Loop Check
**Visual:**
- ✅ Primo frame = stance neutrale
- ✅ Ultimo frame = stance identica
- ✅ Nessun "pop" o discontinuità nel loop

#### Test Case 5: Direzionalità
**Input:** Front-flip + direzionale forward/back  
**Atteso:**
- ✅ Direzione impostata al momento dello stacco
- ✅ Nessun cambio direzione in aria
- ✅ Atterraggio con facing corretto

#### Test Case 6: Collision
**Check:**
- ✅ Hurtbox rimane attiva durante rotazione
- ✅ Può essere colpito durante front-flip
- ✅ Pushbox disabilitata in aria (attraversamento)
- ✅ Ground collision attiva

---

### Smoke Tests Automatici

**File da modificare:** `tests/smoke_tests.gd`

#### Nuovo Test 1: Animazione Exists

```gdscript
func test_front_flip_animation_exists() -> void:
    assert_true(
        fighter.animated_sprite.sprite_frames.has_animation(&"front_flip"),
        "Front-flip animation deve esistere in SpriteFrames"
    )
    var frame_count := fighter.animated_sprite.sprite_frames.get_frame_count(&"front_flip")
    assert_true(
        frame_count >= 8 and frame_count <= 12,
        "Front-flip deve avere 8-12 frame, trovati: " + str(frame_count)
    )
```

#### Nuovo Test 2: Double-Tap Detection

```gdscript
func test_front_flip_double_tap_detection() -> void:
    fighter.reset_fighter(Vector2(100, 0))
    await get_tree().process_frame
    
    # Primo tap
    fighter.record_input_snapshot({"jump": true}, 0.0, 0.0)
    await get_tree().process_frame
    fighter.record_input_snapshot({}, 0.0, 0.0)
    
    # Breve delay (5 frame, entro window)
    for i in range(5):
        await get_tree().process_frame
    
    # Secondo tap
    fighter.record_input_snapshot({"jump": true}, 0.0, 0.0)
    await get_tree().process_frame
    
    assert_true(
        fighter.use_flip_animation,
        "Doppio tap entro window deve attivare flip"
    )
    assert_equal(
        fighter.current_state,
        Mangler.State.JUMP_STARTUP,
        "Deve essere in JUMP_STARTUP dopo doppio tap"
    )
```

#### Nuovo Test 3: Single-Tap Normal Jump

```gdscript
func test_front_flip_single_tap_normal_jump() -> void:
    fighter.reset_fighter(Vector2(100, 0))
    await get_tree().process_frame
    
    # Singolo tap
    fighter.record_input_snapshot({"jump": true}, 0.0, 0.0)
    await get_tree().process_frame
    
    assert_false(
        fighter.use_flip_animation,
        "Singolo tap NON deve attivare flip"
    )
```

#### Nuovo Test 4: Window Timeout

```gdscript
func test_front_flip_window_timeout() -> void:
    fighter.reset_fighter(Vector2(100, 0))
    await get_tree().process_frame
    
    # Primo tap
    fighter.record_input_snapshot({"jump": true}, 0.0, 0.0)
    await get_tree().process_frame
    fighter.record_input_snapshot({}, 0.0, 0.0)
    
    # Delay oltre window (15 frame)
    for i in range(15):
        await get_tree().process_frame
    
    # Secondo tap
    fighter.record_input_snapshot({"jump": true}, 0.0, 0.0)
    await get_tree().process_frame
    
    assert_false(
        fighter.use_flip_animation,
        "Doppio tap oltre window NON deve attivare flip"
    )
```

#### Nuovo Test 5: Animation Transition

```gdscript
func test_front_flip_animation_transition() -> void:
    fighter.reset_fighter(Vector2(100, 0))
    fighter.use_flip_animation = true
    await get_tree().process_frame
    
    # Avvia salto
    fighter.record_input_snapshot({"jump": true}, 0.0, 0.0)
    await get_tree().process_frame
    
    # Aspetta stacco (8+ frame)
    for i in range(10):
        await get_tree().process_frame
    
    assert_equal(
        fighter.current_state,
        Mangler.State.JUMPING_FLIP,
        "Deve essere in JUMPING_FLIP dopo stacco"
    )
    assert_equal(
        fighter.animated_sprite.animation,
        &"front_flip",
        "Animazione deve essere front_flip"
    )
```

#### Nuovo Test 6: Reset Cleanup

```gdscript
func test_front_flip_reset_cleanup() -> void:
    fighter.use_flip_animation = true
    fighter.last_jump_press_frame = 100
    
    fighter.reset_fighter(Vector2(100, 0))
    
    assert_false(
        fighter.use_flip_animation,
        "Reset deve disabilitare flip flag"
    )
    assert_true(
        fighter.last_jump_press_frame < -Mangler.FLIP_INPUT_WINDOW,
        "Reset deve invalidare last jump timestamp"
    )
```

**Target totale test dopo integrazione:** 59 test (53 esistenti + 6 nuovi)

---

### Esecuzione Smoke Tests

**Windows:**
```powershell
.\tests\run_smoke_tests.cmd
```

**Cross-platform:**
```bash
godot --headless --path . --script res://tests/smoke_tests.gd
```

**Successo atteso:**
```
SMOKE_TESTS_OK
Exit Code: 0
```

---

## FASE 5: Checklist Pre-Deploy 📋

### Generazione & Import

- [ ] Spritesheet generato da AutoSprite.io
- [ ] File salvato come `front-flip.png` (512×512 cells)
- [ ] Import settings configurati (Nearest filter, no mipmaps)
- [ ] Frame count verificato (8-12 frame)
- [ ] Primo/ultimo frame visivamente identici

### SpriteFrames Configuration

- [ ] Animazione `front_flip` aggiunta a `idle_frames.tres`
- [ ] Frame slicing corretto (tutti frame visibili)
- [ ] FPS impostato a 24
- [ ] Loop disabilitato
- [ ] Preview animation funzionante in editor

### Code Integration

- [ ] `State.JUMPING_FLIP` aggiunto a enum
- [ ] Costanti `FLIP_TAKEOFF_FRAME` e `FLIP_INPUT_WINDOW` definite
- [ ] Variabili `use_flip_animation` e `last_jump_press_frame` aggiunte
- [ ] `handle_input()` implementa double-tap detection
- [ ] `start_jump()` seleziona animazione corretta
- [ ] `begin_jump_ascent()` transizione a stato corretto
- [ ] `change_state()` include `JUMPING_FLIP` nei match
- [ ] `update_animation()` gestisce `front_flip`
- [ ] `_on_animation_frame_changed()` usa frame stacco corretto
- [ ] `_on_animation_finished()` transizione da flip a falling
- [ ] `update_state()` preserva `JUMPING_FLIP` state
- [ ] `reset_fighter()` pulisce flag flip

### Testing

- [ ] Smoke test compilano senza errori
- [ ] 6 nuovi test front-flip passano
- [ ] Tutti 59 test (53+6) passano
- [ ] Test manuale: singolo tap → salto normale
- [ ] Test manuale: doppio tap → front-flip
- [ ] Test manuale: window timeout funziona
- [ ] Visual check: loop perfetto
- [ ] Visual check: rotazione fluida 360°
- [ ] Collision check: hurtbox attiva
- [ ] Direction check: facing corretto
- [ ] Performance: nessun frame drop
- [ ] No regressioni su funzionalità esistenti

### Documentation

- [ ] `PROJECT_MEMORY.md` aggiornato con front-flip
- [ ] `FRAME_DATA.md` aggiornato con timing flip
- [ ] Questo piano archiviato per reference

---

## 📊 Metriche Attese

### Performance

| Metrica | Valore | Note |
|---------|--------|------|
| Frame count | 8-12 | Da confermare post-generazione |
| FPS | 24 | 50% più veloce di idle (16 FPS) |
| Durata totale | ~0.33-0.50s | (8-12 frame) / 24 FPS |
| Takeoff frame | 8 | Frame 0-indexed |
| Tempo a takeoff | ~0.33s | 8 frame @ 24 FPS |
| Double-tap window | 10 frame | ~0.167s @ 60 FPS engine |
| Input latency | 1-2 frame | Standard fighting game |

### Visual

| Aspetto | Specifica |
|---------|-----------|
| Rotazione | Esattamente 360° clockwise |
| Pivot point | Hip/pelvis fisso al centro canvas |
| Camera | Side-view statico, no parallax |
| Body pose | Compatto al center frame, esteso a inizio/fine |
| Silhouette | Sempre leggibile, no cropping |
| Loop | Seamless (primo = ultimo frame) |
| Translation | Zero (movimento gestito da Godot physics) |

### Gameplay

| Feature | Comportamento |
|---------|---------------|
| Activation | Doppio tap salto entro 0.167s |
| Direction | Impostata al takeoff, immutabile in aria |
| Vulnerability | Hurtbox attiva, può essere colpito |
| Collision | Pushbox disabilitata (attraversamento) |
| Cancel | Non cancellabile una volta iniziato |
| Air control | Nessuno (come salto normale) |
| Atterraggio | Identico a salto normale |

---

## 🚀 Workflow Automatico (con API key)

Una volta configurata `AUTOSPRITE_API_KEY`, il processo diventa:

```
1. User: "Genera front-flip per Mangler"
   ↓
2. Agent: Carica prompt da Untitled-3
   ↓
3. Agent: Chiama AutoSprite API
   ├─ Prompt: Front-flip specs
   ├─ Character: Mangler (existing o new)
   └─ Settings: 512×512, 8-12 frame, 24 FPS
   ↓
4. Agent: Poll job status fino a completion
   ↓
5. Agent: Download spritesheet
   └─ Salva in: assets/sprites/characters/mangler/front-flip.png
   ↓
6. Agent: Integra in SpriteFrames
   ├─ Slice frames (auto-detect grid)
   ├─ Set FPS a 24
   └─ Disabilita loop
   ↓
7. Agent: Applica code changes
   └─ Multi-replace tutte le modifiche in Mangler.gd
   ↓
8. Agent: Aggiorna smoke tests
   └─ Aggiungi 6 nuovi test
   ↓
9. Agent: Esegui smoke test
   └─ .\tests\run_smoke_tests.cmd
   ↓
10. Agent: Launch headless test
    └─ 240 frame in-game simulation
    ↓
11. Agent: Report
    ├─ Credits consumati
    ├─ File modificati
    ├─ Test results
    ├─ Screenshot/video (se disponibile)
    └─ Next steps
```

**Tempo stimato:** 3-5 minuti end-to-end (95% automatico)

---

## 🔄 Rollback Plan

In caso di problemi gravi post-integrazione:

### Rollback Codice (Git)

```bash
# Assumendo commit pre-flip sia l'HEAD~1
git revert HEAD
git commit -m "Rollback: Front-flip integration"
```

### Rollback Manuale

1. Rimuovi `front-flip.png` da `assets/sprites/characters/mangler/`
2. Rimuovi animazione `front_flip` da `idle_frames.tres`
3. Ripristina `Mangler.gd` alla versione precedente:
   - Rimuovi `State.JUMPING_FLIP`
   - Rimuovi costanti `FLIP_*`
   - Rimuovi variabili `use_flip_animation`, `last_jump_press_frame`
   - Ripristina funzioni modificate
4. Rimuovi test front-flip da `smoke_tests.gd`
5. Riesegui smoke test per conferma

---

## 📝 Note Tecniche

### Perché doppio-tap invece di comando dedicato?

- ✅ **Ergonomia:** Non occupa tasto aggiuntivo
- ✅ **Familiarità:** Comune in fighting game (es. dash in KOF)
- ✅ **Skill ceiling:** Richiede timing preciso (0.167s window)
- ✅ **Backward compatibility:** Gamepad e tastiera supportano già

### Perché stato separato `JUMPING_FLIP`?

- ✅ **Animazione diversa:** `front_flip` vs `jump`
- ✅ **Timing diverso:** Frame stacco 8 vs 11
- ✅ **Estendibilità:** Futuro supporto per attacchi aerei specifici
- ✅ **Debug:** Più facile tracciare stato in overlay

### Perché non looping?

- ✅ **Realism:** Una capriola è un'azione discreta
- ✅ **Control:** Physics di Godot gestisce falling dopo rotazione
- ✅ **Consistency:** Come altri state transitions (crouch, stand-up)

### Considerazioni future

#### Possibili estensioni:
- **Attacco aereo durante flip:** Input comando durante `JUMPING_FLIP` → nuovo stato `AIR_ATTACK`
- **Direzione variabile:** Forward-flip vs backward-flip (doppio tap back+jump)
- **EX version:** Spendi meter per flip invulnerabile
- **Landing options:** Direzione input durante landing → slide/roll

#### Performance optimization:
- Se front-flip diventa comune, pre-cache texture in VRAM
- Considera sprite atlas dedicato per animazioni aeree
- Profile physics step durante rotazione (interpolazione hurtbox?)

---

## 📚 Riferimenti

### File di progetto chiave

- [PROJECT_MEMORY.md](PROJECT_MEMORY.md) - Stato corrente progetto
- [FRAME_DATA.md](FRAME_DATA.md) - Frame data tutti attacchi/animazioni
- [TUTORIAL_ANIMAZIONI.md](TUTORIAL_ANIMAZIONI.md) - Guida import sprite
- [scripts/Mangler.gd](scripts/Mangler.gd) - Fighter controller
- [tests/smoke_tests.gd](tests/smoke_tests.gd) - Test suite

### Skill & Pipeline

- [.agents/skills/sanmo-autosprite-pipeline/SKILL.md](.agents/skills/sanmo-autosprite-pipeline/SKILL.md)
- [.codex/config.toml](.codex/config.toml) - MCP server config

### External

- AutoSprite.io: https://www.autosprite.io/app
- Godot AnimatedSprite2D docs: https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html
- Fighting game frame data reference: https://wiki.supercombo.gg/

---

## ✅ Sign-off

**Piano creato:** 2026-07-16  
**Ultima revisione:** 2026-07-16  
**Status:** Ready for implementation  
**Blockers:** AUTOSPRITE_API_KEY non configurata  

**Next immediate action:**
1. Configura `AUTOSPRITE_API_KEY` in environment
2. Riavvia VS Code per caricare variabile
3. Esegui: "Genera front-flip per Mangler usando il prompt Untitled-3"
4. Agent procederà automaticamente con tutto il workflow

---

*Fine del documento*

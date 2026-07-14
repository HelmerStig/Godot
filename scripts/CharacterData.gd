extends Resource
class_name CharacterData

## Risorsa per configurare i dati di un personaggio
## Facilita la creazione di un roster multiplo

# === INFORMAZIONI GENERALI ===
@export var character_name: String = "Fighter"
@export var display_name: String = "Fighter"
@export_multiline var description: String = "Un combattente generico"

# === STATISTICHE ===
@export_group("Stats")
@export var max_health: int = 100
@export var walk_speed: float = 200.0
@export var air_speed: float = 280.0
@export var jump_velocity: float = -850.0

# === ATTACCHI ===
@export_group("Light Attacks")
@export var light_punch_damage: int = 5
@export var light_punch_duration: float = 0.3
@export var light_kick_damage: int = 8
@export var light_kick_duration: float = 0.4

@export_group("Heavy Attacks")
@export var heavy_punch_damage: int = 15
@export var heavy_punch_duration: float = 0.6
@export var heavy_kick_damage: int = 20
@export var heavy_kick_duration: float = 0.7

# === SPRITE E ANIMAZIONI ===
@export_group("Visuals")
@export var sprite_sheet: Texture2D
@export var sprite_scale: Vector2 = Vector2(1.0, 1.0)
@export var sprite_offset: Vector2 = Vector2.ZERO

# === AUDIO ===
@export_group("Audio")
@export var voice_attack_light: AudioStream
@export var voice_attack_heavy: AudioStream
@export var voice_hit: AudioStream
@export var voice_ko: AudioStream
@export var voice_win: AudioStream

# === MOSSE SPECIALI (futuro) ===
@export_group("Special Moves")
@export var has_projectile: bool = false
@export var projectile_damage: int = 10
@export var special_move_cost: int = 25  # Costo in energia


## Crea un CharacterData di default
static func create_default() -> CharacterData:
	var data = CharacterData.new()
	data.character_name = "Mangler"
	data.display_name = "Mangler"
	data.description = "Un potente combattente con mosse devastanti"
	return data

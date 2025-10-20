extends Node

# === WORLD STATE ===
var world: World = null
var regions: Dictionary = {}  # region_id -> Region
var nations: Dictionary = {}  # nation_id -> Nation
var provinces: Dictionary = {}  # province_id -> Province
var districts: Dictionary = {}  # district_id -> District
var characters: Dictionary = {}  # character_id -> Character

# === PLAYER STATE ===
var player_nation_id: String = ""
var player_character_id: String = ""
var player_resources: Dictionary = {
	"money": 0.0,
	"legitimacy": 50.0,
	"reality_points": 0.0
}

# === GAME STATE ===
var current_date: Dictionary = {
	"day": 1,
	"month": 1,
	"year": 1
}
var game_speed: float = 1.0  # 0 = paused
var is_paused: bool = false

# === SETTINGS ===
var world_seed: String = ""
var difficulty: String = "normal"
var ironman_mode: bool = false

# Getter functions
func get_player_nation() -> Nation:
	return nations.get(player_nation_id)

func get_character(id: String) -> Character:
	return characters.get(id)

func get_province(id: String) -> Province:
	return provinces.get(id)

func get_region(id: String) -> Region:
	return regions.get(id)

func get_district(id: String) -> District:
	return districts.get(id)

class_name Province
extends Resource

var id: String = ""
var name: String = ""
var nation_id: String = ""

# === GEOGRAPHY ===
var terrain_type: String = "plains"  # plains, mountains, desert, etc.
var position: Vector2 = Vector2.ZERO
var adjacent_provinces: Array[String] = []
var boundary_polygon: PackedVector2Array = PackedVector2Array()  # Polygon-Grenzen für Karte
var area_km2: float = 0.0  # Fläche in Quadratkilometern

# === SUBDIVISION ===
var districts: Array[String] = []  # District IDs innerhalb dieser Provinz

# === VISUALS ===
var color: Color = Color.WHITE  # Farbe für politische Karte (basierend auf Nation)

# === ECONOMY ===
var local_gdp: float = 0.0
var resources: Dictionary = {}  # resource_type -> amount
var industries: Array[String] = []

# === DEMOGRAPHICS ===
var population: int = 0
var urban_population: int = 0
var ethnic_makeup: Dictionary = {}

# === INFRASTRUCTURE ===
var infrastructure_level: float = 50.0
var has_port: bool = false
var has_airport: bool = false

# === UNREST ===
var unrest_level: float = 0.0
var protest_risk: float = 0.0

func simulate_tick() -> void:
	_update_economy()
	_update_unrest()

func _update_economy() -> void:
	# Produktion basierend auf Ressourcen
	local_gdp = 0.0
	for resource in resources.keys():
		local_gdp += resources[resource] * _get_resource_value(resource)

func _update_unrest() -> void:
	# Unruhe basierend auf nationalen Faktoren
	var nation = GameState.nations.get(nation_id)
	if nation:
		unrest_level = (nation.unemployment / 10.0) + (100.0 - nation.legitimacy) / 50.0

func _get_resource_value(resource_type: String) -> float:
	"""Gibt den Wert einer Ressource zurück (vereinfacht)."""
	# TODO: Später komplexere Ressourcenbewertung basierend auf Weltmarkt
	match resource_type:
		"oil":
			return 100.0
		"rare_earth":
			return 150.0
		"minerals":
			return 80.0
		"agriculture":
			return 50.0
		"fish":
			return 40.0
		"timber":
			return 60.0
		_:
			return 30.0  # Default-Wert

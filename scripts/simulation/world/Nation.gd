class_name Nation
extends Resource

# === IDENTIFICATION ===
var id: String = ""
var name: String = ""
var adjective: String = ""
var capital_province_id: String = ""
var region_id: String = ""  # Zu welcher Region gehört diese Nation

# === VISUALS ===
var color: Color = Color.WHITE  # Nationale Farbe für politische Karte
var boundary_polygon: PackedVector2Array = PackedVector2Array()  # Gesamtgrenze der Nation

# === GOVERNMENT ===
var government_type: String = "democracy"  # democracy, dictatorship, theocracy, etc.
var leader_character_id: String = ""
var ruling_party_id: String = ""
var legitimacy: float = 50.0

# === ECONOMY ===
var gdp: float = 0.0
var gdp_growth: float = 0.0
var treasury: float = 0.0
var debt: float = 0.0
var inflation: float = 0.0
var unemployment: float = 5.0

# === MILITARY ===
var military_strength: float = 0.0
var armies: Array[String] = []  # Army IDs

# === DIPLOMACY ===
var relationships: Dictionary = {}  # nation_id -> float (-100 to 100)
var alliances: Array[String] = []
var wars: Array[String] = []  # War IDs

# === TECHNOLOGY ===
var tech_level: int = 4  # 1-7
var researched_technologies: Array[String] = []

# === DEMOGRAPHICS ===
var population: int = 0
var population_groups: Array[Dictionary] = []  # TODO: PopulationGroup class erstellen

# === HISTORY (siehe Historical Memory System) ===
var historical_profile: Dictionary = {}
var defining_moments: Array[Dictionary] = []

# === AI (für NPC-Nationen) ===
var ai_personality: Dictionary = {}
var ai_goals: Array[Dictionary] = []

func simulate_detailed_tick() -> void:
	_update_economy()
	_update_politics()
	_update_military()
	_update_population()
	_check_events()

func simulate_simplified_tick() -> void:
	# Vereinfachte Updates
	_update_economy()
	_update_population()

func simulate_background_tick() -> void:
	# Nur grobe Trends
	gdp_growth = randf_range(-0.5, 0.5)
	gdp += gdp * gdp_growth / 100.0

func _update_economy() -> void:
	# TODO: Detaillierte Wirtschaftssimulation
	# Einfaches GDP-Wachstum für Test
	gdp += gdp * (gdp_growth / 100.0) / 365.0  # Täglich ein 365stel des Jahreswachstums

func _update_politics() -> void:
	# TODO: Politische Dynamiken
	pass

func _update_military() -> void:
	# TODO: Militär-Updates
	pass

func _update_population() -> void:
	# TEST-IMPLEMENTIERUNG: Bevölkerungswachstum
	# Realistische jährliche Wachstumsrate: ~1% pro Jahr
	# Pro Tag: 1% / 365 = 0.00274% pro Tag
	var daily_growth_rate = 0.01 / 365.0  # 1% pro Jahr, verteilt auf Tage
	var growth = population * daily_growth_rate
	population += int(growth)

	# Alle 30 Tage: Log-Ausgabe für Entwickler
	if GameState.current_date.day == 1:
		print("Nation %s: Bevölkerung = %d (+%.0f/Tag)" % [name, population, growth])

func _check_events() -> void:
	# Trigger events basierend auf Zustand
	if unemployment > 20.0:
		EventBus.economic_crisis.emit(id, unemployment / 20.0)

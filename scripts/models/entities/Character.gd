class_name Character
extends Resource

# === IDENTIFICATION ===
var id: String = ""
var full_name: String = ""
var age: int = 30
var gender: String = "male"
var ethnicity: String = ""
var portrait_data: Dictionary = {}  # Für prozedurale Generierung

# === POSITION ===
var nation_id: String = ""
var current_position: String = "citizen"  # minister, general, opposition_leader, etc.
var previous_positions: Array[String] = []

# === PERSONALITY (Big Five + Extensions) ===
var personality: Dictionary = {
	"openness": 50,
	"conscientiousness": 50,
	"extraversion": 50,
	"agreeableness": 50,
	"neuroticism": 50,
	"machiavellianism": 30,
	"authoritarianism": 40,
	"risk_tolerance": 50
}

# === IDEOLOGY ===
var ideology: Dictionary = {
	"economic": 0,  # -100 (communist) to 100 (capitalist)
	"social": 0,    # -100 (authoritarian) to 100 (libertarian)
	"foreign": 0    # -100 (isolationist) to 100 (interventionist)
}

# === SKILLS ===
var skills: Dictionary = {
	"economy": 50,
	"military": 50,
	"diplomacy": 50,
	"intrigue": 50,
	"oratory": 50,
	"administration": 50
}

# === RELATIONSHIPS ===
var relationships: Dictionary = {}  # character_id -> int (-100 to 100)
var loyalty_to_player: float = 50.0

# === AMBITIONS ===
var short_term_goals: Array[String] = []
var long_term_goals: Array[String] = []
var secret_agenda: String = ""

# === BIOGRAPHY (Historical Memory) ===
var birth_year: int = 0
var birthplace: String = ""
var biography: Array[Dictionary] = []  # Life events
var formative_events: Array[Dictionary] = []

# === STATUS ===
var is_alive: bool = true
var health: float = 100.0
var wealth: float = 0.0
var influence: float = 0.0

func simulate_tick() -> void:
	_age_character()
	_update_relationships()
	_pursue_goals()
	_health_check()

func _age_character() -> void:
	if GameState.current_date.day == 1 and GameState.current_date.month == 1:
		age += 1

func _update_relationships() -> void:
	# Beziehungen degradieren/verbessern basierend auf Ereignissen
	pass

func _pursue_goals() -> void:
	# AI-gesteuerte Ziel-Verfolgung (GOAP)
	if short_term_goals.size() > 0:
		var goal = short_term_goals[0]
		_work_towards_goal(goal)

func _work_towards_goal(goal: String) -> void:
	# TODO: GOAP-basierte Aktionsplanung
	pass

func _health_check() -> void:
	health -= 0.01  # Langsame Alterung
	if health <= 0:
		die("natural_causes")

func die(cause: String) -> void:
	is_alive = false
	EventBus.character_died.emit(id, cause)
	# Historical record
	biography.append({
		"event": "death",
		"cause": cause,
		"year": GameState.current_date.year
	})

func add_biography_event(event_type: String, description: String, impact: Dictionary = {}) -> void:
	biography.append({
		"event": event_type,
		"description": description,
		"year": GameState.current_date.year,
		"impact": impact
	})

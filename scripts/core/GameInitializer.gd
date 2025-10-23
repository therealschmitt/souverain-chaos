extends Node

"""
Initialisiert das Spiel beim Start.
- Generiert Welt
- Verbindet Simulation mit TimeManager
- Startet erste Events
"""

var world: World = null

func _ready() -> void:
	# Warte einen Frame, damit alle Autoloads geladen sind
	await get_tree().process_frame
	_initialize_game()

func _initialize_game() -> void:
	print("=== SPIEL-INITIALISIERUNG ===")

	# 1. Welt generieren
	world = WorldGenerator.generate_test_world()
	GameState.world = world

	# 2. Simulation mit TimeManager verbinden
	EventBus.day_passed.connect(_on_day_passed)

	# 3. Erste Test-Events einplanen
	_schedule_initial_events()

	print("=== INITIALISIERUNG ABGESCHLOSSEN ===")
	print("Startdatum: %d.%d.%d %02d:00" % [
		GameState.current_date.day,
		GameState.current_date.month,
		GameState.current_date.year,
		GameState.current_date.hour
	])
	print("Spieler-Nation: %s" % GameState.get_player_nation().name)
	print("Bevölkerung: %d" % GameState.get_player_nation().population)

	# 4. Zeit automatisch starten (für Tests)
	print("=== STARTE ZEIT-SIMULATION ===")
	TimeManager.start_time()

func _on_day_passed(day: int) -> void:
	"""Bei jedem Tag: Simulation durchführen."""
	if world:
		world.simulate_tick()

func _schedule_initial_events() -> void:
	"""Plant erste Test-Events ein (inklusive Multi-Choice Events)."""

	# === Multi-Choice Events vom EventManager ===

	# Event in 3 Stunden: Wirtschaftskrise (Multi-Choice)
	TimeManager.schedule_event(
		{
			"type": "choice_event",
			"event_id": "economic_crisis_tax"
		},
		3.0,  # 3 Stunden
		2     # Hohe Priorität (pausiert Spiel)
	)

	# Event in 2 Tage: Diplomatische Krise (Multi-Choice)
	TimeManager.schedule_event(
		{
			"type": "choice_event",
			"event_id": "diplomatic_crisis_border"
		},
		24.0 * 2,  # 2 Tage
		2          # Hohe Priorität
	)

	# Event in 5 Tage: Massenproteste (Multi-Choice)
	TimeManager.schedule_event(
		{
			"type": "choice_event",
			"event_id": "internal_crisis_protests"
		},
		24.0 * 5,  # 5 Tage
		2
	)

	# Event in 10 Tage: Tech-Durchbruch (Multi-Choice)
	TimeManager.schedule_event(
		{
			"type": "choice_event",
			"event_id": "tech_breakthrough"
		},
		24.0 * 10,  # 10 Tage
		1
	)

	# Event in 15 Tage: Minister-Skandal (Multi-Choice)
	TimeManager.schedule_event(
		{
			"type": "choice_event",
			"event_id": "minister_resignation"
		},
		24.0 * 15,  # 15 Tage
		2
	)

	# Event in 20 Tage: Umweltkatastrophe (Multi-Choice)
	TimeManager.schedule_event(
		{
			"type": "choice_event",
			"event_id": "environmental_disaster"
		},
		24.0 * 20,  # 20 Tage
		2
	)

	# Event in 25 Tage: Militärischer Zwischenfall (Multi-Choice)
	TimeManager.schedule_event(
		{
			"type": "choice_event",
			"event_id": "military_incident"
		},
		24.0 * 25,  # 25 Tage
		2
	)

	# === Alte einfache Events ===

	# Event in 2 Stunden: Finanzminister-Bericht
	TimeManager.schedule_event(
		{
			"type": "minister_report",
			"minister": "finance",
			"message": "Exzellenz, der monatliche Wirtschaftsbericht liegt vor."
		},
		2.0,  # 2 Stunden
		1     # Normale Priorität
	)

	# Event in 1 Tag: Außenpolitischer Bericht
	TimeManager.schedule_event(
		{
			"type": "diplomatic_briefing",
			"message": "Ein diplomatischer Zwischenfall mit dem Nordreich erfordert Ihre Aufmerksamkeit."
		},
		24.0,  # 1 Tag
		1      # Normale Priorität
	)

	print("GameInitializer: 9 Events eingeplant (7 Multi-Choice + 2 einfache)")

class_name World
extends Node

var seed_value: String = ""
var nations: Array[Nation] = []
var provinces: Array[Province] = []

var simulation_mode: String = "detailed"  # detailed, simplified, background

func _init(seed: String = ""):
	seed_value = seed
	# HistoricalContext ist jetzt ein Autoload-Singleton
	# Keine lokale Instanz mehr nötig

func simulate_tick() -> void:
	match simulation_mode:
		"detailed":
			_simulate_detailed()
		"simplified":
			_simulate_simplified()
		"background":
			_simulate_background()

func _simulate_detailed() -> void:
	# Vollsimulation für Spieler-Nation und Nachbarn
	for nation in nations:
		if _is_relevant_for_player(nation):
			nation.simulate_detailed_tick()

func _simulate_simplified() -> void:
	# Vereinfachte Simulation für weiter entfernte Nationen
	for nation in nations:
		nation.simulate_simplified_tick()

func _simulate_background() -> void:
	# Nur Makro-Trends für irrelevante Nationen
	for nation in nations:
		nation.simulate_background_tick()

func _is_relevant_for_player(nation: Nation) -> bool:
	if nation.id == GameState.player_nation_id:
		return true
	# Check if neighbor, in war, or important diplomatically
	return _is_neighbor(nation) or _at_war_with_player(nation)

func _is_neighbor(nation: Nation) -> bool:
	# TODO: Check province adjacency
	return false

func _at_war_with_player(nation: Nation) -> bool:
	# TODO: Check war status
	return false

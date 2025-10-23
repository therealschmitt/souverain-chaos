extends Node

"""
SaveManager - Verwaltet das Speichern und Laden des kompletten Spielzustands.

Speichert:
- GameState (Datum, Spieler-Status, Einstellungen)
- TimeManager (Event-Queue, Geschwindigkeit)
- HistoricalContext (Historische Events)
- World (Nationen, Provinzen, Charaktere)

Speicherformat: JSON für Kompatibilität und Lesbarkeit
Speicherort: user://saves/
"""

const SAVE_VERSION: int = 1
const SAVE_DIR: String = "user://saves/"
const AUTO_SAVE_INTERVAL: int = 30  # Tage zwischen Auto-Saves

var last_auto_save_day: int = 0

func _ready() -> void:
	_ensure_save_directory()

func _ensure_save_directory() -> void:
	"""Stellt sicher, dass das Speicherverzeichnis existiert."""
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
		print("[SaveManager] Speicherverzeichnis erstellt: ", SAVE_DIR)

# === SAVE FUNCTIONS ===

func save_game(save_name: String) -> bool:
	"""
	Speichert den kompletten Spielzustand.

	Args:
		save_name: Name des Speicherstands (ohne .sav Endung)

	Returns:
		true wenn erfolgreich, false bei Fehler
	"""
	print("[SaveManager] Speichere Spielstand: ", save_name)

	var save_data = _collect_save_data()
	var file_path = SAVE_DIR + save_name + ".sav"

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("[SaveManager] Fehler beim Öffnen der Datei: " + file_path)
		return false

	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	print("[SaveManager] Spielstand gespeichert: ", file_path)
	EventBus.emit_signal("game_saved", save_name)
	return true

func auto_save() -> bool:
	"""Automatischer Speicherstand."""
	var date = GameState.current_date
	var auto_save_name = "autosave_%d-%02d-%02d" % [date.year, date.month, date.day]
	return save_game(auto_save_name)

func _collect_save_data() -> Dictionary:
	"""Sammelt alle zu speichernden Daten."""
	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"game_state": _serialize_game_state(),
		"time_manager": _serialize_time_manager(),
		"historical_context": _serialize_historical_context(),
		"world": _serialize_world()
	}

func _serialize_game_state() -> Dictionary:
	"""Serialisiert GameState."""
	return {
		"current_date": GameState.current_date.duplicate(),
		"player_nation_id": GameState.player_nation_id,
		"player_character_id": GameState.player_character_id,
		"player_resources": GameState.player_resources.duplicate(),
		"game_speed": GameState.game_speed,
		"is_paused": GameState.is_paused,
		"world_seed": GameState.world_seed,
		"difficulty": GameState.difficulty,
		"ironman_mode": GameState.ironman_mode
	}

func _serialize_time_manager() -> Dictionary:
	"""Serialisiert TimeManager-Zustand."""
	var serialized_queue = []
	for event in TimeManager.event_queue:
		serialized_queue.append({
			"timestamp": event.timestamp.duplicate(),
			"event_data": event.event_data.duplicate(),
			"priority": event.priority
		})

	return {
		"current_speed": TimeManager.current_speed,
		"is_running": TimeManager.is_running,
		"event_queue": serialized_queue
	}

func _serialize_historical_context() -> Dictionary:
	"""Serialisiert historischen Kontext."""
	return {
		"formative_eras": HistoricalContext.formative_eras.duplicate(true),
		"historical_events": HistoricalContext.historical_events.duplicate(true),
		"game_events": HistoricalContext.game_events.duplicate(true)
	}

func _serialize_world() -> Dictionary:
	"""Serialisiert die komplette Welt."""
	if not GameState.world:
		return {}

	return {
		"seed_value": GameState.world.seed_value,
		"simulation_mode": GameState.world.simulation_mode,
		"nations": _serialize_nations(),
		"provinces": _serialize_provinces(),
		"characters": _serialize_characters()
	}

func _serialize_nations() -> Array:
	"""Serialisiert alle Nationen."""
	var serialized = []
	for nation_id in GameState.nations:
		var nation: Nation = GameState.nations[nation_id]
		serialized.append(_serialize_nation(nation))
	return serialized

func _serialize_nation(nation: Nation) -> Dictionary:
	"""Serialisiert eine einzelne Nation."""
	return {
		"id": nation.id,
		"name": nation.name,
		"adjective": nation.adjective,
		"capital_province_id": nation.capital_province_id,
		"government_type": nation.government_type,
		"leader_character_id": nation.leader_character_id,
		"ruling_party_id": nation.ruling_party_id,
		"legitimacy": nation.legitimacy,
		"gdp": nation.gdp,
		"gdp_growth": nation.gdp_growth,
		"treasury": nation.treasury,
		"debt": nation.debt,
		"inflation": nation.inflation,
		"unemployment": nation.unemployment,
		"military_strength": nation.military_strength,
		"armies": nation.armies.duplicate(),
		"relationships": nation.relationships.duplicate(),
		"alliances": nation.alliances.duplicate(),
		"wars": nation.wars.duplicate(),
		"tech_level": nation.tech_level,
		"researched_technologies": nation.researched_technologies.duplicate(),
		"population": nation.population,
		"population_groups": nation.population_groups.duplicate(true),
		"historical_profile": nation.historical_profile.duplicate(true),
		"defining_moments": nation.defining_moments.duplicate(true),
		"ai_personality": nation.ai_personality.duplicate(true),
		"ai_goals": nation.ai_goals.duplicate(true)
	}

func _serialize_provinces() -> Array:
	"""Serialisiert alle Provinzen."""
	var serialized = []
	for province_id in GameState.provinces:
		var province: Province = GameState.provinces[province_id]
		serialized.append(_serialize_province(province))
	return serialized

func _serialize_province(province: Province) -> Dictionary:
	"""Serialisiert eine einzelne Provinz."""
	return {
		"id": province.id,
		"name": province.name,
		"nation_id": province.nation_id,
		"terrain_type": province.terrain_type,
		"position": {"x": province.position.x, "y": province.position.y},
		"adjacent_provinces": province.adjacent_provinces.duplicate(),
		"local_gdp": province.local_gdp,
		"resources": province.resources.duplicate(),
		"industries": province.industries.duplicate(),
		"population": province.population,
		"urban_population": province.urban_population,
		"ethnic_makeup": province.ethnic_makeup.duplicate(),
		"infrastructure_level": province.infrastructure_level,
		"has_port": province.has_port,
		"has_airport": province.has_airport,
		"unrest_level": province.unrest_level,
		"protest_risk": province.protest_risk
	}

func _serialize_characters() -> Array:
	"""Serialisiert alle Charaktere."""
	var serialized = []
	for character_id in GameState.characters:
		var character: Character = GameState.characters[character_id]
		serialized.append(_serialize_character(character))
	return serialized

func _serialize_character(character: Character) -> Dictionary:
	"""Serialisiert einen einzelnen Charakter."""
	return {
		"id": character.id,
		"full_name": character.full_name,
		"age": character.age,
		"gender": character.gender,
		"ethnicity": character.ethnicity,
		"portrait_data": character.portrait_data.duplicate(),
		"nation_id": character.nation_id,
		"current_position": character.current_position,
		"previous_positions": character.previous_positions.duplicate(),
		"personality": character.personality.duplicate(),
		"ideology": character.ideology.duplicate(),
		"skills": character.skills.duplicate(),
		"relationships": character.relationships.duplicate(),
		"loyalty_to_player": character.loyalty_to_player,
		"short_term_goals": character.short_term_goals.duplicate(),
		"long_term_goals": character.long_term_goals.duplicate(),
		"secret_agenda": character.secret_agenda,
		"birth_year": character.birth_year,
		"birthplace": character.birthplace,
		"biography": character.biography.duplicate(true),
		"formative_events": character.formative_events.duplicate(true),
		"is_alive": character.is_alive,
		"health": character.health,
		"wealth": character.wealth,
		"influence": character.influence
	}

# === LOAD FUNCTIONS ===

func load_game(save_name: String) -> bool:
	"""
	Lädt einen Spielstand.

	Args:
		save_name: Name des Speicherstands (ohne .sav Endung)

	Returns:
		true wenn erfolgreich, false bei Fehler
	"""
	print("[SaveManager] Lade Spielstand: ", save_name)

	var file_path = SAVE_DIR + save_name + ".sav"

	if not FileAccess.file_exists(file_path):
		push_error("[SaveManager] Speicherstand nicht gefunden: " + file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[SaveManager] Fehler beim Öffnen der Datei: " + file_path)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("[SaveManager] Fehler beim Parsen der JSON-Datei")
		return false

	var save_data = json.data

	# Versions-Check
	if save_data.get("version", 0) != SAVE_VERSION:
		push_warning("[SaveManager] Speicherstand-Version unterscheidet sich (erwartet: %d, gefunden: %d)" % [SAVE_VERSION, save_data.get("version", 0)])

	# Daten laden
	_restore_save_data(save_data)

	print("[SaveManager] Spielstand geladen: ", file_path)
	EventBus.emit_signal("game_loaded", save_name)
	return true

func _restore_save_data(save_data: Dictionary) -> void:
	"""Stellt den Spielzustand aus gespeicherten Daten wieder her."""

	# Zeit pausieren während des Ladens
	TimeManager.pause_time()

	# GameState wiederherstellen
	_deserialize_game_state(save_data.game_state)

	# Welt wiederherstellen
	_deserialize_world(save_data.world)

	# HistoricalContext wiederherstellen
	_deserialize_historical_context(save_data.historical_context)

	# TimeManager wiederherstellen
	_deserialize_time_manager(save_data.time_manager)

	# UI aktualisieren
	EventBus.emit_signal("game_state_changed")

func _deserialize_game_state(data: Dictionary) -> void:
	"""Stellt GameState wieder her."""
	GameState.current_date = data.current_date.duplicate()
	GameState.player_nation_id = data.player_nation_id
	GameState.player_character_id = data.player_character_id
	GameState.player_resources = data.player_resources.duplicate()
	GameState.game_speed = data.game_speed
	GameState.is_paused = data.is_paused
	GameState.world_seed = data.world_seed
	GameState.difficulty = data.difficulty
	GameState.ironman_mode = data.ironman_mode

func _deserialize_time_manager(data: Dictionary) -> void:
	"""Stellt TimeManager wieder her."""
	TimeManager.current_speed = data.current_speed
	TimeManager.is_running = data.is_running

	# Event-Queue wiederherstellen
	TimeManager.event_queue.clear()
	for event_data in data.event_queue:
		TimeManager.event_queue.append({
			"timestamp": event_data.timestamp.duplicate(),
			"event_data": event_data.event_data.duplicate(),
			"priority": event_data.priority
		})

func _deserialize_historical_context(data: Dictionary) -> void:
	"""Stellt historischen Kontext wieder her."""
	HistoricalContext.formative_eras = data.formative_eras.duplicate(true)
	HistoricalContext.historical_events = data.historical_events.duplicate(true)
	HistoricalContext.game_events = data.game_events.duplicate(true)

func _deserialize_world(data: Dictionary) -> void:
	"""Stellt die Welt wieder her."""
	if data.is_empty():
		return

	# Neue World-Instanz erstellen
	var world = World.new(data.seed_value)
	world.simulation_mode = data.simulation_mode

	# Dictionaries leeren
	GameState.nations.clear()
	GameState.provinces.clear()
	GameState.characters.clear()

	# Nationen laden
	for nation_data in data.nations:
		var nation = _deserialize_nation(nation_data)
		GameState.nations[nation.id] = nation
		world.nations.append(nation)

	# Provinzen laden
	for province_data in data.provinces:
		var province = _deserialize_province(province_data)
		GameState.provinces[province.id] = province
		world.provinces.append(province)

	# Charaktere laden
	for character_data in data.characters:
		var character = _deserialize_character(character_data)
		GameState.characters[character.id] = character

	GameState.world = world

func _deserialize_nation(data: Dictionary) -> Nation:
	"""Erstellt eine Nation aus gespeicherten Daten."""
	var nation = Nation.new()
	nation.id = data.id
	nation.name = data.name
	nation.adjective = data.adjective
	nation.capital_province_id = data.capital_province_id
	nation.government_type = data.government_type
	nation.leader_character_id = data.leader_character_id
	nation.ruling_party_id = data.ruling_party_id
	nation.legitimacy = data.legitimacy
	nation.gdp = data.gdp
	nation.gdp_growth = data.gdp_growth
	nation.treasury = data.treasury
	nation.debt = data.debt
	nation.inflation = data.inflation
	nation.unemployment = data.unemployment
	nation.military_strength = data.military_strength
	nation.armies = data.armies.duplicate()
	nation.relationships = data.relationships.duplicate()
	nation.alliances = data.alliances.duplicate()
	nation.wars = data.wars.duplicate()
	nation.tech_level = data.tech_level
	nation.researched_technologies = data.researched_technologies.duplicate()
	nation.population = data.population
	nation.population_groups = data.population_groups.duplicate(true)
	nation.historical_profile = data.historical_profile.duplicate(true)
	nation.defining_moments = data.defining_moments.duplicate(true)
	nation.ai_personality = data.ai_personality.duplicate(true)
	nation.ai_goals = data.ai_goals.duplicate(true)
	return nation

func _deserialize_province(data: Dictionary) -> Province:
	"""Erstellt eine Provinz aus gespeicherten Daten."""
	var province = Province.new()
	province.id = data.id
	province.name = data.name
	province.nation_id = data.nation_id
	province.terrain_type = data.terrain_type
	province.position = Vector2(data.position.x, data.position.y)
	province.adjacent_provinces = data.adjacent_provinces.duplicate()
	province.local_gdp = data.local_gdp
	province.resources = data.resources.duplicate()
	province.industries = data.industries.duplicate()
	province.population = data.population
	province.urban_population = data.urban_population
	province.ethnic_makeup = data.ethnic_makeup.duplicate()
	province.infrastructure_level = data.infrastructure_level
	province.has_port = data.has_port
	province.has_airport = data.has_airport
	province.unrest_level = data.unrest_level
	province.protest_risk = data.protest_risk
	return province

func _deserialize_character(data: Dictionary) -> Character:
	"""Erstellt einen Charakter aus gespeicherten Daten."""
	var character = Character.new()
	character.id = data.id
	character.full_name = data.full_name
	character.age = data.age
	character.gender = data.gender
	character.ethnicity = data.get("ethnicity", "")
	character.portrait_data = data.get("portrait_data", {}).duplicate()
	character.nation_id = data.nation_id
	character.current_position = data.current_position
	character.previous_positions = data.get("previous_positions", []).duplicate()
	character.personality = data.get("personality", {}).duplicate()
	character.ideology = data.ideology.duplicate()
	character.skills = data.get("skills", {}).duplicate()
	character.relationships = data.relationships.duplicate()
	character.loyalty_to_player = data.loyalty_to_player
	character.short_term_goals = data.short_term_goals.duplicate()
	character.long_term_goals = data.long_term_goals.duplicate()
	character.secret_agenda = data.get("secret_agenda", "")
	character.birth_year = data.birth_year
	character.birthplace = data.get("birthplace", "")
	character.biography = data.biography.duplicate(true)
	character.formative_events = data.get("formative_events", []).duplicate(true)
	character.is_alive = data.is_alive
	character.health = data.health
	character.wealth = data.get("wealth", 0.0)
	character.influence = data.get("influence", 0.0)
	return character

# === UTILITY FUNCTIONS ===

func get_save_list() -> Array:
	"""Gibt eine Liste aller verfügbaren Speicherstände zurück."""
	var saves = []
	var dir = DirAccess.open(SAVE_DIR)

	if not dir:
		return saves

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".sav"):
			var save_name = file_name.replace(".sav", "")
			var save_info = get_save_info(save_name)
			saves.append(save_info)
		file_name = dir.get_next()

	dir.list_dir_end()

	# Sortiere nach Datum (neueste zuerst)
	saves.sort_custom(func(a, b): return a.timestamp > b.timestamp)

	return saves

func get_save_info(save_name: String) -> Dictionary:
	"""Gibt Metadaten eines Speicherstands zurück ohne ihn zu laden."""
	var file_path = SAVE_DIR + save_name + ".sav"

	var info = {
		"name": save_name,
		"exists": false,
		"timestamp": "",
		"date": {},
		"nation_name": "",
		"version": 0
	}

	if not FileAccess.file_exists(file_path):
		return info

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return info

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return info

	var data = json.data

	info.exists = true
	info.timestamp = data.get("timestamp", "")
	info.version = data.get("version", 0)

	if data.has("game_state"):
		info.date = data.game_state.get("current_date", {})
		var player_nation_id = data.game_state.get("player_nation_id", "")

		# Finde Spieler-Nation
		if data.has("world") and data.world.has("nations"):
			for nation_data in data.world.nations:
				if nation_data.id == player_nation_id:
					info.nation_name = nation_data.name
					break

	return info

func delete_save(save_name: String) -> bool:
	"""Löscht einen Spielstand."""
	var file_path = SAVE_DIR + save_name + ".sav"

	if not FileAccess.file_exists(file_path):
		return false

	var dir = DirAccess.open(SAVE_DIR)
	var error = dir.remove(save_name + ".sav")

	if error == OK:
		print("[SaveManager] Spielstand gelöscht: ", save_name)
		return true
	else:
		push_error("[SaveManager] Fehler beim Löschen: ", error)
		return false

# === AUTO-SAVE ===

func check_auto_save() -> void:
	"""Prüft ob ein Auto-Save fällig ist (wird von außen aufgerufen)."""
	if GameState.ironman_mode:
		# In Ironman immer auto-saven
		if GameState.current_date.day != last_auto_save_day:
			auto_save()
			last_auto_save_day = GameState.current_date.day
	else:
		# Normal: Alle X Tage
		var days_since_start = _calculate_days_since_start()
		if days_since_start - last_auto_save_day >= AUTO_SAVE_INTERVAL:
			auto_save()
			last_auto_save_day = days_since_start

func _calculate_days_since_start() -> int:
	"""Berechnet Tage seit Spielstart (ungefähre Berechnung)."""
	var date = GameState.current_date
	return (date.year - 2000) * 365 + (date.month - 1) * 30 + date.day

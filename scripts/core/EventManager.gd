extends Node

"""
EventManager - Verwaltet spielbare Events mit Optionen und Effekten.

Events haben:
- Titel und Beschreibung
- Mehrere Optionen zur Auswahl
- Effekte auf GameState (money, legitimacy, reality_points, nation stats, etc.)
- Triggerbedingungen

Events werden aus JSON-Templates in data/templates/events/ geladen.
"""

# Event-Bibliothek (aus JSON geladen)
var event_library: Dictionary = {}

# Aktives Event (wird gerade angezeigt)
var active_event: Dictionary = {}

const EVENTS_TEMPLATE = "res://data/templates/events/gameplay_events.json"

func _ready() -> void:
	_load_events_from_json()
	print("[EventManager] Event-System initialisiert mit %d Events" % event_library.size())

func _load_events_from_json() -> void:
	"""Lädt Events aus JSON-Template."""
	var file = FileAccess.open(EVENTS_TEMPLATE, FileAccess.READ)
	if not file:
		push_error("[EventManager] Konnte %s nicht laden!" % EVENTS_TEMPLATE)
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error("[EventManager] Fehler beim Parsen von %s" % EVENTS_TEMPLATE)
		return

	var data = json.get_data()
	if not data.has("events"):
		push_error("[EventManager] JSON hat kein 'events' Feld")
		return

	# Events in Dictionary laden
	for event_data in data.events:
		if not event_data.has("id"):
			push_warning("[EventManager] Event ohne ID gefunden, überspringe")
			continue
		event_library[event_data.id] = event_data

	print("[EventManager] %d Events aus JSON geladen" % event_library.size())

func trigger_random_event() -> void:
	"""Triggert ein zufälliges Event aus der Bibliothek."""
	var event_ids = event_library.keys()
	if event_ids.size() == 0:
		print("[EventManager] Keine Events in Bibliothek!")
		return

	var random_id = event_ids[randi() % event_ids.size()]
	trigger_event(random_id)

func trigger_event(event_id: String) -> void:
	"""Triggert ein spezifisches Event."""
	if not event_library.has(event_id):
		print("[EventManager] Event '%s' nicht gefunden!" % event_id)
		return

	var event_data = event_library[event_id]
	print("\n[EventManager] Event getriggert: %s" % event_data.title)

	# Event an EventDialog senden
	EventBus.choice_event_triggered.emit(event_data)

func apply_event_choice(event_id: String, option_index: int) -> void:
	"""Wendet die Effekte einer gewählten Option an."""
	if not event_library.has(event_id):
		print("[EventManager] Event '%s' nicht gefunden!" % event_id)
		return

	var event_data = event_library[event_id]
	if option_index < 0 or option_index >= event_data.options.size():
		print("[EventManager] Ungültiger Option-Index: %d" % option_index)
		return

	var chosen_option = event_data.options[option_index]

	# Prüfe Voraussetzungen
	if chosen_option.has("requires"):
		if not _check_requirements(chosen_option.requires):
			print("[EventManager] ❌ Voraussetzungen nicht erfüllt!")
			return

	print("\n" + "=".repeat(80))
	print("[EventManager] EFFEKTE von '%s' - Option: '%s'" % [event_data.title, chosen_option.label])
	print("=".repeat(80))

	var effects = chosen_option.effects

	# Spieler-Ressourcen
	if effects.has("money"):
		GameState.player_resources.money += effects.money
		var sign = "+" if effects.money >= 0 else ""
		print("💰 Geld: %s$%s (Neu: $%s)" % [sign, _format_number(effects.money), _format_number(GameState.player_resources.money)])

	if effects.has("legitimacy"):
		GameState.player_resources.legitimacy += effects.legitimacy
		GameState.player_resources.legitimacy = clamp(GameState.player_resources.legitimacy, 0, 100)
		var sign = "+" if effects.legitimacy >= 0 else ""
		print("⚖️  Legitimität: %s%d (Neu: %d)" % [sign, effects.legitimacy, GameState.player_resources.legitimacy])

	if effects.has("reality_points"):
		GameState.player_resources.reality_points += effects.reality_points
		var sign = "+" if effects.reality_points >= 0 else ""
		print("✨ Realitätspunkte: %s%d (Neu: %d)" % [sign, effects.reality_points, GameState.player_resources.reality_points])

	# Nation-Werte
	var player_nation = GameState.get_player_nation()
	if player_nation:
		if effects.has("nation_gdp_growth"):
			player_nation.gdp_growth += effects.nation_gdp_growth
			var sign = "+" if effects.nation_gdp_growth >= 0 else ""
			print("📈 BIP-Wachstum: %s%.1f%% (Neu: %.1f%%)" % [sign, effects.nation_gdp_growth, player_nation.gdp_growth])

		if effects.has("nation_unemployment"):
			player_nation.unemployment += effects.nation_unemployment
			player_nation.unemployment = max(0, player_nation.unemployment)
			var sign = "+" if effects.nation_unemployment >= 0 else ""
			print("👷 Arbeitslosigkeit: %s%.1f%% (Neu: %.1f%%)" % [sign, effects.nation_unemployment, player_nation.unemployment])

		if effects.has("nation_debt"):
			player_nation.debt += effects.nation_debt
			var sign = "+" if effects.nation_debt >= 0 else ""
			print("💸 Staatsschulden: %s$%s (Neu: $%s)" % [sign, _format_number(effects.nation_debt), _format_number(player_nation.debt)])

		if effects.has("nation_military_strength"):
			player_nation.military_strength += effects.nation_military_strength
			player_nation.military_strength = max(0, player_nation.military_strength)
			var sign = "+" if effects.nation_military_strength >= 0 else ""
			print("⚔️  Militärstärke: %s%d (Neu: %d)" % [sign, effects.nation_military_strength, player_nation.military_strength])

		if effects.has("nation_tech_level"):
			player_nation.tech_level += effects.nation_tech_level
			player_nation.tech_level = clamp(player_nation.tech_level, 1, 7)
			var sign = "+" if effects.nation_tech_level >= 0 else ""
			print("🔬 Tech-Level: %s%.1f (Neu: %.1f)" % [sign, effects.nation_tech_level, player_nation.tech_level])

	# Beziehungen
	if effects.has("relationship_nordreich"):
		_modify_relationship("nordreich", effects.relationship_nordreich)

	if effects.has("relationship_suedkonfoederation"):
		_modify_relationship("suedkonfoederation", effects.relationship_suedkonfoederation)

	if effects.has("relationship_all"):
		for nation_id in GameState.nations.keys():
			if nation_id != GameState.player_nation_id:
				_modify_relationship(nation_id, effects.relationship_all)

	# Provinz-Effekte
	if effects.has("province_unrest_all"):
		_modify_all_provinces_unrest(effects.province_unrest_all)

	if effects.has("province_unrest_coastal"):
		_modify_coastal_provinces_unrest(effects.province_unrest_coastal)

	# Spezielle Effekte
	if chosen_option.has("triggers_war"):
		var enemy_nation_id = chosen_option.triggers_war
		print("⚔️  KRIEG AUSGERUFEN gegen %s!" % enemy_nation_id.capitalize())
		EventBus.war_declared.emit(GameState.player_nation_id, enemy_nation_id)

	if chosen_option.has("triggers_war_risk"):
		print("⚠️  KRIEGSGEFAHR ERHÖHT!")

	# Console Message
	print("\n📜 " + chosen_option.console_message)
	print("=".repeat(80) + "\n")

	# Event zu Historie hinzufügen
	HistoricalContext.add_game_event(
		GameState.current_date,
		event_data.type,
		event_data.title,
		"Gewählt: %s - %s" % [chosen_option.label, chosen_option.console_message],
		70,  # narrative_weight
		{}
	)

	# UI aktualisieren
	EventBus.game_state_changed.emit()

func _check_requirements(requirements: Dictionary) -> bool:
	"""Prüft ob Voraussetzungen erfüllt sind."""
	if requirements.has("reality_points"):
		if GameState.player_resources.reality_points < requirements.reality_points:
			print("[EventManager] Nicht genug Realitätspunkte! Benötigt: %d, Vorhanden: %d" %
				[requirements.reality_points, GameState.player_resources.reality_points])
			return false
	return true

func _modify_relationship(nation_id: String, change: float) -> void:
	"""Ändert Beziehung zu einer Nation."""
	var player_nation = GameState.get_player_nation()
	if not player_nation:
		return

	if not player_nation.relationships.has(nation_id):
		player_nation.relationships[nation_id] = 0.0

	player_nation.relationships[nation_id] += change
	player_nation.relationships[nation_id] = clamp(player_nation.relationships[nation_id], -100, 100)

	var sign = "+" if change >= 0 else ""
	print("🤝 Beziehung zu %s: %s%d (Neu: %d)" %
		[nation_id.capitalize(), sign, int(change), int(player_nation.relationships[nation_id])])

func _modify_all_provinces_unrest(change: float) -> void:
	"""Ändert Unruhe in allen Provinzen."""
	var count = 0
	for province in GameState.provinces.values():
		province.unrest_level += change
		province.unrest_level = clamp(province.unrest_level, 0, 100)
		count += 1

	var sign = "+" if change >= 0 else ""
	print("🏛️  Unruhe in ALLEN Provinzen: %s%.1f (Anzahl: %d)" % [sign, change, count])

func _modify_coastal_provinces_unrest(change: float) -> void:
	"""Ändert Unruhe in Küstenprovinzen."""
	var count = 0
	for province in GameState.provinces.values():
		if province.has_port:
			province.unrest_level += change
			province.unrest_level = clamp(province.unrest_level, 0, 100)
			count += 1

	var sign = "+" if change >= 0 else ""
	print("🌊 Unruhe in Küstenprovinzen: %s%.1f (Anzahl: %d)" % [sign, change, count])

func _format_number(num: float) -> String:
	"""Formatiert große Zahlen mit Tausendertrennzeichen."""
	var is_negative = num < 0
	var abs_num = abs(num)
	var str_num = str(int(abs_num))
	var result = ""
	var count = 0

	for i in range(str_num.length() - 1, -1, -1):
		if count == 3:
			result = "." + result
			count = 0
		result = str_num[i] + result
		count += 1

	if is_negative:
		result = "-" + result

	return result

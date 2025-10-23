extends Node

"""
Globaler Singleton für historischen Kontext der Welt.
Enthält:
- Langfristige Prägungen (1500-1900): Allgemeine kulturelle/politische Trends
- Konkrete Ereignisse (1900-2000): Spezifische historische Events mit Datum
- Game-Ereignisse (ab 2000): Events die während des Spiels passieren
"""

# === PRÄGUNGEN (1500-1900) ===
var formative_eras: Array[Dictionary] = []

# === KONKRETE EREIGNISSE (1900-2000) ===
var historical_events: Array[Dictionary] = []

# === GAME-EREIGNISSE (ab 2000) ===
var game_events: Array[Dictionary] = []

# === INITIALIZATION ===
func _ready() -> void:
	_generate_historical_context()

# === FUNKTIONEN ===

func add_formative_era(period: String, description: String, legacy: Dictionary) -> void:
	"""Fügt eine Prägungsphase hinzu."""
	formative_eras.append({
		"period": period,
		"description": description,
		"legacy": legacy
	})

func add_historical_event(
	year: int,
	month: int,
	day: int,
	event_type: String,
	name: String,
	description: String,
	narrative_weight: int = 50,
	legacy: Dictionary = {},
	additional_data: Dictionary = {}
) -> void:
	"""Fügt ein konkretes historisches Ereignis hinzu."""
	var event = {
		"date": {"year": year, "month": month, "day": day},
		"type": event_type,
		"name": name,
		"description": description,
		"narrative_weight": narrative_weight,
		"legacy": legacy
	}

	# Zusätzliche Daten mergen
	for key in additional_data:
		event[key] = additional_data[key]

	historical_events.append(event)
	_sort_historical_events()

func add_game_event(
	date: Dictionary,
	event_type: String,
	name: String,
	description: String,
	narrative_weight: int = 50,
	legacy: Dictionary = {},
	additional_data: Dictionary = {}
) -> void:
	"""Fügt ein Spiel-Ereignis hinzu (nach Spielstart)."""
	var event = {
		"date": date.duplicate(),
		"type": event_type,
		"name": name,
		"description": description,
		"narrative_weight": narrative_weight,
		"legacy": legacy,
		"is_game_event": true  # Markierung
	}

	for key in additional_data:
		event[key] = additional_data[key]

	game_events.append(event)

	# Event auch zur Timeline hinzufügen falls wichtig genug
	if narrative_weight >= 60:
		EventBus.historical_event_added.emit(event)

func get_all_events() -> Array[Dictionary]:
	"""Gibt alle Events zurück (historisch + Spiel), chronologisch sortiert."""
	var all_events = historical_events.duplicate() + game_events.duplicate()
	all_events.sort_custom(_compare_events_by_date)
	return all_events

func get_events_in_range(start_year: int, end_year: int) -> Array[Dictionary]:
	"""Gibt Events in einem bestimmten Zeitraum zurück."""
	var result: Array[Dictionary] = []
	for event in get_all_events():
		var year = event.date.year
		if year >= start_year and year <= end_year:
			result.append(event)
	return result

func get_defining_moments(min_weight: int = 80) -> Array[Dictionary]:
	"""Gibt nur die wichtigsten Events zurück (narrative_weight >= min_weight)."""
	var result: Array[Dictionary] = []
	for event in get_all_events():
		if event.narrative_weight >= min_weight:
			result.append(event)
	return result

func get_legacy_impact(legacy_key: String) -> float:
	"""
	Berechnet den kumulativen Einfluss eines Legacy-Werts.
	Beispiel: get_legacy_impact("militarism") -> Summe aller militarism-Werte
	"""
	var total = 0.0

	# Prägungen
	for era in formative_eras:
		if era.legacy.has(legacy_key):
			total += era.legacy[legacy_key] * 0.5  # Geringerer Einfluss

	# Events
	for event in get_all_events():
		if event.legacy.has(legacy_key):
			# Gewichtet nach narrative_weight
			var weight_factor = event.narrative_weight / 100.0
			total += event.legacy[legacy_key] * weight_factor

	return total

func get_events_by_type(event_type: String) -> Array[Dictionary]:
	"""Gibt alle Events eines bestimmten Typs zurück."""
	var result: Array[Dictionary] = []
	for event in get_all_events():
		if event.type == event_type:
			result.append(event)
	return result

# === PRIVATE ===

func _sort_historical_events() -> void:
	"""Sortiert historische Events chronologisch."""
	historical_events.sort_custom(_compare_events_by_date)

func _compare_events_by_date(a: Dictionary, b: Dictionary) -> bool:
	"""Vergleichsfunktion für Datum."""
	var date_a = a.date
	var date_b = b.date

	if date_a.year != date_b.year:
		return date_a.year < date_b.year
	if date_a.month != date_b.month:
		return date_a.month < date_b.month
	return date_a.day < date_b.day

# === HISTORICAL CONTEXT GENERATION ===

func _generate_historical_context() -> void:
	"""Generiert historischen Kontext beim Weltstart."""
	_generate_formative_eras()
	_generate_historical_events()

func _generate_formative_eras() -> void:
	"""
	Generiert Prägungen von 1500-1900.
	Placeholder - wird später erweitert mit Seed-basierter Generierung.
	"""
	add_formative_era(
		"1500-1700",
		"Zeitalter der Entdeckungen und frühen Kolonialismus",
		{"expansionism": 50, "trade_focus": 60}
	)

	add_formative_era(
		"1700-1800",
		"Aufklärung und absolutistische Herrschaft",
		{"rationalism": 40, "centralization": 70}
	)

	add_formative_era(
		"1800-1850",
		"Industrielle Revolution und soziale Umwälzungen",
		{"industrialization": 80, "social_inequality": 60}
	)

	add_formative_era(
		"1850-1900",
		"Nationalismus und imperiale Expansion",
		{"nationalism": 70, "militarism": 65, "imperialism": 75}
	)

func _generate_historical_events() -> void:
	"""
	Generiert konkrete Events von 1900-2000.
	Placeholder - wird später erweitert mit Seed-basierter Generierung.
	"""
	# Erster Weltkrieg
	add_historical_event(
		1914, 7, 28,
		"war_outbreak",
		"Ausbruch des Ersten Weltkrieges",
		"Die Ermordung des Erzherzogs löst eine Kette von Bündnisverpflichtungen aus.",
		95,
		{"trauma": 80, "militarism": -30, "international_cooperation": 20},
		{"casualties": 17000000, "duration_years": 4}
	)

	add_historical_event(
		1918, 11, 11,
		"war_end",
		"Ende des Ersten Weltkrieges",
		"Der Waffenstillstand beendet vier Jahre verheerenden Krieges.",
		90,
		{"relief": 70, "economic_devastation": 60},
		{"casualties_total": 17000000}
	)

	# Zwischenkriegszeit
	add_historical_event(
		1929, 10, 24,
		"economic_crisis",
		"Schwarzer Donnerstag - Beginn der Weltwirtschaftskrise",
		"Der Börsencrash in New York löst globale wirtschaftliche Depression aus.",
		85,
		{"economic_trauma": 70, "distrust_capitalism": 50},
		{"unemployment_peak": 25.0}
	)

	# Zweiter Weltkrieg
	add_historical_event(
		1939, 9, 1,
		"war_outbreak",
		"Beginn des Zweiten Weltkrieges",
		"Der Überfall auf Polen markiert den Beginn des verheerendsten Krieges der Geschichte.",
		98,
		{"trauma": 95, "totalitarianism_fear": 80},
		{"casualties": 70000000, "duration_years": 6}
	)

	add_historical_event(
		1945, 5, 8,
		"war_end",
		"Ende des Zweiten Weltkrieges in Europa",
		"Die bedingungslose Kapitulation beendet den Krieg in Europa.",
		95,
		{"relief": 80, "rebuilding_determination": 70, "nuclear_age_fear": 60}
	)

	# Kalter Krieg
	add_historical_event(
		1947, 3, 12,
		"political_doctrine",
		"Truman-Doktrin - Beginn des Kalten Krieges",
		"Die Welt teilt sich in zwei ideologische Blöcke.",
		75,
		{"ideological_polarization": 70, "nuclear_deterrence": 60}
	)

	add_historical_event(
		1962, 10, 16,
		"crisis",
		"Kubakrise - Höhepunkt des Kalten Krieges",
		"Die Welt steht am Rand eines Atomkrieges.",
		88,
		{"nuclear_fear": 85, "diplomacy_value": 50}
	)

	# Entspannung und Ende des Kalten Krieges
	add_historical_event(
		1989, 11, 9,
		"political_change",
		"Fall der Berliner Mauer",
		"Symbol für das Ende der Teilung und des Kalten Krieges.",
		92,
		{"optimism": 80, "globalization": 70, "democracy_triumph": 65}
	)

	add_historical_event(
		1991, 12, 26,
		"state_dissolution",
		"Auflösung der Sowjetunion",
		"Das Ende der UdSSR markiert das definitive Ende des Kalten Krieges.",
		90,
		{"unipolar_world": 70, "capitalism_dominance": 60}
	)

	# Moderne Ära
	add_historical_event(
		1999, 1, 1,
		"technological",
		"Y2K-Vorbereitung und Internet-Boom",
		"Die Welt bereitet sich auf das neue Jahrtausend vor, während das Internet rasant wächst.",
		60,
		{"technological_optimism": 70, "digital_age": 80}
	)

	print("HistoricalContext: Generiert %d Prägungen und %d historische Events" % [formative_eras.size(), historical_events.size()])

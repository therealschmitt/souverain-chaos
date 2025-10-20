extends Node

# === CONSTANTS ===
const HOURS_PER_DAY: int = 24
const DAYS_PER_MONTH: int = 30
const MONTHS_PER_YEAR: int = 12

# Automatische Geschwindigkeitsstufen basierend auf Zeit bis zum nächsten Event
const SPEED_VERY_SHORT: float = 2.0   # Stunden pro Sekunde (für Events < 2 Stunden entfernt)
const SPEED_SHORT: float = 12.0       # Stunden pro Sekunde (für Events 2-24 Stunden entfernt)
const SPEED_DAYS_SLOW: float = 4.0    # Tage pro Sekunde (für Events 1-7 Tage entfernt)
const SPEED_DAYS_FAST: float = 15.0   # Tage pro Sekunde (für Events 7-30 Tage entfernt)
const SPEED_MONTHS: float = 5.0       # Monate pro Sekunde (für Events > 30 Tage entfernt)

# === STATE ===
var current_speed: float = 0.0
var is_running: bool = false
var _debug_timer: float = 0.0  # Für Debug-Output

# Event Queue: Array of {timestamp: Dictionary, event_data: Dictionary, priority: int}
var event_queue: Array = []

# === INITIALIZATION ===
func _ready() -> void:
	# Startdatum: 1. Januar 2000, 00:00 Uhr
	GameState.current_date = {
		"year": 2000,
		"month": 1,
		"day": 1,
		"hour": 0
	}
	GameState.is_paused = true  # Start pausiert

# === MAIN LOOP ===
func _process(delta: float) -> void:
	if not is_running or GameState.is_paused:
		return

	# Prüfe ob Events anstehen
	if _has_pending_high_priority_events():
		_pause_for_event()
		return

	# Berechne Zeit bis zum nächsten Event
	var next_event_time = _get_next_event_timestamp()
	if next_event_time == null:
		# Keine Events in Queue - pausiere
		print("[TimeManager] Keine Events mehr in Queue - pausiere")
		pause_time()
		return

	# Automatische Geschwindigkeitsanpassung
	var hours_until_event = _calculate_hours_until(next_event_time)
	_adjust_speed_for_distance(hours_until_event)

	# Debug-Output alle Sekunde (Echtzeit)
	_debug_timer += delta
	if _debug_timer >= 1.0:
		_debug_timer = 0.0
		print("[%d.%d.%d %02d:00] Geschwindigkeit: %.1f Stunden/s | Nächstes Event in %.1f Stunden" % [
			GameState.current_date.day,
			GameState.current_date.month,
			GameState.current_date.year,
			GameState.current_date.hour,
			current_speed,
			hours_until_event
		])

	# Zeit vorspulen
	_advance_time(delta * current_speed)

	# Prüfe ob Event erreicht wurde
	_check_and_trigger_events()

# === TIME ADVANCEMENT ===
func _advance_time(hours: float) -> void:
	var old_date = GameState.current_date.duplicate()

	# Stunden hinzufügen
	GameState.current_date.hour += hours

	# Überlauf behandeln
	while GameState.current_date.hour >= HOURS_PER_DAY:
		GameState.current_date.hour -= HOURS_PER_DAY
		_advance_day()

	# Signals nur bei Änderungen
	if old_date.day != GameState.current_date.day:
		EventBus.day_passed.emit(GameState.current_date.day)

func _advance_day() -> void:
	GameState.current_date.day += 1

	if GameState.current_date.day > DAYS_PER_MONTH:
		_advance_month()

func _advance_month() -> void:
	GameState.current_date.day = 1
	GameState.current_date.month += 1
	EventBus.month_passed.emit(GameState.current_date.month, GameState.current_date.year)

	if GameState.current_date.month > MONTHS_PER_YEAR:
		_advance_year()

func _advance_year() -> void:
	GameState.current_date.month = 1
	GameState.current_date.year += 1
	EventBus.year_passed.emit(GameState.current_date.year)

# === EVENT QUEUE MANAGEMENT ===
func schedule_event(event_data: Dictionary, hours_from_now: float, priority: int = 1) -> void:
	"""
	Plant ein Event ein.

	Args:
		event_data: Beliebige Event-Daten (z.B. {type: "minister_arrival", minister_id: "..."})
		hours_from_now: Stunden von jetzt bis Event
		priority: 0 = niedrig (kann gesammelt werden), 1 = normal, 2 = hoch (pausiert sofort)
	"""
	var target_timestamp = _calculate_future_timestamp(hours_from_now)

	var event_entry = {
		"timestamp": target_timestamp,
		"event_data": event_data,
		"priority": priority
	}

	event_queue.append(event_entry)
	event_queue.sort_custom(_compare_events_by_time)

	# Wenn Zeit läuft und Event Priorität hat, prüfe ob pausiert werden muss
	if is_running and priority >= 2:
		_check_and_trigger_events()

func _compare_events_by_time(a: Dictionary, b: Dictionary) -> bool:
	return _timestamp_compare(a.timestamp, b.timestamp) < 0

func _calculate_future_timestamp(hours_from_now: float) -> Dictionary:
	var result = GameState.current_date.duplicate()
	result.hour += hours_from_now

	# Überlauf normalisieren
	while result.hour >= HOURS_PER_DAY:
		result.hour -= HOURS_PER_DAY
		result.day += 1
		if result.day > DAYS_PER_MONTH:
			result.day = 1
			result.month += 1
			if result.month > MONTHS_PER_YEAR:
				result.month = 1
				result.year += 1

	return result

func _get_next_event_timestamp():
	"""Gibt den Timestamp des nächsten Events zurück oder null wenn keine Events."""
	if event_queue.is_empty():
		return null
	return event_queue[0].timestamp

func _has_pending_high_priority_events() -> bool:
	for event in event_queue:
		if event.priority >= 2:
			if _timestamp_compare(GameState.current_date, event.timestamp) >= 0:
				return true
	return false

func _check_and_trigger_events() -> void:
	var triggered_events = []

	# Sammle alle Events die jetzt fällig sind
	for event in event_queue:
		if _timestamp_compare(GameState.current_date, event.timestamp) >= 0:
			triggered_events.append(event)

	# Entferne aus Queue
	for event in triggered_events:
		event_queue.erase(event)

	# Triggere Events
	if not triggered_events.is_empty():
		_trigger_events(triggered_events)

func _trigger_events(events: Array) -> void:
	# Pausiere Zeit
	pause_time()

	# Gruppiere nach Priorität
	var high_priority = []
	var normal_priority = []
	var low_priority = []

	for event in events:
		match event.priority:
			2:
				high_priority.append(event)
			1:
				normal_priority.append(event)
			0:
				low_priority.append(event)

	# Sende Events ans System
	# Hohe Priorität: Einzeln
	for event in high_priority:
		EventBus.event_triggered.emit(event.event_data, event.priority)

	# Normale Priorität: Einzeln
	for event in normal_priority:
		EventBus.event_triggered.emit(event.event_data, event.priority)

	# Niedrige Priorität: Als Batch
	if not low_priority.is_empty():
		var batch_data = []
		for event in low_priority:
			batch_data.append(event.event_data)
		EventBus.events_batch_triggered.emit(batch_data)

# === SPEED MANAGEMENT ===
func _adjust_speed_for_distance(hours_until_event: float) -> void:
	if hours_until_event < 2.0:
		# Weniger als 2 Stunden: Sehr kurz (2 Stunden/s)
		current_speed = SPEED_VERY_SHORT
	elif hours_until_event < HOURS_PER_DAY:
		# 2-24 Stunden: Kurz (12 Stunden/s)
		current_speed = SPEED_SHORT
	elif hours_until_event < HOURS_PER_DAY * 7:
		# 1-7 Tage: Langsam tageweise (4 Tage/s = 96 Stunden/s)
		current_speed = SPEED_DAYS_SLOW * HOURS_PER_DAY
	elif hours_until_event < HOURS_PER_DAY * 30:
		# 7-30 Tage: Schnell tageweise (15 Tage/s = 360 Stunden/s)
		current_speed = SPEED_DAYS_FAST * HOURS_PER_DAY
	else:
		# Über 30 Tage: Monatsweise (5 Monate/s = 3600 Stunden/s)
		current_speed = SPEED_MONTHS * HOURS_PER_DAY * DAYS_PER_MONTH

# === UTILITY FUNCTIONS ===
func _calculate_hours_until(target_timestamp: Dictionary) -> float:
	var current = GameState.current_date
	var target = target_timestamp

	# Vereinfachte Berechnung (genau genug für Geschwindigkeitsanpassung)
	var years_diff = target.year - current.year
	var months_diff = target.month - current.month
	var days_diff = target.day - current.day
	var hours_diff = target.hour - current.hour

	var total_hours = (
		years_diff * MONTHS_PER_YEAR * DAYS_PER_MONTH * HOURS_PER_DAY +
		months_diff * DAYS_PER_MONTH * HOURS_PER_DAY +
		days_diff * HOURS_PER_DAY +
		hours_diff
	)

	return total_hours

func _timestamp_compare(a: Dictionary, b: Dictionary) -> int:
	"""
	Vergleicht zwei Zeitstempel.
	Returns: -1 wenn a < b, 0 wenn gleich, 1 wenn a > b
	"""
	if a.year != b.year:
		return -1 if a.year < b.year else 1
	if a.month != b.month:
		return -1 if a.month < b.month else 1
	if a.day != b.day:
		return -1 if a.day < b.day else 1
	if a.hour != b.hour:
		return -1 if a.hour < b.hour else 1
	return 0

# === PUBLIC API ===
func start_time() -> void:
	"""Startet den Zeitfluss."""
	is_running = true
	GameState.is_paused = false
	print("[TimeManager] Zeit gestartet! is_running=%s, is_paused=%s, Events in Queue: %d" % [is_running, GameState.is_paused, event_queue.size()])
	EventBus.time_started.emit()

func pause_time() -> void:
	"""Pausiert den Zeitfluss."""
	is_running = false
	GameState.is_paused = true
	EventBus.time_paused.emit()

func _pause_for_event() -> void:
	"""Interne Funktion: Pausiert für Event-Handling."""
	pause_time()

func continue_to_next_event() -> void:
	"""
	Wird vom UI aufgerufen: Fährt fort bis zum nächsten Event.
	"""
	if event_queue.is_empty():
		# Keine Events - nichts zu tun
		return

	start_time()

func get_current_speed_description() -> String:
	"""Gibt eine lesbare Beschreibung der aktuellen Geschwindigkeit zurück."""
	if not is_running:
		return "Pausiert"

	if current_speed < HOURS_PER_DAY:
		return "Stündlich"
	elif current_speed < HOURS_PER_DAY * 5:
		return "Täglich (langsam)"
	elif current_speed < HOURS_PER_DAY * 15:
		return "Täglich (schnell)"
	else:
		return "Monatlich"

func get_next_event_description() -> String:
	"""Gibt eine Beschreibung des nächsten Events zurück."""
	if event_queue.is_empty():
		return "Keine anstehenden Ereignisse"

	var next_event = event_queue[0]
	var hours = _calculate_hours_until(next_event.timestamp)

	if hours < 1.0:
		return "In weniger als 1 Stunde"
	elif hours < HOURS_PER_DAY:
		return "In %.1f Stunden" % hours
	elif hours < HOURS_PER_DAY * 7:
		return "In %.1f Tagen" % (hours / HOURS_PER_DAY)
	else:
		return "In %.1f Tagen" % (hours / HOURS_PER_DAY)

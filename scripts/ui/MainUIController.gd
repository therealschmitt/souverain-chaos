extends Control

# References to UI elements
@onready var map_viewport := $MapViewport
@onready var map_container := $MapViewport/SubViewport/MapContainer

# Top bar
@onready var date_label := $UILayer/TopBar/MarginContainer/HBoxContainer/DateDisplay/DateLabel
@onready var money_label := $UILayer/TopBar/MarginContainer/HBoxContainer/Resources/MoneyContainer/MoneyLabel
@onready var legitimacy_label := $UILayer/TopBar/MarginContainer/HBoxContainer/Resources/LegitimacyContainer/LegitimacyLabel
@onready var reality_label := $UILayer/TopBar/MarginContainer/HBoxContainer/Resources/RealityPointsContainer/RealityLabel

# Time controls
@onready var pause_button := $UILayer/TopBar/MarginContainer/HBoxContainer/SpeedControls/PauseButton
@onready var play_button := $UILayer/TopBar/MarginContainer/HBoxContainer/SpeedControls/Speed1Button

# Bottom bar
@onready var province_name_label := $UILayer/BottomBar/MarginContainer/VBoxContainer/InfoDisplay/ProvinceInfo/ProvinceNameLabel
@onready var province_details_label := $UILayer/BottomBar/MarginContainer/VBoxContainer/InfoDisplay/ProvinceInfo/ProvinceDetailsLabel
@onready var character_name_label := $UILayer/BottomBar/MarginContainer/VBoxContainer/InfoDisplay/CharacterInfo/CharacterNameLabel
@onready var character_details_label := $UILayer/BottomBar/MarginContainer/VBoxContainer/InfoDisplay/CharacterInfo/CharacterDetailsLabel

# Panels
@onready var right_panel := $UILayer/RightPanel
@onready var left_panel := $UILayer/LeftPanel
@onready var event_notifications := $UILayer/EventNotifications
@onready var event_panel := $UILayer/EventNotifications/EventPanel

# Event Dialog
@onready var event_dialog := $UILayer/EventDialog

# Save/Load Menu
@onready var save_load_menu := $UILayer/SaveLoadMenu

# Main Menu
@onready var main_menu := $UILayer/MainMenu

# Menu button (Top bar)
@onready var menu_button := $UILayer/TopBar/MarginContainer/HBoxContainer/MenuButton

# Action buttons
@onready var advisors_button := $UILayer/BottomBar/MarginContainer/VBoxContainer/ActionButtons/AdvisorsButton
@onready var military_button := $UILayer/BottomBar/MarginContainer/VBoxContainer/ActionButtons/MilitaryButton
@onready var diplomacy_button := $UILayer/BottomBar/MarginContainer/VBoxContainer/ActionButtons/DiplomacyButton
@onready var economy_button := $UILayer/BottomBar/MarginContainer/VBoxContainer/ActionButtons/EconomyButton
@onready var technology_button := $UILayer/BottomBar/MarginContainer/VBoxContainer/ActionButtons/TechnologyButton
@onready var characters_button := $UILayer/BottomBar/MarginContainer/VBoxContainer/ActionButtons/CharactersButton

# State
var selected_province_id: String = ""
var selected_character_id: String = ""

const MONTH_NAMES := [
	"", "Januar", "Februar", "März", "April", "Mai", "Juni",
	"Juli", "August", "September", "Oktober", "November", "Dezember"
]

func _ready() -> void:
	_connect_signals()
	_connect_buttons()
	_update_ui()

func _connect_signals() -> void:
	# Time events
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.month_passed.connect(_on_month_passed)
	EventBus.year_passed.connect(_on_year_passed)
	EventBus.time_started.connect(_on_time_started)
	EventBus.time_paused.connect(_on_time_paused)
	EventBus.event_triggered.connect(_on_event_triggered)
	EventBus.events_batch_triggered.connect(_on_events_batch_triggered)

	# Province events
	EventBus.province_selected.connect(_on_province_selected)

	# Character events
	EventBus.character_created.connect(_on_character_created)
	EventBus.character_died.connect(_on_character_died)

	# Economy events
	EventBus.economic_crisis.connect(_on_economic_crisis)

	# Game flow
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)

func _connect_buttons() -> void:
	# Time controls
	pause_button.pressed.connect(_on_pause_pressed)
	play_button.pressed.connect(_on_play_pressed)

	# Menu button
	menu_button.pressed.connect(_on_menu_button_pressed)

	# Action buttons
	advisors_button.pressed.connect(func(): _toggle_panel("advisors"))
	military_button.pressed.connect(func(): _toggle_panel("military"))
	diplomacy_button.pressed.connect(func(): _toggle_panel("diplomacy"))
	economy_button.pressed.connect(func(): _toggle_panel("economy"))
	technology_button.pressed.connect(func(): _toggle_panel("technology"))
	characters_button.pressed.connect(func(): _toggle_panel("characters"))

	# Left panel close button
	if left_panel.has_node("MarginContainer/VBoxContainer/CloseButton"):
		var close_btn = left_panel.get_node("MarginContainer/VBoxContainer/CloseButton")
		close_btn.pressed.connect(_close_left_panel)

func _process(delta: float) -> void:
	_update_date_display()  # Datum ständig aktualisieren

func _input(event: InputEvent) -> void:
	# TEMPORÄR: Leertaste zum Fortsetzen der Zeit
	if event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed and not event.echo:
			TimeManager.continue_to_next_event()
			print("[UI] Leertaste gedrückt - Fortsetzen zum nächsten Event")

		# F5: Schnellspeicherung
		if event.keycode == KEY_F5 and event.pressed and not event.echo:
			_quick_save()

		# F9: Schnellladen
		if event.keycode == KEY_F9 and event.pressed and not event.echo:
			_quick_load()

		# ESC: Hauptmenü
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			if main_menu.visible:
				main_menu.close_menu()
			elif save_load_menu.visible:
				save_load_menu.hide()
				# Wenn SaveLoadMenu geschlossen wird, öffne MainMenu wieder
				main_menu.open_menu()
			else:
				main_menu.open_menu()

func _update_ui() -> void:
	_update_date_display()
	_update_resources_display()
	_update_province_info()
	_update_character_info()
	_update_time_controls()

func _update_date_display() -> void:
	var date = GameState.current_date
	var month_name = MONTH_NAMES[date.month] if date.month <= 12 else "???"
	# Neue Formatierung mit Stunde
	if date.has("hour"):
		date_label.text = "%d. %s %d, %02d:00 Uhr" % [date.day, month_name, date.year, date.hour]
	else:
		date_label.text = "%d. %s %d" % [date.day, month_name, date.year]

func _update_resources_display() -> void:
	var resources = GameState.player_resources
	money_label.text = "%.0f" % resources.get("money", 0.0)
	legitimacy_label.text = "%.0f" % resources.get("legitimacy", 50.0)
	reality_label.text = "%.0f" % resources.get("reality_points", 0.0)

func _update_province_info() -> void:
	if selected_province_id.is_empty():
		province_name_label.text = "Keine Provinz ausgewählt"
		province_details_label.text = "Klicken Sie auf eine Provinz für Details"
		return

	var province = GameState.get_province(selected_province_id)
	if province:
		province_name_label.text = province.name
		var nation = GameState.nations.get(province.nation_id)
		var nation_name = nation.name if nation else "???"
		province_details_label.text = "Bevölkerung: %d | Terrain: %s | Nation: %s" % [
			province.population,
			province.terrain_type,
			nation_name
		]
	else:
		province_name_label.text = "Provinz nicht gefunden"
		province_details_label.text = ""

func _update_character_info() -> void:
	if selected_character_id.is_empty():
		character_name_label.text = "Kein Charakter"
		character_details_label.text = ""
		return

	var character = GameState.get_character(selected_character_id)
	if character:
		character_name_label.text = character.full_name
		character_details_label.text = "Alter: %d | Position: %s" % [
			character.age,
			character.current_position
		]
	else:
		character_name_label.text = "Charakter nicht gefunden"
		character_details_label.text = ""

func _update_time_controls() -> void:
	"""Aktualisiert die Zeitsteuerung (neues event-driven System)."""
	var is_running = TimeManager.is_running

	# Pause-Button deaktivieren wenn Zeit bereits pausiert
	pause_button.disabled = not is_running

	# Play-Button deaktivieren wenn Zeit bereits läuft
	play_button.disabled = is_running

	# Visuelles Feedback
	if is_running:
		pause_button.modulate = Color.WHITE
		play_button.modulate = Color(0.5, 0.5, 0.5)
	else:
		pause_button.modulate = Color(0.5, 0.5, 0.5)
		play_button.modulate = Color.WHITE

# Event handlers
func _on_day_passed(day: int) -> void:
	_update_date_display()

func _on_month_passed(month: int, year: int) -> void:
	_update_date_display()

func _on_year_passed(year: int) -> void:
	_update_date_display()

func _on_province_selected(province_id: String) -> void:
	selected_province_id = province_id
	_update_province_info()

func _on_character_created(character: Dictionary) -> void:
	_show_notification("Neuer Charakter: %s" % character.get("full_name", "???"))

func _on_character_died(character_id: String, cause: String) -> void:
	var character = GameState.get_character(character_id)
	if character:
		_show_notification("%s ist gestorben (%s)" % [character.full_name, cause])

func _on_economic_crisis(nation_id: String, severity: float) -> void:
	var nation = GameState.nations.get(nation_id)
	if nation:
		_show_notification("Wirtschaftskrise in %s! (Schwere: %.1f)" % [nation.name, severity])

func _on_game_paused() -> void:
	_update_time_controls()

func _on_game_resumed() -> void:
	_update_time_controls()

func _on_time_started() -> void:
	"""Neues Signal: Zeit wurde gestartet."""
	_update_time_controls()

func _on_time_paused() -> void:
	"""Neues Signal: Zeit wurde pausiert."""
	_update_time_controls()

func _on_event_triggered(event_data: Dictionary, priority: int) -> void:
	"""Ein Event wurde ausgelöst."""
	# Prüfe ob es ein Multi-Choice Event ist
	if event_data.get("type") == "choice_event":
		var event_id = event_data.get("event_id", "")
		print("[Event] Multi-Choice Event triggered: ", event_id)
		EventManager.trigger_event(event_id)
	else:
		print("[Event] Triggered: ", event_data.get("type", "unknown"), " - ", event_data.get("message", ""))
		event_dialog.show_event(event_data, priority)

func _on_events_batch_triggered(events: Array) -> void:
	"""Mehrere niedrig-priorisierte Events wurden als Batch ausgelöst."""
	print("[Event Batch] %d Events:" % events.size())
	for event in events:
		print("  - %s" % event.get("message", "Event"))
	event_dialog.show_event_batch(events)

# Button handlers
func _on_menu_button_pressed() -> void:
	"""Menu-Button: Öffnet das Hauptmenü."""
	main_menu.open_menu()

func _on_pause_pressed() -> void:
	"""Pause-Button: Pausiert die Zeit."""
	if TimeManager.is_running:
		TimeManager.pause_time()
		print("[UI] Zeit pausiert")

func _on_play_pressed() -> void:
	"""Play-Button: Startet die Zeit."""
	if not TimeManager.is_running:
		TimeManager.continue_to_next_event()
		print("[UI] Zeit gestartet")

# Panel management
func _toggle_panel(panel_type: String) -> void:
	if left_panel.visible:
		_close_left_panel()
	else:
		_open_panel(panel_type)

func _open_panel(panel_type: String) -> void:
	left_panel.visible = true
	var title_label = left_panel.get_node("MarginContainer/VBoxContainer/TitleLabel")

	match panel_type:
		"advisors":
			title_label.text = "Berater"
		"military":
			title_label.text = "Militär"
		"diplomacy":
			title_label.text = "Diplomatie"
		"economy":
			title_label.text = "Wirtschaft"
		"technology":
			title_label.text = "Technologie"
		"characters":
			title_label.text = "Charaktere"

	EventBus.ui_panel_opened.emit(panel_type)

func _close_left_panel() -> void:
	left_panel.visible = false
	EventBus.ui_panel_closed.emit("left_panel")

# Save/Load functions
func _quick_save() -> void:
	"""F5: Schnellspeicherung."""
	if SaveManager.save_game("quicksave"):
		_show_notification("Schnellspeicherung erfolgreich!")
	else:
		_show_notification("Fehler beim Speichern!")

func _quick_load() -> void:
	"""F9: Schnellladen."""
	if SaveManager.load_game("quicksave"):
		_show_notification("Schnellladen erfolgreich!")
	else:
		_show_notification("Kein Schnellspeicherstand gefunden!")

# Notifications
func _show_notification(message: String) -> void:
	print("Notification: ", message)
	# TODO: Implement proper notification system with queue

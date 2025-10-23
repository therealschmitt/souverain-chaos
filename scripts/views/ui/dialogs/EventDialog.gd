extends Panel

"""
Event-Dialog zum Anzeigen von Events mit mehreren Optionen.
Unterstützt sowohl einfache Events als auch Multi-Choice Events vom EventManager.
"""

@onready var title_label := $MarginContainer/VBox/TitleLabel
@onready var message_label := $MarginContainer/VBox/MessageLabel
@onready var continue_button := $MarginContainer/VBox/ContinueButton
@onready var options_container := $MarginContainer/VBox/OptionsContainer
@onready var vbox := $MarginContainer/VBox

var current_event_data: Dictionary = {}
var current_event_id: String = ""
var is_choice_event: bool = false

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	_connect_signals()
	hide()

func _connect_signals() -> void:
	EventBus.choice_event_triggered.connect(_on_choice_event_triggered)

func show_event(event_data: Dictionary, priority: int) -> void:
	"""Zeigt ein Event an."""
	current_event_data = event_data

	# Titel basierend auf Event-Typ
	var title = _get_event_title(event_data)
	title_label.text = title

	# Nachricht
	var message = event_data.get("message", "Kein Nachrichtentext vorhanden.")
	message_label.text = message

	# Priority-Indikator
	match priority:
		2:
			title_label.add_theme_color_override("font_color", Color.RED)
		1:
			title_label.add_theme_color_override("font_color", Color.WHITE)
		0:
			title_label.add_theme_color_override("font_color", Color.GRAY)

	show()
	continue_button.grab_focus()

func show_event_batch(events: Array) -> void:
	"""Zeigt mehrere Events als Batch."""
	title_label.text = "Mehrere Ereignisse (%d)" % events.size()

	var message = ""
	for i in range(min(events.size(), 5)):  # Max 5 anzeigen
		var event = events[i]
		message += "• %s\n" % event.get("message", "Event")

	if events.size() > 5:
		message += "\n... und %d weitere" % (events.size() - 5)

	message_label.text = message
	title_label.add_theme_color_override("font_color", Color.GRAY)

	show()
	continue_button.grab_focus()

func _on_continue_pressed() -> void:
	"""Weiter-Button gedrückt."""
	hide()
	TimeManager.continue_to_next_event()

func _on_choice_event_triggered(event_data: Dictionary) -> void:
	"""Wird aufgerufen wenn ein Multi-Choice Event getriggert wird."""
	current_event_data = event_data
	current_event_id = event_data.get("id", "")
	is_choice_event = true

	# Titel
	title_label.text = event_data.get("title", "Ereignis")
	title_label.add_theme_color_override("font_color", Color.ORANGE)

	# Beschreibung
	message_label.text = event_data.get("description", "Keine Beschreibung.")

	# Continue-Button verstecken
	continue_button.hide()

	# Optionen anzeigen
	_show_options(event_data.get("options", []))

	# Dialog anzeigen
	show()

func _show_options(options: Array) -> void:
	"""Zeigt die verfügbaren Optionen als Buttons an."""
	# Alte Optionen entfernen
	_clear_options()

	# Neue Optionen erstellen
	for i in range(options.size()):
		var option = options[i]

		# Option-Button erstellen
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 60)
		button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		# Label und Beschreibung kombinieren
		var label = option.get("label", "Option %d" % (i + 1))
		var description = option.get("description", "")
		button.text = "%s\n%s" % [label, description]

		# Voraussetzungen prüfen
		if option.has("requires"):
			if not _check_requirements(option.requires):
				button.disabled = true
				button.text += "\n❌ Voraussetzungen nicht erfüllt"

		# Button mit Index verbinden
		button.pressed.connect(_on_option_chosen.bind(i))

		# Button zum Container hinzufügen
		options_container.add_child(button)

	options_container.show()

func _clear_options() -> void:
	"""Entfernt alle Option-Buttons."""
	for child in options_container.get_children():
		child.queue_free()

func _check_requirements(requirements: Dictionary) -> bool:
	"""Prüft ob Voraussetzungen erfüllt sind."""
	if requirements.has("reality_points"):
		if GameState.player_resources.reality_points < requirements.reality_points:
			return false
	return true

func _on_option_chosen(option_index: int) -> void:
	"""Wird aufgerufen wenn eine Option gewählt wurde."""
	print("[EventDialog] Option %d gewählt für Event '%s'" % [option_index, current_event_id])

	# Effekte anwenden
	EventManager.apply_event_choice(current_event_id, option_index)

	# Dialog schließen
	_clear_options()
	options_container.hide()
	continue_button.show()
	hide()

	# Zeit fortsetzen (falls pausiert)
	if not TimeManager.is_running:
		TimeManager.continue_to_next_event()

func _get_event_title(event_data: Dictionary) -> String:
	"""Gibt einen passenden Titel für den Event-Typ zurück."""
	var event_type = event_data.get("type", "unknown")

	match event_type:
		"minister_report":
			return "Ministerbericht"
		"diplomatic_briefing":
			return "Diplomatisches Briefing"
		"population_report":
			return "Bevölkerungsbericht"
		"monthly_report":
			return "Monatsbericht"
		"economic_crisis":
			return "WIRTSCHAFTSKRISE"
		_:
			return "Ereignis"

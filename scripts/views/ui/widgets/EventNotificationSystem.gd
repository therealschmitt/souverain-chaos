class_name EventNotificationSystem
extends VBoxContainer

# System for displaying event notifications with map context
# Events appear at the top-center of the screen and can be stacked

signal event_option_selected(event_id: String, option_id: String)

const MAX_VISIBLE_EVENTS := 3
const NOTIFICATION_DURATION := 10.0  # seconds before auto-dismiss
const SLIDE_IN_DURATION := 0.3

@export var event_panel_scene: PackedScene

var active_events: Array[Dictionary] = []
var event_queue: Array[Dictionary] = []
var event_panels: Dictionary = {}  # event_id -> Control

func _ready() -> void:
	_connect_event_signals()

func _connect_event_signals() -> void:
	# Connect to various game events
	EventBus.economic_crisis.connect(_on_economic_crisis)
	EventBus.war_declared.connect(_on_war_declared)
	EventBus.war_ended.connect(_on_war_ended)
	EventBus.nation_created.connect(_on_nation_created)
	EventBus.nation_destroyed.connect(_on_nation_destroyed)
	EventBus.character_died.connect(_on_character_died)

# Event handlers
func _on_economic_crisis(nation_id: String, severity: float) -> void:
	var nation = GameState.nations.get(nation_id)
	if not nation:
		return

	var event_data := {
		"id": "economic_crisis_%d" % Time.get_ticks_msec(),
		"title": "Wirtschaftskrise!",
		"description": "%s erlebt eine schwere Wirtschaftskrise (Schweregrad: %.1f)" % [nation.name, severity],
		"type": "crisis",
		"options": [
			{"id": "acknowledge", "text": "Verstanden"}
		],
		"auto_dismiss": true,
		"duration": 8.0
	}

	show_event(event_data)

func _on_war_declared(aggressor: String, defender: String) -> void:
	var aggressor_nation = GameState.nations.get(aggressor)
	var defender_nation = GameState.nations.get(defender)

	if not aggressor_nation or not defender_nation:
		return

	var event_data := {
		"id": "war_declared_%d" % Time.get_ticks_msec(),
		"title": "Kriegserklärung!",
		"description": "%s hat %s den Krieg erklärt!" % [aggressor_nation.name, defender_nation.name],
		"type": "war",
		"options": [
			{"id": "view_war", "text": "Krieg ansehen"},
			{"id": "dismiss", "text": "Schließen"}
		],
		"auto_dismiss": false
	}

	show_event(event_data)

func _on_war_ended(participants: Array, victor: String) -> void:
	var victor_nation = GameState.nations.get(victor)

	var event_data := {
		"id": "war_ended_%d" % Time.get_ticks_msec(),
		"title": "Krieg beendet",
		"description": "Der Krieg ist vorbei. Sieger: %s" % (victor_nation.name if victor_nation else "Unentschieden"),
		"type": "war",
		"options": [
			{"id": "acknowledge", "text": "Verstanden"}
		],
		"auto_dismiss": true,
		"duration": 10.0
	}

	show_event(event_data)

func _on_nation_created(nation_id: String) -> void:
	var nation = GameState.nations.get(nation_id)
	if not nation:
		return

	var event_data := {
		"id": "nation_created_%d" % Time.get_ticks_msec(),
		"title": "Neue Nation",
		"description": "%s wurde gegründet!" % nation.name,
		"type": "info",
		"options": [
			{"id": "acknowledge", "text": "OK"}
		],
		"auto_dismiss": true,
		"duration": 6.0
	}

	show_event(event_data)

func _on_nation_destroyed(nation_id: String) -> void:
	# Nation is already destroyed, so we can't get details
	var event_data := {
		"id": "nation_destroyed_%d" % Time.get_ticks_msec(),
		"title": "Nation aufgelöst",
		"description": "Eine Nation wurde aufgelöst.",
		"type": "info",
		"options": [
			{"id": "acknowledge", "text": "OK"}
		],
		"auto_dismiss": true,
		"duration": 6.0
	}

	show_event(event_data)

func _on_character_died(character_id: String, cause: String) -> void:
	var character = GameState.get_character(character_id)
	if not character:
		return

	var event_data := {
		"id": "character_died_%d" % Time.get_ticks_msec(),
		"title": "Todesfall",
		"description": "%s ist gestorben (%s)" % [character.full_name, cause],
		"type": "death",
		"options": [
			{"id": "view_character", "text": "Anzeigen"},
			{"id": "dismiss", "text": "Schließen"}
		],
		"auto_dismiss": false
	}

	show_event(event_data)

# Core notification system
func show_event(event_data: Dictionary) -> void:
	if active_events.size() >= MAX_VISIBLE_EVENTS:
		event_queue.append(event_data)
		return

	_create_event_panel(event_data)

func _create_event_panel(event_data: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.name = "EventPanel_" + event_data["id"]

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	margin.add_child(vbox)

	# Title
	var title_label = Label.new()
	title_label.text = event_data.get("title", "Event")
	title_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = event_data.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(350, 0)
	vbox.add_child(desc_label)

	# Options
	var options = event_data.get("options", [])
	if options.size() > 0:
		var button_container = HBoxContainer.new()
		button_container.alignment = BoxContainer.ALIGNMENT_END

		for option in options:
			var button = Button.new()
			button.text = option.get("text", "OK")
			button.custom_minimum_size = Vector2(100, 30)
			button.pressed.connect(_on_event_option_pressed.bind(event_data["id"], option["id"]))
			button_container.add_child(button)

		vbox.add_child(button_container)

	# Add to UI
	add_child(panel)
	active_events.append(event_data)
	event_panels[event_data["id"]] = panel

	# Animate in
	_animate_panel_in(panel)

	# Auto-dismiss timer
	if event_data.get("auto_dismiss", false):
		var duration = event_data.get("duration", NOTIFICATION_DURATION)
		var timer = Timer.new()
		timer.wait_time = duration
		timer.one_shot = true
		timer.timeout.connect(_dismiss_event.bind(event_data["id"]))
		panel.add_child(timer)
		timer.start()

	return panel

func _animate_panel_in(panel: Control) -> void:
	panel.modulate.a = 0.0
	panel.position.y = -50

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, SLIDE_IN_DURATION)
	tween.tween_property(panel, "position:y", 0, SLIDE_IN_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_panel_out(panel: Control, callback: Callable) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 0.0, SLIDE_IN_DURATION)
	tween.tween_property(panel, "position:y", -50, SLIDE_IN_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.finished.connect(callback)

func _on_event_option_pressed(event_id: String, option_id: String) -> void:
	event_option_selected.emit(event_id, option_id)
	EventBus.decision_made.emit(event_id, option_id)

	# Handle common options
	if option_id == "dismiss" or option_id == "acknowledge":
		_dismiss_event(event_id)
	elif option_id == "view_war":
		# TODO: Open war panel
		_dismiss_event(event_id)
	elif option_id == "view_character":
		# TODO: Open character panel
		_dismiss_event(event_id)

func _dismiss_event(event_id: String) -> void:
	var panel = event_panels.get(event_id)
	if not panel:
		return

	_animate_panel_out(panel, func():
		panel.queue_free()
		event_panels.erase(event_id)

		# Remove from active events
		for i in range(active_events.size()):
			if active_events[i]["id"] == event_id:
				active_events.remove_at(i)
				break

		# Show next queued event
		if event_queue.size() > 0:
			var next_event = event_queue.pop_front()
			show_event(next_event)
	)

func clear_all_events() -> void:
	for event_id in event_panels.keys():
		_dismiss_event(event_id)
	event_queue.clear()

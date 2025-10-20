class_name BasePanel
extends PanelContainer

# Base class for all UI panels in the game
# Provides common functionality for panel management, animations, and data binding

signal panel_opened()
signal panel_closed()
signal panel_updated()

@export var panel_title: String = "Panel"
@export var can_close: bool = true
@export var animate_transitions: bool = true
@export var update_interval: float = 0.0  # 0 = only manual updates

var is_open: bool = false
var update_timer: Timer

# Override these in derived classes
func _init_panel() -> void:
	pass

func _update_panel_data() -> void:
	pass

func _on_panel_opened() -> void:
	pass

func _on_panel_closed() -> void:
	pass

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

	if update_interval > 0:
		update_timer = Timer.new()
		update_timer.wait_time = update_interval
		update_timer.autostart = false
		update_timer.timeout.connect(_update_panel_data)
		add_child(update_timer)

	_init_panel()

	if visible:
		open_panel()

func open_panel() -> void:
	if is_open:
		return

	is_open = true
	visible = true

	if animate_transitions:
		_play_open_animation()

	if update_timer:
		update_timer.start()

	_update_panel_data()
	_on_panel_opened()
	panel_opened.emit()

	EventBus.ui_panel_opened.emit(panel_title)

func close_panel() -> void:
	if not is_open or not can_close:
		return

	is_open = false

	if animate_transitions:
		_play_close_animation()
	else:
		visible = false

	if update_timer:
		update_timer.stop()

	_on_panel_closed()
	panel_closed.emit()

	EventBus.ui_panel_closed.emit(panel_title)

func toggle_panel() -> void:
	if is_open:
		close_panel()
	else:
		open_panel()

func update_data() -> void:
	_update_panel_data()
	panel_updated.emit()

func _on_visibility_changed() -> void:
	if visible and not is_open:
		is_open = true
		_on_panel_opened()
	elif not visible and is_open:
		is_open = false
		_on_panel_closed()

# Animation methods (override for custom animations)
func _play_open_animation() -> void:
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _play_close_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(func(): visible = false)

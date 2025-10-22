extends Control

## UI-Panel für Zoom-Steuerung
## Zeigt Zoom-Buttons und Zoom-Slider

# === UI-KOMPONENTEN ===
var zoom_in_button: Button
var zoom_out_button: Button
var reset_button: Button
var zoom_slider: HSlider
var zoom_label: Label

# === REFERENZ ===
var map_controller: Node2D

# === KONFIGURATION ===
const BUTTON_SIZE: Vector2 = Vector2(40, 40)
const PANEL_PADDING: float = 10.0

func _ready() -> void:
	_setup_ui()
	_connect_signals()

func _setup_ui() -> void:
	"""Erstellt UI-Komponenten."""

	# Container für vertikales Layout
	var vbox = VBoxContainer.new()
	vbox.name = "ZoomControls"
	vbox.position = Vector2(PANEL_PADDING, PANEL_PADDING)
	add_child(vbox)

	# === ZOOM-LABEL ===
	zoom_label = Label.new()
	zoom_label.text = "Zoom: 100%"
	zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(zoom_label)

	# === ZOOM-IN BUTTON ===
	zoom_in_button = Button.new()
	zoom_in_button.text = "+"
	zoom_in_button.custom_minimum_size = BUTTON_SIZE
	zoom_in_button.tooltip_text = "Hineinzoomen (Mausrad hoch)"
	vbox.add_child(zoom_in_button)

	# === ZOOM-SLIDER ===
	zoom_slider = HSlider.new()
	zoom_slider.min_value = 0.25
	zoom_slider.max_value = 4.0
	zoom_slider.value = 1.0
	zoom_slider.step = 0.05
	zoom_slider.custom_minimum_size = Vector2(200, 20)
	zoom_slider.tooltip_text = "Zoom-Level"
	vbox.add_child(zoom_slider)

	# === ZOOM-OUT BUTTON ===
	zoom_out_button = Button.new()
	zoom_out_button.text = "-"
	zoom_out_button.custom_minimum_size = BUTTON_SIZE
	zoom_out_button.tooltip_text = "Herauszoomen (Mausrad runter)"
	vbox.add_child(zoom_out_button)

	# === RESET BUTTON ===
	reset_button = Button.new()
	reset_button.text = "Reset"
	reset_button.custom_minimum_size = BUTTON_SIZE
	reset_button.tooltip_text = "Zoom zurücksetzen"
	vbox.add_child(reset_button)

	# Styling
	_apply_styling()

func _apply_styling() -> void:
	"""Wendet Styling auf UI-Komponenten an."""
	# Panel-Hintergrund (semi-transparent)
	var panel = Panel.new()
	panel.z_index = -1
	panel.size = Vector2(220, 220)
	panel.position = Vector2(0, 0)
	panel.modulate = Color(0.1, 0.1, 0.1, 0.7)
	add_child(panel)

	# Font-Größen
	if zoom_label:
		zoom_label.add_theme_font_size_override("font_size", 14)

	# Button-Styling
	for button in [zoom_in_button, zoom_out_button, reset_button]:
		if button:
			button.add_theme_font_size_override("font_size", 16)

func _connect_signals() -> void:
	"""Verbindet Button-Signals."""
	zoom_in_button.pressed.connect(_on_zoom_in_pressed)
	zoom_out_button.pressed.connect(_on_zoom_out_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	zoom_slider.value_changed.connect(_on_slider_changed)

	# EventBus
	EventBus.map_zoom_changed.connect(_on_zoom_changed)

func initialize(p_map_controller: Node2D) -> void:
	"""
	Initialisiert UI mit MapController-Referenz.
	@param p_map_controller: MapController-Referenz
	"""
	map_controller = p_map_controller
	print("MapZoomUI: Initialisiert")

# === BUTTON HANDLERS ===

func _on_zoom_in_pressed() -> void:
	"""Handler für Zoom-In-Button."""
	if map_controller:
		map_controller.zoom_in(0.2)

func _on_zoom_out_pressed() -> void:
	"""Handler für Zoom-Out-Button."""
	if map_controller:
		map_controller.zoom_out(0.2)

func _on_reset_pressed() -> void:
	"""Handler für Reset-Button."""
	if map_controller:
		map_controller.reset_zoom()

func _on_slider_changed(value: float) -> void:
	"""Handler für Slider-Änderung."""
	if map_controller:
		map_controller.set_zoom(value)

# === EVENT HANDLERS ===

func _on_zoom_changed(current_zoom: float, target_zoom: float) -> void:
	"""
	Handler für Zoom-Änderung.
	Aktualisiert UI-Komponenten.
	"""
	# Update Label
	if zoom_label:
		zoom_label.text = "Zoom: %d%%" % int(current_zoom * 100)

	# Update Slider (ohne Signal auszulösen)
	if zoom_slider:
		zoom_slider.set_value_no_signal(current_zoom)

# === UTILITY ===

func set_visible_animated(visible: bool) -> void:
	"""Zeigt/versteckt Panel mit Animation."""
	var tween = create_tween()
	if visible:
		show()
		tween.tween_property(self, "modulate:a", 1.0, 0.2)
	else:
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		tween.tween_callback(hide)

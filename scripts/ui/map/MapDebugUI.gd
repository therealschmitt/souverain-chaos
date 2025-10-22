extends Control

## Debug-UI für Map-System
## Zeigt Zoom-Level, LOD-Info, Panning-Info und weitere Debug-Daten

# === UI-KOMPONENTEN ===
var debug_label: Label
var background_panel: Panel

# === REFERENZEN ===
var map_controller: Node2D

# === UPDATE-TIMER ===
var update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.1  # Update alle 100ms

# === VISIBILITY ===
var is_visible_debug: bool = true

func _ready() -> void:
	# Setze als top-level Control um unabhängig von Parent-Transformationen zu sein
	set_as_top_level(true)

	_setup_ui()
	_connect_signals()
	_register_with_layout_manager()
	set_process(true)

func _register_with_layout_manager() -> void:
	"""Registriert Panel beim UILayoutManager (falls verfügbar)."""
	# Prüfe ob UILayoutManager als Autoload verfügbar ist
	var layout_manager = get_node_or_null("/root/UILayoutManager")
	if layout_manager:
		# Registriere im TOP_LEFT Bereich mit hoher Priorität
		# AnchorArea.TOP_LEFT = 0
		layout_manager.register_panel(self, 0, 100)
		print("MapDebugUI: Mit UILayoutManager registriert")
		return

	# Fallback: Manuelle Positionierung (wenn UILayoutManager nicht als Autoload registriert)
	print("MapDebugUI: UILayoutManager nicht verfügbar, nutze manuelle Positionierung")

func _setup_ui() -> void:
	"""Erstellt Debug-UI-Komponenten."""

	# Setze z_index hoch damit über Karte
	z_index = 100

	# Setze mouse_filter um Maus-Events nicht zu blockieren
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Hintergrund-Panel
	background_panel = Panel.new()
	background_panel.name = "DebugBackground"
	background_panel.custom_minimum_size = Vector2(400, 120)
	background_panel.modulate = Color(0.1, 0.1, 0.1, 0.8)
	background_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_panel)

	# Debug-Label
	debug_label = Label.new()
	debug_label.name = "DebugLabel"
	debug_label.text = "Map Debug Info"
	debug_label.add_theme_color_override("font_color", Color.WHITE)
	debug_label.add_theme_font_size_override("font_size", 12)
	debug_label.position = Vector2(10, 10)
	debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(debug_label)

	# Positioniere in oberer linker Ecke (absolute Position)
	position = Vector2(10, 10)

	print("MapDebugUI: Initialisiert")

func _connect_signals() -> void:
	"""Verbindet EventBus-Signale."""
	EventBus.map_zoom_changed.connect(_on_zoom_changed)
	EventBus.map_zoom_level_changed.connect(_on_lod_changed)

func initialize(p_map_controller: Node2D) -> void:
	"""
	Initialisiert Debug-UI mit MapController-Referenz.
	@param p_map_controller: MapController-Referenz
	"""
	map_controller = p_map_controller

	# Nur update wenn UI-Komponenten bereit sind
	if debug_label:
		_update_debug_info()
	# Sonst wird es im ersten _process() Update gemacht

func _process(delta: float) -> void:
	"""Aktualisiert Debug-Info periodisch."""
	if not is_visible_debug:
		return

	update_timer += delta
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0
		_update_debug_info()

func _input(event: InputEvent) -> void:
	"""Toggle Debug-UI mit F3."""
	if event is InputEventKey:
		if event.keycode == KEY_F3 and event.pressed and not event.echo:
			toggle_visibility()

func _update_debug_info() -> void:
	"""Aktualisiert Debug-Informationen."""
	# Safety check: UI muss bereit sein
	if not debug_label:
		return

	if not map_controller:
		debug_label.text = "Map Debug Info\n[Warte auf MapController...]"
		return

	var info_text = ""

	# === ZOOM INFO ===
	var zoom_info = _get_zoom_info()
	info_text += "=== ZOOM ===\n"
	info_text += "  Maßstab: %.2fx (%.0f%%)\n" % [zoom_info.current, zoom_info.current * 100]
	info_text += "  Target: %.2fx | Range: %.2f - %.2fx\n" % [zoom_info.target, zoom_info.min, zoom_info.max]
	info_text += "  Progress: %.0f%%\n" % (zoom_info.progress * 100)

	# === LOD INFO ===
	var lod_info = _get_lod_info()
	info_text += "\n=== LOD ===\n"
	info_text += "  Level: %s\n" % lod_info.zoom_level_name
	info_text += "  Visible Layers: %s\n" % ", ".join(lod_info.visible_layers)

	# === PANNING INFO ===
	var pan_info = _get_panning_info()
	info_text += "\n=== PANNING ===\n"
	info_text += "  Position: (%.0f, %.0f)\n" % [pan_info.position.x, pan_info.position.y]
	info_text += "  Is Panning: %s\n" % ("Ja" if pan_info.is_panning else "Nein")

	# === LABEL INFO ===
	var label_info = _get_label_info()
	info_text += "\n=== LABELS ===\n"
	info_text += "  Visible: %d / %d\n" % [label_info.visible, label_info.total]

	# === CONTROLS ===
	info_text += "\n[F3] Toggle Debug | [Mausrad] Zoom | [WASD] Pan | [RMB] Drag"

	debug_label.text = info_text

	# Passe Background-Größe an
	var text_size = debug_label.get_minimum_size()
	background_panel.custom_minimum_size = text_size + Vector2(20, 20)

func _get_zoom_info() -> Dictionary:
	"""Holt Zoom-Informationen."""
	if map_controller and map_controller.zoom_controller:
		return map_controller.zoom_controller.get_zoom_info()
	return {
		"current": 1.0,
		"target": 1.0,
		"min": 0.25,
		"max": 4.0,
		"progress": 0.5,
		"is_zooming": false
	}

func _get_lod_info() -> Dictionary:
	"""Holt LOD-Informationen."""
	if map_controller and map_controller.zoom_level_manager:
		return map_controller.zoom_level_manager.get_lod_info()
	return {
		"zoom_level": 2,
		"zoom_level_name": "NORMAL",
		"visible_layers": []
	}

func _get_panning_info() -> Dictionary:
	"""Holt Panning-Informationen."""
	var info = {
		"position": Vector2.ZERO,
		"is_panning": false
	}

	if map_controller:
		info.position = map_controller.position

		if map_controller.panning_controller:
			info.is_panning = map_controller.panning_controller.is_panning()

	return info

func _get_label_info() -> Dictionary:
	"""Holt Label-Informationen."""
	if map_controller and map_controller.label_manager:
		return map_controller.label_manager.get_label_info()
	return {
		"visible": 0,
		"total": 0
	}

# === EVENT HANDLERS ===

func _on_zoom_changed(current_zoom: float, target_zoom: float) -> void:
	"""Handler für Zoom-Änderung."""
	# Sofortiges Update bei Zoom-Änderung
	_update_debug_info()

func _on_lod_changed(new_level: int, old_level: int) -> void:
	"""Handler für LOD-Wechsel."""
	# Sofortiges Update bei LOD-Wechsel
	_update_debug_info()

# === PUBLIC API ===

func toggle_visibility() -> void:
	"""Schaltet Sichtbarkeit der Debug-UI um."""
	is_visible_debug = not is_visible_debug
	visible = is_visible_debug

	if is_visible_debug:
		_update_debug_info()

func show_debug() -> void:
	"""Zeigt Debug-UI."""
	is_visible_debug = true
	visible = true
	_update_debug_info()

func hide_debug() -> void:
	"""Versteckt Debug-UI."""
	is_visible_debug = false
	visible = false

func set_position_preset(preset: String) -> void:
	"""
	Setzt Position der Debug-UI.
	@param preset: "top_left", "top_right", "bottom_left", "bottom_right"
	"""
	var viewport_size = get_viewport_rect().size
	var panel_size = background_panel.custom_minimum_size

	match preset:
		"top_left":
			position = Vector2(10, 10)
		"top_right":
			position = Vector2(viewport_size.x - panel_size.x - 10, 10)
		"bottom_left":
			position = Vector2(10, viewport_size.y - panel_size.y - 10)
		"bottom_right":
			position = Vector2(viewport_size.x - panel_size.x - 10, viewport_size.y - panel_size.y - 10)

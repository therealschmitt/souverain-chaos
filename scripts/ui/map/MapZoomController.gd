class_name MapZoomController
extends Node

## Verwaltet stufenloses Zoomen für die Karte mit Mausrad und Buttons
## Koppelt Zoom an internes Koordinatensystem und triggert LOD-Änderungen

# === ZOOM-KONFIGURATION ===
const ZOOM_MIN: float = 0.25      # Maximales Herauszoomen (25%)
const ZOOM_MAX: float = 4.0       # Maximales Hineinzoomen (400%)
const ZOOM_DEFAULT: float = 1.0   # Standard-Zoom (100%)

const ZOOM_STEP_MOUSE: float = 0.1      # Zoom-Schritt pro Mausrad-Tick
const ZOOM_STEP_BUTTON: float = 0.2     # Zoom-Schritt pro Button-Klick

const ZOOM_SMOOTHING: bool = true       # Sanftes Zoomen aktiviert
const ZOOM_SMOOTH_SPEED: float = 8.0    # Geschwindigkeit des sanften Zoomens

# === ZOOM-PIVOT ===
enum ZoomPivot {
	CENTER,       # Zoome zur Karten-Mitte
	MOUSE,        # Zoome zur Maus-Position
	SELECTION     # Zoome zur Selektion
}

var zoom_pivot_mode: ZoomPivot = ZoomPivot.MOUSE

# === STATE ===
var current_zoom: float = ZOOM_DEFAULT
var target_zoom: float = ZOOM_DEFAULT
var is_zooming: bool = false

# === REFERENZEN ===
var map_controller: Node2D
var viewport_size: Vector2

# === ZOOM-PUNKT ===
var zoom_focus_point: Vector2 = Vector2.ZERO  # World-Koordinate des Zoom-Fokus

func _ready() -> void:
	set_process(true)

func initialize(p_map_controller: Node2D) -> void:
	"""
	Initialisiert den Zoom-Controller.
	@param p_map_controller: Referenz zum MapController
	"""
	map_controller = p_map_controller
	viewport_size = map_controller.get_viewport_rect().size

	# Setze initialen Zoom
	current_zoom = ZOOM_DEFAULT
	target_zoom = ZOOM_DEFAULT

	print("MapZoomController: Initialisiert (Zoom: %.2f, Range: %.2f-%.2f)" % [
		current_zoom, ZOOM_MIN, ZOOM_MAX
	])

func _process(delta: float) -> void:
	"""Verarbeitet sanftes Zoomen."""
	if not ZOOM_SMOOTHING:
		return

	if abs(current_zoom - target_zoom) > 0.001:
		is_zooming = true

		# Interpoliere Zoom
		current_zoom = lerp(current_zoom, target_zoom, delta * ZOOM_SMOOTH_SPEED)

		# Wende Zoom an
		_apply_zoom()

		# Sende Zoom-Changed-Event
		EventBus.map_zoom_changed.emit(current_zoom, target_zoom)
	else:
		if is_zooming:
			current_zoom = target_zoom
			is_zooming = false
			EventBus.map_zoom_completed.emit(current_zoom)

func _input(event: InputEvent) -> void:
	"""Behandelt Mausrad-Zoom."""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_in(ZOOM_STEP_MOUSE, event.position)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_out(ZOOM_STEP_MOUSE, event.position)
			get_viewport().set_input_as_handled()

# === ZOOM-FUNKTIONEN ===

func zoom_in(step: float = ZOOM_STEP_BUTTON, screen_pos: Vector2 = Vector2.ZERO) -> void:
	"""
	Zoomt hinein.
	@param step: Zoom-Schritt
	@param screen_pos: Bildschirm-Position für Zoom-Pivot (optional)
	"""
	set_zoom(target_zoom + step, screen_pos)

func zoom_out(step: float = ZOOM_STEP_BUTTON, screen_pos: Vector2 = Vector2.ZERO) -> void:
	"""
	Zoomt heraus.
	@param step: Zoom-Schritt
	@param screen_pos: Bildschirm-Position für Zoom-Pivot (optional)
	"""
	set_zoom(target_zoom - step, screen_pos)

func set_zoom(new_zoom: float, screen_pos: Vector2 = Vector2.ZERO) -> void:
	"""
	Setzt Zoom-Level.
	@param new_zoom: Neuer Zoom-Wert
	@param screen_pos: Bildschirm-Position für Zoom-Pivot (optional)
	"""
	if not map_controller:
		return

	# Begrenze Zoom
	var old_zoom = target_zoom
	target_zoom = clamp(new_zoom, ZOOM_MIN, ZOOM_MAX)

	# Berechne Zoom-Fokus-Punkt
	_update_zoom_focus(screen_pos, old_zoom)

	# Ohne Smoothing: Sofort anwenden
	if not ZOOM_SMOOTHING:
		current_zoom = target_zoom
		_apply_zoom()
		EventBus.map_zoom_changed.emit(current_zoom, target_zoom)
		EventBus.map_zoom_completed.emit(current_zoom)

func set_zoom_instant(new_zoom: float) -> void:
	"""
	Setzt Zoom sofort ohne Animation.
	@param new_zoom: Neuer Zoom-Wert
	"""
	target_zoom = clamp(new_zoom, ZOOM_MIN, ZOOM_MAX)
	current_zoom = target_zoom
	_apply_zoom()
	EventBus.map_zoom_changed.emit(current_zoom, target_zoom)
	EventBus.map_zoom_completed.emit(current_zoom)

func reset_zoom() -> void:
	"""Setzt Zoom auf Standard zurück."""
	set_zoom(ZOOM_DEFAULT)

func zoom_to_fit_bounds(bounds_min: Vector2, bounds_max: Vector2, padding: float = 50.0) -> void:
	"""
	Zoomt so dass bestimmte Bounds sichtbar sind.
	@param bounds_min: Minimale Map-Pixel-Koordinate
	@param bounds_max: Maximale Map-Pixel-Koordinate
	@param padding: Padding in Pixeln
	"""
	if not map_controller:
		return

	viewport_size = map_controller.get_viewport_rect().size

	var bounds_size = bounds_max - bounds_min
	var viewport_available = viewport_size - Vector2(padding * 2, padding * 2)

	# Berechne benötigten Zoom
	var zoom_x = viewport_available.x / bounds_size.x
	var zoom_y = viewport_available.y / bounds_size.y
	var fit_zoom = min(zoom_x, zoom_y)

	# Begrenze Zoom
	fit_zoom = clamp(fit_zoom, ZOOM_MIN, ZOOM_MAX)

	# Setze Zoom
	set_zoom_instant(fit_zoom)

	# Zentriere Bounds
	var bounds_center = (bounds_min + bounds_max) / 2.0
	var screen_center = viewport_size / 2.0
	map_controller.position = screen_center - bounds_center * current_zoom

# === INTERNE FUNKTIONEN ===

func _update_zoom_focus(screen_pos: Vector2, old_zoom: float) -> void:
	"""
	Aktualisiert Zoom-Fokus-Punkt basierend auf Pivot-Modus.
	@param screen_pos: Bildschirm-Position (für MOUSE-Modus)
	@param old_zoom: Vorheriger Zoom-Wert
	"""
	if not map_controller:
		return

	match zoom_pivot_mode:
		ZoomPivot.CENTER:
			# Zoom zur Karten-Mitte
			viewport_size = map_controller.get_viewport_rect().size
			zoom_focus_point = viewport_size / 2.0

		ZoomPivot.MOUSE:
			# Zoom zur Maus-Position
			if screen_pos != Vector2.ZERO:
				zoom_focus_point = screen_pos
			else:
				# Fallback: Viewport-Mitte
				viewport_size = map_controller.get_viewport_rect().size
				zoom_focus_point = viewport_size / 2.0

		ZoomPivot.SELECTION:
			# Zoom zur Selektion (TODO: Implementiere wenn Selection-System erweitert)
			viewport_size = map_controller.get_viewport_rect().size
			zoom_focus_point = viewport_size / 2.0

func _apply_zoom() -> void:
	"""Wendet aktuellen Zoom auf MapController an."""
	if not map_controller:
		return

	# Berechne Map-Position vor Zoom (in Map-Pixel-Koordinaten)
	var focus_map_pos_before = (zoom_focus_point - map_controller.position) / map_controller.scale.x

	# Wende neuen Zoom an
	map_controller.scale = Vector2(current_zoom, current_zoom)

	# Berechne Map-Position nach Zoom
	var focus_map_pos_after = focus_map_pos_before * current_zoom

	# Passe Position an um Fokus-Punkt beizubehalten
	map_controller.position = zoom_focus_point - focus_map_pos_after

# === GETTER ===

func get_current_zoom() -> float:
	"""Gibt aktuellen Zoom-Level zurück."""
	return current_zoom

func get_target_zoom() -> float:
	"""Gibt Ziel-Zoom-Level zurück."""
	return target_zoom

func get_zoom_progress() -> float:
	"""Gibt Zoom-Progress zwischen Min und Max zurück (0.0 - 1.0)."""
	return inverse_lerp(ZOOM_MIN, ZOOM_MAX, current_zoom)

func is_zooming_active() -> bool:
	"""Gibt zurück ob gerade gezoomt wird."""
	return is_zooming

func get_zoom_info() -> Dictionary:
	"""
	Gibt Zoom-Informationen zurück.
	@return: Dictionary mit Zoom-Daten
	"""
	return {
		"current": current_zoom,
		"target": target_zoom,
		"min": ZOOM_MIN,
		"max": ZOOM_MAX,
		"progress": get_zoom_progress(),
		"is_zooming": is_zooming,
		"pivot_mode": zoom_pivot_mode
	}

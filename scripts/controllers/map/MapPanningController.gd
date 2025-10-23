class_name MapPanningController
extends Node

## Verwaltet Kamera-Panning mit WASD und rechter Maustaste
## Implementiert Bounds-Checking um sicherzustellen dass Kamera im Map-Bereich bleibt

# === PANNING-KONFIGURATION ===
const PAN_SPEED_KEYBOARD: float = 400.0   # Pixel pro Sekunde (WASD)
const PAN_SPEED_MOUSE: float = 1.0        # Multiplier für Maus-Dragging
const SMOOTH_PANNING: bool = true         # Sanftes Panning
const PAN_SMOOTH_SPEED: float = 10.0      # Geschwindigkeit der Interpolation

# Bounds-Konfiguration
const BOUNDS_PADDING: float = 50.0        # Minimaler Abstand zu Karten-Rand

# === STATE ===
var is_panning_mouse: bool = false        # Wird gerade mit Maus gepannt?
var last_mouse_pos: Vector2 = Vector2.ZERO
var pan_velocity: Vector2 = Vector2.ZERO  # Aktuelle Pan-Geschwindigkeit

# === REFERENZEN ===
var map_controller: Node2D
var viewport_size: Vector2
var map_size: Vector2  # Größe der Karte in Pixeln

# === BOUNDS ===
var bounds_min: Vector2  # Minimale erlaubte Position (obere linke Ecke)
var bounds_max: Vector2  # Maximale erlaubte Position (untere rechte Ecke)

func _ready() -> void:
	set_process(true)

func initialize(p_map_controller: Node2D, p_map_size: Vector2) -> void:
	"""
	Initialisiert den Panning-Controller.
	@param p_map_controller: Referenz zum MapController
	@param p_map_size: Größe der Karte in Pixeln (width, height)
	"""
	map_controller = p_map_controller
	map_size = p_map_size
	viewport_size = map_controller.get_viewport_rect().size

	# Berechne initiale Bounds
	_update_bounds()

	print("MapPanningController: Initialisiert")
	print("  Map Size: %.0fx%.0f px" % [map_size.x, map_size.y])
	print("  Viewport Size: %.0fx%.0f px" % [viewport_size.x, viewport_size.y])
	print("  Initial Bounds: (%.0f, %.0f) → (%.0f, %.0f)" % [
		bounds_min.x, bounds_min.y, bounds_max.x, bounds_max.y
	])

func _process(delta: float) -> void:
	"""Verarbeitet kontinuierliches Panning."""
	if not map_controller:
		return

	# WASD-Panning
	var keyboard_pan = _get_keyboard_pan_vector()
	if keyboard_pan != Vector2.ZERO:
		_apply_pan(keyboard_pan * PAN_SPEED_KEYBOARD * delta)

	# Sanftes Panning (Velocity-Dämpfung)
	if SMOOTH_PANNING and pan_velocity.length() > 1.0:
		_apply_pan(pan_velocity * delta)
		pan_velocity = pan_velocity.lerp(Vector2.ZERO, delta * PAN_SMOOTH_SPEED)

func _input(event: InputEvent) -> void:
	"""Behandelt Maus-Panning."""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				# Start Panning
				is_panning_mouse = true
				last_mouse_pos = event.position
				pan_velocity = Vector2.ZERO
				EventBus.map_panning_started.emit()
			else:
				# Stop Panning
				is_panning_mouse = false
				EventBus.map_panning_stopped.emit()

	elif event is InputEventMouseMotion:
		if is_panning_mouse:
			# Berechne Delta
			var delta = event.position - last_mouse_pos
			last_mouse_pos = event.position

			# Wende Pan an (invertiert, da Karte bewegt wird, nicht Kamera)
			_apply_pan(delta * PAN_SPEED_MOUSE)

			# Setze Velocity für sanftes Ausrollen
			if SMOOTH_PANNING:
				pan_velocity = delta * PAN_SPEED_MOUSE * 10.0

# === PANNING-FUNKTIONEN ===

func _get_keyboard_pan_vector() -> Vector2:
	"""
	Gibt Pan-Richtung basierend auf WASD-Input zurück.
	@return: Normalisierter Richtungsvektor
	"""
	var pan_dir = Vector2.ZERO

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		pan_dir.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		pan_dir.y -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		pan_dir.x += 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		pan_dir.x -= 1.0

	return pan_dir.normalized() if pan_dir.length() > 0 else Vector2.ZERO

func _apply_pan(delta: Vector2) -> void:
	"""
	Wendet Pan-Delta auf MapController an mit Bounds-Checking.
	@param delta: Pan-Delta in Pixel
	"""
	if not map_controller:
		return

	# Neue Position berechnen
	var new_pos = map_controller.position + delta

	# Bounds-Checking
	new_pos = _clamp_to_bounds(new_pos)

	# Position setzen
	map_controller.position = new_pos

	# Event senden (nur wenn sich Position geändert hat)
	if delta.length() > 0.1:
		EventBus.map_panned.emit(new_pos)

func _clamp_to_bounds(pos: Vector2) -> Vector2:
	"""
	Begrenzt Position auf erlaubte Bounds.
	@param pos: Gewünschte Position
	@return: Position innerhalb der Bounds
	"""
	var clamped = pos

	# Wenn Karte kleiner als Viewport: Zentriere
	var current_zoom = map_controller.scale.x
	var scaled_map_size = map_size * current_zoom

	if scaled_map_size.x < viewport_size.x:
		# Karte schmaler als Viewport → Zentriere horizontal
		clamped.x = (viewport_size.x - scaled_map_size.x) / 2.0
	else:
		# Karte breiter als Viewport → Begrenze auf Ränder
		clamped.x = clamp(clamped.x, bounds_min.x, bounds_max.x)

	if scaled_map_size.y < viewport_size.y:
		# Karte niedriger als Viewport → Zentriere vertikal
		clamped.y = (viewport_size.y - scaled_map_size.y) / 2.0
	else:
		# Karte höher als Viewport → Begrenze auf Ränder
		clamped.y = clamp(clamped.y, bounds_min.y, bounds_max.y)

	return clamped

func _update_bounds() -> void:
	"""
	Aktualisiert Bounds basierend auf aktuellem Zoom.
	Muss aufgerufen werden wenn Zoom sich ändert.
	"""
	if not map_controller:
		return

	var current_zoom = map_controller.scale.x
	var scaled_map_size = map_size * current_zoom

	# Bounds für Map-Position berechnen
	# Position (0,0) = Karten-Oberkante-Links ist bei Viewport-Oberkante-Links
	# Minimale Position: Karten-Unterkante-Rechts ist bei Viewport-Unterkante-Rechts

	bounds_min.x = viewport_size.x - scaled_map_size.x - BOUNDS_PADDING
	bounds_min.y = viewport_size.y - scaled_map_size.y - BOUNDS_PADDING

	bounds_max.x = BOUNDS_PADDING
	bounds_max.y = BOUNDS_PADDING

	# Falls Karte kleiner als Viewport: Invertiere Bounds (erlaubt Zentrierung)
	if scaled_map_size.x < viewport_size.x:
		bounds_min.x = (viewport_size.x - scaled_map_size.x) / 2.0
		bounds_max.x = bounds_min.x

	if scaled_map_size.y < viewport_size.y:
		bounds_min.y = (viewport_size.y - scaled_map_size.y) / 2.0
		bounds_max.y = bounds_min.y

# === PUBLIC API ===

func pan_to_position(world_pos: Vector2, zoom: float = -1.0) -> void:
	"""
	Panned zu einer bestimmten World-Position.
	@param world_pos: Position in Map-Pixel-Koordinaten
	@param zoom: Optionaler Zoom-Level (nutzt aktuellen wenn < 0)
	"""
	if not map_controller:
		return

	var current_zoom = zoom if zoom > 0 else map_controller.scale.x

	# Berechne Position sodass world_pos in Viewport-Mitte ist
	var screen_center = viewport_size / 2.0
	var new_map_pos = screen_center - world_pos * current_zoom

	# Wende mit Bounds-Checking an
	map_controller.position = _clamp_to_bounds(new_map_pos)

func center_map() -> void:
	"""Zentriert Karte im Viewport."""
	if not map_controller:
		return

	var current_zoom = map_controller.scale.x
	var scaled_map_size = map_size * current_zoom

	var centered_pos = Vector2(
		(viewport_size.x - scaled_map_size.x) / 2.0,
		(viewport_size.y - scaled_map_size.y) / 2.0
	)

	map_controller.position = _clamp_to_bounds(centered_pos)

func update_bounds_for_zoom(zoom: float) -> void:
	"""
	Aktualisiert Bounds für neuen Zoom-Level.
	@param zoom: Neuer Zoom-Level
	"""
	_update_bounds()

	# Passe aktuelle Position an neue Bounds an
	if map_controller:
		map_controller.position = _clamp_to_bounds(map_controller.position)

func set_pan_speed(keyboard_speed: float, mouse_speed: float) -> void:
	"""
	Setzt Pan-Geschwindigkeiten.
	@param keyboard_speed: WASD-Geschwindigkeit (px/s)
	@param mouse_speed: Maus-Geschwindigkeit (Multiplier)
	"""
	# Note: Diese Werte sind const, müssten für Runtime-Änderung als var deklariert werden
	push_warning("MapPanningController: Pan-Geschwindigkeiten sind Konstanten und können nicht zur Laufzeit geändert werden")

func stop_panning() -> void:
	"""Stoppt aktives Panning."""
	is_panning_mouse = false
	pan_velocity = Vector2.ZERO

func is_panning() -> bool:
	"""Gibt zurück ob gerade gepannt wird."""
	return is_panning_mouse or pan_velocity.length() > 1.0

# === GETTER ===

func get_bounds_min() -> Vector2:
	"""Gibt minimale Bounds zurück."""
	return bounds_min

func get_bounds_max() -> Vector2:
	"""Gibt maximale Bounds zurück."""
	return bounds_max

func get_current_pan_velocity() -> Vector2:
	"""Gibt aktuelle Pan-Velocity zurück."""
	return pan_velocity

func get_panning_info() -> Dictionary:
	"""
	Gibt Panning-Informationen zurück.
	@return: Dictionary mit Panning-Daten
	"""
	return {
		"is_panning": is_panning(),
		"is_panning_mouse": is_panning_mouse,
		"velocity": pan_velocity,
		"bounds_min": bounds_min,
		"bounds_max": bounds_max,
		"map_size": map_size,
		"viewport_size": viewport_size
	}

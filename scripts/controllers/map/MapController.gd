extends Node2D

signal territory_clicked(territory_type: String, territory_id: String)

# === MAP SCALE RESOURCE ===
@export var map_scale_resource: MapScale
var map_scale: MapScale

# === DEBUG ===
@export var show_debug_ui: bool = true  # Toggle für Debug-UI
var debug_ui: Control

# === POLYGON RENDERER ===
var polygon_renderer: PolygonRenderer

# === INTERACTION LAYER ===
var interaction_layer: MapInteractionLayer

# === ZOOM SYSTEM ===
var zoom_controller: MapZoomController
var zoom_level_manager: ZoomLevelManager
var label_manager: MapLabelManager

# === PANNING SYSTEM ===
var panning_controller: MapPanningController

# === MAP LAYERS ===
var region_layer: Node2D
var nation_layer: Node2D
var province_layer: Node2D
var district_layer: Node2D
var label_layer: Node2D

# === TERRITORY SHAPES ===
var region_shapes: Dictionary = {}
var nation_shapes: Dictionary = {}
var province_shapes: Dictionary = {}
var district_shapes: Dictionary = {}

# === TERRITORY LABELS ===
var region_labels: Dictionary = {}
var nation_labels: Dictionary = {}
var province_labels: Dictionary = {}
var district_labels: Dictionary = {}

# === INTERACTION ===
var hovered_territory: Dictionary = {}
var selected_territory: Dictionary = {}

func _ready() -> void:
	_initialize_polygon_renderer()
	_initialize_map_scale()
	_setup_layers()
	_initialize_zoom_system()
	_initialize_panning_system()
	_initialize_interaction_layer()
	_initialize_debug_ui()
	_connect_signals()
	call_deferred("_delayed_load")

func _initialize_polygon_renderer() -> void:
	"""Initialisiert das Polygon-Renderer-System."""
	polygon_renderer = PolygonRenderer.new()
	polygon_renderer.print_render_config()
	print("MapController: PolygonRenderer initialized")

func _initialize_map_scale() -> void:
	"""Initializes map scale from resource or creates default."""
	if map_scale_resource:
		map_scale = map_scale_resource
	else:
		# Load default map scale
		map_scale = load("res://data/map_scales/default_map_scale.tres") as MapScale
		if not map_scale:
			# Fallback: create default in code
			map_scale = MapScale.new()
			print("MapController: Using fallback MapScale")

	print("MapController: Map Scale loaded")
	print(map_scale.get_info_string())

func _delayed_load() -> void:
	"""Lädt die Karte verzögert."""
	if GameState.provinces.size() == 0:
		print("MapController: Warte auf Provinz-Daten...")
		await get_tree().create_timer(0.5).timeout
		_delayed_load()
		return

	_load_map_data()
	_center_map()

func _setup_layers() -> void:
	"""Erstellt Map-Layer als Node2D-Hierarchie."""
	region_layer = Node2D.new()
	region_layer.name = "RegionLayer"
	add_child(region_layer)

	nation_layer = Node2D.new()
	nation_layer.name = "NationLayer"
	add_child(nation_layer)

	province_layer = Node2D.new()
	province_layer.name = "ProvinceLayer"
	add_child(province_layer)

	district_layer = Node2D.new()
	district_layer.name = "DistrictLayer"
	add_child(district_layer)

	label_layer = Node2D.new()
	label_layer.name = "LabelLayer"
	add_child(label_layer)

func _initialize_zoom_system() -> void:
	"""Initialisiert das Zoom-System (Controller, LOD-Manager, Label-Manager)."""
	# Zoom Controller
	zoom_controller = MapZoomController.new()
	zoom_controller.name = "ZoomController"
	add_child(zoom_controller)

	# Zoom Level Manager
	zoom_level_manager = ZoomLevelManager.new()
	zoom_level_manager.name = "ZoomLevelManager"
	add_child(zoom_level_manager)

	# Label Manager
	label_manager = MapLabelManager.new()
	label_manager.name = "LabelManager"
	add_child(label_manager)

	print("MapController: Zoom-System initialisiert")

func _initialize_panning_system() -> void:
	"""Initialisiert das Panning-System."""
	panning_controller = MapPanningController.new()
	panning_controller.name = "PanningController"
	add_child(panning_controller)
	print("MapController: Panning-System initialisiert")

func _initialize_interaction_layer() -> void:
	"""Initialisiert die dedizierte Interaktions-Layer."""
	interaction_layer = MapInteractionLayer.new()
	interaction_layer.name = "InteractionLayer"
	add_child(interaction_layer)
	print("MapController: MapInteractionLayer erstellt")

func _initialize_debug_ui() -> void:
	"""Initialisiert die Debug-UI (optional)."""
	if not show_debug_ui:
		return

	# Lade Debug-UI-Script
	var MapDebugUI = load("res://scripts/views/map/MapDebugUI.gd")
	if MapDebugUI:
		debug_ui = MapDebugUI.new()
		debug_ui.name = "MapDebugUI"

		# WICHTIG: Füge Debug-UI zum Root-Node hinzu, nicht zum MapController
		# Damit bewegt sie sich nicht mit der Karte mit
		# VERWENDE call_deferred weil Root gerade busy sein könnte
		var root = get_tree().root
		if root:
			root.call_deferred("add_child", debug_ui)
			print("MapController: Debug-UI erstellt (als Top-Level, deferred)")
		else:
			push_warning("MapController: Konnte Root-Node nicht finden")
	else:
		push_warning("MapController: MapDebugUI.gd nicht gefunden")

func _connect_signals() -> void:
	EventBus.province_selected.connect(_on_province_selected)
	EventBus.territory_clicked.connect(_on_territory_clicked)
	EventBus.territory_hovered.connect(_on_territory_hovered)
	EventBus.territory_selected.connect(_on_territory_selected)

	# Zoom Signals
	EventBus.map_zoom_changed.connect(_on_zoom_changed)
	EventBus.map_zoom_completed.connect(_on_zoom_completed)
	EventBus.map_zoom_level_changed.connect(_on_zoom_level_changed)

	# Panning Signals
	EventBus.map_panning_started.connect(_on_panning_started)
	EventBus.map_panning_stopped.connect(_on_panning_stopped)

func _load_map_data() -> void:
	"""Lädt alle Kartendaten."""
	print("MapController: Lade Kartendaten...")

	for region_id in GameState.regions.keys():
		_create_region_polygon(GameState.regions[region_id])

	for nation_id in GameState.nations.keys():
		_create_nation_polygon(GameState.nations[nation_id])

	for province_id in GameState.provinces.keys():
		_create_province_polygon(GameState.provinces[province_id])

	for district_id in GameState.districts.keys():
		_create_district_polygon(GameState.districts[district_id])

	print("MapController: %d Regionen, %d Nationen, %d Provinzen, %d Distrikte geladen (4-Layer-Hierarchie)" % [
		region_shapes.size(), nation_shapes.size(), province_shapes.size(), district_shapes.size()
	])

	# Alle Layer sichtbar (statisch)
	region_layer.visible = false  # Regionen standardmäßig aus
	nation_layer.visible = true
	province_layer.visible = true
	district_layer.visible = false  # Distrikte standardmäßig aus

	# Alle Labels sichtbar
	for label in region_labels.values():
		if label:
			label.visible = false
	for label in nation_labels.values():
		if label:
			label.visible = true
	for label in province_labels.values():
		if label:
			label.visible = true

	# Initialisiere Interaktions-Layer mit Map-Daten
	if interaction_layer:
		interaction_layer.initialize(self, polygon_renderer)

	# Initialisiere Zoom-System mit Map-Daten
	if zoom_controller:
		zoom_controller.initialize(self)

	if zoom_level_manager:
		zoom_level_manager.initialize(region_layer, nation_layer, province_layer, district_layer)

	if label_manager:
		label_manager.initialize(self, zoom_level_manager, region_labels, nation_labels, province_labels, district_labels)

	# Initialisiere Panning-System mit Map-Daten
	if panning_controller:
		var map_size = Vector2(map_scale.map_width_pixels, map_scale.map_height_pixels)
		panning_controller.initialize(self, map_size)

	# Initialisiere Debug-UI (falls aktiviert)
	if debug_ui:
		debug_ui.initialize(self)

func _center_map() -> void:
	"""Zentriert Karte im Viewport."""
	var viewport_size = get_viewport_rect().size
	position = Vector2(
		(viewport_size.x - map_scale.map_width_pixels) / 2.0,
		(viewport_size.y - map_scale.map_height_pixels) / 2.0
	)
	scale = Vector2(1.0, 1.0)

# === POLYGON CREATION ===

func _create_region_polygon(region) -> void:
	if not polygon_renderer.validate_polygon(region.boundary_polygon):
		print("MapController: Region %s has invalid polygon, skipping" % region.id)
		return

	var polygon = Polygon2D.new()
	polygon.name = "Region_" + region.id
	polygon.polygon = region.boundary_polygon

	# Wende Render-Konfiguration an
	polygon_renderer.apply_fill_color(polygon, "region", region.color)

	# Erstelle Grenzlinie mit Hierarchie-spezifischen Einstellungen
	var line = polygon_renderer.create_boundary_line(region.boundary_polygon, "region")
	polygon.add_child(line)

	# Metadaten für Interaktion
	polygon.set_meta("territory_type", "region")
	polygon.set_meta("territory_id", region.id)

	region_layer.add_child(polygon)
	region_shapes[region.id] = polygon

	var label = _create_territory_label(region.name, region.boundary_polygon, 24)
	region_labels[region.id] = label

func _create_nation_polygon(nation) -> void:
	if not polygon_renderer.validate_polygon(nation.boundary_polygon):
		print("MapController: Nation %s has invalid polygon, skipping" % nation.id)
		return

	var polygon = Polygon2D.new()
	polygon.name = "Nation_" + nation.id
	polygon.polygon = nation.boundary_polygon

	# Wende Render-Konfiguration an
	polygon_renderer.apply_fill_color(polygon, "nation", nation.color)

	# Erstelle Grenzlinie mit Hierarchie-spezifischen Einstellungen
	var line = polygon_renderer.create_boundary_line(nation.boundary_polygon, "nation")
	polygon.add_child(line)

	# Metadaten für Interaktion
	polygon.set_meta("territory_type", "nation")
	polygon.set_meta("territory_id", nation.id)

	nation_layer.add_child(polygon)
	nation_shapes[nation.id] = polygon

	var label = _create_territory_label(nation.name, nation.boundary_polygon, 20)
	nation_labels[nation.id] = label

func _create_province_polygon(province) -> void:
	if not polygon_renderer.validate_polygon(province.boundary_polygon):
		print("MapController: Province %s has invalid polygon, skipping" % province.id)
		return

	var polygon = Polygon2D.new()
	polygon.name = "Province_" + province.id
	polygon.polygon = province.boundary_polygon

	# Wende Render-Konfiguration an
	polygon_renderer.apply_fill_color(polygon, "province", province.color)

	# Erstelle Grenzlinie mit Hierarchie-spezifischen Einstellungen
	var line = polygon_renderer.create_boundary_line(province.boundary_polygon, "province")
	polygon.add_child(line)

	# Metadaten für Interaktion
	polygon.set_meta("territory_type", "province")
	polygon.set_meta("territory_id", province.id)

	province_layer.add_child(polygon)
	province_shapes[province.id] = polygon

	var label = _create_territory_label(province.name, province.boundary_polygon, 16)
	province_labels[province.id] = label

func _create_district_polygon(district) -> void:
	if not polygon_renderer.validate_polygon(district.boundary_polygon):
		print("MapController: District %s has invalid polygon, skipping" % district.id)
		return

	var polygon = Polygon2D.new()
	polygon.name = "District_" + district.id
	polygon.polygon = district.boundary_polygon

	# Wende Render-Konfiguration an (mit leichter Abdunklung für Districts)
	var darkened_color = district.color.darkened(0.05)
	polygon_renderer.apply_fill_color(polygon, "district", darkened_color)

	# Erstelle Grenzlinie mit Hierarchie-spezifischen Einstellungen
	var line = polygon_renderer.create_boundary_line(district.boundary_polygon, "district")
	polygon.add_child(line)

	# Metadaten für Interaktion
	polygon.set_meta("territory_type", "district")
	polygon.set_meta("territory_id", district.id)

	district_layer.add_child(polygon)
	district_shapes[district.id] = polygon

	var label = _create_territory_label(district.name, district.boundary_polygon, 12)
	district_labels[district.id] = label

func _create_territory_label(territory_name: String, polygon: PackedVector2Array, font_size: int) -> Label:
	"""Erstellt Label für Territorium."""
	var label = Label.new()
	label.text = territory_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	label.add_theme_font_size_override("font_size", font_size)

	# Position in World-Koordinaten (Polygon-Zentrum)
	var center = _get_polygon_center(polygon)
	label.position = center

	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_color", Color.WHITE)

	# Größe und Pivot für Zentrierung
	label.custom_minimum_size = Vector2(200, 40)
	label.pivot_offset = label.custom_minimum_size / 2.0

	label_layer.add_child(label)

	return label

# === INPUT (jetzt durch MapInteractionLayer gehandhabt) ===
# Die alte _input-Logik wurde in MapInteractionLayer verschoben

# === COORDINATE CONVERSION ===

func _screen_to_map_pixel(screen_pos: Vector2) -> Vector2:
	"""
	Screen → Map Pixel coordinates.
	Accounts for map position and scale in viewport.
	"""
	return (screen_pos - position) / scale.x

func _map_pixel_to_screen(map_pixel_pos: Vector2) -> Vector2:
	"""
	Map Pixel → Screen coordinates.
	Accounts for map position and scale in viewport.
	"""
	return map_pixel_pos * scale.x + position

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	"""
	Screen → World coordinates (km).
	Complete conversion chain: Screen → MapPixel → World
	"""
	var map_pixel = _screen_to_map_pixel(screen_pos)
	return map_scale.pixel_to_world(map_pixel)

func _world_to_screen(world_pos: Vector2) -> Vector2:
	"""
	World coordinates (km) → Screen.
	Complete conversion chain: World → MapPixel → Screen
	"""
	var map_pixel = map_scale.world_to_pixel(world_pos)
	return _map_pixel_to_screen(map_pixel)

# === VISUAL (jetzt durch MapInteractionLayer gehandhabt) ===
# Highlights werden jetzt in MapInteractionLayer mit Line2D gezeichnet

# === EVENT HANDLERS ===

func _on_province_selected(province_id: String) -> void:
	"""Handler für altes province_selected Signal (Kompatibilität)."""
	EventBus.territory_selected.emit("province", province_id)

func _on_territory_clicked(territory_type: String, territory_id: String) -> void:
	"""Handler für territory_clicked Signal."""
	# Emit eigenes legacy Signal für Kompatibilität
	territory_clicked.emit(territory_type, territory_id)

	# Update selected_territory für Kompatibilität
	selected_territory = {"type": territory_type, "id": territory_id}

	print("MapController: Territorium geklickt: %s [%s]" % [territory_id, territory_type])

func _on_territory_hovered(territory_type: String, territory_id: String) -> void:
	"""Handler für territory_hovered Signal."""
	hovered_territory = {"type": territory_type, "id": territory_id}

func _on_territory_selected(territory_type: String, territory_id: String) -> void:
	"""Handler für territory_selected Signal."""
	selected_territory = {"type": territory_type, "id": territory_id}

func _on_zoom_changed(current_zoom: float, target_zoom: float) -> void:
	"""Handler für map_zoom_changed Signal."""
	# Update LOD-Manager
	if zoom_level_manager:
		zoom_level_manager.update_zoom(current_zoom)

	# Update Label-Manager
	if label_manager:
		label_manager.update_labels(current_zoom)

	# Update Panning-Bounds
	if panning_controller:
		panning_controller.update_bounds_for_zoom(current_zoom)

func _on_zoom_completed(final_zoom: float) -> void:
	"""Handler für map_zoom_completed Signal."""
	print("MapController: Zoom abgeschlossen bei %.2f" % final_zoom)

func _on_zoom_level_changed(new_level: int, old_level: int) -> void:
	"""Handler für map_zoom_level_changed Signal."""
	print("MapController: LOD-Wechsel: %d → %d" % [old_level, new_level])

func _on_panning_started() -> void:
	"""Handler für map_panning_started Signal."""
	pass  # Kann für UI-Feedback genutzt werden

func _on_panning_stopped() -> void:
	"""Handler für map_panning_stopped Signal."""
	pass  # Kann für UI-Feedback genutzt werden

# === HELPERS ===

func _get_polygon_center(polygon: PackedVector2Array) -> Vector2:
	"""Berechnet Polygon-Zentrum."""
	if polygon.size() == 0:
		return Vector2.ZERO

	var sum = Vector2.ZERO
	for point in polygon:
		sum += point
	return sum / polygon.size()

# === PUBLIC UTILITY FUNCTIONS ===

func calculate_distance_km(world_pos1: Vector2, world_pos2: Vector2) -> float:
	"""
	Calculates distance in km between two world coordinates.
	@param world_pos1: First position in world coordinates (km)
	@param world_pos2: Second position in world coordinates (km)
	@return: Distance in kilometers
	"""
	return map_scale.calculate_distance_km(world_pos1, world_pos2)

func calculate_distance_km_from_pixels(pixel_pos1: Vector2, pixel_pos2: Vector2) -> float:
	"""
	Calculates distance in km between two pixel coordinates.
	@param pixel_pos1: First position in pixel coordinates
	@param pixel_pos2: Second position in pixel coordinates
	@return: Distance in kilometers
	"""
	return map_scale.calculate_distance_km_from_pixels(pixel_pos1, pixel_pos2)

func calculate_area_km2(world_polygon: PackedVector2Array) -> float:
	"""
	Calculates area in km² for a polygon in world coordinates.
	@param world_polygon: Polygon vertices in world coordinates (km)
	@return: Area in square kilometers
	"""
	return map_scale.calculate_polygon_area_km2(world_polygon)

func calculate_area_km2_from_pixels(pixel_polygon: PackedVector2Array) -> float:
	"""
	Calculates area in km² for a polygon in pixel coordinates.
	@param pixel_polygon: Polygon vertices in pixel coordinates
	@return: Area in square kilometers
	"""
	return map_scale.calculate_polygon_area_km2_from_pixels(pixel_polygon)

func pixel_to_world(pixel_pos: Vector2) -> Vector2:
	"""Converts pixel coordinates to world coordinates (km)."""
	return map_scale.pixel_to_world(pixel_pos)

func world_to_pixel(world_pos: Vector2) -> Vector2:
	"""Converts world coordinates (km) to pixel coordinates."""
	return map_scale.world_to_pixel(world_pos)

# === ZOOM API ===

func zoom_in(step: float = 0.2) -> void:
	"""Zoomt hinein."""
	if zoom_controller:
		zoom_controller.zoom_in(step)

func zoom_out(step: float = 0.2) -> void:
	"""Zoomt heraus."""
	if zoom_controller:
		zoom_controller.zoom_out(step)

func set_zoom(zoom: float) -> void:
	"""Setzt Zoom-Level."""
	if zoom_controller:
		zoom_controller.set_zoom(zoom)

func reset_zoom() -> void:
	"""Setzt Zoom auf Standard zurück."""
	if zoom_controller:
		zoom_controller.reset_zoom()

func get_current_zoom() -> float:
	"""Gibt aktuellen Zoom-Level zurück."""
	if zoom_controller:
		return zoom_controller.get_current_zoom()
	return 1.0

func zoom_to_territory(territory_type: String, territory_id: String, zoom_level: float = 2.0) -> void:
	"""
	Zoomt zu einem Territorium.
	@param territory_type: Territorium-Typ
	@param territory_id: Territorium-ID
	@param zoom_level: Ziel-Zoom-Level
	"""
	var polygon: Polygon2D = null

	match territory_type:
		"nation": polygon = nation_shapes.get(territory_id)
		"province": polygon = province_shapes.get(territory_id)
		"district": polygon = district_shapes.get(territory_id)

	if polygon and zoom_controller:
		# Berechne Bounds
		var poly_points = polygon.polygon
		if poly_points.size() == 0:
			return

		var min_pos = poly_points[0]
		var max_pos = poly_points[0]

		for point in poly_points:
			min_pos.x = min(min_pos.x, point.x)
			min_pos.y = min(min_pos.y, point.y)
			max_pos.x = max(max_pos.x, point.x)
			max_pos.y = max(max_pos.y, point.y)

		# Zoom to fit
		zoom_controller.zoom_to_fit_bounds(min_pos, max_pos, 50.0)

# === PANNING API ===

func pan_to_position(world_pos: Vector2) -> void:
	"""
	Panned zu einer bestimmten Position.
	@param world_pos: Position in Map-Pixel-Koordinaten
	"""
	if panning_controller:
		panning_controller.pan_to_position(world_pos)

func center_map_view() -> void:
	"""Zentriert Karte im Viewport."""
	if panning_controller:
		panning_controller.center_map()

func get_panning_info() -> Dictionary:
	"""Gibt Panning-Informationen zurück."""
	if panning_controller:
		return panning_controller.get_panning_info()
	return {}

# === DEBUG API ===

func toggle_debug_ui() -> void:
	"""Toggle Debug-UI Sichtbarkeit (F3)."""
	if debug_ui:
		debug_ui.toggle_visibility()

func show_debug_ui_panel() -> void:
	"""Zeigt Debug-UI."""
	if debug_ui:
		debug_ui.show_debug()

func hide_debug_ui_panel() -> void:
	"""Versteckt Debug-UI."""
	if debug_ui:
		debug_ui.hide_debug()

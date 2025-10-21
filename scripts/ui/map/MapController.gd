extends Node2D

signal territory_clicked(territory_type: String, territory_id: String)

# === COORDINATE SYSTEM & METRICS ===
const MAP_WIDTH = 2000.0
const MAP_HEIGHT = 1200.0
const PIXELS_PER_KM = 0.5
const KM_PER_PIXEL = 2.0

# Geografisches Koordinatensystem
const GEO_LON_MIN = -180.0
const GEO_LON_MAX = 180.0
const GEO_LAT_MIN = -90.0
const GEO_LAT_MAX = 90.0

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
	_setup_layers()
	_connect_signals()
	call_deferred("_delayed_load")

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

func _connect_signals() -> void:
	EventBus.province_selected.connect(_on_province_selected)

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

	print("MapController: %d Regionen, %d Nationen, %d Provinzen, %d Distrikte geladen" % [
		region_shapes.size(), nation_shapes.size(), province_shapes.size(), district_shapes.size()
	])

	# Alle Layer sichtbar (statisch)
	region_layer.visible = true
	nation_layer.visible = true
	province_layer.visible = true
	district_layer.visible = false  # Distrikte standardmäßig aus

	# Alle Labels sichtbar
	for label in region_labels.values():
		if label:
			label.visible = true
	for label in nation_labels.values():
		if label:
			label.visible = true
	for label in province_labels.values():
		if label:
			label.visible = true

func _center_map() -> void:
	"""Zentriert Karte im Viewport."""
	var viewport_size = get_viewport_rect().size
	position = Vector2(
		(viewport_size.x - MAP_WIDTH) / 2.0,
		(viewport_size.y - MAP_HEIGHT) / 2.0
	)
	scale = Vector2(1.0, 1.0)

# === POLYGON CREATION ===

func _create_region_polygon(region) -> void:
	if region.boundary_polygon.size() < 3:
		return

	var polygon = Polygon2D.new()
	polygon.name = "Region_" + region.id
	polygon.polygon = region.boundary_polygon
	polygon.color = region.color
	polygon.antialiased = true
	polygon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	var line = Line2D.new()
	line.points = region.boundary_polygon
	line.add_point(region.boundary_polygon[0])
	line.default_color = Color(0.0, 0.0, 0.0, 1.0)
	line.width = 4.0
	line.antialiased = true
	polygon.add_child(line)

	polygon.set_meta("territory_type", "region")
	polygon.set_meta("territory_id", region.id)

	region_layer.add_child(polygon)
	region_shapes[region.id] = polygon

	var label = _create_territory_label(region.name, region.boundary_polygon, 24)
	region_labels[region.id] = label

func _create_nation_polygon(nation) -> void:
	if nation.boundary_polygon.size() < 3:
		return

	var polygon = Polygon2D.new()
	polygon.name = "Nation_" + nation.id
	polygon.polygon = nation.boundary_polygon
	polygon.color = nation.color
	polygon.antialiased = true
	polygon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	var line = Line2D.new()
	line.points = nation.boundary_polygon
	line.add_point(nation.boundary_polygon[0])
	line.default_color = Color(0.0, 0.0, 0.0, 1.0)
	line.width = 3.0
	line.antialiased = true
	polygon.add_child(line)

	polygon.set_meta("territory_type", "nation")
	polygon.set_meta("territory_id", nation.id)

	nation_layer.add_child(polygon)
	nation_shapes[nation.id] = polygon

	var label = _create_territory_label(nation.name, nation.boundary_polygon, 20)
	nation_labels[nation.id] = label

func _create_province_polygon(province) -> void:
	if province.boundary_polygon.size() < 3:
		return

	var polygon = Polygon2D.new()
	polygon.name = "Province_" + province.id
	polygon.polygon = province.boundary_polygon
	polygon.color = province.color
	polygon.antialiased = true
	polygon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	var line = Line2D.new()
	line.points = province.boundary_polygon
	line.add_point(province.boundary_polygon[0])
	line.default_color = Color(0.2, 0.2, 0.2, 0.8)
	line.width = 2.0
	line.antialiased = true
	polygon.add_child(line)

	polygon.set_meta("territory_type", "province")
	polygon.set_meta("territory_id", province.id)

	province_layer.add_child(polygon)
	province_shapes[province.id] = polygon

	var label = _create_territory_label(province.name, province.boundary_polygon, 16)
	province_labels[province.id] = label

func _create_district_polygon(district) -> void:
	if district.boundary_polygon.size() < 3:
		return

	var polygon = Polygon2D.new()
	polygon.name = "District_" + district.id
	polygon.polygon = district.boundary_polygon
	polygon.color = district.color.darkened(0.05)
	polygon.antialiased = true
	polygon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	var line = Line2D.new()
	line.points = district.boundary_polygon
	line.add_point(district.boundary_polygon[0])
	line.default_color = Color(0.3, 0.3, 0.3, 0.5)
	line.width = 1.0
	line.antialiased = true
	polygon.add_child(line)

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

# === INPUT ===

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_mouse_click(event.position)
	elif event is InputEventMouseMotion:
		_handle_mouse_hover(event.position)

func _handle_mouse_click(click_pos: Vector2) -> void:
	"""Klick-Behandlung."""
	var territory = _get_territory_at_position(click_pos)

	if territory.is_empty():
		return

	selected_territory = territory
	territory_clicked.emit(territory.type, territory.id)

	print("MapController: Territorium geklickt: %s (%s)" % [territory.id, territory.type])

func _handle_mouse_hover(mouse_pos: Vector2) -> void:
	"""Hover-Behandlung."""
	var territory = _get_territory_at_position(mouse_pos)

	if territory != hovered_territory:
		hovered_territory = territory
		queue_redraw()

func _get_territory_at_position(screen_pos: Vector2) -> Dictionary:
	"""Findet Territorium an Position."""
	var world_pos = _screen_to_world(screen_pos)

	if district_layer.visible:
		for district_id in district_shapes.keys():
			if _point_in_polygon(world_pos, district_shapes[district_id].polygon):
				return {"type": "district", "id": district_id}

	if province_layer.visible:
		for province_id in province_shapes.keys():
			if _point_in_polygon(world_pos, province_shapes[province_id].polygon):
				return {"type": "province", "id": province_id}

	if nation_layer.visible:
		for nation_id in nation_shapes.keys():
			if _point_in_polygon(world_pos, nation_shapes[nation_id].polygon):
				return {"type": "nation", "id": nation_id}

	if region_layer.visible:
		for region_id in region_shapes.keys():
			if _point_in_polygon(world_pos, region_shapes[region_id].polygon):
				return {"type": "region", "id": region_id}

	return {}

func _point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	"""Punkt-in-Polygon-Test."""
	if polygon.size() < 3:
		return false
	return Geometry2D.is_point_in_polygon(point, polygon)

# === COORDINATE CONVERSION ===

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	"""Screen → World."""
	return (screen_pos - position) / scale.x

func _world_to_screen(world_pos: Vector2) -> Vector2:
	"""World → Screen."""
	return world_pos * scale.x + position

# === VISUAL ===

func _draw() -> void:
	"""Zeichnet Highlights."""
	if not hovered_territory.is_empty():
		_draw_territory_highlight(hovered_territory, Color(1.0, 1.0, 1.0, 0.3))

	if not selected_territory.is_empty() and selected_territory != hovered_territory:
		_draw_territory_highlight(selected_territory, Color(1.0, 1.0, 0.0, 0.5))

func _draw_territory_highlight(territory: Dictionary, color: Color) -> void:
	"""Zeichnet Highlight."""
	var polygon: Polygon2D = null

	match territory.type:
		"region": polygon = region_shapes.get(territory.id)
		"nation": polygon = nation_shapes.get(territory.id)
		"province": polygon = province_shapes.get(territory.id)
		"district": polygon = district_shapes.get(territory.id)

	if polygon and polygon.polygon.size() > 0:
		draw_colored_polygon(polygon.polygon, color)

# === EVENT HANDLERS ===

func _on_province_selected(province_id: String) -> void:
	selected_territory = {"type": "province", "id": province_id}
	queue_redraw()

# === HELPERS ===

func _get_polygon_center(polygon: PackedVector2Array) -> Vector2:
	"""Berechnet Polygon-Zentrum."""
	if polygon.size() == 0:
		return Vector2.ZERO

	var sum = Vector2.ZERO
	for point in polygon:
		sum += point
	return sum / polygon.size()

# === GEO CONVERSION ===

func pixel_to_geo(pixel_pos: Vector2) -> Vector2:
	"""Pixel → Geo."""
	var lon = GEO_LON_MIN + (pixel_pos.x / MAP_WIDTH) * (GEO_LON_MAX - GEO_LON_MIN)
	var lat = GEO_LAT_MAX - (pixel_pos.y / MAP_HEIGHT) * (GEO_LAT_MAX - GEO_LAT_MIN)
	return Vector2(lon, lat)

func geo_to_pixel(geo_pos: Vector2) -> Vector2:
	"""Geo → Pixel."""
	var x = (geo_pos.x - GEO_LON_MIN) / (GEO_LON_MAX - GEO_LON_MIN) * MAP_WIDTH
	var y = (GEO_LAT_MAX - geo_pos.y) / (GEO_LAT_MAX - GEO_LAT_MIN) * MAP_HEIGHT
	return Vector2(x, y)

func calculate_distance_km(pixel_pos1: Vector2, pixel_pos2: Vector2) -> float:
	"""Entfernung in km."""
	return pixel_pos1.distance_to(pixel_pos2) * KM_PER_PIXEL

func calculate_area_km2(polygon: PackedVector2Array) -> float:
	"""Fläche in km²."""
	if polygon.size() < 3:
		return 0.0

	var area_pixels = 0.0
	var n = polygon.size()
	for i in range(n):
		var j = (i + 1) % n
		area_pixels += polygon[i].x * polygon[j].y
		area_pixels -= polygon[j].x * polygon[i].y

	area_pixels = abs(area_pixels) / 2.0
	return area_pixels * (KM_PER_PIXEL * KM_PER_PIXEL)

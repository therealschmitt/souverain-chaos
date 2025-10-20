extends Node2D

## Hierarchischer Karten-Controller mit 4 Zoomstufen
## Stufe 1: Weltkarte (Regionen)
## Stufe 2: Region (Nationen innerhalb der Region)
## Stufe 3: Nation (Provinzen innerhalb der Nation)
## Stufe 4: Provinz (Distrikte innerhalb der Provinz)

signal territory_clicked(territory_type: String, territory_id: String)

# === ZOOM SYSTEM ===
enum ZoomLevel {
	WORLD = 1,      # Regionen sichtbar
	REGION = 2,     # Nationen sichtbar
	NATION = 3,     # Provinzen sichtbar
	PROVINCE = 4    # Distrikte sichtbar
}

var current_zoom_level: ZoomLevel = ZoomLevel.WORLD
var focused_region_id: String = ""
var focused_nation_id: String = ""
var focused_province_id: String = ""

# === MAP LAYERS ===
var region_layer: Node2D
var nation_layer: Node2D
var province_layer: Node2D
var district_layer: Node2D
var label_layer: Node2D

# === TERRITORY SHAPES ===
var region_shapes: Dictionary = {}    # region_id -> Polygon2D
var nation_shapes: Dictionary = {}    # nation_id -> Polygon2D
var province_shapes: Dictionary = {}  # province_id -> Polygon2D
var district_shapes: Dictionary = {}  # district_id -> Polygon2D

# === INTERACTION ===
var hovered_territory: Dictionary = {}  # {type: String, id: String}
var selected_territory: Dictionary = {}  # {type: String, id: String}

# === CAMERA ===
var target_position: Vector2 = Vector2.ZERO
var target_scale: float = 1.0
var zoom_animation_speed: float = 5.0

func _ready() -> void:
	_setup_layers()
	_connect_signals()
	call_deferred("_delayed_load")

func _delayed_load() -> void:
	"""Lädt die Karte verzögert, nachdem GameInitializer fertig ist."""
	if GameState.provinces.size() == 0:
		print("MapController: Warte auf Provinz-Daten...")
		await get_tree().create_timer(0.5).timeout
		_delayed_load()
		return

	_load_map_data()

func _setup_layers() -> void:
	"""Erstellt alle Map-Layer in der richtigen Reihenfolge."""
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
	"""Lädt alle territorialen Daten."""
	print("MapController: Lade Kartendaten...")

	# Regionen laden
	for region_id in GameState.regions.keys():
		var region = GameState.regions[region_id]
		_create_region_polygon(region)

	# Nationen laden
	for nation_id in GameState.nations.keys():
		var nation = GameState.nations[nation_id]
		_create_nation_polygon(nation)

	# Provinzen laden
	for province_id in GameState.provinces.keys():
		var province = GameState.provinces[province_id]
		_create_province_polygon(province)

	# Distrikte laden
	for district_id in GameState.districts.keys():
		var district = GameState.districts[district_id]
		_create_district_polygon(district)

	print("MapController: %d Regionen, %d Nationen, %d Provinzen, %d Distrikte geladen" % [
		region_shapes.size(), nation_shapes.size(), province_shapes.size(), district_shapes.size()
	])

	_update_layer_visibility()

	# Starte bei Weltkarte-Ansicht
	_zoom_to_world()

# === POLYGON CREATION ===

func _create_region_polygon(region) -> void:
	if region.boundary_polygon.size() < 3:
		return

	var polygon = Polygon2D.new()
	polygon.name = "Region_" + region.id
	polygon.polygon = region.boundary_polygon
	polygon.color = region.color

	# Dicke Grenze für Regionen
	var line = Line2D.new()
	line.points = region.boundary_polygon
	line.add_point(region.boundary_polygon[0])
	line.default_color = Color(0.0, 0.0, 0.0, 1.0)
	line.width = 4.0
	polygon.add_child(line)

	polygon.set_meta("territory_type", "region")
	polygon.set_meta("territory_id", region.id)

	region_layer.add_child(polygon)
	region_shapes[region.id] = polygon

func _create_nation_polygon(nation) -> void:
	if nation.boundary_polygon.size() < 3:
		return

	var polygon = Polygon2D.new()
	polygon.name = "Nation_" + nation.id
	polygon.polygon = nation.boundary_polygon
	polygon.color = nation.color

	# Mittlere Grenze für Nationen
	var line = Line2D.new()
	line.points = nation.boundary_polygon
	line.add_point(nation.boundary_polygon[0])
	line.default_color = Color(0.0, 0.0, 0.0, 1.0)
	line.width = 3.0
	polygon.add_child(line)

	polygon.set_meta("territory_type", "nation")
	polygon.set_meta("territory_id", nation.id)

	nation_layer.add_child(polygon)
	nation_shapes[nation.id] = polygon

func _create_province_polygon(province) -> void:
	if province.boundary_polygon.size() < 3:
		return

	var polygon = Polygon2D.new()
	polygon.name = "Province_" + province.id
	polygon.polygon = province.boundary_polygon
	polygon.color = province.color

	# Dünne Grenze für Provinzen
	var line = Line2D.new()
	line.points = province.boundary_polygon
	line.add_point(province.boundary_polygon[0])
	line.default_color = Color(0.2, 0.2, 0.2, 0.8)
	line.width = 2.0
	polygon.add_child(line)

	polygon.set_meta("territory_type", "province")
	polygon.set_meta("territory_id", province.id)

	province_layer.add_child(polygon)
	province_shapes[province.id] = polygon

func _create_district_polygon(district) -> void:
	if district.boundary_polygon.size() < 3:
		return

	var polygon = Polygon2D.new()
	polygon.name = "District_" + district.id
	polygon.polygon = district.boundary_polygon
	polygon.color = district.color.darkened(0.05)

	# Sehr dünne Grenze für Distrikte
	var line = Line2D.new()
	line.points = district.boundary_polygon
	line.add_point(district.boundary_polygon[0])
	line.default_color = Color(0.3, 0.3, 0.3, 0.5)
	line.width = 1.0
	polygon.add_child(line)

	polygon.set_meta("territory_type", "district")
	polygon.set_meta("territory_id", district.id)

	district_layer.add_child(polygon)
	district_shapes[district.id] = polygon

# === ZOOM CONTROL ===

func _update_layer_visibility() -> void:
	"""Aktualisiert Layer-Sichtbarkeit basierend auf Zoom-Level."""
	region_layer.visible = (current_zoom_level == ZoomLevel.WORLD)
	nation_layer.visible = (current_zoom_level == ZoomLevel.REGION)
	province_layer.visible = (current_zoom_level == ZoomLevel.NATION)
	district_layer.visible = (current_zoom_level == ZoomLevel.PROVINCE)

func _zoom_to_world() -> void:
	"""Zoom auf Weltkarte (Regionen)."""
	current_zoom_level = ZoomLevel.WORLD
	focused_region_id = ""
	focused_nation_id = ""
	focused_province_id = ""

	target_scale = 1.0
	target_position = Vector2.ZERO

	_update_layer_visibility()
	print("MapController: Zoom Level 1 - Weltkarte")

func _zoom_to_region(region_id: String) -> void:
	"""Zoom auf eine Region (Nationen innerhalb der Region)."""
	var region = GameState.regions.get(region_id)
	if not region:
		return

	current_zoom_level = ZoomLevel.REGION
	focused_region_id = region_id
	focused_nation_id = ""
	focused_province_id = ""

	target_scale = 2.0
	target_position = -region.center_position * target_scale + get_viewport_rect().size / 2

	_update_layer_visibility()
	print("MapController: Zoom Level 2 - Region: %s" % region.name)

func _zoom_to_nation(nation_id: String) -> void:
	"""Zoom auf eine Nation (Provinzen innerhalb der Nation)."""
	var nation = GameState.nations.get(nation_id)
	if not nation:
		return

	current_zoom_level = ZoomLevel.NATION
	focused_nation_id = nation_id
	focused_province_id = ""

	var nation_center = _get_polygon_center(nation.boundary_polygon)
	target_scale = 3.0
	target_position = -nation_center * target_scale + get_viewport_rect().size / 2

	_update_layer_visibility()
	print("MapController: Zoom Level 3 - Nation: %s" % nation.name)

func _zoom_to_province(province_id: String) -> void:
	"""Zoom auf eine Provinz (Distrikte innerhalb der Provinz)."""
	var province = GameState.provinces.get(province_id)
	if not province:
		return

	current_zoom_level = ZoomLevel.PROVINCE
	focused_province_id = province_id

	target_scale = 5.0
	target_position = -province.position * target_scale + get_viewport_rect().size / 2

	_update_layer_visibility()
	print("MapController: Zoom Level 4 - Provinz: %s" % province.name)

func zoom_out() -> void:
	"""Zoomt eine Stufe heraus."""
	match current_zoom_level:
		ZoomLevel.PROVINCE:
			if not focused_nation_id.is_empty():
				_zoom_to_nation(focused_nation_id)
			else:
				_zoom_to_world()
		ZoomLevel.NATION:
			if not focused_region_id.is_empty():
				_zoom_to_region(focused_region_id)
			else:
				_zoom_to_world()
		ZoomLevel.REGION:
			_zoom_to_world()
		ZoomLevel.WORLD:
			pass  # Bereits auf höchster Ebene

# === ANIMATION ===

func _process(delta: float) -> void:
	# Smooth zoom/pan animation
	position = position.lerp(target_position, delta * zoom_animation_speed)
	scale = scale.lerp(Vector2(target_scale, target_scale), delta * zoom_animation_speed)

# === INPUT HANDLING ===

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_mouse_click(event.position)
		# Rechtsklick zum Rauszoomen
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			zoom_out()

	elif event is InputEventMouseMotion:
		_handle_mouse_hover(event.position)

func _handle_mouse_click(click_pos: Vector2) -> void:
	"""Behandelt Klicks basierend auf Zoom-Level."""
	var territory = _get_territory_at_position(click_pos)

	if territory.is_empty():
		return

	selected_territory = territory
	territory_clicked.emit(territory.type, territory.id)

	# Hierarchisches Zoomen
	match current_zoom_level:
		ZoomLevel.WORLD:
			if territory.type == "region":
				_zoom_to_region(territory.id)
		ZoomLevel.REGION:
			if territory.type == "nation":
				var nation = GameState.nations.get(territory.id)
				if nation and nation.region_id == focused_region_id:
					_zoom_to_nation(territory.id)
		ZoomLevel.NATION:
			if territory.type == "province":
				var province = GameState.provinces.get(territory.id)
				if province and province.nation_id == focused_nation_id:
					_zoom_to_province(territory.id)
					EventBus.province_selected.emit(territory.id)
		ZoomLevel.PROVINCE:
			if territory.type == "district":
				# Distrikt-Auswahl (noch keine weitere Zoom-Stufe)
				print("MapController: Distrikt ausgewählt: %s" % territory.id)

func _handle_mouse_hover(mouse_pos: Vector2) -> void:
	"""Behandelt Mouse-Hover."""
	var territory = _get_territory_at_position(mouse_pos)

	if territory != hovered_territory:
		hovered_territory = territory
		queue_redraw()

func _get_territory_at_position(pos: Vector2) -> Dictionary:
	"""Findet Territorium an Position basierend auf aktuellem Zoom-Level."""
	var local_pos = to_local(pos)

	match current_zoom_level:
		ZoomLevel.WORLD:
			for region_id in region_shapes.keys():
				var polygon = region_shapes[region_id]
				if _point_in_polygon(local_pos, polygon.polygon):
					return {"type": "region", "id": region_id}
		ZoomLevel.REGION:
			for nation_id in nation_shapes.keys():
				var nation = GameState.nations.get(nation_id)
				if nation and nation.region_id == focused_region_id:
					var polygon = nation_shapes[nation_id]
					if _point_in_polygon(local_pos, polygon.polygon):
						return {"type": "nation", "id": nation_id}
		ZoomLevel.NATION:
			for province_id in province_shapes.keys():
				var province = GameState.provinces.get(province_id)
				if province and province.nation_id == focused_nation_id:
					var polygon = province_shapes[province_id]
					if _point_in_polygon(local_pos, polygon.polygon):
						return {"type": "province", "id": province_id}
		ZoomLevel.PROVINCE:
			for district_id in district_shapes.keys():
				var district = GameState.districts.get(district_id)
				if district and district.province_id == focused_province_id:
					var polygon = district_shapes[district_id]
					if _point_in_polygon(local_pos, polygon.polygon):
						return {"type": "district", "id": district_id}

	return {}

func _point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	"""Prüft ob Punkt in Polygon liegt."""
	if polygon.size() < 3:
		return false
	return Geometry2D.is_point_in_polygon(point, polygon)

# === VISUAL FEEDBACK ===

func _draw() -> void:
	"""Zeichnet Highlights für gehöverte/selektierte Territorien."""
	if not hovered_territory.is_empty():
		_draw_territory_highlight(hovered_territory, Color(1.0, 1.0, 1.0, 0.3))

	if not selected_territory.is_empty() and selected_territory != hovered_territory:
		_draw_territory_highlight(selected_territory, Color(1.0, 1.0, 0.0, 0.5))

func _draw_territory_highlight(territory: Dictionary, color: Color) -> void:
	"""Zeichnet Highlight über Territorium."""
	var polygon: Polygon2D = null

	match territory.type:
		"region":
			polygon = region_shapes.get(territory.id)
		"nation":
			polygon = nation_shapes.get(territory.id)
		"province":
			polygon = province_shapes.get(territory.id)
		"district":
			polygon = district_shapes.get(territory.id)

	if polygon and polygon.polygon.size() > 0:
		draw_colored_polygon(polygon.polygon, color)

# === EVENT HANDLERS ===

func _on_province_selected(province_id: String) -> void:
	selected_territory = {"type": "province", "id": province_id}
	queue_redraw()

# === HELPERS ===

func _get_polygon_center(polygon: PackedVector2Array) -> Vector2:
	"""Berechnet Zentrum eines Polygons."""
	if polygon.size() == 0:
		return Vector2.ZERO

	var sum = Vector2.ZERO
	for point in polygon:
		sum += point
	return sum / polygon.size()

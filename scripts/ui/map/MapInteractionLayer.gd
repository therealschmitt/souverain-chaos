class_name MapInteractionLayer
extends Node2D

## Dedizierte Interaktions-Layer für Karten-Polygone
## Fängt Maus-Klicks und Hover-Events ab und identifiziert die zugehörigen Territorien

# === REFERENZEN ===
var map_controller: Node2D  # Referenz zum MapController
var polygon_renderer: PolygonRenderer

# === LAYER-REFERENZEN ===
var region_layer: Node2D
var nation_layer: Node2D
var province_layer: Node2D
var district_layer: Node2D

# === SHAPE DICTIONARIES ===
var region_shapes: Dictionary = {}
var nation_shapes: Dictionary = {}
var province_shapes: Dictionary = {}
var district_shapes: Dictionary = {}

# === INTERACTION STATE ===
var current_hovered_territory: Dictionary = {}  # {type: String, id: String}
var current_selected_territory: Dictionary = {}

# === HOVER HIGHLIGHT VISUALS ===
var hover_highlight: Line2D
var selection_highlight: Line2D

# === CONFIGURATION ===
var hover_line_width: float = 4.0
var selection_line_width: float = 5.0
var hover_color: Color = Color(1.0, 1.0, 1.0, 0.8)  # Weiß für Hover
var selection_color: Color = Color(1.0, 1.0, 0.0, 1.0)  # Gelb für Selektion

func _ready() -> void:
	_setup_highlights()
	_connect_signals()

func _setup_highlights() -> void:
	"""Erstellt Line2D-Objekte für Hover- und Selection-Highlights."""
	# Hover Highlight
	hover_highlight = Line2D.new()
	hover_highlight.name = "HoverHighlight"
	hover_highlight.width = hover_line_width
	hover_highlight.default_color = hover_color
	hover_highlight.antialiased = true
	hover_highlight.joint_mode = Line2D.LINE_JOINT_BEVEL
	hover_highlight.begin_cap_mode = Line2D.LINE_CAP_ROUND
	hover_highlight.end_cap_mode = Line2D.LINE_CAP_ROUND
	hover_highlight.z_index = 1000  # Über allen Polygonen
	hover_highlight.visible = false
	add_child(hover_highlight)

	# Selection Highlight
	selection_highlight = Line2D.new()
	selection_highlight.name = "SelectionHighlight"
	selection_highlight.width = selection_line_width
	selection_highlight.default_color = selection_color
	selection_highlight.antialiased = true
	selection_highlight.joint_mode = Line2D.LINE_JOINT_BEVEL
	selection_highlight.begin_cap_mode = Line2D.LINE_CAP_ROUND
	selection_highlight.end_cap_mode = Line2D.LINE_CAP_ROUND
	selection_highlight.z_index = 999  # Knapp über Polygonen, aber unter Hover
	selection_highlight.visible = false
	add_child(selection_highlight)

func _connect_signals() -> void:
	"""Verbindet EventBus-Signale."""
	EventBus.territory_selected.connect(_on_territory_selected)
	EventBus.territory_deselected.connect(_on_territory_deselected)

func initialize(p_map_controller: Node2D, p_polygon_renderer: PolygonRenderer) -> void:
	"""
	Initialisiert die Interaktions-Layer mit Referenzen.
	@param p_map_controller: Der MapController
	@param p_polygon_renderer: Der PolygonRenderer für Rendering-Konfigurationen
	"""
	map_controller = p_map_controller
	polygon_renderer = p_polygon_renderer

	# Hole Layer-Referenzen
	region_layer = map_controller.get_node_or_null("RegionLayer")
	nation_layer = map_controller.get_node_or_null("NationLayer")
	province_layer = map_controller.get_node_or_null("ProvinceLayer")
	district_layer = map_controller.get_node_or_null("DistrictLayer")

	# Hole Shape-Dictionaries
	region_shapes = map_controller.region_shapes
	nation_shapes = map_controller.nation_shapes
	province_shapes = map_controller.province_shapes
	district_shapes = map_controller.district_shapes

	print("MapInteractionLayer: Initialisiert mit %d Regionen, %d Nationen, %d Provinzen, %d Distrikte" % [
		region_shapes.size(), nation_shapes.size(), province_shapes.size(), district_shapes.size()
	])

# === INPUT HANDLING ===

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_mouse_click(event.position)
	elif event is InputEventMouseMotion:
		_handle_mouse_hover(event.position)

func _handle_mouse_click(click_pos: Vector2) -> void:
	"""
	Behandelt Maus-Klicks auf der Karte.
	Identifiziert das angeklickte Territorium und sendet Events über EventBus.
	"""
	var territory = _get_territory_at_position(click_pos)

	if territory.is_empty():
		# Klick auf leeren Bereich - deselektiere
		if not current_selected_territory.is_empty():
			EventBus.territory_deselected.emit()
		return

	# Sende Klick-Event
	EventBus.territory_clicked.emit(territory.type, territory.id)

	# Sende Selection-Event (falls nicht bereits selektiert)
	if territory != current_selected_territory:
		EventBus.territory_selected.emit(territory.type, territory.id)

	print("MapInteractionLayer: Territorium geklickt: %s [%s]" % [territory.id, territory.type])

func _handle_mouse_hover(mouse_pos: Vector2) -> void:
	"""
	Behandelt Maus-Bewegung über der Karte.
	Aktualisiert Hover-Highlights und sendet Hover-Events.
	"""
	var territory = _get_territory_at_position(mouse_pos)

	# Prüfe ob sich Hover-Status geändert hat
	if territory != current_hovered_territory:
		# Unhover vorheriges Territorium
		if not current_hovered_territory.is_empty():
			EventBus.territory_unhovered.emit()
			_hide_hover_highlight()

		# Hover neues Territorium
		if not territory.is_empty():
			EventBus.territory_hovered.emit(territory.type, territory.id)
			_show_hover_highlight(territory)

		current_hovered_territory = territory

# === TERRITORY DETECTION ===

func _get_territory_at_position(screen_pos: Vector2) -> Dictionary:
	"""
	Findet das Territorium an einer Bildschirm-Position.
	Durchsucht Layer von oben nach unten (District → Province → Nation → Region).
	@param screen_pos: Position auf dem Bildschirm
	@return: Dictionary mit {type: String, id: String} oder leeres Dict
	"""
	if not map_controller:
		return {}

	# Konvertiere Screen-Position zu Map-Pixel-Position
	var map_pixel_pos = _screen_to_map_pixel(screen_pos)

	# Durchsuche Layer von feinster zu gröbster Hierarchie
	# (nur sichtbare Layer)

	if district_layer and district_layer.visible:
		for district_id in district_shapes.keys():
			var polygon = district_shapes[district_id]
			if polygon and _point_in_polygon(map_pixel_pos, polygon.polygon):
				return {"type": "district", "id": district_id}

	if province_layer and province_layer.visible:
		for province_id in province_shapes.keys():
			var polygon = province_shapes[province_id]
			if polygon and _point_in_polygon(map_pixel_pos, polygon.polygon):
				return {"type": "province", "id": province_id}

	if nation_layer and nation_layer.visible:
		for nation_id in nation_shapes.keys():
			var polygon = nation_shapes[nation_id]
			if polygon and _point_in_polygon(map_pixel_pos, polygon.polygon):
				return {"type": "nation", "id": nation_id}

	if region_layer and region_layer.visible:
		for region_id in region_shapes.keys():
			var polygon = region_shapes[region_id]
			if polygon and _point_in_polygon(map_pixel_pos, polygon.polygon):
				return {"type": "region", "id": region_id}

	return {}

func _point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	"""
	Prüft ob ein Punkt innerhalb eines Polygons liegt.
	@param point: Punkt-Position in Map-Pixel-Koordinaten
	@param polygon: Polygon-Punkte
	@return: true wenn Punkt im Polygon liegt
	"""
	if polygon.size() < 3:
		return false
	return Geometry2D.is_point_in_polygon(point, polygon)

# === COORDINATE CONVERSION ===

func _screen_to_map_pixel(screen_pos: Vector2) -> Vector2:
	"""
	Konvertiert Bildschirm-Koordinaten zu Map-Pixel-Koordinaten.
	Berücksichtigt Position und Scale des MapControllers.
	"""
	if not map_controller:
		return screen_pos
	return (screen_pos - map_controller.position) / map_controller.scale.x

# === VISUAL HIGHLIGHTS ===

func _show_hover_highlight(territory: Dictionary) -> void:
	"""
	Zeigt Hover-Highlight für ein Territorium.
	Zeichnet eine helle Linie entlang der Polygon-Grenze.
	"""
	var polygon = _get_territory_polygon(territory)
	if not polygon:
		return

	# Setze Line2D-Punkte
	hover_highlight.clear_points()
	for point in polygon.polygon:
		hover_highlight.add_point(point)

	# Schließe Polygon durch Hinzufügen des ersten Punktes
	if polygon.polygon.size() > 0:
		hover_highlight.add_point(polygon.polygon[0])

	# Passe Hover-Farbe basierend auf Territorium-Typ an
	if polygon_renderer:
		var config = polygon_renderer.get_config(territory.type)
		hover_highlight.width = config.line_width + 2.0  # 2px dicker als normale Linie

	hover_highlight.visible = true

func _hide_hover_highlight() -> void:
	"""Versteckt das Hover-Highlight."""
	hover_highlight.visible = false

func _show_selection_highlight(territory: Dictionary) -> void:
	"""
	Zeigt Selection-Highlight für ein Territorium.
	Zeichnet eine gelbe Linie entlang der Polygon-Grenze.
	"""
	var polygon = _get_territory_polygon(territory)
	if not polygon:
		return

	# Setze Line2D-Punkte
	selection_highlight.clear_points()
	for point in polygon.polygon:
		selection_highlight.add_point(point)

	# Schließe Polygon
	if polygon.polygon.size() > 0:
		selection_highlight.add_point(polygon.polygon[0])

	# Passe Selection-Farbe basierend auf Territorium-Typ an
	if polygon_renderer:
		var config = polygon_renderer.get_config(territory.type)
		selection_highlight.width = config.line_width + 3.0  # 3px dicker als normale Linie

	selection_highlight.visible = true

func _hide_selection_highlight() -> void:
	"""Versteckt das Selection-Highlight."""
	selection_highlight.visible = false

func _get_territory_polygon(territory: Dictionary) -> Polygon2D:
	"""
	Gibt das Polygon2D-Objekt für ein Territorium zurück.
	@param territory: Dictionary mit {type: String, id: String}
	@return: Polygon2D oder null
	"""
	match territory.type:
		"region": return region_shapes.get(territory.id)
		"nation": return nation_shapes.get(territory.id)
		"province": return province_shapes.get(territory.id)
		"district": return district_shapes.get(territory.id)
	return null

# === EVENT HANDLERS ===

func _on_territory_selected(territory_type: String, territory_id: String) -> void:
	"""Reagiert auf Territory-Selection-Event."""
	current_selected_territory = {"type": territory_type, "id": territory_id}
	_show_selection_highlight(current_selected_territory)

func _on_territory_deselected() -> void:
	"""Reagiert auf Territory-Deselection-Event."""
	current_selected_territory = {}
	_hide_selection_highlight()

# === PUBLIC API ===

func clear_selection() -> void:
	"""Löscht aktuelle Selektion."""
	if not current_selected_territory.is_empty():
		EventBus.territory_deselected.emit()

func select_territory(territory_type: String, territory_id: String) -> void:
	"""
	Selektiert ein Territorium programmatisch.
	@param territory_type: "region", "nation", "province", oder "district"
	@param territory_id: ID des Territoriums
	"""
	EventBus.territory_selected.emit(territory_type, territory_id)

func get_hovered_territory() -> Dictionary:
	"""Gibt aktuell gehovertes Territorium zurück."""
	return current_hovered_territory

func get_selected_territory() -> Dictionary:
	"""Gibt aktuell selektiertes Territorium zurück."""
	return current_selected_territory

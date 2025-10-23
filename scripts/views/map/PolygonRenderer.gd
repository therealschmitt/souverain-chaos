class_name PolygonRenderer
extends RefCounted

## Zentrale Rendering-Konfiguration für alle Polygon-Ebenen
## Verwaltet Linienstärken, Farben und Rendering-Parameter nach Hierarchieebene

# === RENDERING-KONSTANTEN ===
class RenderConfig:
	var line_width: float
	var line_color: Color
	var line_opacity: float
	var fill_opacity: float
	var layer_index: int
	var description: String

	func _init(p_width: float, p_color: Color, p_line_opacity: float, p_fill_opacity: float, p_layer: int, p_desc: String) -> void:
		line_width = p_width
		line_color = p_color
		line_opacity = p_line_opacity
		fill_opacity = p_fill_opacity
		layer_index = p_layer
		description = p_desc

# === KONFIGURATIONEN PRO HIERARCHIEEBENE ===
var configs: Dictionary = {}

func _init() -> void:
	_setup_render_configs()

func _setup_render_configs() -> void:
	"""Definiert Rendering-Konfigurationen für jede geografische Ebene."""

	# NATION: Dickste Grenzen (4.0 px), dunkle Linien, Layer 0 (höchste Hierarchie)
	configs["nation"] = RenderConfig.new(
		4.0,                                    # line_width
		Color(0.1, 0.1, 0.1, 1.0),             # line_color (dunkelgrau)
		1.0,                                    # line_opacity
		0.2,                                    # fill_opacity für Highlight
		0,                                      # layer_index (hinterste)
		"Nationen: Dickste Grenzen"
	)

	# PROVINCE: Mittlere Grenzen (2.5 px), mittleres Grau, Layer 1
	configs["province"] = RenderConfig.new(
		2.5,                                    # line_width
		Color(0.3, 0.3, 0.3, 0.95),            # line_color (grau, leicht transparent)
		0.95,                                   # line_opacity
		0.15,                                   # fill_opacity für Highlight
		1,                                      # layer_index
		"Provinzen: Mittlere Grenzen"
	)

	# DISTRICT: Feine Grenzen (1.5 px), helles Grau, Layer 2
	configs["district"] = RenderConfig.new(
		1.5,                                    # line_width
		Color(0.5, 0.5, 0.5, 0.75),            # line_color (hellgrau, transparent)
		0.75,                                   # line_opacity
		0.1,                                    # fill_opacity für Highlight
		2,                                      # layer_index (oberste)
		"Distrikte: Feine Grenzen"
	)

func get_config(territory_type: String) -> RenderConfig:
	"""Gibt Render-Konfiguration für einen Territory-Typ zurück."""
	if territory_type in configs:
		return configs[territory_type]
	push_error("PolygonRenderer: Unknown territory type '%s'" % territory_type)
	return configs["province"]  # Fallback

func create_boundary_line(polygon: PackedVector2Array, territory_type: String) -> Line2D:
	"""
	Erstellt eine Line2D für Polygon-Grenzen mit Hierarchie-spezifischen Einstellungen.

	@param polygon: PackedVector2Array der Polygon-Punkte
	@param territory_type: "nation", "province", oder "district"
	@return: Konfigurierte Line2D
	"""
	var config = get_config(territory_type)

	var line = Line2D.new()
	line.points = polygon

	# Schließe Polygon durch Hinzufügen des ersten Punktes am Ende
	if polygon.size() > 0:
		line.add_point(polygon[0])

	# Konfiguriere Linieneigenschaften
	line.default_color = config.line_color
	line.default_color.a = config.line_opacity
	line.width = config.line_width
	line.antialiased = true
	line.joint_mode = Line2D.LINE_JOINT_BEVEL
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND

	# Textur-Filter für bessere Qualität
	line.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	return line

func apply_fill_color(polygon_2d: Polygon2D, territory_type: String, base_color: Color) -> void:
	"""
	Setzt die Füllfarbe für ein Polygon mit Transparenz-Anpassung.

	@param polygon_2d: Das zu färbende Polygon2D
	@param territory_type: "nation", "province", oder "district"
	@param base_color: Die Basis-Farbe des Territoriums
	"""
	var config = get_config(territory_type)

	# Wende Fill-Opacity an
	var fill_color = base_color
	fill_color.a = config.fill_opacity
	polygon_2d.color = fill_color
	polygon_2d.antialiased = true
	polygon_2d.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func get_highlight_color(territory_type: String, is_selected: bool = false) -> Color:
	"""
	Gibt eine Highlight-Farbe für ein Territorium zurück.

	@param territory_type: "nation", "province", oder "district"
	@param is_selected: Ob das Territorium ausgewählt ist (vs. gehovered)
	@return: Highlight-Farbe mit angemessener Opacity
	"""
	if is_selected:
		return Color(1.0, 1.0, 0.0, 0.5)  # Gelb für ausgewählt
	else:
		return Color(1.0, 1.0, 1.0, 0.3)  # Weiß für gehovered

func get_hover_line_width(territory_type: String) -> float:
	"""
	Gibt die empfohlene Linienbreite für Hover-Highlights zurück.
	@param territory_type: "nation", "province", oder "district"
	@return: Linienbreite in Pixeln (2px dicker als normale Linie)
	"""
	var config = get_config(territory_type)
	return config.line_width + 2.0

func get_selection_line_width(territory_type: String) -> float:
	"""
	Gibt die empfohlene Linienbreite für Selection-Highlights zurück.
	@param territory_type: "nation", "province", oder "district"
	@return: Linienbreite in Pixeln (3px dicker als normale Linie)
	"""
	var config = get_config(territory_type)
	return config.line_width + 3.0

func create_highlight_line(polygon: PackedVector2Array, territory_type: String, is_selected: bool = false) -> Line2D:
	"""
	Erstellt eine Line2D für Hover- oder Selection-Highlights.

	@param polygon: PackedVector2Array der Polygon-Punkte
	@param territory_type: "nation", "province", oder "district"
	@param is_selected: true für Selection-Highlight, false für Hover-Highlight
	@return: Konfigurierte Line2D mit Highlight-Styling
	"""
	var line = Line2D.new()
	line.points = polygon

	# Schließe Polygon durch Hinzufügen des ersten Punktes am Ende
	if polygon.size() > 0:
		line.add_point(polygon[0])

	# Setze Farbe und Breite basierend auf Highlight-Typ
	if is_selected:
		line.default_color = Color(1.0, 1.0, 0.0, 1.0)  # Gelb
		line.width = get_selection_line_width(territory_type)
	else:
		line.default_color = Color(1.0, 1.0, 1.0, 0.8)  # Weiß
		line.width = get_hover_line_width(territory_type)

	# Konfiguriere Linieneigenschaften
	line.antialiased = true
	line.joint_mode = Line2D.LINE_JOINT_BEVEL
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	line.z_index = 1000  # Über allen Polygonen

	return line

func print_render_config() -> void:
	"""Gibt eine übersichtliche Tabelle mit allen Render-Konfigurationen aus."""
	print("\n=== POLYGON RENDERER CONFIGURATION ===")
	for territory_type in ["nation", "province", "district"]:
		var config = get_config(territory_type)
		print("  %s:" % territory_type.to_upper())
		print("    Line Width:     %.1f px" % config.line_width)
		print("    Line Color:     %s (opacity: %.1f)" % [config.line_color, config.line_opacity])
		print("    Fill Opacity:   %.2f" % config.fill_opacity)
		print("    Layer Index:    %d" % config.layer_index)
		print("    Description:    %s" % config.description)
	print("=====================================\n")

func validate_polygon(polygon: PackedVector2Array, min_area: float = 10.0) -> bool:
	"""
	Validiert ein Polygon auf Integrität.

	@param polygon: PackedVector2Array zum Validieren
	@param min_area: Minimale erforderliche Fläche in Pixeln
	@return: true wenn Polygon valid ist
	"""
	if polygon.size() < 3:
		return false

	# Berechne grobe Fläche mit Shoelace-Formel
	var area = 0.0
	for i in range(polygon.size()):
		var current = polygon[i]
		var next = polygon[(i + 1) % polygon.size()]
		area += current.x * next.y - next.x * current.y
	area = abs(area) / 2.0

	return area >= min_area

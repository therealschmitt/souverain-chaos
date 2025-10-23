## Beispiele für die Konfiguration des Polygon-Rendering-Systems
## Diese Datei zeigt verschiedene Konfigurationsszenarien

class_name RenderingConfigExamples
extends RefCounted

## BEISPIEL 1: Standard-Konfiguration (verwendet von PolygonRenderer)
static func create_standard_config() -> PolygonRenderer:
	var renderer = PolygonRenderer.new()
	# Verwendet die Standard-Werte aus _setup_render_configs()
	return renderer

## BEISPIEL 2: Klassische politische Karte (wie in Europa im 19. Jahrhundert)
static func create_classic_political_map() -> PolygonRenderer:
	var renderer = PolygonRenderer.new()

	# Dickere Grenzen für klassischen Kartenlook
	renderer.configs["region"] = PolygonRenderer.RenderConfig(
		5.0,                                    # Dickere Grenzlinien
		Color(0.05, 0.05, 0.05, 1.0),          # Fast schwarz
		1.0,
		0.20,
		0,
		"Regions: Classic thick borders"
	)

	renderer.configs["nation"] = PolygonRenderer.RenderConfig(
		4.0,
		Color(0.15, 0.15, 0.15, 1.0),
		1.0,
		0.25,
		1,
		"Nations: Classic borders"
	)

	return renderer

## BEISPIEL 3: Minimalistischer Look (moderne Design-Ästhetik)
static func create_minimalist_config() -> PolygonRenderer:
	var renderer = PolygonRenderer.new()

	# Sehr dünne Grenzen, subtile Farben
	renderer.configs["region"] = PolygonRenderer.RenderConfig(
		1.5,                                    # Sehr dünn
		Color(0.7, 0.7, 0.7, 0.8),             # Hellgrau, transparent
		0.8,
		0.05,                                   # Kaum sichtbare Füllung
		0,
		"Regions: Minimalist thin borders"
	)

	renderer.configs["nation"] = PolygonRenderer.RenderConfig(
		1.2,
		Color(0.6, 0.6, 0.6, 0.8),
		0.8,
		0.08,
		1,
		"Nations: Minimalist borders"
	)

	renderer.configs["province"] = PolygonRenderer.RenderConfig(
		0.8,
		Color(0.5, 0.5, 0.5, 0.6),
		0.6,
		0.03,
		2,
		"Provinces: Minimalist borders"
	)

	renderer.configs["district"] = PolygonRenderer.RenderConfig(
		0.5,
		Color(0.4, 0.4, 0.4, 0.4),
		0.4,
		0.01,
		3,
		"Districts: Minimalist borders"
	)

	return renderer

## BEISPIEL 4: Farbcodierte Hierarchie (verschiedene Farben pro Ebene)
static func create_hierarchical_color_config() -> PolygonRenderer:
	var renderer = PolygonRenderer.new()

	# Region: Dunkelblau
	renderer.configs["region"] = PolygonRenderer.RenderConfig(
		4.0,
		Color(0.1, 0.2, 0.5, 1.0),              # Dunkelblau
		1.0,
		0.15,
		0,
		"Regions: Dark blue borders"
	)

	# Nation: Dunkelgrün
	renderer.configs["nation"] = PolygonRenderer.RenderConfig(
		3.0,
		Color(0.2, 0.4, 0.2, 1.0),              # Dunkelgrün
		1.0,
		0.2,
		1,
		"Nations: Dark green borders"
	)

	# Province: Dunkelrot
	renderer.configs["province"] = PolygonRenderer.RenderConfig(
		2.0,
		Color(0.4, 0.2, 0.2, 0.9),              # Dunkelrot
		0.9,
		0.15,
		2,
		"Provinces: Dark red borders"
	)

	# District: Grau
	renderer.configs["district"] = PolygonRenderer.RenderConfig(
		1.0,
		Color(0.6, 0.6, 0.6, 0.7),              # Grau
		0.7,
		0.1,
		3,
		"Districts: Gray borders"
	)

	return renderer

## BEISPIEL 5: High-Contrast für Barrierefreiheit
static func create_high_contrast_config() -> PolygonRenderer:
	var renderer = PolygonRenderer.new()

	# Sehr dickere, sehr dunkle Grenzen
	renderer.configs["region"] = PolygonRenderer.RenderConfig(
		6.0,                                    # Extrem dick
		Color(0.0, 0.0, 0.0, 1.0),              # Reines Schwarz
		1.0,
		0.30,                                   # Opaque Füllung
		0,
		"Regions: High contrast thick borders"
	)

	renderer.configs["nation"] = PolygonRenderer.RenderConfig(
		5.0,
		Color(0.0, 0.0, 0.0, 1.0),
		1.0,
		0.35,
		1,
		"Nations: High contrast borders"
	)

	renderer.configs["province"] = PolygonRenderer.RenderConfig(
		3.0,
		Color(0.0, 0.0, 0.0, 1.0),
		1.0,
		0.25,
		2,
		"Provinces: High contrast borders"
	)

	renderer.configs["district"] = PolygonRenderer.RenderConfig(
		2.0,
		Color(0.0, 0.0, 0.0, 1.0),
		1.0,
		0.20,
		3,
		"Districts: High contrast borders"
	)

	return renderer

## BEISPIEL 6: Strategisches Spiel (optimiert für schnelle Lesbarkeit)
static func create_strategic_game_config() -> PolygonRenderer:
	var renderer = PolygonRenderer.new()

	# Fokus auf Nation und Province für Gameplay
	renderer.configs["region"] = PolygonRenderer.RenderConfig(
		2.0,                                    # Subtil
		Color(0.5, 0.5, 0.5, 0.4),              # Sehr transparent
		0.4,
		0.05,
		0,
		"Regions: Strategic subtle"
	)

	renderer.configs["nation"] = PolygonRenderer.RenderConfig(
		4.0,                                    # Prominent
		Color(0.0, 0.0, 0.0, 1.0),              # Schwarz, opaque
		1.0,
		0.2,
		1,
		"Nations: Strategic prominent"
	)

	renderer.configs["province"] = PolygonRenderer.RenderConfig(
		3.0,                                    # Prominent
		Color(0.3, 0.3, 0.3, 0.9),              # Dunkelgrau
		0.9,
		0.15,
		2,
		"Provinces: Strategic prominent"
	)

	renderer.configs["district"] = PolygonRenderer.RenderConfig(
		0.5,                                    # Sehr dünn
		Color(0.7, 0.7, 0.7, 0.3),              # Hellgrau, transparent
		0.3,
		0.0,                                    # Keine Füllung
		3,
		"Districts: Strategic minimal"
	)

	return renderer

## BEISPIEL 7: Detailkarte (optimiert für Zoom-Stufen)
static func create_detail_map_config() -> PolygonRenderer:
	"""
	Für Zoom-Level-System:
	- Weit weg: Nur Region+Nation sichtbar
	- Mittel: Province sichtbar
	- Nah: District sichtbar
	"""
	var renderer = PolygonRenderer.new()

	renderer.configs["region"] = PolygonRenderer.RenderConfig(
		3.0,
		Color(0.1, 0.1, 0.1, 1.0),
		1.0,
		0.1,
		0,
		"Regions: Detail map"
	)

	renderer.configs["nation"] = PolygonRenderer.RenderConfig(
		2.5,
		Color(0.2, 0.2, 0.2, 1.0),
		1.0,
		0.15,
		1,
		"Nations: Detail map"
	)

	renderer.configs["province"] = PolygonRenderer.RenderConfig(
		1.5,
		Color(0.4, 0.4, 0.4, 0.9),
		0.9,
		0.1,
		2,
		"Provinces: Detail map"
	)

	renderer.configs["district"] = PolygonRenderer.RenderConfig(
		0.8,
		Color(0.6, 0.6, 0.6, 0.7),
		0.7,
		0.05,
		3,
		"Districts: Detail map"
	)

	return renderer

## HILFSFUNKTION: Dynamisch zwischen Konfigurationen wechseln
static func apply_config_to_controller(
	map_controller: MapController,
	config: PolygonRenderer
) -> void:
	"""
	Wendet eine neue Rendering-Konfiguration auf MapController an.
	Aktualisiert bestehende Layer-Grenzen.
	"""
	map_controller.polygon_renderer = config

	# Update Region Layer
	for region_id in map_controller.region_shapes.keys():
		var polygon = map_controller.region_shapes[region_id]
		var line = polygon.get_child(0) as Line2D
		if line:
			var cfg = config.get_config("region")
			line.width = cfg.line_width
			line.default_color = cfg.line_color
			line.default_color.a = cfg.line_opacity

	# Update Nation Layer
	for nation_id in map_controller.nation_shapes.keys():
		var polygon = map_controller.nation_shapes[nation_id]
		var line = polygon.get_child(0) as Line2D
		if line:
			var cfg = config.get_config("nation")
			line.width = cfg.line_width
			line.default_color = cfg.line_color
			line.default_color.a = cfg.line_opacity

	# Update Province Layer
	for province_id in map_controller.province_shapes.keys():
		var polygon = map_controller.province_shapes[province_id]
		var line = polygon.get_child(0) as Line2D
		if line:
			var cfg = config.get_config("province")
			line.width = cfg.line_width
			line.default_color = cfg.line_color
			line.default_color.a = cfg.line_opacity

	# Update District Layer
	for district_id in map_controller.district_shapes.keys():
		var polygon = map_controller.district_shapes[district_id]
		var line = polygon.get_child(0) as Line2D
		if line:
			var cfg = config.get_config("district")
			line.width = cfg.line_width
			line.default_color = cfg.line_color
			line.default_color.a = cfg.line_opacity

	print("Applied new rendering configuration")

## Teste alle verfügbaren Konfigurationen
static func test_all_configs() -> void:
	print("\n=== TESTING ALL RENDERING CONFIGURATIONS ===\n")

	var configs = [
		{"name": "Standard", "config": create_standard_config()},
		{"name": "Classic Political", "config": create_classic_political_map()},
		{"name": "Minimalist", "config": create_minimalist_config()},
		{"name": "Hierarchical Color", "config": create_hierarchical_color_config()},
		{"name": "High Contrast", "config": create_high_contrast_config()},
		{"name": "Strategic Game", "config": create_strategic_game_config()},
		{"name": "Detail Map", "config": create_detail_map_config()}
	]

	for cfg_info in configs:
		print("Configuration: %s" % cfg_info.name)
		cfg_info.config.print_render_config()

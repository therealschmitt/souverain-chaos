class_name RenderingDebugger
extends Node

## Debug-Utilities für Polygon-Rendering
## Hilft bei der Visualisierung von Koordinaten, Grenzen und Performance

var map_controller: MapController
var polygon_renderer: PolygonRenderer
var debug_mode: bool = false
var show_polygon_vertices: bool = false
var show_coordinates: bool = false

func _ready() -> void:
	map_controller = get_parent() as MapController
	if not map_controller:
		push_error("RenderingDebugger: MapController parent not found")
		return

	polygon_renderer = map_controller.polygon_renderer
	if not polygon_renderer:
		push_error("RenderingDebugger: PolygonRenderer not found")
		return

	print("RenderingDebugger initialized")

func _input(event: InputEvent) -> void:
	"""Debug-Tastatur-Shortcuts."""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_D:
				debug_mode = !debug_mode
				print("Debug Mode: %s" % debug_mode)
				if map_controller:
					map_controller.queue_redraw()

			KEY_V:
				show_polygon_vertices = !show_polygon_vertices
				print("Show Polygon Vertices: %s" % show_polygon_vertices)
				if map_controller:
					map_controller.queue_redraw()

			KEY_C:
				show_coordinates = !show_coordinates
				print("Show Coordinates: %s" % show_coordinates)
				if map_controller:
					map_controller.queue_redraw()

			KEY_R:
				print_rendering_stats()

func print_rendering_stats() -> void:
	"""Gibt Rendering-Statistiken aus."""
	print("\n=== RENDERING STATISTICS ===")

	if not map_controller:
		print("Error: MapController not found")
		return

	var total_polygons = 0
	var total_vertices = 0

	# Zähle Regionen
	var region_count = map_controller.region_shapes.size()
	for region_id in map_controller.region_shapes.keys():
		var polygon = map_controller.region_shapes[region_id] as Polygon2D
		if polygon:
			total_polygons += 1
			total_vertices += polygon.polygon.size()

	print("Regions: %d" % region_count)

	# Zähle Nationen
	var nation_count = map_controller.nation_shapes.size()
	for nation_id in map_controller.nation_shapes.keys():
		var polygon = map_controller.nation_shapes[nation_id] as Polygon2D
		if polygon:
			total_polygons += 1
			total_vertices += polygon.polygon.size()

	print("Nations: %d" % nation_count)

	# Zähle Provinzen
	var province_count = map_controller.province_shapes.size()
	for province_id in map_controller.province_shapes.keys():
		var polygon = map_controller.province_shapes[province_id] as Polygon2D
		if polygon:
			total_polygons += 1
			total_vertices += polygon.polygon.size()

	print("Provinces: %d" % province_count)

	# Zähle Distrikte
	var district_count = map_controller.district_shapes.size()
	for district_id in map_controller.district_shapes.keys():
		var polygon = map_controller.district_shapes[district_id] as Polygon2D
		if polygon:
			total_polygons += 1
			total_vertices += polygon.polygon.size()

	print("Districts: %d" % district_count)

	print("\nTotal Polygons: %d" % total_polygons)
	print("Total Vertices: %d" % total_vertices)
	print("Average Vertices per Polygon: %.1f" % (float(total_vertices) / max(total_polygons, 1)))

	# Layer Sichtbarkeit
	print("\nLayer Visibility:")
	print("  Regions:   %s" % map_controller.region_layer.visible)
	print("  Nations:   %s" % map_controller.nation_layer.visible)
	print("  Provinces: %s" % map_controller.province_layer.visible)
	print("  Districts: %s" % map_controller.district_layer.visible)

	# Rendering-Konfiguration
	print("\nRendering Configuration:")
	polygon_renderer.print_render_config()

func print_polygon_info(territory_type: String, territory_id: String) -> void:
	"""Gibt ausführliche Informationen zu einem Polygon aus."""
	var polygon: Polygon2D = null
	var territory_name = ""

	match territory_type:
		"region":
			polygon = map_controller.region_shapes.get(territory_id)
			var region = GameState.regions.get(territory_id)
			territory_name = region.name if region else "Unknown"

		"nation":
			polygon = map_controller.nation_shapes.get(territory_id)
			var nation = GameState.nations.get(territory_id)
			territory_name = nation.name if nation else "Unknown"

		"province":
			polygon = map_controller.province_shapes.get(territory_id)
			var province = GameState.provinces.get(territory_id)
			territory_name = province.name if province else "Unknown"

		"district":
			polygon = map_controller.district_shapes.get(territory_id)
			var district = GameState.districts.get(territory_id)
			territory_name = district.name if district else "Unknown"

	if not polygon:
		print("Polygon not found: %s/%s" % [territory_type, territory_id])
		return

	print("\n=== POLYGON INFO: %s ===\n" % territory_name.to_upper())
	print("Type: %s" % territory_type)
	print("ID: %s" % territory_id)
	print("Vertices: %d" % polygon.polygon.size())

	# Berechne Bounds
	var min_x = 999999.0
	var min_y = 999999.0
	var max_x = -999999.0
	var max_y = -999999.0

	for vertex in polygon.polygon:
		min_x = min(min_x, vertex.x)
		min_y = min(min_y, vertex.y)
		max_x = max(max_x, vertex.x)
		max_y = max(max_y, vertex.y)

	print("\nBounds (Pixel):")
	print("  X: [%.1f, %.1f] (width: %.1f)" % [min_x, max_x, max_x - min_x])
	print("  Y: [%.1f, %.1f] (height: %.1f)" % [min_y, max_y, max_y - min_y])

	# Konvertiere zu World-Koordinaten
	var world_min = map_controller.map_scale.pixel_to_world(Vector2(min_x, min_y))
	var world_max = map_controller.map_scale.pixel_to_world(Vector2(max_x, max_y))

	print("\nBounds (World - km):")
	print("  X: [%.1f, %.1f] km" % [world_min.x, world_max.x])
	print("  Y: [%.1f, %.1f] km" % [world_min.y, world_max.y])

	# Berechne Fläche
	var area_km2 = map_controller.calculate_area_km2_from_pixels(polygon.polygon)
	print("\nArea: %.0f km²" % area_km2)

	# Farbe
	print("\nColor: %s" % polygon.color)

	# Rendering-Config
	var config = polygon_renderer.get_config(territory_type)
	print("\nRendering Config:")
	print("  Line Width: %.1f px" % config.line_width)
	print("  Line Color: %s" % config.line_color)
	print("  Line Opacity: %.2f" % config.line_opacity)
	print("  Fill Opacity: %.2f" % config.fill_opacity)

	# Erste 5 Vertices anzeigen
	print("\nFirst 5 Vertices (Pixel):")
	for i in range(min(5, polygon.polygon.size())):
		var vertex = polygon.polygon[i]
		var world_vertex = map_controller.map_scale.pixel_to_world(vertex)
		print("  [%d] Pixel: (%.1f, %.1f) → World: (%.1f, %.1f) km" % [
			i, vertex.x, vertex.y, world_vertex.x, world_vertex.y
		])

func validate_all_polygons() -> Dictionary:
	"""Validiert alle Polygone und gibt Bericht aus."""
	var report = {
		"valid_regions": 0,
		"invalid_regions": 0,
		"valid_nations": 0,
		"invalid_nations": 0,
		"valid_provinces": 0,
		"invalid_provinces": 0,
		"valid_districts": 0,
		"invalid_districts": 0,
		"errors": []
	}

	print("\n=== POLYGON VALIDATION REPORT ===\n")

	# Validiere Regionen
	for region_id in map_controller.region_shapes.keys():
		var polygon = map_controller.region_shapes[region_id] as Polygon2D
		if polygon_renderer.validate_polygon(polygon.polygon):
			report.valid_regions += 1
		else:
			report.invalid_regions += 1
			report.errors.append("Invalid region: %s" % region_id)

	# Validiere Nationen
	for nation_id in map_controller.nation_shapes.keys():
		var polygon = map_controller.nation_shapes[nation_id] as Polygon2D
		if polygon_renderer.validate_polygon(polygon.polygon):
			report.valid_nations += 1
		else:
			report.invalid_nations += 1
			report.errors.append("Invalid nation: %s" % nation_id)

	# Validiere Provinzen
	for province_id in map_controller.province_shapes.keys():
		var polygon = map_controller.province_shapes[province_id] as Polygon2D
		if polygon_renderer.validate_polygon(polygon.polygon):
			report.valid_provinces += 1
		else:
			report.invalid_provinces += 1
			report.errors.append("Invalid province: %s" % province_id)

	# Validiere Distrikte
	for district_id in map_controller.district_shapes.keys():
		var polygon = map_controller.district_shapes[district_id] as Polygon2D
		if polygon_renderer.validate_polygon(polygon.polygon):
			report.valid_districts += 1
		else:
			report.invalid_districts += 1
			report.errors.append("Invalid district: %s" % district_id)

	print("Regions:   %d valid, %d invalid" % [report.valid_regions, report.invalid_regions])
	print("Nations:   %d valid, %d invalid" % [report.valid_nations, report.invalid_nations])
	print("Provinces: %d valid, %d invalid" % [report.valid_provinces, report.invalid_provinces])
	print("Districts: %d valid, %d invalid" % [report.valid_districts, report.invalid_districts])

	if report.errors.size() > 0:
		print("\nErrors:")
		for error in report.errors:
			print("  - " + error)
	else:
		print("\nAll polygons valid! ✓")

	return report

func print_coordinate_conversion_test() -> void:
	"""Testet die Koordinaten-Konvertierungskette."""
	print("\n=== COORDINATE CONVERSION TEST ===\n")

	var test_points = [
		Vector2(0, 0),
		Vector2(1000, 600),
		Vector2(2000, 1200),
		Vector2(500, 300)
	]

	for pixel_pos in test_points:
		var world_pos = map_controller.map_scale.pixel_to_world(pixel_pos)
		var back_to_pixel = map_controller.map_scale.world_to_pixel(world_pos)
		var error = pixel_pos.distance_to(back_to_pixel)

		print("Pixel: (%.0f, %.0f)" % [pixel_pos.x, pixel_pos.y])
		print("  → World: (%.1f, %.1f) km" % [world_pos.x, world_pos.y])
		print("  → Back to Pixel: (%.1f, %.1f)" % [back_to_pixel.x, back_to_pixel.y])
		print("  Conversion Error: %.4f px\n" % error)

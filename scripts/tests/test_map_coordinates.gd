extends Node

## Test Script für MapScale Koordinatensystem
## Validiert Koordinaten-Konvertierungen und Berechnungen
## Kann mit F6 direkt in Godot ausgeführt werden

var map_scale: MapScale

func _ready() -> void:
	print("\n=== MAP COORDINATE SYSTEM TEST ===\n")

	# Lade MapScale
	map_scale = load("res://data/map_scales/default_map_scale.tres") as MapScale
	if not map_scale:
		print("FEHLER: MapScale konnte nicht geladen werden!")
		return

	print(map_scale.get_info_string())
	print("\n")

	# Führe Tests aus
	test_coordinate_conversions()
	test_distance_calculations()
	test_area_calculations()
	test_boundary_validation()
	test_real_world_scenarios()

	print("\n=== ALLE TESTS ABGESCHLOSSEN ===\n")

	# Beende nach Tests
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()

func test_coordinate_conversions() -> void:
	print("--- Test 1: Koordinaten-Konvertierungen ---")

	# Test 1.1: Pixel → World → Pixel (Round-trip)
	var test_pixels = [
		Vector2(0, 0),
		Vector2(2000, 1200),
		Vector2(1000, 600),
		Vector2(500, 300)
	]

	for pixel in test_pixels:
		var world = map_scale.pixel_to_world(pixel)
		var back_to_pixel = map_scale.world_to_pixel(world)
		var error = pixel.distance_to(back_to_pixel)

		var status = "✓" if error < 0.01 else "✗"
		print("%s Pixel %s → World %s → Pixel %s (Error: %.4f)" % [
			status, pixel, world, back_to_pixel, error
		])

	# Test 1.2: World → Pixel → World (Round-trip)
	var test_world = [
		Vector2(0, 0),
		Vector2(20000, 12000),
		Vector2(10000, 6000),
		Vector2(5000, 3000)
	]

	for world in test_world:
		var pixel = map_scale.world_to_pixel(world)
		var back_to_world = map_scale.pixel_to_world(pixel)
		var error = world.distance_to(back_to_world)

		var status = "✓" if error < 0.01 else "✗"
		print("%s World %s → Pixel %s → World %s (Error: %.4f)" % [
			status, world, pixel, back_to_world, error
		])

	print("")

func test_distance_calculations() -> void:
	print("--- Test 2: Distanz-Berechnungen ---")

	# Test 2.1: Bekannte Distanzen in Pixel-Koordinaten
	var tests = [
		{
			"name": "Horizontale Kartenbreite",
			"pixel1": Vector2(0, 600),
			"pixel2": Vector2(2000, 600),
			"expected_km": 20000.0
		},
		{
			"name": "Vertikale Kartenhöhe",
			"pixel1": Vector2(1000, 0),
			"pixel2": Vector2(1000, 1200),
			"expected_km": 12000.0
		},
		{
			"name": "Halbe Breite",
			"pixel1": Vector2(0, 600),
			"pixel2": Vector2(1000, 600),
			"expected_km": 10000.0
		},
		{
			"name": "Diagonale (Pythagoras)",
			"pixel1": Vector2(0, 0),
			"pixel2": Vector2(2000, 1200),
			"expected_km": sqrt(20000.0*20000.0 + 12000.0*12000.0)
		}
	]

	for test in tests:
		var calculated = map_scale.calculate_distance_km_from_pixels(test.pixel1, test.pixel2)
		var error = abs(calculated - test.expected_km)
		var error_percent = (error / test.expected_km) * 100.0

		var status = "✓" if error_percent < 0.1 else "✗"
		print("%s %s: %.2f km (Erwartet: %.2f km, Fehler: %.2f%%)" % [
			status, test.name, calculated, test.expected_km, error_percent
		])

	# Test 2.2: World-Koordinaten direkt
	var world1 = Vector2(0, 0)
	var world2 = Vector2(10000, 6000)
	var distance = map_scale.calculate_distance_km(world1, world2)
	var expected = sqrt(10000.0*10000.0 + 6000.0*6000.0)
	var error_percent = (abs(distance - expected) / expected) * 100.0

	var status = "✓" if error_percent < 0.1 else "✗"
	print("%s World-Distanz %s → %s: %.2f km (Erwartet: %.2f km)" % [
		status, world1, world2, distance, expected
	])

	print("")

func test_area_calculations() -> void:
	print("--- Test 3: Flächen-Berechnungen ---")

	# Test 3.1: Rechteck in Pixel-Koordinaten
	var rect_pixels = PackedVector2Array([
		Vector2(0, 0),
		Vector2(1000, 0),
		Vector2(1000, 600),
		Vector2(0, 600)
	])

	var area_from_pixels = map_scale.calculate_polygon_area_km2_from_pixels(rect_pixels)
	var expected_area = 10000.0 * 6000.0  # 60,000,000 km²
	var error_percent = (abs(area_from_pixels - expected_area) / expected_area) * 100.0

	var status = "✓" if error_percent < 0.1 else "✗"
	print("%s Rechteck (1000x600 px): %.0f km² (Erwartet: %.0f km², Fehler: %.2f%%)" % [
		status, area_from_pixels, expected_area, error_percent
	])

	# Test 3.2: Rechteck in World-Koordinaten
	var rect_world = PackedVector2Array([
		Vector2(0, 0),
		Vector2(10000, 0),
		Vector2(10000, 6000),
		Vector2(0, 6000)
	])

	var area_from_world = map_scale.calculate_polygon_area_km2(rect_world)
	error_percent = (abs(area_from_world - expected_area) / expected_area) * 100.0

	status = "✓" if error_percent < 0.1 else "✗"
	print("%s Rechteck (10000x6000 km): %.0f km² (Erwartet: %.0f km², Fehler: %.2f%%)" % [
		status, area_from_world, expected_area, error_percent
	])

	# Test 3.3: Dreieck
	var triangle_world = PackedVector2Array([
		Vector2(0, 0),
		Vector2(10000, 0),
		Vector2(5000, 6000)
	])

	var triangle_area = map_scale.calculate_polygon_area_km2(triangle_world)
	var expected_triangle = (10000.0 * 6000.0) / 2.0  # 30,000,000 km²
	error_percent = (abs(triangle_area - expected_triangle) / expected_triangle) * 100.0

	status = "✓" if error_percent < 0.1 else "✗"
	print("%s Dreieck: %.0f km² (Erwartet: %.0f km², Fehler: %.2f%%)" % [
		status, triangle_area, expected_triangle, error_percent
	])

	# Test 3.4: Gesamte Weltkarte
	var world_rect = PackedVector2Array([
		Vector2(0, 0),
		Vector2(20000, 0),
		Vector2(20000, 12000),
		Vector2(0, 12000)
	])

	var world_area = map_scale.calculate_polygon_area_km2(world_rect)
	var expected_world = 240000000.0  # 240 Millionen km²
	error_percent = (abs(world_area - expected_world) / expected_world) * 100.0

	status = "✓" if error_percent < 0.1 else "✗"
	print("%s Gesamte Weltkarte: %.0f km² (Erwartet: %.0f km², Fehler: %.2f%%)" % [
		status, world_area, expected_world, error_percent
	])

	print("")

func test_boundary_validation() -> void:
	print("--- Test 4: Grenz-Validierung ---")

	# Test 4.1: Gültige Positionen
	var valid_tests = [
		{"pos": Vector2(0, 0), "name": "Ecke oben-links"},
		{"pos": Vector2(20000, 12000), "name": "Ecke unten-rechts"},
		{"pos": Vector2(10000, 6000), "name": "Zentrum"}
	]

	for test in valid_tests:
		var is_valid = map_scale.is_valid_world_position(test.pos)
		var status = "✓" if is_valid else "✗"
		print("%s %s ist gültig: %s" % [status, test.name, is_valid])

	# Test 4.2: Ungültige Positionen
	var invalid_tests = [
		{"pos": Vector2(-100, 6000), "name": "Negative X"},
		{"pos": Vector2(10000, -100), "name": "Negative Y"},
		{"pos": Vector2(25000, 6000), "name": "X zu groß"},
		{"pos": Vector2(10000, 15000), "name": "Y zu groß"}
	]

	for test in invalid_tests:
		var is_valid = map_scale.is_valid_world_position(test.pos)
		var status = "✓" if not is_valid else "✗"
		print("%s %s ist ungültig: %s" % [status, test.name, not is_valid])

	# Test 4.3: Clamping
	var clamp_test = Vector2(-1000, 15000)
	var clamped = map_scale.clamp_world_position(clamp_test)
	var expected_clamp = Vector2(0, 12000)
	var is_correct = clamped == expected_clamp

	var status = "✓" if is_correct else "✗"
	print("%s Clamping %s → %s (Erwartet: %s)" % [
		status, clamp_test, clamped, expected_clamp
	])

	print("")

func test_real_world_scenarios() -> void:
	print("--- Test 5: Real-World Szenarien ---")

	# Test 5.1: Typische Provinzgröße
	print("Typische Provinz (500x300 km):")
	var province_world = PackedVector2Array([
		Vector2(0, 0),
		Vector2(500, 0),
		Vector2(500, 300),
		Vector2(0, 300)
	])
	var province_area = map_scale.calculate_polygon_area_km2(province_world)
	print("  Fläche: %.0f km² (Vergleich: Bayern = ~70.550 km²)" % province_area)

	# Test 5.2: Typische Nation (3000x2000 km)
	print("Typische Nation (3000x2000 km):")
	var nation_world = PackedVector2Array([
		Vector2(0, 0),
		Vector2(3000, 0),
		Vector2(3000, 2000),
		Vector2(0, 2000)
	])
	var nation_area = map_scale.calculate_polygon_area_km2(nation_world)
	print("  Fläche: %.0f km² (Vergleich: Deutschland = ~357.000 km²)" % nation_area)

	# Test 5.3: Distanz zwischen Hauptstädten
	print("Distanz zwischen Hauptstädten:")
	var capital1 = Vector2(2000, 3000)  # World coords
	var capital2 = Vector2(8000, 7000)
	var distance = map_scale.calculate_distance_km(capital1, capital2)
	print("  %s → %s: %.0f km (Vergleich: Berlin-Paris = ~880 km)" % [
		capital1, capital2, distance
	])

	# Test 5.4: Bevölkerungsdichte berechnen
	print("Bevölkerungsdichte:")
	var district_pixels = PackedVector2Array([
		Vector2(100, 100),
		Vector2(200, 100),
		Vector2(200, 200),
		Vector2(100, 200)
	])
	var district_area = map_scale.calculate_polygon_area_km2_from_pixels(district_pixels)
	var population = 500000
	var density = population / district_area if district_area > 0 else 0
	print("  Fläche: %.0f km², Bevölkerung: %d, Dichte: %.1f Einw./km²" % [
		district_area, population, density
	])
	print("  (Vergleich: Berlin = ~4.100 Einw./km², Landkreis = ~150 Einw./km²)")

	print("")

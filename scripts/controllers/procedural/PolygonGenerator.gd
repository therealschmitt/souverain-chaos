class_name PolygonGenerator
extends RefCounted

## Generiert realistische, organische Polygone für Karten
## Verwendet verschiedene Algorithmen für natürlich aussehende Grenzen

## Generiert ein organisches Polygon innerhalb gegebener Bounds
static func generate_organic_polygon(
	bounds_min: Vector2,
	bounds_max: Vector2,
	irregularity: float = 0.3,
	spikeyness: float = 0.2,
	num_vertices: int = 12
) -> PackedVector2Array:
	"""
	Generiert ein organisches Polygon mit zufälligen Variationen.

	Args:
		bounds_min: Minimale Position (x, y)
		bounds_max: Maximale Position (x, y)
		irregularity: Wie unregelmäßig die Abstände zwischen Punkten sind (0.0 - 1.0)
		spikeyness: Wie "spitzig" die Ecken sind (0.0 - 1.0)
		num_vertices: Anzahl der Eckpunkte (mehr = glatter)

	Returns:
		PackedVector2Array mit Polygon-Punkten
	"""
	var center = (bounds_min + bounds_max) / 2.0
	var avg_radius_x = (bounds_max.x - bounds_min.x) / 2.0
	var avg_radius_y = (bounds_max.y - bounds_min.y) / 2.0

	# Clamp Werte
	irregularity = clamp(irregularity, 0.0, 1.0)
	spikeyness = clamp(spikeyness, 0.0, 1.0)

	# Generiere Winkel-Schritte
	var angle_steps = []
	var lower = (2.0 * PI / num_vertices) - irregularity
	var upper = (2.0 * PI / num_vertices) + irregularity
	var cumsum = 0.0

	for i in range(num_vertices):
		var angle = randf_range(lower, upper)
		angle_steps.append(angle)
		cumsum += angle

	# Normalisiere Winkel auf 2*PI
	for i in range(num_vertices):
		angle_steps[i] = angle_steps[i] / cumsum * 2.0 * PI

	# Generiere Punkte
	var points: Array[Vector2] = []
	var angle = randf_range(0.0, 2.0 * PI)

	for i in range(num_vertices):
		# Radius mit Variation
		var radius_variation = 1.0 + randf_range(-spikeyness, spikeyness)
		var radius_x = avg_radius_x * radius_variation
		var radius_y = avg_radius_y * radius_variation

		# Punkt berechnen (elliptisch)
		var x = center.x + radius_x * cos(angle)
		var y = center.y + radius_y * sin(angle)

		points.append(Vector2(x, y))

		angle += angle_steps[i]

	# Konvertiere zu PackedVector2Array
	var result = PackedVector2Array()
	for point in points:
		result.append(point)

	return result

## Generiert mehrere Polygone innerhalb eines Mutter-Polygons (Voronoi-basiert)
static func generate_voronoi_subdivision(
	parent_polygon: PackedVector2Array,
	num_subdivisions: int,
	irregularity: float = 0.2,
	relaxation_iterations: int = 2
) -> Array[PackedVector2Array]:
	"""
	Teilt ein Polygon in mehrere Unter-Polygone mit Voronoi-Diagramm auf.
	Die Untergrenzen folgen realistisch den Grenzen des Mutter-Polygons.

	Args:
		parent_polygon: Das zu unterteilende Polygon
		num_subdivisions: Anzahl der Unter-Polygone
		irregularity: Grad der Unregelmäßigkeit der Seed-Punkte (0.0 - 1.0)
		relaxation_iterations: Lloyd's Relaxation für gleichmäßigere Zellen

	Returns:
		Array von PackedVector2Array (Voronoi-Zellen innerhalb des Parent-Polygons)
	"""
	if parent_polygon.size() < 3 or num_subdivisions < 1:
		return []

	print("PolygonGenerator: Generating %d subdivisions for polygon with %d vertices" % [num_subdivisions, parent_polygon.size()])

	# Berechne Bounds des Parent-Polygons
	var bounds = _get_polygon_bounds(parent_polygon)
	var width = bounds.max.x - bounds.min.x
	var height = bounds.max.y - bounds.min.y
	var area = _calculate_polygon_area(parent_polygon)

	print("  Parent bounds: min=%s, max=%s, area=%.1f" % [bounds.min, bounds.max, area])

	# Prüfe ob Polygon zu klein oder zu komplex ist
	if width < 10.0 or height < 10.0 or area < 100.0:
		push_warning("PolygonGenerator: Parent polygon too small (w=%.1f, h=%.1f, area=%.1f), using simple subdivision" % [width, height, area])
		return _simple_grid_subdivision(parent_polygon, num_subdivisions)

	# Generiere Voronoi-Seed-Punkte innerhalb des Polygons
	var seeds = _generate_seeds_in_polygon(parent_polygon, bounds, num_subdivisions, irregularity)

	print("  Generated %d seeds" % seeds.size())

	# Falls zu wenig Seeds, verwende einfache Grid-Subdivision
	if seeds.size() < num_subdivisions * 0.75:  # Mindestens 75% der Seeds müssen erfolgreich sein
		push_warning("PolygonGenerator: Not enough seeds generated (%d/%d), falling back to simple subdivision" % [seeds.size(), num_subdivisions])
		return _simple_grid_subdivision(parent_polygon, num_subdivisions)

	# Lloyd's Relaxation für gleichmäßigere Verteilung (nur wenn genug Seeds)
	if seeds.size() >= num_subdivisions:
		for _i in range(relaxation_iterations):
			seeds = _relax_seeds(seeds, parent_polygon, bounds)

	# Generiere Voronoi-Zellen mit Godots eingebauter Clip-Funktion
	var voronoi_cells = _generate_voronoi_cells_robust(seeds, parent_polygon, bounds)

	print("  Generated %d voronoi cells" % voronoi_cells.size())

	# Validierung - Falls zu viele ungültige Zellen, Fallback
	var valid_cells = 0
	for cell in voronoi_cells:
		if cell.size() >= 3:
			valid_cells += 1

	if valid_cells < num_subdivisions * 0.5:  # Mindestens 50% müssen gültig sein
		push_warning("PolygonGenerator: Too many invalid cells (%d/%d), falling back to simple subdivision" % [valid_cells, num_subdivisions])
		return _simple_grid_subdivision(parent_polygon, num_subdivisions)

	return voronoi_cells

## Einfache Grid-Subdivision als Fallback
static func _simple_grid_subdivision(
	parent_polygon: PackedVector2Array,
	num_subdivisions: int
) -> Array[PackedVector2Array]:
	"""Einfache Grid-basierte Subdivision als Fallback."""
	var cells: Array[PackedVector2Array] = []
	var bounds = _get_polygon_bounds(parent_polygon)

	var cols = int(ceil(sqrt(num_subdivisions)))
	var rows = int(ceil(float(num_subdivisions) / cols))

	var width = bounds.max.x - bounds.min.x
	var height = bounds.max.y - bounds.min.y
	var cell_width = width / cols
	var cell_height = height / rows

	for row in range(rows):
		for col in range(cols):
			if cells.size() >= num_subdivisions:
				break

			var min_x = bounds.min.x + col * cell_width
			var min_y = bounds.min.y + row * cell_height
			var max_x = min_x + cell_width
			var max_y = min_y + cell_height

			var cell_rect = PackedVector2Array([
				Vector2(min_x, min_y),
				Vector2(max_x, min_y),
				Vector2(max_x, max_y),
				Vector2(min_x, max_y)
			])

			# Clippe mit Parent
			var clipped = Geometry2D.clip_polygons(cell_rect, parent_polygon)
			if clipped.size() > 0 and clipped[0].size() >= 3:
				cells.append(clipped[0])

	return cells

## Generiert Seed-Punkte innerhalb eines Polygons
static func _generate_seeds_in_polygon(
	polygon: PackedVector2Array,
	bounds: Dictionary,
	count: int,
	irregularity: float
) -> Array[Vector2]:
	"""Generiert count Seed-Punkte innerhalb des Polygons."""
	var seeds: Array[Vector2] = []
	var width = bounds.max.x - bounds.min.x
	var height = bounds.max.y - bounds.min.y

	# Grid-Layout für initiale Verteilung
	var cols = int(ceil(sqrt(count)))
	var rows = int(ceil(float(count) / cols))
	var cell_width = width / cols
	var cell_height = height / rows

	var attempts = 0
	var max_attempts = count * 50

	for row in range(rows):
		for col in range(cols):
			if seeds.size() >= count:
				break

			# Basis-Position im Grid
			var base_x = bounds.min.x + (col + 0.5) * cell_width
			var base_y = bounds.min.y + (row + 0.5) * cell_height

			# Füge Irregularität hinzu
			var offset_x = randf_range(-irregularity * cell_width * 0.4, irregularity * cell_width * 0.4)
			var offset_y = randf_range(-irregularity * cell_height * 0.4, irregularity * cell_height * 0.4)

			var seed = Vector2(base_x + offset_x, base_y + offset_y)

			# Prüfe ob Punkt innerhalb des Polygons liegt
			if Geometry2D.is_point_in_polygon(seed, polygon):
				seeds.append(seed)
			else:
				# Fallback: Versuche nächsten Punkt in Richtung Zentrum
				var polygon_center = _calculate_polygon_center_internal(polygon)
				seed = seed.lerp(polygon_center, 0.3)
				if Geometry2D.is_point_in_polygon(seed, polygon):
					seeds.append(seed)

			attempts += 1
			if attempts >= max_attempts:
				break

	return seeds

## Lloyd's Relaxation für gleichmäßigere Seed-Verteilung
static func _relax_seeds(
	seeds: Array[Vector2],
	polygon: PackedVector2Array,
	bounds: Dictionary
) -> Array[Vector2]:
	"""Bewegt Seeds zu Zentren ihrer Voronoi-Zellen für gleichmäßigere Verteilung."""
	var relaxed: Array[Vector2] = []

	for seed in seeds:
		# Berechne Voronoi-Zelle für diesen Seed (vereinfachte Version)
		var cell = _calculate_voronoi_cell_simple(seed, seeds, polygon, bounds)

		if cell.size() >= 3:
			# Zentrum der Zelle wird neuer Seed
			var new_seed = _calculate_polygon_center_internal(cell)

			# Falls außerhalb, bleibe beim alten Seed
			if Geometry2D.is_point_in_polygon(new_seed, polygon):
				relaxed.append(new_seed)
			else:
				relaxed.append(seed)
		else:
			# Falls Zelle ungültig, behalte alten Seed
			relaxed.append(seed)

	return relaxed

## Vereinfachte Voronoi-Zellen-Berechnung für Relaxation
static func _calculate_voronoi_cell_simple(
	seed: Vector2,
	all_seeds: Array[Vector2],
	parent_polygon: PackedVector2Array,
	bounds: Dictionary
) -> PackedVector2Array:
	"""Schnellere, vereinfachte Voronoi-Zelle für Relaxation."""
	var margin = max(bounds.max.x - bounds.min.x, bounds.max.y - bounds.min.y) * 1.0
	var cell = parent_polygon.duplicate()

	# Clippe mit maximal 3 nächsten Seeds für Performance
	var nearest_seeds = _get_nearest_seeds(seed, all_seeds, 4)

	for other_seed in nearest_seeds:
		if other_seed == seed:
			continue

		var midpoint = (seed + other_seed) / 2.0
		var direction = (other_seed - seed).normalized()
		var perpendicular = Vector2(-direction.y, direction.x)
		var extension = margin * 2.0

		var p1 = midpoint + perpendicular * extension
		var p2 = midpoint - perpendicular * extension
		var p3 = p2 - direction * extension
		var p4 = p1 - direction * extension

		var half_plane_poly = PackedVector2Array([p1, p2, p3, p4])
		var clipped = Geometry2D.intersect_polygons(cell, half_plane_poly)

		if clipped.size() > 0 and clipped[0].size() >= 3:
			cell = clipped[0]

	return cell

## Findet die N nächsten Seeds zu einem gegebenen Seed
static func _get_nearest_seeds(seed: Vector2, all_seeds: Array[Vector2], count: int) -> Array[Vector2]:
	"""Gibt die count nächsten Seeds zurück."""
	var distances: Array[Dictionary] = []

	for other_seed in all_seeds:
		var dist = seed.distance_to(other_seed)
		distances.append({"seed": other_seed, "distance": dist})

	# Sortiere nach Distanz
	distances.sort_custom(func(a, b): return a.distance < b.distance)

	# Nimm die ersten count
	var result: Array[Vector2] = []
	for i in range(min(count, distances.size())):
		result.append(distances[i].seed)

	return result

## Berechnet eine einzelne Voronoi-Zelle
static func _calculate_voronoi_cell(
	seed: Vector2,
	all_seeds: Array[Vector2],
	parent_polygon: PackedVector2Array,
	bounds: Dictionary
) -> PackedVector2Array:
	"""Berechnet die Voronoi-Zelle für einen Seed-Punkt."""
	# Erstelle ein großes Polygon um den Seed
	var cell_points: Array[Vector2] = []

	# Sampling-Auflösung für Polygon-Kanten
	var resolution = 32
	var margin = max(bounds.max.x - bounds.min.x, bounds.max.y - bounds.min.y) * 0.1

	# Erstelle initiales großes Rechteck um Seed
	var large_polygon = PackedVector2Array([
		Vector2(bounds.min.x - margin, bounds.min.y - margin),
		Vector2(bounds.max.x + margin, bounds.min.y - margin),
		Vector2(bounds.max.x + margin, bounds.max.y + margin),
		Vector2(bounds.min.x - margin, bounds.max.y + margin)
	])

	# Schneide mit Halbebenen aller anderen Seeds
	var clipped = large_polygon
	for other_seed in all_seeds:
		if other_seed == seed:
			continue

		# Berechne Mittelsenkrechte zwischen seed und other_seed
		var midpoint = (seed + other_seed) / 2.0
		var direction = (other_seed - seed).normalized()
		var perpendicular = Vector2(-direction.y, direction.x)

		# Erstelle Halbebene (Linie + sehr große Extension)
		var extension = 10000.0
		var half_plane_line = PackedVector2Array([
			midpoint + perpendicular * extension,
			midpoint - perpendicular * extension
		])

		# Clippe clipped mit dieser Halbebene (keep seed side)
		clipped = _clip_polygon_by_half_plane(clipped, seed, midpoint, perpendicular)

	# Schneide mit Parent-Polygon
	var final_cell = _clip_polygon_by_polygon(clipped, parent_polygon)

	return final_cell

## Clippt Polygon an Halbebene
static func _clip_polygon_by_half_plane(
	polygon: PackedVector2Array,
	keep_side_point: Vector2,
	plane_point: Vector2,
	plane_normal: Vector2
) -> PackedVector2Array:
	"""Clippt Polygon an einer Halbebene, behält Seite mit keep_side_point."""
	if polygon.size() < 3:
		return polygon

	var result = PackedVector2Array()

	for i in range(polygon.size()):
		var current = polygon[i]
		var next = polygon[(i + 1) % polygon.size()]

		var current_side = (current - plane_point).dot(plane_normal)
		var next_side = (next - plane_point).dot(plane_normal)
		var keep_side = (keep_side_point - plane_point).dot(plane_normal)

		# Beide Punkte auf keep-Seite
		if sign(current_side) == sign(keep_side) or abs(current_side) < 0.001:
			result.append(current)

		# Edge kreuzt Ebene
		if sign(current_side) != sign(next_side) and abs(current_side) > 0.001 and abs(next_side) > 0.001:
			# Berechne Schnittpunkt
			var t = abs(current_side) / (abs(current_side) + abs(next_side))
			var intersection = current.lerp(next, t)
			result.append(intersection)

	return result

## Clippt Polygon an anderem Polygon (Intersection)
static func _clip_polygon_by_polygon(
	polygon: PackedVector2Array,
	clip_polygon: PackedVector2Array
) -> PackedVector2Array:
	"""Schneidet zwei Polygone (vereinfachte Sutherland-Hodgman)."""
	if polygon.size() < 3 or clip_polygon.size() < 3:
		return PackedVector2Array()

	# Verwende Godots eingebaute Geometry-Funktion
	var intersection = Geometry2D.clip_polygons(polygon, clip_polygon)

	if intersection.size() > 0:
		return intersection[0]  # Nehme größte Intersection
	else:
		return PackedVector2Array()

## Generiert alle Voronoi-Zellen (robuste Version mit Godot-Clipping)
static func _generate_voronoi_cells_robust(
	seeds: Array[Vector2],
	parent_polygon: PackedVector2Array,
	bounds: Dictionary
) -> Array[PackedVector2Array]:
	"""Generiert Voronoi-Zellen mit Godots Geometry2D für robustes Clipping."""
	var cells: Array[PackedVector2Array] = []

	# Erweiterte Bounds für initiale Zellen
	var margin = max(bounds.max.x - bounds.min.x, bounds.max.y - bounds.min.y) * 1.0
	var expanded_min = bounds.min - Vector2(margin, margin)
	var expanded_max = bounds.max + Vector2(margin, margin)

	for i in range(seeds.size()):
		var seed = seeds[i]

		# Starte mit Parent-Polygon als initiale Zelle
		var cell = parent_polygon.duplicate()

		# Clippe mit allen Halbebenen von anderen Seeds
		for j in range(seeds.size()):
			if i == j:
				continue

			var other_seed = seeds[j]

			# Berechne Mittelsenkrechte zwischen seed und other_seed
			var midpoint = (seed + other_seed) / 2.0
			var direction = (other_seed - seed).normalized()

			# Senkrechte zur Verbindungslinie
			var perpendicular = Vector2(-direction.y, direction.x)

			# Erstelle großes Halbebenen-Rechteck auf der seed-Seite
			# Das Rechteck geht von der Mittelsenkrechte weg in Richtung seed
			var extension = margin * 2.0

			# Die 4 Eckpunkte des Halbebenen-Rechtecks:
			# Zwei Punkte auf der Mittelsenkrechte, zwei weit auf der seed-Seite
			var p1 = midpoint + perpendicular * extension  # Oben auf Mittelsenkrechte
			var p2 = midpoint - perpendicular * extension  # Unten auf Mittelsenkrechte
			var p3 = p2 - direction * extension           # Unten auf seed-Seite
			var p4 = p1 - direction * extension           # Oben auf seed-Seite

			var half_plane_poly = PackedVector2Array([p1, p2, p3, p4])

			# Intersection: Behalte nur den Teil der Zelle, der näher an seed ist
			var clipped = Geometry2D.intersect_polygons(cell, half_plane_poly)

			if clipped.size() > 0:
				# Nimm größtes resultierendes Polygon
				var largest = clipped[0]
				var largest_area = _calculate_polygon_area(largest)

				for k in range(1, clipped.size()):
					var area = _calculate_polygon_area(clipped[k])
					if area > largest_area:
						largest = clipped[k]
						largest_area = area

				if largest.size() >= 3:
					cell = largest

		# Validiere Zelle
		if cell.size() >= 3:
			cells.append(cell)
		else:
			push_warning("PolygonGenerator: Voronoi cell %d has < 3 vertices after clipping" % i)

	return cells

## Berechnet Fläche eines Polygons (Shoelace-Formel)
static func _calculate_polygon_area(polygon: PackedVector2Array) -> float:
	"""Berechnet die Fläche eines Polygons."""
	if polygon.size() < 3:
		return 0.0

	var area = 0.0
	for i in range(polygon.size()):
		var j = (i + 1) % polygon.size()
		area += polygon[i].x * polygon[j].y
		area -= polygon[j].x * polygon[i].y

	return abs(area) / 2.0

## Generiert alle Voronoi-Zellen (alte Version)
static func _generate_voronoi_cells(
	seeds: Array[Vector2],
	parent_polygon: PackedVector2Array,
	bounds: Dictionary
) -> Array[PackedVector2Array]:
	"""Generiert alle Voronoi-Zellen."""
	var cells: Array[PackedVector2Array] = []

	for seed in seeds:
		var cell = _calculate_voronoi_cell(seed, seeds, parent_polygon, bounds)
		if cell.size() >= 3:  # Nur gültige Polygone
			cells.append(cell)

	return cells

## Berechnet Bounds eines Polygons
static func _get_polygon_bounds(polygon: PackedVector2Array) -> Dictionary:
	"""Gibt {min: Vector2, max: Vector2} zurück."""
	var bounds_min = Vector2(INF, INF)
	var bounds_max = Vector2(-INF, -INF)

	for point in polygon:
		bounds_min.x = min(bounds_min.x, point.x)
		bounds_min.y = min(bounds_min.y, point.y)
		bounds_max.x = max(bounds_max.x, point.x)
		bounds_max.y = max(bounds_max.y, point.y)

	return {"min": bounds_min, "max": bounds_max}

## Interne Zentrumsberechnung
static func _calculate_polygon_center_internal(polygon: PackedVector2Array) -> Vector2:
	"""Berechnet Zentrum eines Polygons."""
	if polygon.size() == 0:
		return Vector2.ZERO

	var sum = Vector2.ZERO
	for point in polygon:
		sum += point
	return sum / polygon.size()

## Generiert ein "natürliches" Polygon mit Perlin Noise
static func generate_natural_polygon(
	bounds_min: Vector2,
	bounds_max: Vector2,
	roughness: float = 0.15,
	num_vertices: int = 16,
	seed_value: int = -1
) -> PackedVector2Array:
	"""
	Generiert ein Polygon mit naturalistischen Grenzen.
	Nutzt Perlin-ähnliches Noise für organische Formen.

	Args:
		bounds_min: Minimale Position
		bounds_max: Maximale Position
		roughness: Grad der Rauheit der Grenzen (0.0 - 1.0)
		num_vertices: Anzahl der Punkte
		seed_value: Seed für Reproduzierbarkeit (oder -1 für zufällig)

	Returns:
		PackedVector2Array mit Polygon-Punkten
	"""
	if seed_value >= 0:
		seed(seed_value)

	var center = (bounds_min + bounds_max) / 2.0
	var radius_x = (bounds_max.x - bounds_min.x) / 2.0
	var radius_y = (bounds_max.y - bounds_min.y) / 2.0

	var points = PackedVector2Array()
	var angle_step = 2.0 * PI / num_vertices

	for i in range(num_vertices):
		var angle = i * angle_step

		# Basis-Radius (elliptisch)
		var base_radius_x = radius_x
		var base_radius_y = radius_y

		# Noise-basierte Variation
		# Verwende mehrere Oktaven für natürliches Aussehen
		var noise_val = _simplex_noise(angle * 2.0, 0.0) * 0.5
		noise_val += _simplex_noise(angle * 4.0, 100.0) * 0.25
		noise_val += _simplex_noise(angle * 8.0, 200.0) * 0.125

		var radius_variation = 1.0 + noise_val * roughness

		var x = center.x + base_radius_x * cos(angle) * radius_variation
		var y = center.y + base_radius_y * sin(angle) * radius_variation

		points.append(Vector2(x, y))

	return points

## Vereinfachte Simplex Noise Funktion (1D)
static func _simplex_noise(x: float, offset: float) -> float:
	"""
	Vereinfachte Noise-Funktion für Polygon-Generierung.
	Gibt Werte zwischen -1.0 und 1.0 zurück.
	"""
	var val = sin(x * 3.14159 + offset) * 43758.5453
	return fmod(val, 1.0) * 2.0 - 1.0

## Glättet ein Polygon durch Interpolation
static func smooth_polygon(polygon: PackedVector2Array, iterations: int = 1) -> PackedVector2Array:
	"""
	Glättet ein Polygon durch Chaikin's Corner Cutting Algorithm.

	Args:
		polygon: Das zu glättende Polygon
		iterations: Anzahl der Glättungsiterationen

	Returns:
		Geglättetes Polygon
	"""
	var result = polygon

	for _iter in range(iterations):
		var smoothed = PackedVector2Array()
		var n = result.size()

		for i in range(n):
			var p0 = result[i]
			var p1 = result[(i + 1) % n]

			# Chaikin's corner cutting: 0.25 und 0.75 Punkte
			var q = p0.lerp(p1, 0.25)
			var r = p0.lerp(p1, 0.75)

			smoothed.append(q)
			smoothed.append(r)

		result = smoothed

	return result

## Validiert ob ein Polygon gültig ist
static func validate_polygon(polygon: PackedVector2Array) -> bool:
	"""
	Prüft ob ein Polygon gültig ist (mindestens 3 Punkte, keine self-intersections).
	"""
	if polygon.size() < 3:
		return false

	# TODO: Self-intersection check (komplex, für späteren Zeitpunkt)

	return true

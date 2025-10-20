class_name MapDataGenerator
extends RefCounted

## Generiert eine fiktive Weltkarte mit vollständigen Polygon-Daten für alle 5 Zoomstufen
## Lädt Kartendaten aus Templates in data/templates/maps/
## Zoomstufe 1: Weltkarte
## Zoomstufe 2: Regionen
## Zoomstufe 3: Nationen
## Zoomstufe 4: Provinzen
## Zoomstufe 5: Distrikte/Städte

const MAP_WIDTH = 2000.0  # Pixel-Breite der Weltkarte
const MAP_HEIGHT = 1200.0  # Pixel-Höhe der Weltkarte

const REGIONS_TEMPLATE = "res://data/templates/maps/regions.json"
const NATIONS_TEMPLATE = "res://data/templates/maps/nations.json"
const TERRAIN_RESOURCES_TEMPLATE = "res://data/templates/terrain/terrain_resources.json"
const PROVINCE_NAMES_TEMPLATE = "res://data/templates/naming/province_names.json"
const DISTRICT_NAMES_TEMPLATE = "res://data/templates/naming/district_names.json"

# Geladene Template-Daten
static var _terrain_data: Dictionary = {}
static var _province_naming_data: Dictionary = {}
static var _district_naming_data: Dictionary = {}

static func generate_full_map() -> Dictionary:
	"""
	Generiert eine vollständige fiktive Weltkarte aus Templates.
	Returns: {regions: Array[Region], nations: Array[Nation], provinces: Array[Province], districts: Array[District]}
	"""
	print("MapDataGenerator: Lade Templates und generiere Weltkarte...")

	# Lade Template-Daten beim ersten Aufruf
	if _terrain_data.is_empty():
		_load_terrain_resources_template()
	if _province_naming_data.is_empty():
		_load_province_naming_template()
	if _district_naming_data.is_empty():
		_load_district_naming_template()

	var result = {
		"regions": [],
		"nations": [],
		"provinces": [],
		"districts": []
	}

	# 1. Lade und generiere Regionen aus Template
	var regions = _load_and_generate_regions()
	result.regions = regions

	# 2. Lade Nationen-Template-Daten
	var nation_templates = _load_nation_templates()

	# Gruppiere Nationen-Templates nach Region
	var templates_by_region = {}  # region_id -> Array[nation_template]
	for template in nation_templates:
		var region_id = template.region_id
		if not templates_by_region.has(region_id):
			templates_by_region[region_id] = []
		templates_by_region[region_id].append(template)

	# Generiere Nationen für jede Region mit Voronoi-Subdivision
	for region in regions:
		if not templates_by_region.has(region.id):
			continue

		var region_templates = templates_by_region[region.id]
		var nations_in_region = _generate_nations_for_region(region, region_templates)

		result.nations.append_array(nations_in_region)

		# Nation-IDs zur Region hinzufügen
		var nation_ids: Array[String] = []
		for nation in nations_in_region:
			nation_ids.append(nation.id)
		region.nations = nation_ids

	# 3. Provinzen pro Nation generieren
	for nation in result.nations:
		var provinces = _generate_provinces_for_nation(nation)
		result.provinces.append_array(provinces)

	# 4. Distrikte pro Provinz generieren
	for province in result.provinces:
		var districts = _generate_districts_for_province(province)
		result.districts.append_array(districts)
		# Distrikt-IDs zur Provinz hinzufügen
		var district_ids: Array[String] = []
		for district in districts:
			district_ids.append(district.id)
		province.districts = district_ids

	print("MapDataGenerator: %d Regionen, %d Nationen, %d Provinzen, %d Distrikte" % [
		regions.size(), result.nations.size(), result.provinces.size(), result.districts.size()
	])

	return result

# === REGIONEN ===

static func _load_and_generate_regions() -> Array[Region]:
	"""Lädt Regionen aus Template und generiert Polygone."""
	var regions: Array[Region] = []

	var file = FileAccess.open(REGIONS_TEMPLATE, FileAccess.READ)
	if not file:
		push_error("MapDataGenerator: Konnte regions.json nicht laden!")
		return regions

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error("MapDataGenerator: Fehler beim Parsen von regions.json")
		return regions

	var data = json.get_data()
	if not data.has("regions"):
		push_error("MapDataGenerator: regions.json hat kein 'regions' Feld")
		return regions

	for region_data in data.regions:
		var region = Region.new()
		region.id = region_data.id
		region.name = region_data.name

		# Farbe aus Array laden
		var color_array = region_data.color
		region.color = Color(color_array[0], color_array[1], color_array[2])

		# Center Position
		var center_array = region_data.center_position
		region.center_position = Vector2(center_array[0], center_array[1])

		# Bounds
		var bounds_min_array = region_data.bounds.min
		var bounds_max_array = region_data.bounds.max
		var bounds_min = Vector2(bounds_min_array[0], bounds_min_array[1])
		var bounds_max = Vector2(bounds_max_array[0], bounds_max_array[1])

		# Generiere organisches Polygon
		region.boundary_polygon = PolygonGenerator.generate_natural_polygon(
			bounds_min,
			bounds_max,
			0.12,  # Weniger Roughness für große Regionen
			24,    # Mehr Vertices für glattere Grenzen
			region_data.id.hash()  # Seed basierend auf ID für Konsistenz
		)

		regions.append(region)

	print("MapDataGenerator: %d Regionen aus Template geladen" % regions.size())
	return regions

# === NATIONEN ===

static func _load_nation_templates() -> Array[Dictionary]:
	"""Lädt Nationen-Template-Daten aus JSON."""
	var templates: Array[Dictionary] = []

	var file = FileAccess.open(NATIONS_TEMPLATE, FileAccess.READ)
	if not file:
		push_error("MapDataGenerator: Konnte nations.json nicht laden!")
		return templates

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error("MapDataGenerator: Fehler beim Parsen von nations.json")
		return templates

	var data = json.get_data()
	if not data.has("nations"):
		push_error("MapDataGenerator: nations.json hat kein 'nations' Feld")
		return templates

	for nation_data in data.nations:
		templates.append(nation_data)

	print("MapDataGenerator: %d Nationen-Templates aus JSON geladen" % templates.size())
	return templates

static func _generate_nations_for_region(region: Region, nation_templates: Array) -> Array[Nation]:
	"""Generiert Nationen innerhalb einer Region mit Voronoi-Subdivision."""
	var nations: Array[Nation] = []

	if nation_templates.size() == 0:
		return nations

	print("MapDataGenerator: Generiere %d Nationen für Region %s" % [nation_templates.size(), region.name])

	# Generiere Voronoi-Subdivision innerhalb der Region
	var nation_polygons = PolygonGenerator.generate_voronoi_subdivision(
		region.boundary_polygon,
		nation_templates.size(),
		0.25,  # Mittlere Irregularity
		2      # Normale Relaxation
	)

	# Falls Voronoi fehlschlägt, verwende Bounds aus Templates
	if nation_polygons.size() < nation_templates.size():
		push_warning("MapDataGenerator: Voronoi für Nationen fehlgeschlagen, verwende Template-Bounds")
		nation_polygons = []
		for nation_data in nation_templates:
			var bounds_min_array = nation_data.bounds.min
			var bounds_max_array = nation_data.bounds.max
			var bounds_min = Vector2(bounds_min_array[0], bounds_min_array[1])
			var bounds_max = Vector2(bounds_max_array[0], bounds_max_array[1])

			var polygon = PolygonGenerator.generate_natural_polygon(
				bounds_min,
				bounds_max,
				0.15,
				20,
				nation_data.id.hash()
			)
			nation_polygons.append(polygon)

	# Erstelle Nation-Objekte mit generierten Polygonen
	for i in range(min(nation_templates.size(), nation_polygons.size())):
		var nation_data = nation_templates[i]
		var polygon = nation_polygons[i]

		var nation = Nation.new()
		nation.id = nation_data.id
		nation.name = nation_data.name
		nation.adjective = nation_data.adjective
		nation.region_id = nation_data.region_id

		# Farbe
		var color_array = nation_data.color
		nation.color = Color(color_array[0], color_array[1], color_array[2])

		# Gameplay-Daten
		nation.government_type = nation_data.government_type
		nation.leader_character_id = nation_data.leader_character_id
		nation.capital_province_id = nation_data.capital_province_id
		nation.legitimacy = nation_data.legitimacy
		nation.gdp = nation_data.gdp
		nation.population = nation_data.population
		nation.tech_level = nation_data.tech_level
		nation.unemployment = nation_data.unemployment
		nation.military_strength = nation_data.military_strength

		# Verwende generiertes Voronoi-Polygon
		nation.boundary_polygon = polygon

		nations.append(nation)

	print("MapDataGenerator: %d Nationen für Region %s generiert" % [nations.size(), region.name])
	return nations

# === PROVINZEN ===

static func _generate_provinces_for_nation(nation: Nation) -> Array[Province]:
	"""Generiert 4 Provinzen pro Nation mit Voronoi-basierten organischen Grenzen."""
	var provinces: Array[Province] = []
	var num_provinces = 4

	# Berechne Bounds der Nation
	var nation_bounds = nation.boundary_polygon
	if nation_bounds.size() < 3:
		return provinces

	# Generiere Provinz-Polygone mit Voronoi-Subdivision innerhalb der Nation
	var province_polygons = PolygonGenerator.generate_voronoi_subdivision(
		nation_bounds,
		num_provinces,
		0.3,  # Irregularity
		2     # Lloyd's Relaxation Iterations
	)

	for i in range(province_polygons.size()):
		var polygon = province_polygons[i]

		var province = Province.new()
		province.id = "%s_prov_%d" % [nation.id, i]
		province.name = _generate_province_name(nation, i)
		province.nation_id = nation.id
		province.color = nation.color.lightened(0.05 + randf() * 0.15)
		province.boundary_polygon = polygon

		# Position = Zentrum des Polygons
		province.position = _calculate_polygon_center(polygon)

		# Gameplay-Daten
		province.terrain_type = _random_terrain()
		province.population = nation.population / num_provinces
		province.local_gdp = nation.gdp / float(num_provinces)
		province.infrastructure_level = randf_range(40.0, 80.0)
		province.has_port = province.terrain_type == "coastal"

		# Ressourcen basierend auf Terrain
		_assign_province_resources(province)

		provinces.append(province)

		# Erste Provinz ist Hauptstadt
		if i == 0:
			nation.capital_province_id = province.id

	return provinces

static func _generate_province_name(nation: Nation, index: int) -> String:
	"""Generiert Provinznamen aus Template-Daten."""
	if _province_naming_data.is_empty():
		return "Provinz %d" % index

	var prefixes = _province_naming_data.get("prefixes", [])
	var suffixes = _province_naming_data.get("suffixes", [])

	if prefixes.is_empty() or suffixes.is_empty():
		return "Provinz %d" % index

	var prefix_idx = index % prefixes.size()
	var suffix_idx = (index / prefixes.size()) % suffixes.size()

	return "%s%s" % [prefixes[prefix_idx], suffixes[suffix_idx]]

static func _random_terrain() -> String:
	"""Wählt zufälliges Terrain aus Template-Daten."""
	if _terrain_data.is_empty():
		return "plains"

	var terrains = _terrain_data.get("terrain_types", ["plains"])
	return terrains[randi() % terrains.size()]

static func _assign_province_resources(province: Province) -> void:
	"""Weist Ressourcen basierend auf Terrain und Template-Daten zu."""
	if _terrain_data.is_empty():
		return

	var resource_rules = _terrain_data.get("resource_rules", {})
	if not resource_rules.has(province.terrain_type):
		return

	var terrain_resources = resource_rules[province.terrain_type]
	for resource_name in terrain_resources.keys():
		var resource_config = terrain_resources[resource_name]
		var min_value = resource_config.get("min", 0.0)
		var max_value = resource_config.get("max", 100.0)
		province.resources[resource_name] = randf_range(min_value, max_value)

# === DISTRIKTE ===

static func _generate_districts_for_province(province: Province) -> Array[District]:
	"""Generiert 4 Distrikte pro Provinz mit organischen Grenzen."""
	var districts: Array[District] = []
	var num_districts = 4

	var bounds = province.boundary_polygon
	if bounds.size() < 3:
		return districts

	# Generiere Distrikt-Polygone mit Voronoi-Subdivision innerhalb der Provinz
	var district_polygons = PolygonGenerator.generate_voronoi_subdivision(
		bounds,
		num_districts,
		0.15,  # Sehr wenig Irregularity für kleine Einheiten
		0      # Keine Relaxation für bessere Stabilität bei kleinen Polygonen
	)

	for i in range(district_polygons.size()):
		var polygon = district_polygons[i]

		var district = District.new()
		district.id = "%s_dist_%d" % [province.id, i]
		district.province_id = province.id
		district.is_urban = (i == 0)  # Erster Distrikt ist Großstadt
		district.name = _generate_district_name(province, district.is_urban, i)
		district.color = province.color
		district.boundary_polygon = polygon
		district.position = _calculate_polygon_center(polygon)

		# Gameplay-Daten
		district.population = province.population / num_districts
		district.density = 1000.0 if district.is_urban else 200.0
		district.infrastructure_quality = randf_range(40.0, 80.0)
		district.has_university = district.is_urban and randf() > 0.5
		district.has_major_factory = randf() > 0.7
		district.has_military_base = randf() > 0.8

		districts.append(district)

	return districts

static func _generate_district_name(province: Province, is_urban: bool, index: int) -> String:
	"""Generiert Distrikt-Namen aus Template-Daten."""
	if _district_naming_data.is_empty():
		return "%s Distrikt %d" % [province.name, index]

	if is_urban:
		var city_names = _district_naming_data.get("urban_names", ["Hauptstadt"])
		return "%s %s" % [province.name, city_names[index % city_names.size()]]
	else:
		var rural_names = _district_naming_data.get("rural_names", ["Landkreis"])
		return "%s %s" % [province.name, rural_names[index % rural_names.size()]]

# === HILFSFUNKTIONEN ===

static func _calculate_polygon_center(polygon: PackedVector2Array) -> Vector2:
	"""Berechnet das Zentrum eines Polygons."""
	if polygon.size() == 0:
		return Vector2.ZERO

	var sum = Vector2.ZERO
	for point in polygon:
		sum += point
	return sum / polygon.size()

# === TEMPLATE-LADE-FUNKTIONEN ===

static func _load_terrain_resources_template() -> void:
	"""Lädt Terrain-Ressourcen-Regeln aus JSON."""
	var file = FileAccess.open(TERRAIN_RESOURCES_TEMPLATE, FileAccess.READ)
	if not file:
		push_error("MapDataGenerator: Konnte %s nicht laden!" % TERRAIN_RESOURCES_TEMPLATE)
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("MapDataGenerator: Fehler beim Parsen von %s" % TERRAIN_RESOURCES_TEMPLATE)
		return

	_terrain_data = json.get_data()
	print("MapDataGenerator: Terrain-Ressourcen-Template geladen")

static func _load_province_naming_template() -> void:
	"""Lädt Provinz-Namensregeln aus JSON."""
	var file = FileAccess.open(PROVINCE_NAMES_TEMPLATE, FileAccess.READ)
	if not file:
		push_error("MapDataGenerator: Konnte %s nicht laden!" % PROVINCE_NAMES_TEMPLATE)
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("MapDataGenerator: Fehler beim Parsen von %s" % PROVINCE_NAMES_TEMPLATE)
		return

	_province_naming_data = json.get_data()
	print("MapDataGenerator: Provinz-Namen-Template geladen")

static func _load_district_naming_template() -> void:
	"""Lädt Distrikt-Namensregeln aus JSON."""
	var file = FileAccess.open(DISTRICT_NAMES_TEMPLATE, FileAccess.READ)
	if not file:
		push_error("MapDataGenerator: Konnte %s nicht laden!" % DISTRICT_NAMES_TEMPLATE)
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("MapDataGenerator: Fehler beim Parsen von %s" % DISTRICT_NAMES_TEMPLATE)
		return

	_district_naming_data = json.get_data()
	print("MapDataGenerator: Distrikt-Namen-Template geladen")

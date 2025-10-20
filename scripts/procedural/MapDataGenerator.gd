class_name MapDataGenerator
extends RefCounted

## Generiert eine fiktive Weltkarte mit vollständigen Polygon-Daten für alle 5 Zoomstufen
## Zoomstufe 1: Weltkarte
## Zoomstufe 2: Regionen
## Zoomstufe 3: Nationen
## Zoomstufe 4: Provinzen
## Zoomstufe 5: Distrikte/Städte

const MAP_WIDTH = 2000.0  # Pixel-Breite der Weltkarte
const MAP_HEIGHT = 1200.0  # Pixel-Höhe der Weltkarte

static func generate_full_map() -> Dictionary:
	"""
	Generiert eine vollständige fiktive Weltkarte.
	Returns: {regions: Array[Region], nations: Array[Nation], provinces: Array[Province], districts: Array[District]}
	"""
	print("MapDataGenerator: Generiere Weltkarte...")

	var result = {
		"regions": [],
		"nations": [],
		"provinces": [],
		"districts": []
	}

	# 1. Regionen generieren (4 große geopolitische Regionen)
	var regions = _generate_regions()
	result.regions = regions

	# 2. Nationen pro Region generieren
	for region in regions:
		var nations = _generate_nations_for_region(region)
		result.nations.append_array(nations)
		# Explicitly create typed array for region.nations
		var nation_ids: Array[String] = []
		for nation in nations:
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
		# Explicitly create typed array for province.districts
		var district_ids: Array[String] = []
		for district in districts:
			district_ids.append(district.id)
		province.districts = district_ids

	print("MapDataGenerator: %d Regionen, %d Nationen, %d Provinzen, %d Distrikte" % [
		regions.size(), result.nations.size(), result.provinces.size(), result.districts.size()
	])

	return result

# === REGIONEN ===

static func _generate_regions() -> Array[Region]:
	"""Generiert 4 große geopolitische Regionen."""
	var regions: Array[Region] = []

	# Region 1: Westlicher Ozean (links)
	var west = Region.new()
	west.id = "west_ocean"
	west.name = "Westliche Ozeanstaaten"
	west.color = Color(0.3, 0.5, 0.8)  # Blau
	west.center_position = Vector2(400, 600)
	west.boundary_polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(800, 0),
		Vector2(800, 1200),
		Vector2(0, 1200)
	])
	regions.append(west)

	# Region 2: Mittelkontinent (mitte-oben)
	var central = Region.new()
	central.id = "central_continent"
	central.name = "Mittelkontinent"
	central.color = Color(0.7, 0.4, 0.3)  # Braun
	central.center_position = Vector2(1200, 400)
	central.boundary_polygon = PackedVector2Array([
		Vector2(800, 0),
		Vector2(2000, 0),
		Vector2(2000, 600),
		Vector2(800, 600)
	])
	regions.append(central)

	# Region 3: Südliche Steppen (mitte-unten)
	var south = Region.new()
	south.id = "southern_steppes"
	south.name = "Südliche Steppen"
	south.color = Color(0.8, 0.7, 0.4)  # Gelb-braun
	south.center_position = Vector2(1200, 900)
	south.boundary_polygon = PackedVector2Array([
		Vector2(800, 600),
		Vector2(2000, 600),
		Vector2(2000, 1200),
		Vector2(800, 1200)
	])
	regions.append(south)

	# Region 4: Östliche Inseln (separate Inselgruppe, imaginär rechts)
	# Für Zoom-Level 1 nicht sichtbar, nur bei Zoom auf Region

	return regions

# === NATIONEN ===

static func _generate_nations_for_region(region: Region) -> Array[Nation]:
	"""Generiert Nationen für eine Region."""
	var nations: Array[Nation] = []

	match region.id:
		"west_ocean":
			nations.append_array(_create_west_nations(region))
		"central_continent":
			nations.append_array(_create_central_nations(region))
		"southern_steppes":
			nations.append_array(_create_south_nations(region))

	return nations

static func _create_west_nations(region: Region) -> Array[Nation]:
	"""Westliche Ozeanstaaten: 2 maritime Demokratien."""
	var nations: Array[Nation] = []

	# Thalassia (Spieler-Nation)
	var thalassia = Nation.new()
	thalassia.id = "thalassia"
	thalassia.name = "Thalassische Republik"
	thalassia.adjective = "thalassisch"
	thalassia.region_id = region.id
	thalassia.color = Color(0.2, 0.4, 0.7)  # Dunkelblau
	thalassia.government_type = "democracy"
	thalassia.leader_character_id = "leader_thalassia"
	thalassia.capital_province_id = "thalassia_capital"
	thalassia.legitimacy = 65.0
	thalassia.gdp = 500000000000.0
	thalassia.population = 45000000
	thalassia.tech_level = 4
	thalassia.unemployment = 6.5
	thalassia.military_strength = 75.0
	# Polygon: Nördliche Hälfte der Westregion
	thalassia.boundary_polygon = PackedVector2Array([
		Vector2(50, 50),
		Vector2(750, 50),
		Vector2(750, 550),
		Vector2(50, 550)
	])
	nations.append(thalassia)

	# Azuria
	var azuria = Nation.new()
	azuria.id = "azuria"
	azuria.name = "Azurianische Föderation"
	azuria.adjective = "azurianisch"
	azuria.region_id = region.id
	azuria.color = Color(0.4, 0.6, 0.9)  # Hellblau
	azuria.government_type = "federal_republic"
	azuria.leader_character_id = "leader_azuria"
	azuria.capital_province_id = "azuria_capital"
	azuria.legitimacy = 70.0
	azuria.gdp = 350000000000.0
	azuria.population = 32000000
	azuria.tech_level = 4
	azuria.unemployment = 5.2
	azuria.military_strength = 65.0
	# Polygon: Südliche Hälfte der Westregion
	azuria.boundary_polygon = PackedVector2Array([
		Vector2(50, 600),
		Vector2(750, 600),
		Vector2(750, 1150),
		Vector2(50, 1150)
	])
	nations.append(azuria)

	return nations

static func _create_central_nations(region: Region) -> Array[Nation]:
	"""Mittelkontinent: 3 große Landmächte."""
	var nations: Array[Nation] = []

	# Nordreich
	var nordreich = Nation.new()
	nordreich.id = "nordreich"
	nordreich.name = "Nordreich"
	nordreich.adjective = "nordisch"
	nordreich.region_id = region.id
	nordreich.color = Color(0.6, 0.3, 0.2)  # Rotbraun
	nordreich.government_type = "constitutional_monarchy"
	nordreich.leader_character_id = "leader_nordreich"
	nordreich.capital_province_id = "nordreich_capital"
	nordreich.legitimacy = 80.0
	nordreich.gdp = 300000000000.0
	nordreich.population = 28000000
	nordreich.tech_level = 4
	nordreich.unemployment = 4.2
	nordreich.military_strength = 60.0
	# Polygon: Obere Hälfte Mittelkontinent
	nordreich.boundary_polygon = PackedVector2Array([
		Vector2(850, 50),
		Vector2(1950, 50),
		Vector2(1950, 550),
		Vector2(850, 550)
	])
	nations.append(nordreich)

	# Kaiserreich Centralia
	var centralia = Nation.new()
	centralia.id = "centralia"
	centralia.name = "Kaiserreich Centralia"
	centralia.adjective = "centralisch"
	centralia.region_id = region.id
	centralia.color = Color(0.8, 0.6, 0.3)  # Gold
	centralia.government_type = "absolute_monarchy"
	centralia.leader_character_id = "leader_centralia"
	centralia.capital_province_id = "centralia_capital"
	centralia.legitimacy = 55.0
	centralia.gdp = 280000000000.0
	centralia.population = 38000000
	centralia.tech_level = 3
	centralia.unemployment = 8.5
	centralia.military_strength = 70.0
	# Polygon: Untere linke Ecke Mittelkontinent
	centralia.boundary_polygon = PackedVector2Array([
		Vector2(850, 600),
		Vector2(1400, 600),
		Vector2(1400, 1150),
		Vector2(850, 1150)
	])
	# Verschoben zu Südregion - Korrektur:
	centralia.region_id = "southern_steppes"
	nations.append(centralia)

	return nations

static func _create_south_nations(region: Region) -> Array[Nation]:
	"""Südliche Steppen: 2 autoritäre Regime."""
	var nations: Array[Nation] = []

	# Südkonföderation
	var sued = Nation.new()
	sued.id = "suedkonfoederation"
	sued.name = "Südkonföderation"
	sued.adjective = "südlich"
	sued.region_id = region.id
	sued.color = Color(0.7, 0.5, 0.2)  # Orangebraun
	sued.government_type = "military_junta"
	sued.leader_character_id = "leader_suedkonfoederation"
	sued.capital_province_id = "sued_capital"
	sued.legitimacy = 40.0
	sued.gdp = 180000000000.0
	sued.population = 25000000
	sued.tech_level = 3
	sued.unemployment = 12.0
	sued.military_strength = 85.0
	# Polygon: Rechte Hälfte Südregion
	sued.boundary_polygon = PackedVector2Array([
		Vector2(1450, 650),
		Vector2(1950, 650),
		Vector2(1950, 1150),
		Vector2(1450, 1150)
	])
	nations.append(sued)

	return nations

# === PROVINZEN ===

static func _generate_provinces_for_nation(nation: Nation) -> Array[Province]:
	"""Generiert 3-5 Provinzen pro Nation."""
	var provinces: Array[Province] = []
	var num_provinces = 4  # Jede Nation hat 4 Provinzen

	# Berechne Provinz-Polygone durch Unterteilung des Nationspolygons
	var nation_bounds = nation.boundary_polygon
	if nation_bounds.size() < 4:
		return provinces

	var bounds_min = Vector2(INF, INF)
	var bounds_max = Vector2(-INF, -INF)
	for point in nation_bounds:
		bounds_min.x = min(bounds_min.x, point.x)
		bounds_min.y = min(bounds_min.y, point.y)
		bounds_max.x = max(bounds_max.x, point.x)
		bounds_max.y = max(bounds_max.y, point.y)

	var width = bounds_max.x - bounds_min.x
	var height = bounds_max.y - bounds_min.y

	# 2x2 Grid für 4 Provinzen
	for i in range(2):
		for j in range(2):
			var province = Province.new()
			province.id = "%s_prov_%d%d" % [nation.id, i, j]
			province.name = _generate_province_name(nation, i * 2 + j)
			province.nation_id = nation.id
			province.color = nation.color.lightened(0.1 * (i + j))  # Leichte Variation

			# Provinz-Polygon
			var px = bounds_min.x + i * width / 2.0
			var py = bounds_min.y + j * height / 2.0
			var pw = width / 2.0
			var ph = height / 2.0

			province.boundary_polygon = PackedVector2Array([
				Vector2(px, py),
				Vector2(px + pw, py),
				Vector2(px + pw, py + ph),
				Vector2(px, py + ph)
			])

			province.position = Vector2(px + pw/2, py + ph/2)
			province.terrain_type = _random_terrain()
			province.population = nation.population / 4
			province.local_gdp = nation.gdp / 4.0

			provinces.append(province)

			# Erste Provinz ist Hauptstadt
			if i == 0 and j == 0:
				nation.capital_province_id = province.id

	return provinces

static func _generate_province_name(nation: Nation, index: int) -> String:
	"""Generiert Provinznamen."""
	var prefixes = ["Nord", "Süd", "Ost", "West", "Zentral", "Küsten", "Berg", "Flach"]
	var suffixes = ["land", "provinz", "gebiet", "mark", "reich", "tal", "küste"]
	return "%s%s" % [prefixes[index % prefixes.size()], suffixes[index / prefixes.size() % suffixes.size()]]

static func _random_terrain() -> String:
	var terrains = ["plains", "mountains", "forest", "coast", "desert", "hills"]
	return terrains[randi() % terrains.size()]

# === DISTRIKTE ===

static func _generate_districts_for_province(province: Province) -> Array[District]:
	"""Generiert 4-6 Distrikte pro Provinz."""
	var districts: Array[District] = []
	var num_districts = 4  # 4 Distrikte pro Provinz

	var bounds = province.boundary_polygon
	if bounds.size() < 4:
		return districts

	var bounds_min = Vector2(INF, INF)
	var bounds_max = Vector2(-INF, -INF)
	for point in bounds:
		bounds_min.x = min(bounds_min.x, point.x)
		bounds_min.y = min(bounds_min.y, point.y)
		bounds_max.x = max(bounds_max.x, point.x)
		bounds_max.y = max(bounds_max.y, point.y)

	var width = bounds_max.x - bounds_min.x
	var height = bounds_max.y - bounds_min.y

	# 2x2 Grid für 4 Distrikte
	for i in range(2):
		for j in range(2):
			var district = District.new()
			district.id = "%s_dist_%d%d" % [province.id, i, j]
			district.province_id = province.id
			district.is_urban = (i == 0 and j == 0)  # Erster Distrikt ist Großstadt
			district.name = _generate_district_name(province, district.is_urban, i * 2 + j)
			district.color = province.color

			var dx = bounds_min.x + i * width / 2.0
			var dy = bounds_min.y + j * height / 2.0
			var dw = width / 2.0
			var dh = height / 2.0

			district.boundary_polygon = PackedVector2Array([
				Vector2(dx, dy),
				Vector2(dx + dw, dy),
				Vector2(dx + dw, dy + dh),
				Vector2(dx, dy + dh)
			])

			district.position = Vector2(dx + dw/2, dy + dh/2)
			district.population = province.population / 4
			district.density = 500.0 if district.is_urban else 150.0

			districts.append(district)

	return districts

static func _generate_district_name(province: Province, is_urban: bool, index: int) -> String:
	"""Generiert Distrikt-Namen."""
	if is_urban:
		var city_names = ["Hauptstadt", "Metropole", "Großstadt", "Zentrum"]
		return "%s %s" % [province.name, city_names[index % city_names.size()]]
	else:
		var rural_names = ["Landkreis Nord", "Landkreis Süd", "Landkreis Ost", "Landkreis West"]
		return "%s %s" % [province.name, rural_names[index % rural_names.size()]]

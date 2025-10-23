class_name WorldGenerator
extends RefCounted

"""
Generiert eine Spielwelt mit Nationen, Provinzen und Charakteren.
Derzeit: Einfacher Test-Generator für grundlegende Simulation.
Später: Seed-basierte prozedurale Generierung.
"""

static func generate_test_world() -> World:
	"""
	Generiert eine vollständige Welt mit MapDataGenerator.
	- Regionen, Nationen, Provinzen, Distrikte
	- Charaktere für alle Nationen
	"""
	var world = World.new("TEST_SEED")

	print("WorldGenerator: Generiere Welt mit vollständiger Karte...")

	# Vollständige Karte generieren
	var map_data = MapDataGenerator.generate_full_map()

	# In World speichern (mit expliziter Typ-Konvertierung)
	var nations_typed: Array[Nation] = []
	nations_typed.assign(map_data.nations)
	world.nations = nations_typed

	var provinces_typed: Array[Province] = []
	provinces_typed.assign(map_data.provinces)
	world.provinces = provinces_typed

	# Charaktere generieren (mit Typ-Konvertierung für Argument)
	var characters = _generate_test_characters(nations_typed)

	# Typed arrays für alle Daten erstellen
	var regions_typed: Array[Region] = []
	regions_typed.assign(map_data.regions)

	var districts_typed: Array[District] = []
	districts_typed.assign(map_data.districts)

	# In GameState registrieren
	for region in regions_typed:
		GameState.regions[region.id] = region

	for nation in nations_typed:
		GameState.nations[nation.id] = nation

	for province in provinces_typed:
		GameState.provinces[province.id] = province

	for district in districts_typed:
		GameState.districts[district.id] = district

	for character in characters:
		GameState.characters[character.id] = character

	# Spieler-Nation festlegen (Thalassia)
	for nation in nations_typed:
		if nation.id == "thalassia":
			GameState.player_nation_id = nation.id
			GameState.player_character_id = nation.leader_character_id
			break

	print("WorldGenerator: Welt generiert - %d Regionen, %d Nationen, %d Provinzen, %d Distrikte, %d Charaktere" % [
		regions_typed.size(), nations_typed.size(), provinces_typed.size(),
		districts_typed.size(), characters.size()
	])

	return world

# === NATION GENERATION ===

static func _generate_test_nations() -> Array[Nation]:
	"""Generiert 3 Test-Nationen."""
	var nations: Array[Nation] = []

	# Nation 1: Thalassia (Spieler-Nation)
	var thalassia = Nation.new()
	thalassia.id = "thalassia"
	thalassia.name = "Thalassische Republik"
	thalassia.adjective = "thalassisch"
	thalassia.capital_province_id = "thalassia_capital"
	thalassia.government_type = "democracy"
	thalassia.leader_character_id = "leader_thalassia"
	thalassia.legitimacy = 65.0
	thalassia.gdp = 500000000000.0  # 500 Mrd
	thalassia.gdp_growth = 2.5
	thalassia.treasury = 50000000000.0  # 50 Mrd
	thalassia.debt = 200000000000.0  # 200 Mrd
	thalassia.inflation = 2.0
	thalassia.unemployment = 6.5
	thalassia.military_strength = 75.0
	thalassia.tech_level = 4  # Zeitgenössisch
	thalassia.population = 45000000
	nations.append(thalassia)

	# Nation 2: Nordreich
	var nordreich = Nation.new()
	nordreich.id = "nordreich"
	nordreich.name = "Nordreich"
	nordreich.adjective = "nordisch"
	nordreich.capital_province_id = "nordreich_capital"
	nordreich.government_type = "constitutional_monarchy"
	nordreich.leader_character_id = "leader_nordreich"
	nordreich.legitimacy = 80.0
	nordreich.gdp = 300000000000.0  # 300 Mrd
	nordreich.gdp_growth = 1.8
	nordreich.treasury = 40000000000.0
	nordreich.debt = 100000000000.0
	nordreich.inflation = 1.5
	nordreich.unemployment = 4.2
	nordreich.military_strength = 60.0
	nordreich.tech_level = 4
	nordreich.population = 28000000
	nordreich.relationships["thalassia"] = 45.0  # Neutral-freundlich
	nations.append(nordreich)

	# Nation 3: Südkonföderation
	var sued = Nation.new()
	sued.id = "suedkonfoederation"
	sued.name = "Südkonföderation"
	sued.adjective = "südisch"
	sued.capital_province_id = "sued_capital"
	sued.government_type = "federation"
	sued.leader_character_id = "leader_sued"
	sued.legitimacy = 55.0
	sued.gdp = 400000000000.0
	sued.gdp_growth = 3.2
	sued.treasury = 30000000000.0
	sued.debt = 250000000000.0
	sued.inflation = 3.5
	sued.unemployment = 8.0
	sued.military_strength = 85.0
	sued.tech_level = 4
	sued.population = 52000000
	sued.relationships["thalassia"] = -20.0  # Leicht angespannt
	sued.relationships["nordreich"] = 10.0
	nations.append(sued)

	# Gegenseitige Beziehungen
	thalassia.relationships["nordreich"] = 45.0
	thalassia.relationships["suedkonfoederation"] = -20.0
	nordreich.relationships["suedkonfoederation"] = 10.0

	return nations

# === PROVINCE GENERATION ===

static func _generate_test_provinces(nations: Array[Nation]) -> Array[Province]:
	"""Generiert 3 Provinzen pro Nation."""
	var provinces: Array[Province] = []

	# Thalassia Provinzen
	provinces.append(_create_province("thalassia_capital", "Hauptstadt Portus", "thalassia",
		"coastal", Vector2(100, 100), 12000000, 10000000))
	provinces.append(_create_province("thalassia_north", "Nordprovinz", "thalassia",
		"plains", Vector2(100, 50), 18000000, 8000000))
	provinces.append(_create_province("thalassia_south", "Südprovinz", "thalassia",
		"mountains", Vector2(100, 150), 15000000, 5000000))

	# Nordreich Provinzen
	provinces.append(_create_province("nordreich_capital", "Königsstadt", "nordreich",
		"coastal", Vector2(200, 50), 8000000, 7000000))
	provinces.append(_create_province("nordreich_west", "Westland", "nordreich",
		"forest", Vector2(150, 50), 12000000, 4000000))
	provinces.append(_create_province("nordreich_east", "Ostland", "nordreich",
		"plains", Vector2(250, 50), 8000000, 3000000))

	# Südkonföderation Provinzen
	provinces.append(_create_province("sued_capital", "Zentralia", "suedkonfoederation",
		"plains", Vector2(150, 200), 15000000, 12000000))
	provinces.append(_create_province("sued_west", "Westbund", "suedkonfoederation",
		"desert", Vector2(100, 200), 20000000, 8000000))
	provinces.append(_create_province("sued_east", "Ostbund", "suedkonfoederation",
		"coastal", Vector2(200, 200), 17000000, 10000000))

	return provinces

static func _create_province(
	id: String,
	name: String,
	nation_id: String,
	terrain: String,
	pos: Vector2,
	pop: int,
	urban_pop: int
) -> Province:
	"""Hilfsmethod zur Provinz-Erstellung."""
	var province = Province.new()
	province.id = id
	province.name = name
	province.nation_id = nation_id
	province.terrain_type = terrain
	province.position = pos
	province.population = pop
	province.urban_population = urban_pop
	province.infrastructure_level = randf_range(40.0, 80.0)
	province.has_port = terrain == "coastal"

	# Ressourcen basierend auf Terrain
	match terrain:
		"coastal":
			province.resources["fish"] = randf_range(50.0, 100.0)
			province.resources["oil"] = randf_range(0.0, 50.0)
		"mountains":
			province.resources["minerals"] = randf_range(70.0, 100.0)
			province.resources["rare_earth"] = randf_range(30.0, 60.0)
		"plains":
			province.resources["agriculture"] = randf_range(80.0, 100.0)
		"forest":
			province.resources["timber"] = randf_range(60.0, 90.0)
		"desert":
			province.resources["oil"] = randf_range(50.0, 100.0)

	return province

# === CHARACTER GENERATION ===

static func _generate_test_characters(nations: Array[Nation]) -> Array[Character]:
	"""Generiert Test-Charaktere (Leader für jede Nation)."""
	var characters: Array[Character] = []

	# Thalassia Leader
	var leader1 = Character.new()
	leader1.id = "leader_thalassia"
	leader1.full_name = "Alexandra Petrov"
	leader1.age = 52
	leader1.gender = "female"
	leader1.nation_id = "thalassia"
	leader1.current_position = "president"
	leader1.personality.openness = 75
	leader1.personality.conscientiousness = 80
	leader1.personality.extraversion = 65
	leader1.personality.agreeableness = 60
	leader1.personality.neuroticism = 35
	leader1.ideology.economic = 30  # Leicht kapitalistisch
	leader1.ideology.social = 45  # Leicht libertär
	leader1.ideology.foreign = 20  # Leicht interventionistisch
	leader1.skills.economy = 75
	leader1.skills.diplomacy = 70
	leader1.skills.military = 55
	leader1.skills.administration = 80
	characters.append(leader1)

	# Nordreich Leader
	var leader2 = Character.new()
	leader2.id = "leader_nordreich"
	leader2.full_name = "König Harald VII"
	leader2.age = 68
	leader2.gender = "male"
	leader2.nation_id = "nordreich"
	leader2.current_position = "monarch"
	leader2.personality.conscientiousness = 85
	leader2.personality.agreeableness = 75
	leader2.ideology.economic = -10  # Leicht sozialistisch
	leader2.ideology.social = -20  # Leicht autoritär
	leader2.ideology.foreign = -30  # Isolationistisch
	leader2.skills.diplomacy = 80
	leader2.skills.administration = 70
	characters.append(leader2)

	# Südkonföderation Leader
	var leader3 = Character.new()
	leader3.id = "leader_sued"
	leader3.full_name = "General Marcus Chen"
	leader3.age = 45
	leader3.gender = "male"
	leader3.nation_id = "suedkonfoederation"
	leader3.current_position = "president"
	leader3.personality.authoritarianism = 70
	leader3.personality.risk_tolerance = 75
	leader3.ideology.economic = 50  # Kapitalistisch
	leader3.ideology.social = -40  # Autoritär
	leader3.ideology.foreign = 60  # Interventionistisch
	leader3.skills.military = 90
	leader3.skills.economy = 50
	leader3.skills.diplomacy = 45
	characters.append(leader3)

	return characters

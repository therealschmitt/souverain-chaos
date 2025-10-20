class_name Region
extends Resource

## Repräsentiert eine geopolitische Großregion (Zoomstufe 2)
## Beispiel: "Mittelkontinent", "Östlicher Archipel", "Südliche Steppen"

var id: String = ""
var name: String = ""

# === GEOGRAPHIE ===
var nations: Array[String] = []  # Nation IDs in dieser Region
var color: Color = Color.WHITE  # Farbe für politische Karte
var center_position: Vector2 = Vector2.ZERO  # Zentrum der Region

# === VISUELLE DARSTELLUNG ===
var boundary_polygon: PackedVector2Array = PackedVector2Array()  # Außengrenzen der Region

# === WIRTSCHAFT (aggregiert) ===
var total_gdp: float = 0.0
var total_population: int = 0

# === POLITISCHES KLIMA ===
var dominant_ideology: Dictionary = {}  # Durchschnittliche Ideologie der Region
var stability: float = 100.0  # Regionale Stabilität (0-100)

func update_aggregated_stats() -> void:
	"""Aktualisiert aggregierte Statistiken basierend auf Nationen."""
	total_gdp = 0.0
	total_population = 0

	for nation_id in nations:
		var nation = GameState.nations.get(nation_id)
		if nation:
			total_gdp += nation.gdp
			total_population += nation.population

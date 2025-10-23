class_name District
extends Resource

## Repräsentiert einen Landkreis oder Stadtbezirk (Zoomstufe 5)
## Unterhalb von Provinzen

var id: String = ""
var name: String = ""
var province_id: String = ""

# === GEOGRAPHIE ===
var position: Vector2 = Vector2.ZERO
var boundary_polygon: PackedVector2Array = PackedVector2Array()
var area_km2: float = 0.0  # Fläche in Quadratkilometern
var is_urban: bool = false  # Großstadt vs. Landkreis

# === DEMOGRAPHIE ===
var population: int = 0
var density: float = 0.0  # Einwohner pro km²

# === WIRTSCHAFT ===
var local_economy: String = "agriculture"  # agriculture, industry, services, etc.
var employment_rate: float = 95.0

# === INFRASTRUKTUR ===
var infrastructure_quality: float = 50.0  # 0-100
var has_university: bool = false
var has_major_factory: bool = false
var has_military_base: bool = false

# === VISUELLE DARSTELLUNG ===
var color: Color = Color.WHITE  # Basierend auf Provinz/Nation

func get_type_string() -> String:
	"""Gibt den Typ als String zurück für UI."""
	return "Großstadt" if is_urban else "Landkreis"

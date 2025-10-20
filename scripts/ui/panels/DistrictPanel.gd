extends PanelContainer

## Info-Panel für Distrikte/Städte (Zoomstufe 5)

@onready var title_label := $MarginContainer/VBoxContainer/TitleLabel
@onready var type_label := $MarginContainer/VBoxContainer/TypeLabel
@onready var stats_label := $MarginContainer/VBoxContainer/StatsLabel
@onready var features_label := $MarginContainer/VBoxContainer/FeaturesLabel

var current_district_id: String = ""

func _ready() -> void:
	visible = false

func show_district(district_id: String) -> void:
	"""Zeigt Informationen über einen Distrikt/Stadt an."""
	current_district_id = district_id
	var district = GameState.get_district(district_id)

	if not district:
		hide()
		return

	# Titel
	title_label.text = district.name
	type_label.text = district.get_type_string()

	# Statistiken
	stats_label.text = """Bevölkerung: %s
Dichte: %.0f Einw./km²
Beschäftigungsrate: %.1f%%
Infrastruktur: %.0f%%
""" % [
		_format_number(district.population),
		district.density,
		district.employment_rate,
		district.infrastructure_quality
	]

	# Besonderheiten
	var features: Array[String] = []
	if district.has_university:
		features.append("• Universität")
	if district.has_major_factory:
		features.append("• Großfabrik")
	if district.has_military_base:
		features.append("• Militärbasis")

	if features.size() > 0:
		features_label.text = "Besonderheiten:\n" + "\n".join(features)
	else:
		features_label.text = "Keine besonderen Einrichtungen"

	visible = true

func _format_number(value: float) -> String:
	"""Formatiert Zahlen mit Tausender-Trennzeichen."""
	if value >= 1000000:
		return "%.1f Mio" % (value / 1000000.0)
	elif value >= 1000:
		return "%.1f Tsd" % (value / 1000.0)
	else:
		return str(int(value))

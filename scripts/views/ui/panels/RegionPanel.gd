extends PanelContainer

## Info-Panel für Regionen (Zoomstufe 2)

@onready var title_label := $MarginContainer/VBoxContainer/TitleLabel
@onready var stats_label := $MarginContainer/VBoxContainer/StatsLabel
@onready var nations_list := $MarginContainer/VBoxContainer/NationsList

var current_region_id: String = ""

func _ready() -> void:
	visible = false

func show_region(region_id: String) -> void:
	"""Zeigt Informationen über eine Region an."""
	current_region_id = region_id
	var region = GameState.get_region(region_id)

	if not region:
		hide()
		return

	# Titel
	title_label.text = region.name

	# Statistiken
	region.update_aggregated_stats()
	stats_label.text = """Bevölkerung: %s
BIP: $%s Mrd
Stabilität: %.1f%%
""" % [
		_format_number(region.total_population),
		_format_number(region.total_gdp / 1000000000.0),
		region.stability
	]

	# Nationen-Liste
	_update_nations_list(region)

	visible = true

func _update_nations_list(region: Region) -> void:
	"""Aktualisiert die Liste der Nationen in dieser Region."""
	# Clear existing children
	for child in nations_list.get_children():
		child.queue_free()

	for nation_id in region.nations:
		var nation = GameState.nations.get(nation_id)
		if nation:
			var label = Label.new()
			label.text = "• %s (%s)" % [nation.name, _get_government_type_name(nation.government_type)]
			nations_list.add_child(label)

func _get_government_type_name(type: String) -> String:
	"""Übersetzt Regierungstypen ins Deutsche."""
	match type:
		"democracy":
			return "Demokratie"
		"dictatorship":
			return "Diktatur"
		"constitutional_monarchy":
			return "Konstitutionelle Monarchie"
		"absolute_monarchy":
			return "Absolute Monarchie"
		"military_junta":
			return "Militärjunta"
		"federal_republic":
			return "Bundesrepublik"
		_:
			return type

func _format_number(value: float) -> String:
	"""Formatiert Zahlen mit Tausender-Trennzeichen."""
	if value >= 1000000:
		return "%.1f Mio" % (value / 1000000.0)
	elif value >= 1000:
		return "%.1f Tsd" % (value / 1000.0)
	else:
		return str(int(value))

class_name NationPanel
extends BasePanel

# Panel displaying national statistics and overview

@onready var nation_name_label: Label
@onready var government_type_label: Label
@onready var leader_name_label: Label
@onready var gdp_label: Label
@onready var population_label: Label
@onready var legitimacy_bar: ProgressBar
@onready var treasury_label: Label
@onready var debt_label: Label
@onready var unemployment_label: Label

var displayed_nation_id: String = ""

func _init_panel() -> void:
	panel_title = "Nationale Übersicht"
	update_interval = 1.0  # Update every second
	_setup_ui()

func _setup_ui() -> void:
	# This would be set up in the scene, but we can create it programmatically too
	# For now, just reference nodes that should exist in the scene
	pass

func _update_panel_data() -> void:
	var nation_id = displayed_nation_id
	if nation_id.is_empty():
		nation_id = GameState.player_nation_id

	var nation = GameState.nations.get(nation_id)
	if not nation:
		return

	_display_nation_info(nation)

func _display_nation_info(nation: Nation) -> void:
	if nation_name_label:
		nation_name_label.text = nation.name

	if government_type_label:
		government_type_label.text = "Regierungsform: %s" % nation.government_type

	if leader_name_label:
		var leader = GameState.get_character(nation.leader_character_id)
		leader_name_label.text = "Anführer: %s" % (leader.full_name if leader else "Vakant")

	if gdp_label:
		gdp_label.text = "BIP: %.2f Mrd. | Wachstum: %.1f%%" % [nation.gdp / 1e9, nation.gdp_growth]

	if population_label:
		population_label.text = "Bevölkerung: %s" % _format_number(nation.population)

	if legitimacy_bar:
		legitimacy_bar.value = nation.legitimacy

	if treasury_label:
		treasury_label.text = "Staatshaushalt: %.2f Mrd." % (nation.treasury / 1e9)

	if debt_label:
		debt_label.text = "Schulden: %.2f Mrd." % (nation.debt / 1e9)

	if unemployment_label:
		unemployment_label.text = "Arbeitslosigkeit: %.1f%%" % nation.unemployment

func set_displayed_nation(nation_id: String) -> void:
	displayed_nation_id = nation_id
	_update_panel_data()

func _format_number(num: int) -> String:
	if num >= 1_000_000_000:
		return "%.2f Mrd." % (num / 1_000_000_000.0)
	elif num >= 1_000_000:
		return "%.2f Mio." % (num / 1_000_000.0)
	elif num >= 1_000:
		return "%.2f Tsd." % (num / 1_000.0)
	else:
		return str(num)

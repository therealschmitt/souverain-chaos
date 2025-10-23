class_name ProvincePanel
extends BasePanel

# Panel displaying detailed province information

@onready var province_name_label: Label
@onready var nation_label: Label
@onready var terrain_label: Label
@onready var population_label: Label
@onready var urban_population_label: Label
@onready var gdp_label: Label
@onready var infrastructure_bar: ProgressBar
@onready var unrest_bar: ProgressBar
@onready var resources_container: VBoxContainer
@onready var industries_container: VBoxContainer

var displayed_province_id: String = ""

func _init_panel() -> void:
	panel_title = "Provinzdetails"
	update_interval = 0.5

func _ready() -> void:
	super._ready()
	EventBus.province_selected.connect(_on_province_selected)

func _on_province_selected(province_id: String) -> void:
	set_displayed_province(province_id)
	open_panel()

func _update_panel_data() -> void:
	if displayed_province_id.is_empty():
		return

	var province = GameState.get_province(displayed_province_id)
	if not province:
		return

	_display_province_info(province)

func _display_province_info(province: Province) -> void:
	if province_name_label:
		province_name_label.text = province.name

	if nation_label:
		var nation = GameState.nations.get(province.nation_id)
		nation_label.text = "Nation: %s" % (nation.name if nation else "Unbekannt")

	if terrain_label:
		terrain_label.text = "Terrain: %s" % province.terrain_type

	if population_label:
		population_label.text = "Bevölkerung: %s" % _format_number(province.population)

	if urban_population_label:
		var urban_pct = (float(province.urban_population) / province.population * 100.0) if province.population > 0 else 0.0
		urban_population_label.text = "Urbanisierung: %.1f%%" % urban_pct

	if gdp_label:
		gdp_label.text = "Lokales BIP: %.2f Mrd." % (province.local_gdp / 1e9)

	if infrastructure_bar:
		infrastructure_bar.value = province.infrastructure_level

	if unrest_bar:
		unrest_bar.value = min(province.unrest_level * 10.0, 100.0)

	_update_resources_display(province)
	_update_industries_display(province)

func _update_resources_display(province: Province) -> void:
	if not resources_container:
		return

	# Clear existing children
	for child in resources_container.get_children():
		child.queue_free()

	# Add resource labels
	for resource_type in province.resources.keys():
		var amount = province.resources[resource_type]
		var label = Label.new()
		label.text = "%s: %.1f" % [resource_type.capitalize(), amount]
		resources_container.add_child(label)

func _update_industries_display(province: Province) -> void:
	if not industries_container:
		return

	# Clear existing children
	for child in industries_container.get_children():
		child.queue_free()

	# Add industry labels
	for industry in province.industries:
		var label = Label.new()
		label.text = "• %s" % industry
		industries_container.add_child(label)

func set_displayed_province(province_id: String) -> void:
	displayed_province_id = province_id
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

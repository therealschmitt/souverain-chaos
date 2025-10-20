class_name CharacterPanel
extends BasePanel

# Panel displaying detailed character information

@onready var portrait_rect: TextureRect
@onready var name_label: Label
@onready var age_label: Label
@onready var position_label: Label
@onready var nation_label: Label

# Personality traits
@onready var personality_container: VBoxContainer

# Skills
@onready var economy_skill_bar: ProgressBar
@onready var military_skill_bar: ProgressBar
@onready var diplomacy_skill_bar: ProgressBar
@onready var intrigue_skill_bar: ProgressBar
@onready var oratory_skill_bar: ProgressBar
@onready var administration_skill_bar: ProgressBar

# Ideology
@onready var economic_ideology_label: Label
@onready var social_ideology_label: Label
@onready var foreign_ideology_label: Label

# Stats
@onready var health_bar: ProgressBar
@onready var wealth_label: Label
@onready var influence_bar: ProgressBar
@onready var loyalty_bar: ProgressBar

# Biography
@onready var biography_text: RichTextLabel

var displayed_character_id: String = ""

func _init_panel() -> void:
	panel_title = "Charakterdetails"
	update_interval = 1.0

func _ready() -> void:
	super._ready()
	EventBus.character_created.connect(_on_character_created)
	EventBus.character_died.connect(_on_character_died)

func _on_character_created(character: Dictionary) -> void:
	if character.get("id") == displayed_character_id:
		_update_panel_data()

func _on_character_died(character_id: String) -> void:
	if character_id == displayed_character_id:
		_update_panel_data()

func _update_panel_data() -> void:
	if displayed_character_id.is_empty():
		return

	var character = GameState.get_character(displayed_character_id)
	if not character:
		return

	_display_character_info(character)

func _display_character_info(character: Character) -> void:
	if name_label:
		name_label.text = character.full_name

	if age_label:
		age_label.text = "Alter: %d" % character.age

	if position_label:
		position_label.text = "Position: %s" % character.current_position

	if nation_label:
		var nation = GameState.nations.get(character.nation_id)
		nation_label.text = "Nation: %s" % (nation.name if nation else "Keine")

	_update_personality_display(character)
	_update_skills_display(character)
	_update_ideology_display(character)
	_update_stats_display(character)
	_update_biography_display(character)

func _update_personality_display(character: Character) -> void:
	if not personality_container:
		return

	# Clear existing
	for child in personality_container.get_children():
		child.queue_free()

	# Display personality traits
	var traits := [
		["Offenheit", character.personality.get("openness", 50)],
		["Gewissenhaftigkeit", character.personality.get("conscientiousness", 50)],
		["Extraversion", character.personality.get("extraversion", 50)],
		["Verträglichkeit", character.personality.get("agreeableness", 50)],
		["Neurotizismus", character.personality.get("neuroticism", 50)],
		["Machiavellismus", character.personality.get("machiavellianism", 30)],
		["Autoritarismus", character.personality.get("authoritarianism", 40)],
		["Risikobereitschaft", character.personality.get("risk_tolerance", 50)]
	]

	for trait in traits:
		var hbox = HBoxContainer.new()
		var label = Label.new()
		label.text = trait[0]
		label.custom_minimum_size.x = 150
		hbox.add_child(label)

		var bar = ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = trait[1]
		bar.custom_minimum_size.x = 100
		hbox.add_child(bar)

		personality_container.add_child(hbox)

func _update_skills_display(character: Character) -> void:
	if economy_skill_bar:
		economy_skill_bar.value = character.skills.get("economy", 50)
	if military_skill_bar:
		military_skill_bar.value = character.skills.get("military", 50)
	if diplomacy_skill_bar:
		diplomacy_skill_bar.value = character.skills.get("diplomacy", 50)
	if intrigue_skill_bar:
		intrigue_skill_bar.value = character.skills.get("intrigue", 50)
	if oratory_skill_bar:
		oratory_skill_bar.value = character.skills.get("oratory", 50)
	if administration_skill_bar:
		administration_skill_bar.value = character.skills.get("administration", 50)

func _update_ideology_display(character: Character) -> void:
	if economic_ideology_label:
		var econ = character.ideology.get("economic", 0)
		var econ_text = _get_economic_ideology_text(econ)
		economic_ideology_label.text = "Wirtschaft: %s (%d)" % [econ_text, econ]

	if social_ideology_label:
		var social = character.ideology.get("social", 0)
		var social_text = _get_social_ideology_text(social)
		social_ideology_label.text = "Sozial: %s (%d)" % [social_text, social]

	if foreign_ideology_label:
		var foreign = character.ideology.get("foreign", 0)
		var foreign_text = _get_foreign_ideology_text(foreign)
		foreign_ideology_label.text = "Außenpolitik: %s (%d)" % [foreign_text, foreign]

func _get_economic_ideology_text(value: int) -> String:
	if value < -60: return "Kommunistisch"
	elif value < -20: return "Sozialistisch"
	elif value < 20: return "Gemischt"
	elif value < 60: return "Kapitalistisch"
	else: return "Laissez-faire"

func _get_social_ideology_text(value: int) -> String:
	if value < -60: return "Autoritär"
	elif value < -20: return "Konservativ"
	elif value < 20: return "Moderat"
	elif value < 60: return "Liberal"
	else: return "Libertär"

func _get_foreign_ideology_text(value: int) -> String:
	if value < -60: return "Isolationistisch"
	elif value < -20: return "Defensiv"
	elif value < 20: return "Neutral"
	elif value < 60: return "Aktiv"
	else: return "Interventionistisch"

func _update_stats_display(character: Character) -> void:
	if health_bar:
		health_bar.value = character.health

	if wealth_label:
		wealth_label.text = "Vermögen: %.2f Mio." % (character.wealth / 1e6)

	if influence_bar:
		influence_bar.value = character.influence

	if loyalty_bar:
		loyalty_bar.value = character.loyalty_to_player

func _update_biography_display(character: Character) -> void:
	if not biography_text:
		return

	var bio_html = "[b]Biografie:[/b]\n\n"
	bio_html += "Geboren: %d in %s\n\n" % [character.birth_year, character.birthplace]

	if character.biography.size() > 0:
		bio_html += "[b]Lebensereignisse:[/b]\n"
		for event in character.biography:
			var year = event.get("year", "?")
			var event_type = event.get("event", "")
			var description = event.get("description", "")
			bio_html += "• %s - %s: %s\n" % [year, event_type, description]

	biography_text.text = bio_html

func set_displayed_character(character_id: String) -> void:
	displayed_character_id = character_id
	_update_panel_data()

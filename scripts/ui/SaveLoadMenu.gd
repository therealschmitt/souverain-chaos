extends Panel

"""
SaveLoadMenu - UI für Speichern/Laden von Spielständen.

Features:
- Liste verfügbarer Speicherstände
- Speichern mit benutzerdefiniertem Namen
- Laden von Spielständen
- Löschen von Spielständen
- Auto-Save-Anzeige
"""

enum Mode {
	SAVE,
	LOAD
}

@onready var title_label := $MarginContainer/VBox/TitleLabel
@onready var save_list := $MarginContainer/VBox/SaveList
@onready var save_name_input := $MarginContainer/VBox/SaveNameContainer/SaveNameInput
@onready var save_button := $MarginContainer/VBox/ButtonContainer/SaveButton
@onready var load_button := $MarginContainer/VBox/ButtonContainer/LoadButton
@onready var delete_button := $MarginContainer/VBox/ButtonContainer/DeleteButton
@onready var close_button := $MarginContainer/VBox/ButtonContainer/CloseButton

var current_mode: Mode = Mode.SAVE
var selected_save: String = ""

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	save_list.item_selected.connect(_on_save_selected)

	hide()

func open_save_menu() -> void:
	"""Öffnet das Menü im Speichern-Modus."""
	current_mode = Mode.SAVE
	title_label.text = "Spielstand speichern"
	save_button.visible = true
	load_button.visible = false
	save_name_input.visible = true
	save_name_input.text = _generate_default_save_name()
	_refresh_save_list()
	show()
	save_name_input.grab_focus()

func open_load_menu() -> void:
	"""Öffnet das Menü im Laden-Modus."""
	current_mode = Mode.LOAD
	title_label.text = "Spielstand laden"
	save_button.visible = false
	load_button.visible = true
	save_name_input.visible = false
	_refresh_save_list()
	show()
	save_list.grab_focus()

func _refresh_save_list() -> void:
	"""Aktualisiert die Liste der Speicherstände."""
	save_list.clear()

	var saves = SaveManager.get_save_list()

	for save_info in saves:
		var display_text = _format_save_entry(save_info)
		save_list.add_item(display_text)
		save_list.set_item_metadata(save_list.item_count - 1, save_info.name)

func _format_save_entry(save_info: Dictionary) -> String:
	"""Formatiert einen Eintrag für die Liste."""
	var date_str = ""
	if save_info.date.has("day"):
		date_str = "%d.%d.%d" % [
			save_info.date.day,
			save_info.date.month,
			save_info.date.year
		]

	var nation_str = save_info.nation_name if save_info.nation_name != "" else "???"
	var timestamp_str = save_info.timestamp.substr(0, 16)  # Nur Datum/Uhrzeit ohne Sekunden

	return "%s | %s | %s | %s" % [
		save_info.name,
		nation_str,
		date_str,
		timestamp_str
	]

func _generate_default_save_name() -> String:
	"""Generiert einen Standard-Speichernamen."""
	var date = GameState.current_date
	var nation = GameState.get_player_nation()
	var nation_name = nation.name if nation else "Spielstand"

	return "%s_%d-%02d-%02d" % [
		nation_name.replace(" ", "_"),
		date.year,
		date.month,
		date.day
	]

func _on_save_selected(index: int) -> void:
	"""Wird aufgerufen wenn ein Speicherstand ausgewählt wird."""
	selected_save = save_list.get_item_metadata(index)

	if current_mode == Mode.SAVE:
		save_name_input.text = selected_save

	delete_button.disabled = false

func _on_save_pressed() -> void:
	"""Speichern-Button gedrückt."""
	var save_name = save_name_input.text.strip_edges()

	if save_name.is_empty():
		_show_error("Bitte geben Sie einen Speichernamen ein!")
		return

	# Prüfe ob Speicherstand bereits existiert
	var save_info = SaveManager.get_save_info(save_name)
	if save_info.exists:
		# TODO: Bestätigungsdialog
		print("[SaveLoadMenu] Überschreibe bestehenden Speicherstand: ", save_name)

	if SaveManager.save_game(save_name):
		print("[SaveLoadMenu] Spielstand gespeichert: ", save_name)
		_refresh_save_list()
		_show_notification("Spielstand gespeichert!")
	else:
		_show_error("Fehler beim Speichern!")

func _on_load_pressed() -> void:
	"""Laden-Button gedrückt."""
	if selected_save.is_empty():
		_show_error("Bitte wählen Sie einen Spielstand aus!")
		return

	if SaveManager.load_game(selected_save):
		print("[SaveLoadMenu] Spielstand geladen: ", selected_save)
		hide()
		_show_notification("Spielstand geladen!")
	else:
		_show_error("Fehler beim Laden!")

func _on_delete_pressed() -> void:
	"""Löschen-Button gedrückt."""
	if selected_save.is_empty():
		return

	# TODO: Bestätigungsdialog
	if SaveManager.delete_save(selected_save):
		print("[SaveLoadMenu] Spielstand gelöscht: ", selected_save)
		selected_save = ""
		delete_button.disabled = true
		_refresh_save_list()
		_show_notification("Spielstand gelöscht!")
	else:
		_show_error("Fehler beim Löschen!")

func _on_close_pressed() -> void:
	"""Schließen-Button gedrückt."""
	hide()

func _show_notification(message: String) -> void:
	"""Zeigt eine Benachrichtigung an."""
	print("[Notification] ", message)
	# TODO: Proper notification system

func _show_error(message: String) -> void:
	"""Zeigt eine Fehlermeldung an."""
	push_error("[SaveLoadMenu] ", message)
	# TODO: Error dialog

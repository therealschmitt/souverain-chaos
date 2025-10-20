extends Panel

"""
MainMenu - Hauptmenü-Overlay das das Spiel pausiert.

Features:
- Pausiert das Spiel automatisch beim Öffnen
- Zugriff auf Speichern/Laden-Menü
- Platzhalter für zukünftige Optionen
- Schließen via ESC oder "Fortsetzen"-Button
"""

@onready var continue_button := $MarginContainer/VBox/ContinueButton
@onready var save_button := $MarginContainer/VBox/SaveButton
@onready var load_button := $MarginContainer/VBox/LoadButton
@onready var settings_button := $MarginContainer/VBox/SettingsButton
@onready var main_menu_button := $MarginContainer/VBox/MainMenuButton
@onready var quit_button := $MarginContainer/VBox/QuitButton

signal menu_opened()
signal menu_closed()

var was_paused_before: bool = false

func _ready() -> void:
	_connect_buttons()
	hide()

func _connect_buttons() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func open_menu() -> void:
	"""Öffnet das Hauptmenü und pausiert das Spiel."""
	was_paused_before = GameState.is_paused

	if not was_paused_before:
		TimeManager.pause_time()

	show()
	continue_button.grab_focus()
	menu_opened.emit()
	EventBus.ui_panel_opened.emit("main_menu")

func close_menu() -> void:
	"""Schließt das Hauptmenü und setzt Pause-Status zurück."""
	hide()

	if not was_paused_before:
		TimeManager.start_time()

	menu_closed.emit()
	EventBus.ui_panel_closed.emit("main_menu")

func _on_continue_pressed() -> void:
	"""Fortsetzen-Button: Schließt das Menü."""
	close_menu()

func _on_save_pressed() -> void:
	"""Speichern-Button: Öffnet das Speichermenü."""
	# Referenz zum SaveLoadMenu über den Parent (MainUI)
	var main_ui = get_parent().get_parent()  # UILayer -> MainUI
	if main_ui.has_node("UILayer/SaveLoadMenu"):
		var save_menu = main_ui.get_node("UILayer/SaveLoadMenu")
		save_menu.open_save_menu()
		close_menu()  # Schließe Hauptmenü wenn SaveMenu geöffnet wird

func _on_load_pressed() -> void:
	"""Laden-Button: Öffnet das Lademenü."""
	var main_ui = get_parent().get_parent()  # UILayer -> MainUI
	if main_ui.has_node("UILayer/SaveLoadMenu"):
		var save_menu = main_ui.get_node("UILayer/SaveLoadMenu")
		save_menu.open_load_menu()
		close_menu()  # Schließe Hauptmenü wenn LoadMenu geöffnet wird

func _on_settings_pressed() -> void:
	"""Einstellungen-Button: Platzhalter für zukünftige Einstellungen."""
	print("[MainMenu] Einstellungen noch nicht implementiert")
	# TODO: Einstellungsmenü öffnen

func _on_main_menu_pressed() -> void:
	"""Hauptmenü-Button: Zurück zum Hauptmenü (mit Bestätigung)."""
	print("[MainMenu] Zurück zum Hauptmenü noch nicht implementiert")
	# TODO: Bestätigungsdialog, dann zur Hauptmenü-Szene wechseln

func _on_quit_pressed() -> void:
	"""Beenden-Button: Spiel beenden (mit Bestätigung)."""
	print("[MainMenu] Spiel beenden noch nicht implementiert")
	# TODO: Bestätigungsdialog, dann get_tree().quit()

func _input(event: InputEvent) -> void:
	# ESC schließt das Menü wenn es offen ist
	if visible and event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			close_menu()
			get_viewport().set_input_as_handled()  # Verhindere dass ESC weiter propagiert wird

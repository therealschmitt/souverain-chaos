extends Node

# EventBus: Signals werden von anderen Klassen genutzt, nicht hier selbst
# Daher die @warning_ignore Annotationen
# @warning_ignore("unused_signal")

# === GAME FLOW SIGNALS ===
signal game_started()
signal game_paused()
signal game_resumed()
signal day_passed(day: int)
signal month_passed(month: int, year: int)
signal year_passed(year: int)

# === TIME SYSTEM SIGNALS ===
signal time_started()
signal time_paused()
signal event_triggered(event_data: Dictionary, priority: int)
signal events_batch_triggered(events: Array)
signal choice_event_triggered(event_data: Dictionary)  # Multi-option events from EventManager

# === WORLD EVENTS ===
signal nation_created(nation_id: String)
signal nation_destroyed(nation_id: String)
signal war_declared(aggressor: String, defender: String)
signal war_ended(participants: Array, victor: String)

# === PLAYER ACTIONS ===
signal action_executed(action_type: String, parameters: Dictionary)
signal decision_made(event_id: String, choice_id: String)

# === UI EVENTS ===
signal ui_panel_opened(panel_name: String)
signal ui_panel_closed(panel_name: String)
signal map_zoom_changed(zoom_level: int)
signal province_selected(province_id: String)

# === CHARACTER EVENTS ===
signal character_created(character: Dictionary)
signal character_died(character_id: String, cause: String)
signal character_relationship_changed(char_a: String, char_b: String, value: int)

# === ECONOMY EVENTS ===
signal economic_crisis(nation_id: String, severity: float)
signal trade_route_established(from: String, to: String)
signal corporation_bankrupt(corp_id: String)

# === HISTORICAL EVENTS ===
signal historical_event_added(event: Dictionary)

# === SAVE/LOAD EVENTS ===
signal game_saved(save_name: String)
signal game_loaded(save_name: String)
signal game_state_changed()

# Hilfsfunktionen
func emit_deferred_signal(signal_name: String, args: Array = []):
	call_deferred("emit_signal", signal_name, args)

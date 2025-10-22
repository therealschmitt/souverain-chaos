class_name ZoomLevelManager
extends Node

## Verwaltet Level-of-Detail (LOD) basierend auf Zoom-Level
## Definiert Schwellenwerte für Ein-/Ausblenden von Layern und Labels
## Implementiert sanftes Fading zwischen Zoom-Stufen

# === LOD-KONFIGURATION ===
# Zoom-Schwellenwerte für Layer-Sichtbarkeit
class ZoomThreshold:
	var show_start: float   # Zoom-Level ab dem Layer eingeblendet wird
	var show_full: float    # Zoom-Level ab dem Layer voll sichtbar ist
	var hide_start: float   # Zoom-Level ab dem Layer ausgeblendet wird
	var hide_full: float    # Zoom-Level ab dem Layer komplett unsichtbar ist

	func _init(p_show_start: float, p_show_full: float, p_hide_start: float, p_hide_full: float):
		show_start = p_show_start
		show_full = p_show_full
		hide_start = p_hide_start
		hide_full = p_hide_full

	func get_opacity(zoom: float) -> float:
		"""
		Berechnet Opacity basierend auf aktuellem Zoom.
		@param zoom: Aktueller Zoom-Level
		@return: Opacity zwischen 0.0 und 1.0
		"""
		# Zu weit herausgezoomt (unter show_start)
		if zoom < show_start:
			return 0.0

		# Fade-in Phase (von show_start zu show_full)
		elif zoom < show_full:
			return inverse_lerp(show_start, show_full, zoom)

		# Voll sichtbar (zwischen show_full und hide_start)
		elif zoom < hide_start:
			return 1.0

		# Fade-out Phase (von hide_start zu hide_full)
		elif zoom < hide_full:
			return 1.0 - inverse_lerp(hide_start, hide_full, zoom)

		# Zu weit hineingezoomt (über hide_full)
		else:
			return 0.0

# === ZOOM-LEVEL-DEFINITIONEN ===
enum ZoomLevel {
	MACRO,      # 0.25 - 0.6: Nur Nationen
	OVERVIEW,   # 0.6 - 1.2: Nationen + Provinzen (fade-in)
	NORMAL,     # 1.2 - 2.5: Nationen + Provinzen
	DETAILED,   # 2.5 - 3.5: Provinzen + Distrikte (fade-in)
	MICRO       # 3.5 - 4.0: Alle Details
}

# === THRESHOLD-DEFINITIONEN ===
var thresholds: Dictionary = {}

# === STATE ===
var current_zoom_level: ZoomLevel = ZoomLevel.NORMAL
var previous_zoom_level: ZoomLevel = ZoomLevel.NORMAL

# === LAYER-REFERENZEN ===
var nation_layer: Node2D
var province_layer: Node2D
var district_layer: Node2D

# === FADING ===
const FADE_SPEED: float = 5.0  # Geschwindigkeit des Fadings
var layer_opacities: Dictionary = {
	"nation": 1.0,
	"province": 1.0,
	"district": 0.0
}

var target_opacities: Dictionary = {
	"nation": 1.0,
	"province": 1.0,
	"district": 0.0
}

func _ready() -> void:
	_setup_thresholds()
	set_process(true)

func _setup_thresholds() -> void:
	"""Definiert Zoom-Schwellenwerte für alle Layer."""

	# NATION Layer: Immer sichtbar ab Zoom 0.25, nie ausblenden (höchste Hierarchie)
	# Bei maximalem Zoom-out (0.25) MUSS Nation sichtbar sein
	# show_start, show_full, hide_start, hide_full
	thresholds["nation"] = ZoomThreshold.new(0.25, 0.35, 999.0, 999.0)

	# PROVINCE Layer: Ab Zoom 0.6 fade-in, ab 0.8 voll sichtbar, nie ausblenden
	thresholds["province"] = ZoomThreshold.new(0.6, 0.8, 999.0, 999.0)

	# DISTRICT Layer: Ab Zoom 2.0 fade-in, ab 2.5 voll sichtbar, nie ausblenden
	thresholds["district"] = ZoomThreshold.new(2.0, 2.5, 999.0, 999.0)

	print("ZoomLevelManager: Thresholds initialisiert (3-Layer-Hierarchie)")
	print("  Nation: %.2f-%.2f (fade-in), immer sichtbar danach (max zoom-out: %.2f)" % [0.25, 0.35, 0.25])
	print("  Province: %.2f-%.2f (fade-in), immer sichtbar danach" % [0.6, 0.8])
	print("  District: %.2f-%.2f (fade-in), immer sichtbar danach" % [2.0, 2.5])

func initialize(p_nation_layer: Node2D, p_province_layer: Node2D, p_district_layer: Node2D) -> void:
	"""
	Initialisiert Manager mit Layer-Referenzen.
	@param p_nation_layer: Nation-Layer
	@param p_province_layer: Province-Layer
	@param p_district_layer: District-Layer
	"""
	nation_layer = p_nation_layer
	province_layer = p_province_layer
	district_layer = p_district_layer

	# Setze initiale Opacity (Zoom 1.0 = NORMAL)
	_update_target_opacities(1.0)

	# Wende Opacities SOFORT an (ohne Fading-Verzögerung)
	for layer_name in layer_opacities.keys():
		layer_opacities[layer_name] = target_opacities[layer_name]
		_apply_layer_opacity(layer_name, layer_opacities[layer_name])

	print("ZoomLevelManager: Initialisiert mit 3 Layern (Nation, Province, District)")
	print("  Initial Opacities: Nation=%.2f, Province=%.2f, District=%.2f" % [
		layer_opacities["nation"],
		layer_opacities["province"],
		layer_opacities["district"]
	])

func _process(delta: float) -> void:
	"""Verarbeitet sanftes Fading."""
	_update_layer_fading(delta)

func update_zoom(zoom: float) -> void:
	"""
	Aktualisiert LOD basierend auf Zoom-Level.
	@param zoom: Aktueller Zoom-Wert
	"""
	# Bestimme neues Zoom-Level
	var new_zoom_level = _determine_zoom_level(zoom)

	# Prüfe ob Zoom-Level gewechselt hat
	if new_zoom_level != current_zoom_level:
		previous_zoom_level = current_zoom_level
		current_zoom_level = new_zoom_level
		EventBus.map_zoom_level_changed.emit(current_zoom_level, previous_zoom_level)
		print("ZoomLevelManager: Zoom-Level gewechselt: %s → %s" % [
			ZoomLevel.keys()[previous_zoom_level],
			ZoomLevel.keys()[current_zoom_level]
		])

	# Update Target-Opacities basierend auf Zoom
	_update_target_opacities(zoom)

func _determine_zoom_level(zoom: float) -> ZoomLevel:
	"""
	Bestimmt Zoom-Level basierend auf Zoom-Wert.
	@param zoom: Zoom-Wert
	@return: ZoomLevel
	"""
	if zoom < 0.6:
		return ZoomLevel.MACRO
	elif zoom < 1.2:
		return ZoomLevel.OVERVIEW
	elif zoom < 2.5:
		return ZoomLevel.NORMAL
	elif zoom < 3.5:
		return ZoomLevel.DETAILED
	else:
		return ZoomLevel.MICRO

func _update_target_opacities(zoom: float) -> void:
	"""
	Aktualisiert Ziel-Opacities basierend auf Zoom.
	@param zoom: Aktueller Zoom-Wert
	"""
	target_opacities["nation"] = thresholds["nation"].get_opacity(zoom)
	target_opacities["province"] = thresholds["province"].get_opacity(zoom)
	target_opacities["district"] = thresholds["district"].get_opacity(zoom)

func _update_layer_fading(delta: float) -> void:
	"""
	Aktualisiert Layer-Fading.
	@param delta: Delta-Zeit
	"""
	for layer_name in layer_opacities.keys():
		var current = layer_opacities[layer_name]
		var target = target_opacities[layer_name]

		if abs(current - target) > 0.01:
			# Interpoliere Opacity
			layer_opacities[layer_name] = lerp(current, target, delta * FADE_SPEED)

			# Wende Opacity auf Layer an
			_apply_layer_opacity(layer_name, layer_opacities[layer_name])
		else:
			layer_opacities[layer_name] = target

func _apply_layer_opacity(layer_name: String, opacity: float) -> void:
	"""
	Wendet Opacity auf einen Layer an.
	@param layer_name: Name des Layers ("nation", "province", "district")
	@param opacity: Opacity-Wert (0.0 - 1.0)
	"""
	var layer: Node2D = null

	match layer_name:
		"nation": layer = nation_layer
		"province": layer = province_layer
		"district": layer = district_layer

	if not layer:
		return

	# Setze Sichtbarkeit basierend auf Opacity
	if opacity <= 0.01:
		if layer.visible:
			layer.visible = false
	else:
		if not layer.visible:
			layer.visible = true

		# Setze Modulate für Fading
		layer.modulate.a = opacity

func get_layer_visibility(layer_name: String) -> bool:
	"""
	Gibt zurück ob ein Layer sichtbar sein sollte.
	@param layer_name: Name des Layers
	@return: true wenn sichtbar
	"""
	return target_opacities.get(layer_name, 0.0) > 0.0

func get_layer_opacity(layer_name: String) -> float:
	"""
	Gibt aktuelle Opacity eines Layers zurück.
	@param layer_name: Name des Layers
	@return: Opacity (0.0 - 1.0)
	"""
	return layer_opacities.get(layer_name, 0.0)

func get_current_zoom_level() -> ZoomLevel:
	"""Gibt aktuelles Zoom-Level zurück."""
	return current_zoom_level

func get_visible_layers() -> Array[String]:
	"""
	Gibt Liste der aktuell sichtbaren Layer zurück.
	@return: Array von Layer-Namen
	"""
	var visible: Array[String] = []
	for layer_name in target_opacities.keys():
		if target_opacities[layer_name] > 0.0:
			visible.append(layer_name)
	return visible

func get_label_priority_for_zoom(zoom: float) -> Dictionary:
	"""
	Gibt Label-Prioritäten basierend auf Zoom zurück.
	@param zoom: Aktueller Zoom-Level
	@return: Dictionary mit {layer_name: priority} (höher = wichtiger)
	"""
	var priorities: Dictionary = {}

	if zoom < 0.6:
		# MACRO: Nur Nation-Labels
		priorities["nation"] = 3
		priorities["province"] = 0
		priorities["district"] = 0
	elif zoom < 1.2:
		# OVERVIEW: Nation + Province (fade-in)
		priorities["nation"] = 3
		priorities["province"] = 2
		priorities["district"] = 0
	elif zoom < 2.5:
		# NORMAL: Nation + Province
		priorities["nation"] = 2
		priorities["province"] = 3
		priorities["district"] = 0
	elif zoom < 3.5:
		# DETAILED: Province + District
		priorities["nation"] = 1
		priorities["province"] = 2
		priorities["district"] = 3
	else:
		# MICRO: Alle Details
		priorities["nation"] = 1
		priorities["province"] = 2
		priorities["district"] = 3

	return priorities

func should_show_borders(layer_name: String) -> bool:
	"""
	Gibt zurück ob Grenzen für einen Layer gezeigt werden sollen.
	@param layer_name: Name des Layers
	@return: true wenn Grenzen gezeigt werden sollen
	"""
	return get_layer_opacity(layer_name) > 0.2

func get_lod_info() -> Dictionary:
	"""
	Gibt LOD-Informationen zurück.
	@return: Dictionary mit LOD-Daten
	"""
	return {
		"zoom_level": current_zoom_level,
		"zoom_level_name": ZoomLevel.keys()[current_zoom_level],
		"layer_opacities": layer_opacities.duplicate(),
		"visible_layers": get_visible_layers()
	}

class_name MapLabelManager
extends Node

## Verwaltet intelligentes Label-Management für die Karte
## Verhindert Überlappungen und zeigt nur wichtige Labels basierend auf Zoom
## Implementiert Prioritäts-System und Fading

# === LABEL-KONFIGURATION ===
const LABEL_MIN_DISTANCE: float = 10.0  # Minimaler Abstand zwischen Labels
const LABEL_FADE_SPEED: float = 6.0     # Geschwindigkeit des Label-Fadings

# === LABEL-DATENSTRUKTUR ===
class LabelData:
	var label: Label
	var territory_type: String  # "nation", "province", "district"
	var territory_id: String
	var priority: int           # Höher = wichtiger
	var base_font_size: int
	var bounds: Rect2          # Bildschirm-Bounds des Labels
	var target_opacity: float = 1.0
	var current_opacity: float = 1.0

	func _init(p_label: Label, p_type: String, p_id: String, p_priority: int, p_font_size: int):
		label = p_label
		territory_type = p_type
		territory_id = p_id
		priority = p_priority
		base_font_size = p_font_size

	func update_bounds() -> void:
		"""Aktualisiert Bildschirm-Bounds des Labels."""
		if label and label.visible:
			var pos = label.global_position
			var size = label.size
			bounds = Rect2(pos, size)

	func overlaps(other: LabelData) -> bool:
		"""
		Prüft ob dieses Label ein anderes überlappt.
		@param other: Anderes Label
		@return: true wenn überlappend
		"""
		if not bounds or not other.bounds:
			return false
		return bounds.intersects(other.bounds)

# === STATE ===
var label_data_list: Array[LabelData] = []
var visible_label_ids: Dictionary = {}  # {territory_id: bool}

# === REFERENZEN ===
var zoom_level_manager: ZoomLevelManager
var map_controller: Node2D

# === LABEL DICTIONARIES (Referenzen) ===
var region_labels: Dictionary = {}
var nation_labels: Dictionary = {}
var province_labels: Dictionary = {}
var district_labels: Dictionary = {}

func _ready() -> void:
	set_process(true)

func initialize(p_map_controller: Node2D, p_zoom_manager: ZoomLevelManager,
				p_region_labels: Dictionary, p_nation_labels: Dictionary, p_province_labels: Dictionary, p_district_labels: Dictionary) -> void:
	"""
	Initialisiert Label-Manager.
	@param p_map_controller: MapController-Referenz
	@param p_zoom_manager: ZoomLevelManager-Referenz
	@param p_region_labels: Region-Labels
	@param p_nation_labels: Nation-Labels
	@param p_province_labels: Province-Labels
	@param p_district_labels: District-Labels
	"""
	map_controller = p_map_controller
	zoom_level_manager = p_zoom_manager

	region_labels = p_region_labels
	nation_labels = p_nation_labels
	province_labels = p_province_labels
	district_labels = p_district_labels

	_build_label_data_list()

	print("MapLabelManager: Initialisiert mit %d Labels (4-Layer-Hierarchie)" % label_data_list.size())

func _build_label_data_list() -> void:
	"""Erstellt Liste aller Label-Daten."""
	label_data_list.clear()

	# Region Labels (niedrigste Priorität)
	for region_id in region_labels.keys():
		var label = region_labels[region_id]
		if label:
			var data = LabelData.new(label, "region", region_id, 1, 20)
			label_data_list.append(data)

	# Nation Labels (höchste Priorität)
	for nation_id in nation_labels.keys():
		var label = nation_labels[nation_id]
		if label:
			var data = LabelData.new(label, "nation", nation_id, 4, 22)
			label_data_list.append(data)

	# Province Labels
	for province_id in province_labels.keys():
		var label = province_labels[province_id]
		if label:
			var data = LabelData.new(label, "province", province_id, 3, 16)
			label_data_list.append(data)

	# District Labels
	for district_id in district_labels.keys():
		var label = district_labels[district_id]
		if label:
			var data = LabelData.new(label, "district", district_id, 2, 12)
			label_data_list.append(data)

func _process(delta: float) -> void:
	"""Verarbeitet Label-Fading."""
	_update_label_fading(delta)

func update_labels(zoom: float) -> void:
	"""
	Aktualisiert Label-Sichtbarkeit basierend auf Zoom.
	@param zoom: Aktueller Zoom-Level
	"""
	if not zoom_level_manager:
		return

	# Hole Label-Prioritäten für aktuellen Zoom
	var priorities = zoom_level_manager.get_label_priority_for_zoom(zoom)

	# Update Label-Prioritäten
	for data in label_data_list:
		data.priority = priorities.get(data.territory_type, 0)

	# Bestimme sichtbare Labels
	_determine_visible_labels()

	# Update Font-Größen basierend auf Zoom
	_update_label_sizes(zoom)

func _determine_visible_labels() -> void:
	"""
	Bestimmt welche Labels sichtbar sein sollen basierend auf Priorität und Überlappung.
	Implementiert Anti-Overlap-Algorithmus.
	"""
	# Sortiere Labels nach Priorität (höchste zuerst)
	var sorted_labels = label_data_list.duplicate()
	sorted_labels.sort_custom(func(a, b): return a.priority > b.priority)

	# Reset visible IDs
	visible_label_ids.clear()

	# Liste der bereits platzierten Labels
	var placed_labels: Array[LabelData] = []

	for data in sorted_labels:
		if data.priority <= 0:
			# Keine Priorität → Verstecke
			data.target_opacity = 0.0
			continue

		# Update Bounds
		data.update_bounds()

		# Prüfe Überlappung mit bereits platzierten Labels
		var overlaps = false
		for placed in placed_labels:
			if data.overlaps(placed):
				overlaps = true
				break

		if overlaps:
			# Überlappung → Verstecke
			data.target_opacity = 0.0
		else:
			# Kein Overlap → Zeige
			data.target_opacity = 1.0
			placed_labels.append(data)
			visible_label_ids[data.territory_id] = true

func _update_label_fading(delta: float) -> void:
	"""
	Aktualisiert Label-Fading.
	@param delta: Delta-Zeit
	"""
	for data in label_data_list:
		if abs(data.current_opacity - data.target_opacity) > 0.01:
			# Interpoliere Opacity
			data.current_opacity = lerp(data.current_opacity, data.target_opacity, delta * LABEL_FADE_SPEED)

			# Wende Opacity an
			if data.label:
				if data.current_opacity <= 0.01:
					data.label.visible = false
				else:
					data.label.visible = true
					data.label.modulate.a = data.current_opacity
		else:
			data.current_opacity = data.target_opacity

func _update_label_sizes(zoom: float) -> void:
	"""
	Aktualisiert Label-Font-Größen basierend auf Zoom.
	@param zoom: Aktueller Zoom-Level
	"""
	for data in label_data_list:
		if not data.label:
			continue

		# Berechne skalierte Font-Größe
		# Bei kleinem Zoom: Größere Schrift relativ zur Karte
		# Bei großem Zoom: Normale Schrift
		var scale_factor = 1.0
		if zoom < 1.0:
			scale_factor = 1.0 / zoom  # Vergrößere bei kleinem Zoom
		else:
			scale_factor = 1.0

		var font_size = int(data.base_font_size * scale_factor)
		font_size = clamp(font_size, data.base_font_size, data.base_font_size * 2)

		data.label.add_theme_font_size_override("font_size", font_size)

func force_update() -> void:
	"""Erzwingt sofortiges Update aller Labels."""
	if zoom_level_manager:
		var zoom = 1.0  # Fallback
		if map_controller:
			zoom = map_controller.scale.x
		update_labels(zoom)

func show_label(territory_type: String, territory_id: String) -> void:
	"""
	Zeigt ein bestimmtes Label programmatisch.
	@param territory_type: Territorium-Typ
	@param territory_id: Territorium-ID
	"""
	for data in label_data_list:
		if data.territory_type == territory_type and data.territory_id == territory_id:
			data.target_opacity = 1.0
			break

func hide_label(territory_type: String, territory_id: String) -> void:
	"""
	Versteckt ein bestimmtes Label programmatisch.
	@param territory_type: Territorium-Typ
	@param territory_id: Territorium-ID
	"""
	for data in label_data_list:
		if data.territory_type == territory_type and data.territory_id == territory_id:
			data.target_opacity = 0.0
			break

func is_label_visible(territory_id: String) -> bool:
	"""
	Prüft ob ein Label sichtbar ist.
	@param territory_id: Territorium-ID
	@return: true wenn sichtbar
	"""
	return visible_label_ids.get(territory_id, false)

func get_visible_label_count() -> int:
	"""Gibt Anzahl der sichtbaren Labels zurück."""
	return visible_label_ids.size()

func get_label_info() -> Dictionary:
	"""
	Gibt Label-Informationen zurück.
	@return: Dictionary mit Label-Daten
	"""
	var info: Dictionary = {
		"total": label_data_list.size(),
		"visible": get_visible_label_count(),
		"by_type": {}
	}

	# Zähle Labels pro Typ
	for type in ["nation", "province", "district"]:
		var count = 0
		var visible_count = 0
		for data in label_data_list:
			if data.territory_type == type:
				count += 1
				if data.current_opacity > 0.5:
					visible_count += 1
		info["by_type"][type] = {"total": count, "visible": visible_count}

	return info

func set_label_priority_override(territory_type: String, territory_id: String, priority: int) -> void:
	"""
	Setzt manuelle Priorität für ein Label (überschreibt Auto-Priorität).
	@param territory_type: Territorium-Typ
	@param territory_id: Territorium-ID
	@param priority: Neue Priorität
	"""
	for data in label_data_list:
		if data.territory_type == territory_type and data.territory_id == territory_id:
			data.priority = priority
			break

func clear_all_labels() -> void:
	"""Versteckt alle Labels sofort."""
	for data in label_data_list:
		data.target_opacity = 0.0
		data.current_opacity = 0.0
		if data.label:
			data.label.visible = false

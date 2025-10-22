extends Node

## UILayoutManager - Automatisches Layout-Management für UI-Panels
## Verwaltet Positionierung und Spacing von UI-Elementen
## Verhindert Überlappungen mit existierenden UI-Elementen

# === ANCHOR-BEREICHE ===
enum AnchorArea {
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT,
	TOP_CENTER,
	BOTTOM_CENTER
}

# === KONFIGURATION ===
const DEFAULT_MARGIN: Vector2 = Vector2(10, 10)  # Margin zum Viewport-Rand
const DEFAULT_SPACING: float = 10.0              # Spacing zwischen Panels
const RESERVED_TOP: float = 60.0                 # Reservierter Bereich oben (für Menüleiste)
const RESERVED_BOTTOM: float = 60.0              # Reservierter Bereich unten (für Menüleiste)

# === REGISTRIERTE PANELS ===
class PanelInfo:
	var panel: Control
	var anchor_area: AnchorArea
	var priority: int  # Höher = näher am Anchor-Punkt
	var custom_offset: Vector2 = Vector2.ZERO

	func _init(p_panel: Control, p_anchor: AnchorArea, p_priority: int = 0):
		panel = p_panel
		anchor_area = p_anchor
		priority = p_priority

var registered_panels: Array[PanelInfo] = []

# === VIEWPORT ===
var viewport_size: Vector2

func _ready() -> void:
	# Hole initiale Viewport-Größe
	viewport_size = get_viewport().get_visible_rect().size

	# Verbinde Viewport-Resize-Signal
	get_viewport().size_changed.connect(_on_viewport_resized)

	print("UILayoutManager: Initialisiert (Viewport: %.0fx%.0f)" % [viewport_size.x, viewport_size.y])

func _on_viewport_resized() -> void:
	"""Handler für Viewport-Resize."""
	viewport_size = get_viewport().get_visible_rect().size
	print("UILayoutManager: Viewport resized to %.0fx%.0f" % [viewport_size.x, viewport_size.y])

	# Update alle Panel-Positionen
	update_all_panel_positions()

# === PANEL-REGISTRIERUNG ===

func register_panel(panel: Control, anchor_area: AnchorArea, priority: int = 0) -> void:
	"""
	Registriert ein Panel für automatisches Layout.
	@param panel: Das Control-Node
	@param anchor_area: Anchor-Bereich
	@param priority: Priorität (höher = näher am Anchor)
	"""
	# Prüfe ob bereits registriert
	for info in registered_panels:
		if info.panel == panel:
			push_warning("UILayoutManager: Panel '%s' bereits registriert" % panel.name)
			return

	var info = PanelInfo.new(panel, anchor_area, priority)
	registered_panels.append(info)

	print("UILayoutManager: Panel '%s' registriert (%s, Priority: %d)" % [
		panel.name,
		AnchorArea.keys()[anchor_area],
		priority
	])

	# Update Positionen
	update_all_panel_positions()

func unregister_panel(panel: Control) -> void:
	"""
	Entfernt ein Panel aus dem Layout-Management.
	@param panel: Das Control-Node
	"""
	for i in range(registered_panels.size() - 1, -1, -1):
		if registered_panels[i].panel == panel:
			print("UILayoutManager: Panel '%s' unregistriert" % panel.name)
			registered_panels.remove_at(i)
			update_all_panel_positions()
			return

func update_all_panel_positions() -> void:
	"""Aktualisiert Positionen aller registrierten Panels."""
	# Sortiere Panels nach Anchor-Bereich und Priorität
	var sorted_panels = registered_panels.duplicate()
	sorted_panels.sort_custom(func(a, b):
		if a.anchor_area != b.anchor_area:
			return a.anchor_area < b.anchor_area
		return a.priority > b.priority
	)

	# Gruppiere nach Anchor-Bereich
	var panels_by_anchor: Dictionary = {}
	for area in AnchorArea.values():
		panels_by_anchor[area] = []

	for info in sorted_panels:
		panels_by_anchor[info.anchor_area].append(info)

	# Positioniere Panels pro Bereich
	for area in AnchorArea.values():
		_position_panels_in_area(panels_by_anchor[area], area)

func _position_panels_in_area(panels: Array, anchor_area: AnchorArea) -> void:
	"""
	Positioniert Panels innerhalb eines Anchor-Bereichs.
	@param panels: Liste von PanelInfo für diesen Bereich
	@param anchor_area: Der Anchor-Bereich
	"""
	if panels.is_empty():
		return

	var current_offset = Vector2.ZERO

	for info in panels:
		var panel = info.panel
		if not panel or not panel.is_inside_tree():
			continue

		# Berechne Position basierend auf Anchor
		var pos = _calculate_anchor_position(anchor_area, current_offset)

		# Wende Position an
		panel.position = pos + info.custom_offset

		# Aktualisiere Offset für nächstes Panel
		var panel_size = panel.get_minimum_size()
		if panel_size == Vector2.ZERO:
			# Fallback: verwende custom_minimum_size oder geschätzte Größe
			panel_size = panel.size if panel.size != Vector2.ZERO else Vector2(200, 100)

		# Offset basierend auf Anchor-Richtung
		match anchor_area:
			AnchorArea.TOP_LEFT, AnchorArea.TOP_RIGHT, AnchorArea.TOP_CENTER:
				# Stack vertikal nach unten
				current_offset.y += panel_size.y + DEFAULT_SPACING

			AnchorArea.BOTTOM_LEFT, AnchorArea.BOTTOM_RIGHT, AnchorArea.BOTTOM_CENTER:
				# Stack vertikal nach oben
				current_offset.y -= panel_size.y + DEFAULT_SPACING

func _calculate_anchor_position(anchor_area: AnchorArea, offset: Vector2) -> Vector2:
	"""
	Berechnet Anchor-Position mit Offset.
	@param anchor_area: Der Anchor-Bereich
	@param offset: Offset vom Anchor-Punkt
	@return: Absolute Position
	"""
	var pos = Vector2.ZERO

	match anchor_area:
		AnchorArea.TOP_LEFT:
			pos = DEFAULT_MARGIN + Vector2(0, RESERVED_TOP) + offset

		AnchorArea.TOP_RIGHT:
			pos = Vector2(viewport_size.x - DEFAULT_MARGIN.x, DEFAULT_MARGIN.y + RESERVED_TOP) + offset

		AnchorArea.TOP_CENTER:
			pos = Vector2(viewport_size.x / 2.0, DEFAULT_MARGIN.y + RESERVED_TOP) + offset

		AnchorArea.BOTTOM_LEFT:
			pos = Vector2(DEFAULT_MARGIN.x, viewport_size.y - DEFAULT_MARGIN.y - RESERVED_BOTTOM) + offset

		AnchorArea.BOTTOM_RIGHT:
			pos = Vector2(viewport_size.x - DEFAULT_MARGIN.x, viewport_size.y - DEFAULT_MARGIN.y - RESERVED_BOTTOM) + offset

		AnchorArea.BOTTOM_CENTER:
			pos = Vector2(viewport_size.x / 2.0, viewport_size.y - DEFAULT_MARGIN.y - RESERVED_BOTTOM) + offset

	return pos

# === RESERVED AREAS ===

func set_reserved_top(height: float) -> void:
	"""
	Setzt reservierten Bereich oben (z.B. für Menüleiste).
	@param height: Höhe in Pixeln
	"""
	# Note: RESERVED_TOP ist const, müsste als var deklariert werden für Runtime-Änderung
	push_warning("UILayoutManager: RESERVED_TOP ist konstant und kann nicht zur Laufzeit geändert werden")

func set_reserved_bottom(height: float) -> void:
	"""
	Setzt reservierten Bereich unten (z.B. für Statusleiste).
	@param height: Höhe in Pixeln
	"""
	# Note: RESERVED_BOTTOM ist const, müsste als var deklariert werden für Runtime-Änderung
	push_warning("UILayoutManager: RESERVED_BOTTOM ist konstant und kann nicht zur Laufzeit geändert werden")

# === UTILITY ===

func get_anchor_area_name(area: AnchorArea) -> String:
	"""Gibt Name des Anchor-Bereichs zurück."""
	return AnchorArea.keys()[area]

func get_registered_panels_count() -> int:
	"""Gibt Anzahl registrierter Panels zurück."""
	return registered_panels.size()

func get_panels_in_area(anchor_area: AnchorArea) -> Array:
	"""
	Gibt alle Panels in einem Anchor-Bereich zurück.
	@param anchor_area: Der Anchor-Bereich
	@return: Array von Control-Nodes
	"""
	var panels: Array = []
	for info in registered_panels:
		if info.anchor_area == anchor_area:
			panels.append(info.panel)
	return panels

func print_layout_info() -> void:
	"""Gibt Layout-Informationen aus (Debug)."""
	print("\n=== UILayoutManager Info ===")
	print("Viewport: %.0fx%.0f" % [viewport_size.x, viewport_size.y])
	print("Reserved Top: %.0f px, Bottom: %.0f px" % [RESERVED_TOP, RESERVED_BOTTOM])
	print("Registered Panels: %d" % registered_panels.size())

	for area in AnchorArea.values():
		var panels = get_panels_in_area(area)
		if not panels.is_empty():
			print("  %s: %d panels" % [get_anchor_area_name(area), panels.size()])
			for panel in panels:
				print("    - %s (pos: %.0f, %.0f)" % [panel.name, panel.position.x, panel.position.y])

	print("============================\n")

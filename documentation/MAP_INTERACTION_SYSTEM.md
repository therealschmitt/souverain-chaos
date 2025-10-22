# Map Interaction System

**Autor:** Claude Code
**Datum:** 2025-10-21
**Version:** 1.0

## Übersicht

Das Map Interaction System ist eine dedizierte Schicht für Benutzer-Interaktionen mit der Spielkarte. Es trennt sauber die Interaktionslogik (Klicks, Hover) von der Rendering-Logik und kommuniziert über den EventBus.

## Architektur

### Komponenten

```
MapController (Haupt-Controller)
├── PolygonRenderer (Rendering-Konfiguration)
├── MapInteractionLayer (Interaktions-Schicht)
│   ├── Hover Highlight (Line2D)
│   └── Selection Highlight (Line2D)
├── RegionLayer (Node2D)
├── NationLayer (Node2D)
├── ProvinceLayer (Node2D)
├── DistrictLayer (Node2D)
└── LabelLayer (Node2D)
```

### Klassen

#### MapInteractionLayer
- **Pfad:** `scripts/ui/map/MapInteractionLayer.gd`
- **Zweck:** Dedizierte Schicht für Maus-Interaktionen
- **Funktionen:**
  - Fängt Maus-Klicks und Hover-Events ab
  - Identifiziert Territorium unter Mauszeiger via Point-in-Polygon-Test
  - Zeichnet visuelle Highlights mit Line2D
  - Sendet Events über EventBus

#### PolygonRenderer
- **Pfad:** `scripts/ui/map/PolygonRenderer.gd`
- **Erweiterungen:**
  - `get_hover_line_width()` - Berechnet Linienbreite für Hover-Highlights
  - `get_selection_line_width()` - Berechnet Linienbreite für Selection-Highlights
  - `create_highlight_line()` - Erstellt konfigurierte Line2D für Highlights

## EventBus-Signale

### Neue Signale (in `autoload/EventBus.gd`)

```gdscript
# === MAP INTERACTION EVENTS ===
signal territory_clicked(territory_type: String, territory_id: String)
signal territory_hovered(territory_type: String, territory_id: String)
signal territory_unhovered()
signal territory_selected(territory_type: String, territory_id: String)
signal territory_deselected()
```

### Signal-Flow

```
Benutzer klickt Polygon
        ↓
MapInteractionLayer._input()
        ↓
_get_territory_at_position() → {type, id}
        ↓
EventBus.territory_clicked.emit()
        ↓
EventBus.territory_selected.emit()
        ↓
MapController._on_territory_clicked()
MapController._on_territory_selected()
        ↓
UI-Panels/andere Systeme reagieren
```

## Visuelle Highlights

### Hover-Highlight
- **Farbe:** Weiß (`Color(1.0, 1.0, 1.0, 0.8)`)
- **Linienbreite:** Territorium-Linienbreite + 2px
- **Z-Index:** 1000 (über allen Polygonen)
- **Verhalten:** Wird angezeigt wenn Maus über Polygon schwebt

### Selection-Highlight
- **Farbe:** Gelb (`Color(1.0, 1.0, 0.0, 1.0)`)
- **Linienbreite:** Territorium-Linienbreite + 3px
- **Z-Index:** 999 (knapp unter Hover)
- **Verhalten:** Bleibt sichtbar bis anderes Territorium selektiert wird

### Hierarchie-Anpassung

Die Linienbreite der Highlights passt sich automatisch an die Territorium-Hierarchie an:

| Territorium-Typ | Basis-Linienbreite | Hover | Selection |
|-----------------|-------------------|-------|-----------|
| Region          | 4.0 px            | 6.0 px| 7.0 px    |
| Nation          | 3.0 px            | 5.0 px| 6.0 px    |
| Province        | 2.0 px            | 4.0 px| 5.0 px    |
| District        | 1.0 px            | 3.0 px| 4.0 px    |

## Verwendung

### Initialisierung

Die MapInteractionLayer wird automatisch in `MapController._ready()` initialisiert:

```gdscript
func _initialize_interaction_layer() -> void:
    interaction_layer = MapInteractionLayer.new()
    interaction_layer.name = "InteractionLayer"
    add_child(interaction_layer)
```

Nach dem Laden der Map-Daten wird sie mit Referenzen verknüpft:

```gdscript
if interaction_layer:
    interaction_layer.initialize(self, polygon_renderer)
```

### Auf Interaktionen Reagieren

Andere Systeme können auf Interaktions-Events reagieren:

```gdscript
func _ready():
    EventBus.territory_clicked.connect(_on_territory_clicked)
    EventBus.territory_hovered.connect(_on_territory_hovered)
    EventBus.territory_selected.connect(_on_territory_selected)

func _on_territory_clicked(territory_type: String, territory_id: String):
    print("Territorium geklickt: %s [%s]" % [territory_id, territory_type])

    # Hole Territorium-Daten
    var territory = null
    match territory_type:
        "region": territory = GameState.regions.get(territory_id)
        "nation": territory = GameState.nations.get(territory_id)
        "province": territory = GameState.provinces.get(territory_id)
        "district": territory = GameState.districts.get(territory_id)

    # Zeige Detail-Panel, etc.

func _on_territory_hovered(territory_type: String, territory_id: String):
    # Zeige Tooltip, etc.
    pass

func _on_territory_selected(territory_type: String, territory_id: String):
    # Update UI Selection State
    pass
```

### Programmatische Selektion

```gdscript
# Selektiere Territorium programmatisch
interaction_layer.select_territory("province", "province_001")

# Lösche Selektion
interaction_layer.clear_selection()

# Hole aktuell gehovertes Territorium
var hovered = interaction_layer.get_hovered_territory()
# → {"type": "province", "id": "province_001"}

# Hole aktuell selektiertes Territorium
var selected = interaction_layer.get_selected_territory()
# → {"type": "nation", "id": "nation_002"}
```

## Koordinaten-Konversion

Das System verwendet mehrere Koordinatensysteme:

### 1. Screen-Koordinaten
- **Ursprung:** Obere linke Ecke des Viewports
- **Einheit:** Pixel
- **Verwendung:** Input-Events (`InputEventMouse`)

### 2. Map-Pixel-Koordinaten
- **Ursprung:** Obere linke Ecke der Karte
- **Einheit:** Pixel
- **Verwendung:** Polygon-Vertices, Point-in-Polygon-Tests

### 3. World-Koordinaten
- **Ursprung:** Zentrum der Spielwelt
- **Einheit:** Kilometer
- **Verwendung:** Gameplay-Logik (Distanzen, Bereiche)

### Konversion

```gdscript
# Screen → Map Pixel
var map_pixel = _screen_to_map_pixel(screen_pos)
# Berücksichtigt: position und scale des MapControllers

# Map Pixel → Screen
var screen_pos = _map_pixel_to_screen(map_pixel_pos)

# Screen → World (via MapScale)
var world_pos = map_scale.pixel_to_world(map_pixel)

# World → Map Pixel (via MapScale)
var map_pixel = map_scale.world_to_pixel(world_pos)
```

## Point-in-Polygon-Algorithmus

Verwendet Godots eingebaute Funktion:

```gdscript
func _point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
    if polygon.size() < 3:
        return false
    return Geometry2D.is_point_in_polygon(point, polygon)
```

- **Algorithmus:** Ray-Casting (Godot-intern)
- **Performance:** O(n) pro Polygon, wobei n = Anzahl Vertices
- **Optimierung:** Layer werden von feinster zu gröbster Hierarchie durchsucht

## Performance-Überlegungen

### Aktuell
- **Worst-Case:** O(n * m) wobei n = Anzahl Polygone, m = Durchschnittliche Vertices
- **Typisch:** ~100-500 Polygone bei 10-30 Vertices → < 1ms bei Hover

### Geplante Optimierungen (bei Bedarf)
1. **Spatial Hashing:** Unterteile Karte in Grid für schnellere Lookup
2. **Bounding Box Pre-Check:** Prüfe AABB vor Point-in-Polygon
3. **Layer-Caching:** Cache letztes gehovertes Polygon
4. **LOD-basierte Interaktion:** Deaktiviere kleinste Layer bei Zoom-Out

## Bekannte Limitierungen

1. **Überlappende Polygone:** Bei überlappenden Territorien wird immer das erste gefundene zurückgegeben (Layer-Hierarchie)
2. **Keine Multi-Selection:** Aktuell kann nur ein Territorium selektiert werden
3. **Keine Touch-Unterstützung:** System ist nur für Maus optimiert

## Erweiterungsmöglichkeiten

### Tooltip-System
```gdscript
func _on_territory_hovered(territory_type: String, territory_id: String):
    var tooltip = _create_tooltip(territory_type, territory_id)
    tooltip.position = get_global_mouse_position()
    add_child(tooltip)
```

### Context-Menu bei Rechtsklick
```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
            _show_context_menu(event.position)
```

### Multi-Selection mit Ctrl
```gdscript
func _handle_mouse_click(click_pos: Vector2) -> void:
    var territory = _get_territory_at_position(click_pos)

    if Input.is_key_pressed(KEY_CTRL):
        # Add to selection
        selected_territories.append(territory)
    else:
        # Replace selection
        selected_territories = [territory]
```

## Testing

### Manuelle Tests
1. **Hover-Test:** Bewege Maus über verschiedene Polygone → Highlight sollte folgen
2. **Click-Test:** Klicke Polygone → Selection-Highlight bleibt
3. **Layer-Test:** Deaktiviere/aktiviere Layer → Interaktion passt sich an
4. **Grenz-Test:** Klicke nahe Polygon-Grenzen → Korrekte Zuordnung

### Debugging

```gdscript
# In MapInteractionLayer:
func _handle_mouse_hover(mouse_pos: Vector2) -> void:
    var territory = _get_territory_at_position(mouse_pos)

    # Debug-Output
    if not territory.is_empty():
        print("Hover: %s [%s]" % [territory.id, territory.type])
```

## Changelog

### Version 1.0 (2025-10-21)
- Initiale Implementierung
- Dedizierte MapInteractionLayer-Klasse
- EventBus-Integration
- Hover- und Selection-Highlights
- Hierarchie-angepasste Linienbreiten
- Dokumentation

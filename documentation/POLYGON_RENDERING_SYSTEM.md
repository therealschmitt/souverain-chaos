# Polygon Rendering System

## Übersicht

Das verbesserte Polygon-Rendering-System verwaltet die visuelle Darstellung aller geografischen Entitäten (Regionen, Nationen, Provinzen, Distrikte) auf der Weltkarte. Es implementiert eine hierarchie-basierte Grenzdarstellung mit unterschiedlichen Linienstärken und Farben je nach geografischer Ebene.

---

## Architektur

### Komponenten

```
MapController.gd (Hauptkoordinator)
    ├── PolygonRenderer.gd (Rendering-Konfiguration & -Logik)
    ├── Region/Nation/Province/District (Entity-Klassen mit boundary_polygon)
    └── MapScale.gd (Koordinaten-Konvertierung)
```

### Datenfluss

```
GameState (Entities mit Polygonen)
    ↓
MapController (lädt & erstellt)
    ↓
PolygonRenderer (konfiguriert Rendering)
    ↓
Polygon2D + Line2D (Godot-Nodes für Rendering)
```

---

## Hierarchie-basierte Linienstärken

| Ebene | Linienstärke | Farbe | Opacity | Beschreibung |
|-------|--------------|-------|---------|---|
| **Region** | 4.0 px | #1A1A1A (dunkelgrau) | 1.0 | Dickste Grenzen, oberste Ebene der Unterteilung |
| **Nation** | 3.0 px | #333333 (grau) | 1.0 | Mittlere Grenzen, politische Grenzen |
| **Province** | 2.0 px | #666666 (hellgrau) | 0.9 | Feine Grenzen, wirtschaftliche/verwaltungstechnische Grenzen |
| **District** | 1.0 px | #999999 (sehr hellgrau) | 0.7 | Sehr feine Grenzen, städtische Unterteilung |

### Rendering-Stack (Z-Order)

```
Layer 0: Regionen (hinterste)
Layer 1: Nationen
Layer 2: Provinzen
Layer 3: Distrikte (vorderste)
```

---

## Koordinaten-Systeme

### 1. World-Koordinaten (km)
- **Bereich**: X[0, 20000] km, Y[0, 12000] km
- **Verwendet für**: Spiellogik, Entfernungen, Flächenberechnungen
- **Speicherort**: GameState Entities

### 2. Pixel-Koordinaten (px)
- **Bereich**: X[0, 2000] px, Y[0, 1200] px
- **Verwendet für**: Rendering, Polygon-Definition
- **Speicherort**: `boundary_polygon` in Entity-Klassen
- **Verhältnis**: 10 km/px (MapScale)

### 3. Screen-Koordinaten (px)
- **Verwendet für**: Viewport/Input-Verarbeitung
- **Berechnung**: `screen_pos = map_pixel_pos * scale + map_position`

### Konvertierungskette

```
┌─────────────────────┐
│ World-Koordinaten   │  (km)
│ z.B.: (10000, 6000) │
└──────────┬──────────┘
           │
      MapScale:
   pixel_to_world()
   world_to_pixel()
           │
┌──────────▼──────────┐
│ Pixel-Koordinaten   │  (px)
│ z.B.: (1000, 600)   │
└──────────┬──────────┘
           │
      MapController:
   _map_pixel_to_screen()
   _screen_to_map_pixel()
           │
┌──────────▼──────────┐
│ Screen-Koordinaten  │  (px)
│ z.B.: (500, 300)    │
└─────────────────────┘
```

### Verwendete Klassen und Funktionen

#### MapScale (`scripts/resources/MapScale.gd`)
```gdscript
# World ↔ Pixel Konvertierung
func pixel_to_world(pixel_pos: Vector2) -> Vector2
func world_to_pixel(world_pos: Vector2) -> Vector2

# Berechnungen auf Basis von Koordinaten
func calculate_distance_km(world_pos1, world_pos2) -> float
func calculate_polygon_area_km2(world_polygon) -> float
```

#### MapController (`scripts/ui/map/MapController.gd`)
```gdscript
# Pixel ↔ Screen Konvertierung
func _map_pixel_to_screen(map_pixel_pos: Vector2) -> Vector2
func _screen_to_map_pixel(screen_pos: Vector2) -> Vector2

# Komplette Konvertierungsketten
func _screen_to_world(screen_pos: Vector2) -> Vector2
func _world_to_screen(world_pos: Vector2) -> Vector2
```

---

## PolygonRenderer-Klasse

### Öffentliche API

#### `get_config(territory_type: String) -> RenderConfig`
Gibt die Render-Konfiguration für einen Territory-Typ zurück.

```gdscript
var config = polygon_renderer.get_config("nation")
print("Line Width: %f px" % config.line_width)
```

#### `create_boundary_line(polygon: PackedVector2Array, territory_type: String) -> Line2D`
Erstellt eine konfigurierte Line2D für Polygon-Grenzen.

```gdscript
var line = polygon_renderer.create_boundary_line(nation.boundary_polygon, "nation")
# Line2D mit automatisch gesetzter Linienstärke, Farbe, etc.
```

#### `apply_fill_color(polygon_2d: Polygon2D, territory_type: String, base_color: Color) -> void`
Setzt die Füllfarbe mit Hierarchie-spezifischer Transparenz.

```gdscript
polygon_renderer.apply_fill_color(polygon_2d, "province", province.color)
# Füllfarbe wird mit Province-spezifischer Opacity angewendet
```

#### `get_highlight_color(territory_type: String, is_selected: bool) -> Color`
Gibt die Highlight-Farbe für Interaktion zurück.

```gdscript
var hover_color = polygon_renderer.get_highlight_color("nation", false)  # Weiß
var select_color = polygon_renderer.get_highlight_color("nation", true)   # Gelb
```

#### `validate_polygon(polygon: PackedVector2Array, min_area: float = 10.0) -> bool`
Validiert Polygon-Integrität vor dem Rendering.

```gdscript
if polygon_renderer.validate_polygon(region.boundary_polygon):
    # Polygon ist gültig
```

---

## Rendering-Prozess

### 1. Initialisierung (MapController._ready)
```gdscript
func _ready() -> void:
    _initialize_polygon_renderer()      # Erstelle PolygonRenderer
    _initialize_map_scale()             # Lade Koordinaten-System
    _setup_layers()                     # Erstelle rendering Layer
    call_deferred("_delayed_load")      # Lade asynchron Kartendaten
```

### 2. Datenladung (MapController._load_map_data)
```gdscript
for region_id in GameState.regions.keys():
    _create_region_polygon(GameState.regions[region_id])

for nation_id in GameState.nations.keys():
    _create_nation_polygon(GameState.nations[nation_id])
# ... usw. für Province und District
```

### 3. Polygon-Erstellung (z.B. `_create_nation_polygon`)
```gdscript
func _create_nation_polygon(nation) -> void:
    # Validierung
    if not polygon_renderer.validate_polygon(nation.boundary_polygon):
        return

    # Erstelle Polygon-Node
    var polygon = Polygon2D.new()
    polygon.polygon = nation.boundary_polygon

    # Wende Render-Konfiguration an
    polygon_renderer.apply_fill_color(polygon, "nation", nation.color)

    # Erstelle Grenzlinie
    var line = polygon_renderer.create_boundary_line(
        nation.boundary_polygon,
        "nation"
    )
    polygon.add_child(line)

    # Füge zur Render-Hierarchie hinzu
    nation_layer.add_child(polygon)
    nation_shapes[nation.id] = polygon
```

### 4. Interaktive Highlights (MapController._draw)
```gdscript
func _draw() -> void:
    if not hovered_territory.is_empty():
        var hover_color = polygon_renderer.get_highlight_color(
            hovered_territory.type,
            false
        )
        _draw_territory_highlight(hovered_territory, hover_color)

    if not selected_territory.is_empty():
        var select_color = polygon_renderer.get_highlight_color(
            selected_territory.type,
            true
        )
        _draw_territory_highlight(selected_territory, select_color)
```

---

## Konfiguration anpassen

### Linienstärke ändern
```gdscript
# In PolygonRenderer._setup_render_configs():
configs["nation"] = RenderConfig(
    2.5,  # Neue Linienstärke (Standard: 3.0)
    Color(0.2, 0.2, 0.2, 1.0),
    1.0,
    0.2,
    1,
    "Nationen: Mittlere Grenzen"
)
```

### Linienfarben anpassen
```gdscript
# In PolygonRenderer._setup_render_configs():
configs["province"] = RenderConfig(
    2.0,
    Color(1.0, 0.0, 0.0, 0.8),  # Neue Farbe: Rot
    0.8,  # Opacity angepasst
    0.15,
    2,
    "Provinzen: Rote Grenzen"
)
```

### Neue Hierarchie-Ebene hinzufügen
```gdscript
# Beispiel: Subprovinzen
configs["subprovince"] = RenderConfig(
    0.5,
    Color(0.8, 0.8, 0.8, 0.5),
    0.5,
    0.08,
    2.5,
    "Subprovinzen: Sehr dünne Grenzen"
)

# Dann nutzen:
var line = polygon_renderer.create_boundary_line(polygon, "subprovince")
```

---

## Performance-Hinweise

### Polygon-Validierung
Alle Polygone werden vor dem Rendering validiert:
- **Minimum 3 Punkte** erforderlich
- **Mindestfläche** von 10 px² erforderlich (verhindet Render-Artefakte)

### Layer-Strategie
- **Regionen**: Layer 0 (immer sichtbar)
- **Nationen**: Layer 1 (immer sichtbar)
- **Provinzen**: Layer 2 (immer sichtbar)
- **Distrikte**: Layer 3 (optional, standard aus)

```gdscript
# Distrikte ein/ausblenden
district_layer.visible = true   # Zoom Level hoch
district_layer.visible = false  # Zoom Level niedrig
```

### Caching & Wiederverwendung
- Alle Layer und Shapes sind in Dictionaries gecacht
- Kein Neuerstellen bei jedem Frame
- Nur Highlights werden jeden Frame neu gezeichnet

---

## Fehlersuche

### Problem: Polygone werden nicht angezeigt
**Lösung**:
1. Prüfe in Ausgabe nach Validierungsfehlern
2. Prüfe ob `layer.visible = true`
3. Prüfe ob `boundary_polygon` gültige Koordinaten hat

```gdscript
if polygon_renderer.validate_polygon(territory.boundary_polygon):
    print("Polygon ist valide")
else:
    print("Polygon hat zu wenige Punkte oder Fläche zu klein")
```

### Problem: Grenzen sind zu dünn/dick
**Lösung**: Ändere `line_width` in PolygonRenderer für entsprechenden Territory-Typ

### Problem: Falsche Polygon-Positionen
**Lösung**: Prüfe Koordinaten-Konvertierung
```gdscript
# Debug-Ausgabe
var world_pos = map_scale.pixel_to_world(polygon_center)
print("Pixel: %v, World: %v" % [polygon_center, world_pos])
```

---

## Zusammenfassung

Das verbesserte Polygon-Rendering-System bietet:

✅ **Hierarchie-basierte Visualisierung** - Unterschiedliche Linienstärken pro Ebene
✅ **Zentrale Konfiguration** - Alle Rendering-Parameter an einem Ort
✅ **Koordinaten-Konvertierung** - Nahtlose Umrechnung zwischen Koordinatensystemen
✅ **Interaktive Highlights** - Unterschiedliche Farben für Hover/Select
✅ **Performance-Optimierungen** - Caching, Validierung, Layer-Management
✅ **Erweiterbar** - Neue Hierarchie-Ebenen einfach hinzufügbar

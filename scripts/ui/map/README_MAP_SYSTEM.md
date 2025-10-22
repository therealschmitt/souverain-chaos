# Map System - Übersicht

**Version:** 1.0
**Datum:** 2025-10-21

## Verzeichnisstruktur

```
scripts/ui/map/
├── MapController.gd              # Haupt-Controller
├── PolygonRenderer.gd            # Rendering-Konfiguration
├── MapInteractionLayer.gd        # Maus-Interaktion
├── MapZoomController.gd          # Zoom-Logik
├── MapPanningController.gd       # Panning-Logik & Kamera-Grenzen
├── ZoomLevelManager.gd           # LOD-Management
├── MapLabelManager.gd            # Label-Verwaltung
├── MapZoomUI.gd                  # Zoom-UI-Komponente
├── MapDebugUI.gd                 # Debug-UI (F3 Toggle)
├── RenderingConfigExamples.gd    # Beispiel-Konfigurationen
├── RenderingDebugger.gd          # Debug-Tools
├── README_MAP_SYSTEM.md          # Diese Datei
└── DEBUG_UI_README.md            # Debug-UI Dokumentation
```

## Komponenten-Übersicht

### 🎯 MapController.gd
**Haupt-Controller für das gesamte Kartensystem**

- Verwaltet alle Map-Layer (Region, Nation, Province, District)
- Koordiniert Sub-Systeme (Zoom, Interaktion, Labels)
- Lädt Map-Daten aus GameState
- Bietet Public API für Karten-Operationen

**Verwendung:**
```gdscript
var map = MapController.new()
map.zoom_in(0.2)
map.zoom_to_territory("province", "province_001")
```

---

### 🎨 PolygonRenderer.gd
**Zentrale Rendering-Konfiguration**

- Definiert Linienstärken, Farben, Opacities pro Hierarchie-Ebene
- Erstellt Line2D für Polygon-Grenzen
- Erstellt Polygon2D mit Fill-Colors
- Validiert Polygone

**Hierarchie-Konfiguration:**

| Ebene | Linienbreite | Farbe | Layer |
|-------|--------------|-------|-------|
| Region | 4.0 px | Dunkelgrau | 0 |
| Nation | 3.0 px | Grau | 1 |
| Province | 2.0 px | Hellgrau | 2 |
| District | 1.0 px | Sehr hell | 3 |

---

### 🖱️ MapInteractionLayer.gd
**Maus-Interaktion mit Polygonen**

- Fängt Klicks und Hover-Events ab
- Point-in-Polygon-Erkennung
- Hover-Highlights (weiße Linie)
- Selection-Highlights (gelbe Linie)
- Sendet Events über EventBus

**Events:**
- `territory_clicked(type, id)`
- `territory_hovered(type, id)`
- `territory_selected(type, id)`

---

### 🔍 MapZoomController.gd
**Stufenloses Zoomen**

- Zoom-Range: 0.25 - 4.0
- Mausrad-Support
- Sanfte Interpolation
- Zoom-Pivot (Maus, Zentrum, Selektion)

**API:**
```gdscript
zoom_controller.zoom_in(0.2)
zoom_controller.set_zoom(1.5)
zoom_controller.zoom_to_fit_bounds(min, max)
```

---

### 🎮 MapPanningController.gd
**Kamera-Panning mit Grenzen**

- WASD-Panning (400 px/s)
- Rechte-Maustaste-Dragging
- Dynamische Kamera-Grenzen (angepasst an Zoom)
- Verhindert Verlassen der Map-Grenzen
- Sanftes Ausrollen nach Maus-Panning

**Steuerung:**
- `W/A/S/D` oder `Pfeiltasten`: Kamera bewegen
- `Rechte Maustaste + Ziehen`: Kamera dragging
- Automatische Zentrierung bei zu kleiner Karte

---

### 📊 ZoomLevelManager.gd
**Level-of-Detail (LOD) Verwaltung**

- 5 LOD-Stufen: MACRO → OVERVIEW → NORMAL → DETAILED → MICRO
- Automatisches Layer-Fading basierend auf Zoom
- Schwellenwerte für Ein-/Ausblenden
- Alpha-Modulation für sanfte Übergänge

**LOD-Stufen:**
```
MACRO    (0.25-0.5): Nur Regionen
OVERVIEW (0.5-1.0):  Regionen + Nationen
NORMAL   (1.0-2.0):  Nationen + Provinzen
DETAILED (2.0-3.0):  Provinzen + Distrikte
MICRO    (3.0-4.0):  Alle Details
```

---

### 🏷️ MapLabelManager.gd
**Intelligentes Label-Management**

- Anti-Overlap-Algorithmus
- Prioritäts-basierte Sichtbarkeit
- Font-Skalierung basierend auf Zoom
- Sanftes Label-Fading

**Features:**
- Verhindert Überlappungen
- Zeigt nur wichtige Labels bei geringem Zoom
- Größere Schrift bei kleinem Zoom

---

### 🎛️ MapZoomUI.gd
**UI-Komponente für Zoom-Steuerung**

- Zoom-In/Out-Buttons
- Zoom-Slider
- Zoom-Label (Prozent-Anzeige)
- Reset-Button

**Integration:**
```gdscript
var zoom_ui = MapZoomUI.new()
add_child(zoom_ui)
zoom_ui.initialize(map_controller)
```

---

### 🐛 MapDebugUI.gd
**Debug-UI für Entwicklung**

- Zeigt Zoom-Level und Maßstab in Echtzeit
- LOD-Level und sichtbare Layer
- Panning-Position und Status
- Label-Statistiken (sichtbar/total)
- Toggle mit `F3`-Taste

**Angezeigte Informationen:**
- **ZOOM:** Maßstab (z.B. 1.50x = 150%), Target, Range, Progress
- **LOD:** Aktuelles Level, sichtbare Layer
- **PANNING:** Position, Is Panning Status
- **LABELS:** Anzahl sichtbar / total
- **CONTROLS:** Aktive Steuerungs-Hinweise

**Aktivierung:**
```gdscript
# Im MapController Inspector:
@export var show_debug_ui: bool = true  # Standard: aktiviert

# Programmatisch:
map_controller.toggle_debug_ui()        # F3
```

**Siehe:** [DEBUG_UI_README.md](DEBUG_UI_README.md) für Details

---

## System-Integration

### Initialisierungs-Reihenfolge

```
1. MapController._ready()
   ├── _initialize_polygon_renderer()
   ├── _initialize_map_scale()
   ├── _setup_layers()
   ├── _initialize_zoom_system()
   └── _initialize_interaction_layer()

2. MapController._load_map_data()
   ├── Lade Polygone aus GameState
   ├── Erstelle Layer mit PolygonRenderer
   └── Initialisiere Sub-Systeme

3. Sub-System-Initialisierung
   ├── zoom_controller.initialize(self)
   ├── zoom_level_manager.initialize(layers...)
   ├── label_manager.initialize(...)
   └── interaction_layer.initialize(...)
```

### EventBus-Signale

**Map Interaction:**
- `territory_clicked(type, id)`
- `territory_hovered(type, id)`
- `territory_unhovered()`
- `territory_selected(type, id)`
- `territory_deselected()`

**Map Zoom:**
- `map_zoom_changed(current, target)`
- `map_zoom_completed(final)`
- `map_zoom_level_changed(new, old)`

### Koordinatensysteme

```
Screen Coordinates (Viewport-Pixel)
        ↓ _screen_to_map_pixel()
Map Pixel Coordinates (Polygon-Vertices)
        ↓ map_scale.pixel_to_world()
World Coordinates (Kilometer)
```

---

## Verwendungsbeispiele

### 1. Zoom zu Territory bei Klick

```gdscript
func _ready():
    EventBus.territory_clicked.connect(_on_territory_clicked)

func _on_territory_clicked(territory_type: String, territory_id: String):
    map_controller.zoom_to_territory(territory_type, territory_id, 2.0)
```

### 2. Reagiere auf LOD-Wechsel

```gdscript
func _ready():
    EventBus.map_zoom_level_changed.connect(_on_lod_changed)

func _on_lod_changed(new_level: int, old_level: int):
    if new_level == ZoomLevelManager.ZoomLevel.DETAILED:
        print("Detaillierte Ansicht - aktiviere zusätzliche Features")
```

### 3. Custom Highlight-Farben

```gdscript
# In PolygonRenderer.gd:
func get_highlight_color(territory_type: String, is_selected: bool) -> Color:
    if is_selected:
        return nation_colors.get(territory_type, Color.YELLOW)
    else:
        return Color.WHITE.darkened(0.2)
```

---

## Debug-Tools

### RenderingDebugger.gd

```gdscript
# Zeige Rendering-Statistiken
RenderingDebugger.print_stats(map_controller)

# Zeige LOD-Informationen
RenderingDebugger.print_lod_info(zoom_level_manager)

# Zeige Label-Informationen
RenderingDebugger.print_label_info(label_manager)
```

---

## Performance-Hinweise

### Optimierungen

1. **Layer-Fading:** O(1) - Konstant 4 Layer
2. **Zoom-Interpolation:** O(1) pro Frame
3. **Label-Culling:** O(n log n) - Sortierung
4. **Point-in-Polygon:** O(n*m) - n=Polygone, m=Vertices

### Bottlenecks

- **Label-Overlap-Check:** O(n²) bei vielen sichtbaren Labels
- **Polygon-Rendering:** Abhängig von Vertex-Anzahl

### Geplante Optimierungen

- Spatial Hashing für Labels
- Polygon-Simplification bei kleinem Zoom
- Dirty-Flags für Label-Updates

---

## Dokumentation

**Vollständige Dokumentation:**

- [MAP_INTERACTION_SYSTEM.md](../../../documentation/MAP_INTERACTION_SYSTEM.md) - Interaktions-System
- [MAP_ZOOM_SYSTEM.md](../../../documentation/MAP_ZOOM_SYSTEM.md) - Zoom & LOD System
- [MAP_PANNING_SYSTEM.md](../../../documentation/MAP_PANNING_SYSTEM.md) - Panning & Kamera-Grenzen
- [MAP_COORDINATE_SYSTEM.md](../../../documentation/MAP_COORDINATE_SYSTEM.md) - Koordinatensysteme
- [POLYGON_RENDERING_SYSTEM.md](../../../documentation/POLYGON_RENDERING_SYSTEM.md) - Polygon-Rendering

---

## Changelog

### Version 1.0 (2025-10-21)
- Initiale Implementierung aller Komponenten
- MapController mit vollständiger API
- PolygonRenderer mit Hierarchie-Konfiguration
- MapInteractionLayer mit Hover/Selection
- MapZoomController mit sanftem Zoomen
- ZoomLevelManager mit 5 LOD-Stufen
- MapLabelManager mit Anti-Overlap
- MapZoomUI mit Buttons und Slider
- Vollständige Dokumentation

---

**Für weitere Fragen siehe:** `documentation/MAP_*.md`

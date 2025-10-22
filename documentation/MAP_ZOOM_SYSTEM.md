# Map Zoom & LOD System

**Autor:** Claude Code
**Datum:** 2025-10-21
**Version:** 1.0

## Übersicht

Das Map Zoom & LOD (Level-of-Detail) System implementiert stufenloses Zoomen mit intelligenter Verwaltung von Layer-Sichtbarkeit, Label-Management und sanftem Fading zwischen Zoom-Stufen.

## Architektur

### Komponenten-Übersicht

```
MapController
├── MapZoomController        → Zoom-Logik (Mausrad, Buttons)
├── ZoomLevelManager         → LOD-Verwaltung (Layer-Fading)
├── MapLabelManager          → Label-Verwaltung (Anti-Overlap)
└── MapZoomUI                → UI-Controls (optional)
```

### Datenfluss

```
Benutzer-Input (Mausrad/Button)
        ↓
MapZoomController
        ↓
EventBus.map_zoom_changed
        ↓
┌───────┴───────┐
↓               ↓
ZoomLevelManager    MapLabelManager
↓               ↓
Layer-Fading    Label-Culling
```

## Kern-Komponenten

### 1. MapZoomController

**Pfad:** `scripts/ui/map/MapZoomController.gd`

**Verantwortlichkeiten:**
- Verarbeitet Mausrad-Input
- Verwaltet Zoom-Werte (0.25 - 4.0)
- Implementiert sanftes Zoomen (Interpolation)
- Berechnet Zoom-Pivot (Maus-Position, Zentrum, Selektion)
- Sendet Zoom-Events

**Konfiguration:**

```gdscript
const ZOOM_MIN: float = 0.25      # 25% - Maximales Herauszoomen
const ZOOM_MAX: float = 4.0       # 400% - Maximales Hineinzoomen
const ZOOM_DEFAULT: float = 1.0   # 100% - Standard

const ZOOM_STEP_MOUSE: float = 0.1      # Mausrad-Schritt
const ZOOM_STEP_BUTTON: float = 0.2     # Button-Schritt

const ZOOM_SMOOTHING: bool = true       # Sanftes Zoomen
const ZOOM_SMOOTH_SPEED: float = 8.0    # Interpolations-Geschwindigkeit
```

**Zoom-Pivot-Modi:**

| Modus | Beschreibung |
|-------|--------------|
| `CENTER` | Zoomt zur Karten-Mitte |
| `MOUSE` | Zoomt zur Maus-Position (Standard) |
| `SELECTION` | Zoomt zur Selektion |

**API:**

```gdscript
# Zoom-Steuerung
zoom_controller.zoom_in(0.2)
zoom_controller.zoom_out(0.2)
zoom_controller.set_zoom(1.5)
zoom_controller.reset_zoom()

# Zoom zu Bounds
zoom_controller.zoom_to_fit_bounds(min_pos, max_pos, padding)

# Getter
var current = zoom_controller.get_current_zoom()
var target = zoom_controller.get_target_zoom()
var progress = zoom_controller.get_zoom_progress()  # 0.0 - 1.0
var is_zooming = zoom_controller.is_zooming_active()
```

### 2. ZoomLevelManager

**Pfad:** `scripts/ui/map/ZoomLevelManager.gd`

**Verantwortlichkeiten:**
- Definiert Zoom-Schwellenwerte für Layer
- Implementiert sanftes Fading (Alpha-Modulation)
- Verwaltet LOD-Stufen (MACRO, OVERVIEW, NORMAL, DETAILED, MICRO)
- Berechnet Layer-Opacities
- Sendet LOD-Wechsel-Events

**LOD-Stufen:**

| Stufe | Zoom-Range | Sichtbare Layer | Beschreibung |
|-------|------------|-----------------|--------------|
| **MACRO** | 0.25 - 0.5 | Region | Nur große Regionen |
| **OVERVIEW** | 0.5 - 1.0 | Region + Nation | Regionale Übersicht |
| **NORMAL** | 1.0 - 2.0 | Nation + Province | Standard-Ansicht |
| **DETAILED** | 2.0 - 3.0 | Province + District | Detaillierte Ansicht |
| **MICRO** | 3.0 - 4.0 | Alle | Maximales Detail |

**Zoom-Schwellenwerte (Fading):**

```gdscript
class ZoomThreshold:
    var show_start: float   # Start Fade-in
    var show_full: float    # Voll sichtbar
    var hide_start: float   # Start Fade-out
    var hide_full: float    # Komplett unsichtbar

# Layer-Definitionen:
Region:   show_start=0.25, show_full=0.4,  hide_start=2.5,   hide_full=3.5
Nation:   show_start=0.4,  show_full=0.6,  hide_start=3.5,   hide_full=4.0
Province: show_start=0.7,  show_full=0.9,  hide_start=999.0, hide_full=999.0
District: show_start=1.5,  show_full=1.8,  hide_start=999.0, hide_full=999.0
```

**Bei Standard-Zoom (1.0):** Region, Nation und Province sind voll sichtbar, District ist unsichtbar.

**Fading-Visualisierung:**

```
Zoom:    0.0   0.5   1.0   1.5   2.0   2.5   3.0   3.5   4.0
         |-----|-----|-----|-----|-----|-----|-----|-----|
Region:  [=FADE=][====FULL====][==FADE==][hide]
Nation:        [=FADE=][========FULL========][==FADE==][h]
Province:         [=F=][========FULL=============]
District:                   [=F=][====FULL=======]
```

**API:**

```gdscript
# LOD-Update
zoom_level_manager.update_zoom(current_zoom)

# Getter
var level = zoom_level_manager.get_current_zoom_level()
var visible = zoom_level_manager.get_visible_layers()  # ["nation", "province"]
var opacity = zoom_level_manager.get_layer_opacity("province")  # 0.0 - 1.0

# Label-Prioritäten
var priorities = zoom_level_manager.get_label_priority_for_zoom(zoom)
# → {"region": 1, "nation": 2, "province": 3, "district": 0}
```

### 3. MapLabelManager

**Pfad:** `scripts/ui/map/MapLabelManager.gd`

**Verantwortlichkeiten:**
- Verhindert Label-Überlappungen
- Zeigt nur wichtige Labels basierend auf Zoom
- Implementiert Prioritäts-System
- Skaliert Font-Größen basierend auf Zoom
- Sanftes Label-Fading

**Algorithmus (Anti-Overlap):**

1. Sortiere Labels nach Priorität (höchste zuerst)
2. Platziere Labels nacheinander
3. Prüfe Überlappung mit bereits platzierten Labels
4. Bei Überlappung: Verstecke Label
5. Sonst: Zeige Label

**Prioritäts-System:**

| Zoom-Stufe | Region | Nation | Province | District |
|------------|--------|--------|----------|----------|
| MACRO      | 3      | 0      | 0        | 0        |
| OVERVIEW   | 2      | 3      | 0        | 0        |
| NORMAL     | 1      | 2      | 3        | 0        |
| DETAILED   | 0      | 1      | 2        | 3        |
| MICRO      | 1      | 1      | 2        | 3        |

**Font-Skalierung:**

```gdscript
# Bei kleinem Zoom: Größere Schrift relativ zur Karte
# Bei großem Zoom: Normale Schrift

if zoom < 1.0:
    scale_factor = 1.0 / zoom
else:
    scale_factor = 1.0

font_size = base_font_size * scale_factor
font_size = clamp(font_size, base_font_size, base_font_size * 2)
```

**API:**

```gdscript
# Update Labels
label_manager.update_labels(current_zoom)

# Manuelle Steuerung
label_manager.show_label("province", "province_001")
label_manager.hide_label("district", "district_042")
label_manager.set_label_priority_override("region", "region_001", 10)

# Getter
var is_visible = label_manager.is_label_visible("province_001")
var count = label_manager.get_visible_label_count()
var info = label_manager.get_label_info()
```

### 4. MapZoomUI

**Pfad:** `scripts/ui/map/MapZoomUI.gd`

**UI-Komponenten:**
- Zoom-In-Button (`+`)
- Zoom-Out-Button (`-`)
- Reset-Button
- Zoom-Slider (0.25 - 4.0)
- Zoom-Label (`Zoom: 100%`)

**Integration:**

```gdscript
# In MainUI.tscn oder MapScene:
var zoom_ui = MapZoomUI.new()
add_child(zoom_ui)
zoom_ui.initialize(map_controller)
zoom_ui.position = Vector2(20, 20)  # Obere linke Ecke
```

## EventBus-Signale

### Neue Signale

```gdscript
# === MAP ZOOM EVENTS ===
signal map_zoom_changed(current_zoom: float, target_zoom: float)
signal map_zoom_completed(final_zoom: float)
signal map_zoom_level_changed(new_level: int, old_level: int)
```

### Signal-Flow-Beispiel

```gdscript
# Benutzer scrollt Mausrad
MapZoomController._input() → zoom_in(0.1)
        ↓
EventBus.map_zoom_changed.emit(1.0, 1.1)
        ↓
MapController._on_zoom_changed()
        ↓
ZoomLevelManager.update_zoom(1.0)
MapLabelManager.update_labels(1.0)
        ↓
Layer-Opacity aktualisiert, Labels gefiltert
        ↓
EventBus.map_zoom_completed.emit(1.1)
```

## MapController Integration

### Initialisierung

```gdscript
func _ready() -> void:
    _initialize_zoom_system()
    # ... andere Initialisierungen

func _initialize_zoom_system() -> void:
    zoom_controller = MapZoomController.new()
    add_child(zoom_controller)

    zoom_level_manager = ZoomLevelManager.new()
    add_child(zoom_level_manager)

    label_manager = MapLabelManager.new()
    add_child(label_manager)
```

### Nach Map-Laden

```gdscript
func _load_map_data() -> void:
    # ... Lade Polygone und Labels

    # Initialisiere Zoom-Komponenten
    zoom_controller.initialize(self)
    zoom_level_manager.initialize(region_layer, nation_layer, province_layer, district_layer)
    label_manager.initialize(self, zoom_level_manager, region_labels, nation_labels, province_labels, district_labels)
```

### Public API

```gdscript
# Zoom-Steuerung
map_controller.zoom_in(0.2)
map_controller.zoom_out(0.2)
map_controller.set_zoom(1.5)
map_controller.reset_zoom()
map_controller.get_current_zoom()

# Zoom zu Territorium
map_controller.zoom_to_territory("province", "province_001", 2.0)
```

## Verwendungsbeispiele

### 1. Zoom zu Nation bei Klick

```gdscript
func _on_territory_clicked(territory_type: String, territory_id: String):
    if territory_type == "nation":
        map_controller.zoom_to_territory("nation", territory_id, 1.5)
```

### 2. Reagiere auf LOD-Wechsel

```gdscript
func _ready():
    EventBus.map_zoom_level_changed.connect(_on_lod_changed)

func _on_lod_changed(new_level: int, old_level: int):
    match new_level:
        ZoomLevelManager.ZoomLevel.MACRO:
            print("Weit herausgezoomt - zeige nur Regionen")
        ZoomLevelManager.ZoomLevel.DETAILED:
            print("Detaillierte Ansicht - zeige Distrikte")
```

### 3. Zeige immer wichtige Labels

```gdscript
# Hauptstadt-Label immer anzeigen
label_manager.set_label_priority_override("province", "capital_province", 999)
```

### 4. Zoom-Animation zu Selektion

```gdscript
func _on_territory_selected(territory_type: String, territory_id: String):
    # Sanft zu Territorium zoomen
    map_controller.zoom_to_territory(territory_type, territory_id, 2.5)
```

## Performance-Optimierungen

### Aktuelle Implementierung

- **Layer-Fading:** O(4) - Nur 4 Layer
- **Label-Culling:** O(n²) worst-case, typisch O(n log n) durch Sortierung
- **Zoom-Interpolation:** O(1) pro Frame

### Geplante Optimierungen (bei Bedarf)

1. **Spatial Hashing für Labels:**
   ```gdscript
   # Unterteile Bildschirm in Grid
   # Prüfe nur Labels in benachbarten Grid-Zellen
   # Reduziert Overlap-Checks von O(n²) auf O(n)
   ```

2. **Label-Pooling:**
   ```gdscript
   # Wiederverwendung von Label-Objekten
   # Reduziert Speicher-Allokationen
   ```

3. **Dirty-Flag für Label-Updates:**
   ```gdscript
   # Update nur wenn sich Zoom signifikant geändert hat
   if abs(last_zoom - current_zoom) > 0.05:
       label_manager.update_labels(current_zoom)
       last_zoom = current_zoom
   ```

## Konfiguration & Tuning

### Zoom-Geschwindigkeit anpassen

```gdscript
# In MapZoomController.gd:
const ZOOM_SMOOTH_SPEED: float = 8.0  # Höher = schneller
const ZOOM_STEP_MOUSE: float = 0.1    # Größer = größere Sprünge
```

### Fading-Geschwindigkeit anpassen

```gdscript
# In ZoomLevelManager.gd:
const FADE_SPEED: float = 5.0  # Höher = schnelleres Fading

# In MapLabelManager.gd:
const LABEL_FADE_SPEED: float = 6.0
```

### Schwellenwerte ändern

```gdscript
# In ZoomLevelManager._setup_thresholds():
thresholds["province"] = ZoomThreshold.new(
    0.8,    # show_start: Beginne Fade-in bei Zoom 0.8
    1.2,    # show_full: Voll sichtbar ab Zoom 1.2
    999.0,  # hide_start: Beginne Fade-out (nie)
    999.0   # hide_full: Komplett unsichtbar (nie)
)
```

### Label-Abstände anpassen

```gdscript
# In MapLabelManager.gd:
const LABEL_MIN_DISTANCE: float = 10.0  # Minimaler Abstand in Pixeln
```

## Bekannte Limitierungen

1. **Label-Overlap-Algorithmus:** O(n²) bei vielen Labels - könnte bei > 1000 Labels langsam werden
2. **Keine Label-Rotation:** Labels sind immer horizontal
3. **Keine Multi-Line-Labels:** Lange Namen werden abgeschnitten
4. **Fading linear:** Könnte mit Easing-Funktionen verbessert werden

## Erweiterungsmöglichkeiten

### 1. Zoom-zu-Position mit Animation

```gdscript
func zoom_to_world_position(world_pos: Vector2, target_zoom: float) -> void:
    var tween = create_tween()
    tween.tween_method(_interpolate_zoom_to_pos, current_zoom, target_zoom, 1.0)
```

### 2. Zoom-Presets

```gdscript
enum ZoomPreset {
    WORLD,      # 0.5x
    CONTINENT,  # 1.0x
    NATION,     # 2.0x
    CITY        # 3.0x
}

func apply_zoom_preset(preset: ZoomPreset) -> void:
    match preset:
        ZoomPreset.WORLD: set_zoom(0.5)
        ZoomPreset.NATION: set_zoom(2.0)
```

### 3. Smart-Zoom (Auto-LOD)

```gdscript
# Automatisch bester Zoom basierend auf Selektion
func auto_zoom_to_selection() -> void:
    match selected_territory.type:
        "region": set_zoom(0.6)
        "nation": set_zoom(1.2)
        "province": set_zoom(2.0)
        "district": set_zoom(3.0)
```

### 4. Minimap mit Zoom-Indikator

```gdscript
# Zeige aktuellen Viewport als Rechteck auf Minimap
func update_minimap_viewport() -> void:
    var viewport_rect = _get_viewport_rect_in_map_space()
    minimap.draw_viewport_indicator(viewport_rect)
```

## Testing

### Manuelle Tests

1. **Zoom-Range:** Teste Min/Max-Grenzen (0.25 / 4.0)
2. **Mausrad-Zoom:** Scrolle schnell → Smooth-Zoom sollte folgen
3. **LOD-Wechsel:** Zoome langsam 0.25 → 4.0 → Beobachte Layer-Fading
4. **Label-Culling:** Zoome heraus → Weniger Labels sichtbar
5. **Label-Overlap:** Verifiziere dass Labels nicht überlappen

### Debug-Commands

```gdscript
# In Debug-Console:
map_controller.zoom_controller.set_zoom_instant(0.5)
print(map_controller.zoom_level_manager.get_lod_info())
print(map_controller.label_manager.get_label_info())
```

## Changelog

### Version 1.0 (2025-10-21)
- Initiale Implementierung
- Stufenloses Zoomen (0.25 - 4.0)
- 5 LOD-Stufen mit sanftem Fading
- Intelligentes Label-Management
- Anti-Overlap-Algorithmus
- Zoom-UI mit Buttons und Slider
- EventBus-Integration
- Dokumentation

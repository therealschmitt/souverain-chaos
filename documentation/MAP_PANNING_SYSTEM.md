# Map Panning System

**Autor:** Claude Code
**Datum:** 2025-10-21
**Version:** 1.0

## Übersicht

Das Map Panning System ermöglicht das Verschieben der Kamera mit WASD-Tasten und rechter Maustaste. Das System implementiert intelligente Kamera-Grenzen, die sicherstellen, dass die Kamera niemals die Map-Grenzen verlässt, auch nicht in Kombination mit Zoomen.

## Architektur

### Komponente

**MapPanningController** (`scripts/ui/map/MapPanningController.gd`)

- Verarbeitet WASD-Tasteneingabe für kontinuierliches Panning
- Verarbeitet Rechte-Maustaste-Dragging für Maus-Panning
- Implementiert dynamische Bounds-Checking basierend auf Zoom
- Sendet Panning-Events über EventBus

### Integration

```
MapController
├── MapPanningController (Panning-Logik & Bounds)
├── MapZoomController (Zoom-Logik)
└── ... (andere Systeme)
```

## Steuerung

### WASD-Panning

**Tasten:**
- `W` / `↑`: Nach oben pannen
- `S` / `↓`: Nach unten pannen
- `A` / `←`: Nach links pannen
- `D` / `→`: Nach rechts pannen

**Eigenschaften:**
- Kontinuierliches Panning während Taste gedrückt
- Geschwindigkeit: 400 px/s
- Diagonales Pannen möglich (normalisierter Richtungsvektor)

### Maus-Panning

**Steuerung:**
1. Rechte Maustaste gedrückt halten
2. Maus bewegen
3. Karte folgt Maus-Bewegung
4. Rechte Maustaste loslassen

**Eigenschaften:**
- Direkte 1:1-Bewegung (Multiplier: 1.0)
- Sanftes Ausrollen nach Loslassen (Velocity-Dämpfung)
- Invertierte Bewegung (Karte bewegt sich, nicht Kamera)

## Kamera-Grenzen (Bounds)

### Dynamische Bounds

Die Kamera-Grenzen passen sich automatisch an den Zoom-Level an:

**Kleiner Zoom (Karte < Viewport):**
- Karte wird zentriert
- Panning deaktiviert in betreffender Achse

**Großer Zoom (Karte > Viewport):**
- Kamera darf nur bis zu Map-Rändern pannen
- Minimaler Abstand zu Rand: 50px (konfigurierbar)

### Bounds-Berechnung

```gdscript
var scaled_map_size = map_size * current_zoom

# Horizontale Bounds
if scaled_map_size.x < viewport_size.x:
    # Zentriere
    bounds_min.x = (viewport_size.x - scaled_map_size.x) / 2.0
    bounds_max.x = bounds_min.x
else:
    # Begrenze auf Ränder
    bounds_min.x = viewport_size.x - scaled_map_size.x - PADDING
    bounds_max.x = PADDING
```

### Bounds-Updates

Bounds werden automatisch aktualisiert bei:
- **Zoom-Änderungen:** `_on_zoom_changed()` → `update_bounds_for_zoom()`
- **Viewport-Resize:** (TODO: Implementierung bei Bedarf)

## Konfiguration

```gdscript
# In MapPanningController.gd

# Pan-Geschwindigkeiten
const PAN_SPEED_KEYBOARD: float = 400.0   # px/s für WASD
const PAN_SPEED_MOUSE: float = 1.0        # Multiplier für Maus

# Sanftes Panning
const SMOOTH_PANNING: bool = true
const PAN_SMOOTH_SPEED: float = 10.0      # Dämpfungs-Geschwindigkeit

# Bounds
const BOUNDS_PADDING: float = 50.0        # Abstand zu Map-Rand
```

## EventBus-Signale

### Neue Signale

```gdscript
# === MAP PANNING EVENTS ===
signal map_panning_started()              # Start Panning (Rechtsklick gedrückt)
signal map_panning_stopped()              # Stop Panning (Rechtsklick losgelassen)
signal map_panned(new_position: Vector2)  # Position geändert
```

## API

### MapPanningController

```gdscript
# Initialisierung
panning_controller.initialize(map_controller, map_size)

# Programmatisches Panning
panning_controller.pan_to_position(world_pos)
panning_controller.center_map()

# Bounds-Update
panning_controller.update_bounds_for_zoom(zoom)

# Steuerung
panning_controller.stop_panning()

# Getter
var is_panning = panning_controller.is_panning()
var bounds_min = panning_controller.get_bounds_min()
var bounds_max = panning_controller.get_bounds_max()
var info = panning_controller.get_panning_info()
```

### MapController (Public API)

```gdscript
# Panning
map_controller.pan_to_position(world_pos)
map_controller.center_map_view()
map_controller.get_panning_info()
```

## Verwendungsbeispiele

### 1. Pan zu Territory bei Klick

```gdscript
func _on_territory_clicked(territory_type: String, territory_id: String):
    var territory = GameState.provinces.get(territory_id)
    if territory:
        # Hole Zentrum des Territoriums
        var center = territory.center_position  # World-Koordinaten

        # Panne zu Zentrum
        map_controller.pan_to_position(center)
```

### 2. Kombiniertes Zoom & Pan zu Territory

```gdscript
func focus_territory(territory_type: String, territory_id: String):
    # Nutze existierende Funktion (macht beides)
    map_controller.zoom_to_territory(territory_type, territory_id, 2.0)
```

### 3. Reagiere auf Panning-Start

```gdscript
func _ready():
    EventBus.map_panning_started.connect(_on_panning_started)
    EventBus.map_panning_stopped.connect(_on_panning_stopped)

func _on_panning_started():
    # Verstecke UI während Panning
    ui_overlay.visible = false

func _on_panning_stopped():
    # Zeige UI wieder
    ui_overlay.visible = true
```

### 4. Debug: Zeige Bounds

```gdscript
func _draw():
    var bounds_min = map_controller.panning_controller.get_bounds_min()
    var bounds_max = map_controller.panning_controller.get_bounds_max()

    # Zeichne Bounds-Rechteck
    draw_rect(Rect2(bounds_min, bounds_max - bounds_min), Color.RED, false, 2.0)
```

## Interaktion mit Zoom-System

### Automatische Bounds-Anpassung

```
Benutzer zoomt
    ↓
MapZoomController.set_zoom()
    ↓
EventBus.map_zoom_changed.emit()
    ↓
MapController._on_zoom_changed()
    ↓
PanningController.update_bounds_for_zoom()
    ↓
Position wird auf neue Bounds geclamped
```

### Koordinierte Zoom & Pan Operationen

```gdscript
# In MapZoomController.zoom_to_fit_bounds():
func zoom_to_fit_bounds(bounds_min: Vector2, bounds_max: Vector2):
    # 1. Berechne benötigten Zoom
    var fit_zoom = calculate_fit_zoom(bounds_min, bounds_max)

    # 2. Setze Zoom
    set_zoom_instant(fit_zoom)

    # 3. Zentriere Bounds (Panning)
    var bounds_center = (bounds_min + bounds_max) / 2.0
    map_controller.position = viewport_center - bounds_center * fit_zoom

    # 4. Bounds werden automatisch durch Zoom-Event aktualisiert
```

## Performance

### Optimierungen

- **WASD-Panning:** O(1) pro Frame
- **Bounds-Checking:** O(1) - Einfache Clamp-Operation
- **Velocity-Dämpfung:** O(1) - Linear Interpolation

### Keine Performance-Probleme erwartet

Das Panning-System ist sehr leichtgewichtig und sollte selbst bei komplexen Maps keine Performance-Probleme verursachen.

## Bekannte Limitierungen

1. **Keine Trägheit:** Panning stoppt sofort wenn WASD losgelassen (nur Maus hat Velocity-Dämpfung)
2. **Feste Geschwindigkeit:** Pan-Geschwindigkeit ist konstant, unabhängig von Zoom
3. **Keine Edge-Scrolling:** Kein Panning durch Maus an Bildschirm-Rand

## Erweiterungsmöglichkeiten

### 1. Zoom-abhängige Pan-Geschwindigkeit

```gdscript
func _get_scaled_pan_speed() -> float:
    # Schnelleres Panning bei kleinem Zoom
    var zoom = map_controller.scale.x
    return PAN_SPEED_KEYBOARD / zoom
```

### 2. Edge-Scrolling

```gdscript
func _process(delta):
    var mouse_pos = get_viewport().get_mouse_position()
    var edge_zone = 50.0  # Pixel vom Rand

    if mouse_pos.x < edge_zone:
        _apply_pan(Vector2(PAN_SPEED_KEYBOARD * delta, 0))
    # ... weitere Ränder
```

### 3. Elastische Bounds (Rubber-Band-Effekt)

```gdscript
func _clamp_to_bounds(pos: Vector2) -> Vector2:
    var clamped = pos
    var overshoot = Vector2.ZERO

    # Erlaube Überschreiten mit Widerstand
    if pos.x < bounds_min.x:
        overshoot.x = pos.x - bounds_min.x
        clamped.x = bounds_min.x + overshoot.x * 0.2  # 20% Widerstand

    return clamped
```

### 4. Minimap-Panning

```gdscript
func _on_minimap_clicked(minimap_pos: Vector2):
    # Konvertiere Minimap-Position zu Map-Position
    var world_pos = minimap_to_world(minimap_pos)

    # Panne zu Position
    pan_to_position(world_pos)
```

## Testing

### Manuelle Tests

1. **WASD-Panning:** Bewege mit W/A/S/D → Karte bewegt sich
2. **Maus-Panning:** Rechtsklick + Ziehen → Karte folgt
3. **Bounds:** Panne zu allen Rändern → Stoppt an Grenzen
4. **Zoom + Pan:** Zoome rein/raus während Panning → Bounds passen sich an
5. **Zentrierte Karte:** Zoome weit raus → Karte zentriert, Panning deaktiviert

### Debug-Commands

```gdscript
# In Debug-Console:
print(map_controller.get_panning_info())
# → {is_panning: false, bounds_min: (100, 50), bounds_max: (800, 600), ...}

map_controller.center_map_view()
# → Zentriert Karte
```

## Changelog

### Version 1.0 (2025-10-21)
- Initiale Implementierung
- WASD-Panning mit 400 px/s
- Rechte-Maustaste-Dragging
- Dynamische Kamera-Grenzen
- Zoom-integrierte Bounds-Updates
- EventBus-Integration
- Velocity-Dämpfung für sanftes Ausrollen
- Dokumentation

# UI Layout Manager System

**Autor:** Claude Code
**Datum:** 2025-10-21
**Version:** 1.0

## Übersicht

Das UI Layout Manager System verwaltet automatisch die Positionierung von UI-Panels und verhindert Überlappungen mit existierenden UI-Elementen wie Menüleisten.

## Features

- ✅ Automatische Panel-Positionierung in 6 Anchor-Bereichen
- ✅ Intelligentes Stacking von Panels
- ✅ Reservierte Bereiche für Menüleisten
- ✅ Automatisches Re-Layout bei Viewport-Resize
- ✅ Prioritäts-basierte Positionierung
- ✅ Konfigurierbares Margin und Spacing

## Installation

### 1. Autoload Registrierung

Öffne `Project → Project Settings → Autoload` in Godot:

1. **Path:** `res://scripts/autoload/UILayoutManager.gd`
2. **Node Name:** `UILayoutManager`
3. **Enable** aktivieren
4. **Add** klicken

**Wichtig:** UILayoutManager sollte VOR anderen UI-Autoloads geladen werden.

### 2. Verifikation

Nach dem Neustart sollte im Output zu sehen sein:
```
UILayoutManager: Initialisiert (Viewport: 1920x1080)
```

## Anchor-Bereiche

```
┌─────────────────────────────────────────┐
│  [TOP_LEFT]  [TOP_CENTER]   [TOP_RIGHT] │ ← Reserved Top (60px)
│                                          │
│                                          │
│                                          │
│                                          │
│                                          │
│                                          │
│[BOTTOM_LEFT][BOTTOM_CENTER][BOTTOM_RIGHT]│ ← Reserved Bottom (60px)
└─────────────────────────────────────────┘
```

### AnchorArea Enum

```gdscript
enum AnchorArea {
    TOP_LEFT,        # 0
    TOP_RIGHT,       # 1
    BOTTOM_LEFT,     # 2
    BOTTOM_RIGHT,    # 3
    TOP_CENTER,      # 4
    BOTTOM_CENTER    # 5
}
```

## Konfiguration

```gdscript
# In UILayoutManager.gd

const DEFAULT_MARGIN: Vector2 = Vector2(10, 10)  # Margin zum Viewport-Rand
const DEFAULT_SPACING: float = 10.0              # Spacing zwischen Panels
const RESERVED_TOP: float = 60.0                 # Reserviert für Menüleiste oben
const RESERVED_BOTTOM: float = 60.0              # Reserviert für Menüleiste unten
```

## Verwendung

### Panel Registrieren

```gdscript
# In deinem UI-Panel (_ready() oder später):

# Hole Referenz zum UILayoutManager
var layout_manager = get_node("/root/UILayoutManager")

if layout_manager:
    # Registriere Panel
    layout_manager.register_panel(
        self,                          # Control-Node
        UILayoutManager.AnchorArea.TOP_LEFT,  # Anchor-Bereich
        100                            # Priorität (höher = näher am Anchor)
    )
```

### Panel Deregistrieren

```gdscript
# Beim Löschen des Panels
func _exit_tree():
    var layout_manager = get_node_or_null("/root/UILayoutManager")
    if layout_manager:
        layout_manager.unregister_panel(self)
```

### Automatisches Update Forcieren

```gdscript
# Wenn Panel-Größe sich ändert
var layout_manager = get_node("/root/UILayoutManager")
layout_manager.update_all_panel_positions()
```

## Beispiel: Debug-Panel

```gdscript
extends Control

func _ready():
    _setup_ui()
    _register_with_layout_manager()

func _register_with_layout_manager():
    var layout_manager = get_node_or_null("/root/UILayoutManager")
    if layout_manager:
        layout_manager.register_panel(
            self,
            UILayoutManager.AnchorArea.TOP_LEFT,
            100  # Hohe Priorität
        )
        print("Panel mit UILayoutManager registriert")
    else:
        # Fallback: Manuelle Positionierung
        position = Vector2(10, 70)
```

## Stacking-Verhalten

### TOP_LEFT / TOP_RIGHT / TOP_CENTER
Panels werden **vertikal nach unten** gestackt:

```
┌──────────┐
│ Panel 1  │ ← Priority 100
├──────────┤
│ Panel 2  │ ← Priority 50
├──────────┤
│ Panel 3  │ ← Priority 10
└──────────┘
```

### BOTTOM_LEFT / BOTTOM_RIGHT / BOTTOM_CENTER
Panels werden **vertikal nach oben** gestackt:

```
┌──────────┐
│ Panel 3  │ ← Priority 10
├──────────┤
│ Panel 2  │ ← Priority 50
├──────────┤
│ Panel 1  │ ← Priority 100
└──────────┘
```

## Prioritäten

- **Höhere Priorität = Näher am Anchor-Punkt**
- Standard-Priorität: `0`
- Empfohlene Ranges:
  - **100+** - Wichtige Debug/System-Panels
  - **50-99** - Gameplay-UI
  - **0-49** - Weniger wichtige UI

## Reservierte Bereiche

### Top-Bereich (Menüleiste)

- **Höhe:** 60px (Standard)
- **Zweck:** Platz für obere Menüleiste
- **Panels beginnen bei:** Y = 70px (Margin 10px + Reserved 60px)

### Bottom-Bereich (Statusleiste)

- **Höhe:** 60px (Standard)
- **Zweck:** Platz für untere Statusleiste
- **Panels enden bei:** Y = Viewport.height - 70px

## Viewport-Resize

Der Layout Manager reagiert automatisch auf Viewport-Resize:

```
Viewport resized
    ↓
UILayoutManager._on_viewport_resized()
    ↓
update_all_panel_positions()
    ↓
Alle Panels neu positioniert
```

## API-Referenz

### register_panel()

```gdscript
func register_panel(panel: Control, anchor_area: AnchorArea, priority: int = 0) -> void
```

Registriert ein Panel für automatisches Layout.

**Parameter:**
- `panel` - Das Control-Node
- `anchor_area` - Anchor-Bereich (TOP_LEFT, TOP_RIGHT, etc.)
- `priority` - Priorität (höher = näher am Anchor)

### unregister_panel()

```gdscript
func unregister_panel(panel: Control) -> void
```

Entfernt ein Panel aus dem Layout-Management.

### update_all_panel_positions()

```gdscript
func update_all_panel_positions() -> void
```

Aktualisiert Positionen aller registrierten Panels.

### get_panels_in_area()

```gdscript
func get_panels_in_area(anchor_area: AnchorArea) -> Array
```

Gibt alle Panels in einem Anchor-Bereich zurück.

### print_layout_info()

```gdscript
func print_layout_info() -> void
```

Gibt Layout-Informationen für Debugging aus.

## Debug

### Layout-Info ausgeben

```gdscript
# In der Debug-Console oder via Code:
var layout_manager = get_node("/root/UILayoutManager")
layout_manager.print_layout_info()
```

**Output:**
```
=== UILayoutManager Info ===
Viewport: 1920x1080
Reserved Top: 60 px, Bottom: 60 px
Registered Panels: 3
  TOP_LEFT: 2 panels
    - MapDebugUI (pos: 10, 70)
    - PerformancePanel (pos: 10, 200)
  TOP_RIGHT: 1 panels
    - MinimapPanel (pos: 1700, 70)
============================
```

## Best Practices

### 1. Immer als Top-Level setzen

```gdscript
func _ready():
    set_as_top_level(true)  # Unabhängig von Parent-Transformationen
    _register_with_layout_manager()
```

### 2. Fallback-Positionierung

```gdscript
func _register_with_layout_manager():
    var layout_manager = get_node_or_null("/root/UILayoutManager")
    if layout_manager:
        layout_manager.register_panel(self, UILayoutManager.AnchorArea.TOP_LEFT, 100)
    else:
        # Fallback: Manuelle Positionierung
        position = Vector2(10, 70)
```

### 3. Cleanup beim Löschen

```gdscript
func _exit_tree():
    var layout_manager = get_node_or_null("/root/UILayoutManager")
    if layout_manager:
        layout_manager.unregister_panel(self)
```

### 4. Mouse-Filter setzen

```gdscript
# Damit Panel Maus-Events nicht blockiert
mouse_filter = Control.MOUSE_FILTER_IGNORE
```

## Integration mit existierenden Panels

### MapDebugUI

```gdscript
# In MapDebugUI.gd bereits integriert:
func _register_with_layout_manager():
    var layout_manager = get_node_or_null("/root/UILayoutManager")
    if layout_manager:
        layout_manager.register_panel(self, 0, 100)  # TOP_LEFT, Priority 100
```

### Weitere Panels

Nutze das gleiche Pattern für andere UI-Panels:

```gdscript
# MinimapPanel.gd
func _ready():
    set_as_top_level(true)
    _setup_ui()

    var layout_manager = get_node_or_null("/root/UILayoutManager")
    if layout_manager:
        layout_manager.register_panel(
            self,
            UILayoutManager.AnchorArea.BOTTOM_RIGHT,
            50
        )
```

## Troubleshooting

### Panel wird nicht positioniert

1. Prüfe ob UILayoutManager als Autoload registriert ist
2. Prüfe Console-Output nach `"Mit UILayoutManager registriert"`
3. Prüfe ob Panel `set_as_top_level(true)` hat
4. Rufe `layout_manager.print_layout_info()` auf

### Panel überlappt Menüleiste

1. Prüfe `RESERVED_TOP` / `RESERVED_BOTTOM` Werte
2. Passe Werte in `UILayoutManager.gd` an
3. Rufe `update_all_panel_positions()` auf

### Panel springt bei Resize

1. Stelle sicher dass Panel `set_as_top_level(true)` hat
2. Prüfe ob `custom_minimum_size` gesetzt ist
3. Vermeide manuelle `position`-Änderungen nach Registrierung

## Erweiterungsmöglichkeiten

### 1. Animiertes Positionieren

```gdscript
func _position_panels_in_area(panels: Array, anchor_area: AnchorArea):
    for info in panels:
        var target_pos = _calculate_anchor_position(...)

        # Animate statt sofort setzen
        var tween = create_tween()
        tween.tween_property(info.panel, "position", target_pos, 0.3)
```

### 2. Drag-and-Drop Repositionierung

```gdscript
# Erlaube Benutzer Panels zu verschieben
func _on_panel_dragged(panel: Control, new_anchor: AnchorArea):
    # Ändere Anchor-Bereich
    for info in registered_panels:
        if info.panel == panel:
            info.anchor_area = new_anchor
            update_all_panel_positions()
```

### 3. Gespeicherte Layouts

```gdscript
func save_layout(save_path: String):
    var layout_data = {}
    for info in registered_panels:
        layout_data[info.panel.name] = {
            "anchor": info.anchor_area,
            "priority": info.priority
        }
    # Speichere als JSON...
```

## Changelog

### Version 1.0 (2025-10-21)
- Initiale Implementierung
- 6 Anchor-Bereiche
- Prioritäts-System
- Automatisches Viewport-Resize-Handling
- Reservierte Bereiche für Menüleisten
- MapDebugUI Integration
- Dokumentation

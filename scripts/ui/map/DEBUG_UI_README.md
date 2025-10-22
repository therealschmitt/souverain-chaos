# Map Debug UI

**Version:** 1.0
**Datum:** 2025-10-21

## Übersicht

Die MapDebugUI zeigt wichtige Debug-Informationen über das Karten-System in Echtzeit an. Sie wird standardmäßig in der oberen linken Ecke angezeigt.

## Aktivierung/Deaktivierung

### Toggle mit F3

Drücke `F3` während des Spiels um die Debug-UI ein-/auszublenden.

### Über MapController

```gdscript
# Im Inspector (Export-Variable)
@export var show_debug_ui: bool = true  # Aktiviert Debug-UI

# Programmatisch
map_controller.toggle_debug_ui()        # Toggle
map_controller.show_debug_ui_panel()    # Zeige
map_controller.hide_debug_ui_panel()    # Verstecke
```

## Angezeigte Informationen

### ZOOM
- **Maßstab:** Aktueller Zoom-Faktor (z.B. 1.50x = 150%)
- **Target:** Ziel-Zoom-Level (bei animiertem Zoom)
- **Range:** Minimaler und maximaler Zoom
- **Progress:** Zoom-Progress zwischen Min und Max (0-100%)

### LOD (Level of Detail)
- **Level:** Aktuelles LOD-Level (MACRO, OVERVIEW, NORMAL, DETAILED, MICRO)
- **Visible Layers:** Liste der aktuell sichtbaren Layer

### PANNING
- **Position:** Aktuelle Kamera-Position in Pixel
- **Is Panning:** Ob gerade gepannt wird (Ja/Nein)

### LABELS
- **Visible:** Anzahl sichtbarer Labels
- **Total:** Gesamtanzahl Labels

### CONTROLS
Zeigt aktive Steuerelemente an:
- `[F3]` Toggle Debug
- `[Mausrad]` Zoom
- `[WASD]` Pan
- `[RMB]` Drag

## Konfiguration

### Position ändern

```gdscript
# In MapDebugUI.gd oder via Code:
debug_ui.set_position_preset("top_left")     # Oben links (Standard)
debug_ui.set_position_preset("top_right")    # Oben rechts
debug_ui.set_position_preset("bottom_left")  # Unten links
debug_ui.set_position_preset("bottom_right") # Unten rechts
```

### Update-Intervall ändern

```gdscript
# In MapDebugUI.gd
const UPDATE_INTERVAL: float = 0.1  # Update alle 100ms (Standard)
```

## Beispiel-Ausgabe

```
=== ZOOM ===
  Maßstab: 1.50x (150%)
  Target: 1.50x | Range: 0.25 - 4.00x
  Progress: 33%

=== LOD ===
  Level: NORMAL
  Visible Layers: region, nation, province

=== PANNING ===
  Position: (512, 384)
  Is Panning: Nein

=== LABELS ===
  Visible: 42 / 156

[F3] Toggle Debug | [Mausrad] Zoom | [WASD] Pan | [RMB] Drag
```

## Performance

Die Debug-UI aktualisiert sich alle 100ms und hat minimalen Performance-Impact:
- Update-Frequenz: 10 Hz
- CPU-Last: < 0.1%
- Keine Auswirkung auf Gameplay

## Verwendung für Debugging

### Zoom-Probleme diagnostizieren

Wenn Zoom nicht funktioniert:
1. Prüfe "Maßstab" in Debug-UI
2. Prüfe ob "Target" sich ändert
3. Prüfe "Range" - Zoom könnte an Grenzen sein

### LOD-Probleme diagnostizieren

Wenn Layer nicht erscheinen:
1. Prüfe "LOD Level"
2. Prüfe "Visible Layers"
3. Vergleiche mit erwarteten Layern für aktuellen Zoom

### Panning-Probleme diagnostizieren

Wenn Panning nicht funktioniert:
1. Prüfe "Position" - ändert sie sich?
2. Prüfe "Is Panning" - wird es erkannt?
3. Prüfe Bounds im Code (via `get_panning_info()`)

### Label-Probleme diagnostizieren

Wenn Labels fehlen:
1. Prüfe "Visible / Total" Verhältnis
2. Zu wenig visible → Anti-Overlap-Algorithmus filtert zu viel
3. Zu viele visible → Overlap-Detection funktioniert nicht

## Erweiterung

Weitere Debug-Informationen hinzufügen:

```gdscript
# In MapDebugUI._update_debug_info():

# === CUSTOM INFO ===
var custom_info = _get_custom_info()
info_text += "\n=== CUSTOM ===\n"
info_text += "  Value: %s\n" % custom_info.value

func _get_custom_info() -> Dictionary:
    return {"value": "test"}
```

## Deaktivierung für Release

```gdscript
# Im MapController-Inspector:
show_debug_ui = false  # Deaktiviert Debug-UI komplett

# Oder via Code:
if OS.is_debug_build():
    show_debug_ui = true
else:
    show_debug_ui = false
```

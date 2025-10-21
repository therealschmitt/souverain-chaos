# Map Rendering & Zoom System

## Übersicht

Das Karten-Rendering-System wurde für optimale Skalierbarkeit und Performance entwickelt, ähnlich wie bei Crusader Kings oder Europa Universalis.

## Vektor-basiertes Rendering

### Polygon2D mit Anti-Aliasing
Alle Territorien werden als **Vektor-Polygone** gerendert (nicht als Bitmaps):

```gdscript
polygon.antialiased = true
polygon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
```

**Vorteile:**
- ✅ Keine Unschärfe beim Zoomen
- ✅ Scharfe Kanten bei jedem Zoom-Level
- ✅ Geringe Speichernutzung
- ✅ Flüssige Skalierung

### Line2D für Grenzen
Grenzen werden als separate Line2D-Objekte mit Anti-Aliasing gerendert:

```gdscript
line.antialiased = true
line.width = 4.0  // Regionen: 4px, Nationen: 3px, Provinzen: 2px, Distrikte: 1px
```

## Kontinuierliches Zoom-System

### Zoom-Level-Range
```gdscript
const ZOOM_MIN = 0.3        # Minimaler Zoom
const ZOOM_MAX = 8.0        # Maximaler Zoom
const ZOOM_DEFAULT = 1.0    # Standard-Zoom
```

### Zoom-Schwellwerte für Layer-Visibility

**Layer-Sichtbarkeit:**
- `ZOOM_SHOW_REGIONS = 0.3` - Regionen ab Zoom 0.3
- `ZOOM_SHOW_NATIONS = 0.8` - Nationen ab Zoom 0.8
- `ZOOM_SHOW_PROVINCES = 2.0` - Provinzen ab Zoom 2.0
- `ZOOM_SHOW_DISTRICTS = 5.0` - Distrikte ab Zoom 5.0

**Label-Sichtbarkeit:**
- `ZOOM_SHOW_REGION_LABELS = 0.3`
- `ZOOM_SHOW_NATION_LABELS = 1.0`
- `ZOOM_SHOW_PROVINCE_LABELS = 2.5`
- `ZOOM_SHOW_DISTRICT_LABELS = 6.0`

### Dynamische Layer-Anpassung

```gdscript
func _update_layer_visibility() -> void:
    region_layer.visible = (current_zoom >= ZOOM_SHOW_REGIONS)
    nation_layer.visible = (current_zoom >= ZOOM_SHOW_NATIONS)
    province_layer.visible = (current_zoom >= ZOOM_SHOW_PROVINCES)
    district_layer.visible = (current_zoom >= ZOOM_SHOW_DISTRICTS)
```

Ähnlich wie Crusader Kings: Je nach Zoom-Level werden automatisch die passenden Layer ein-/ausgeblendet.

## Zoom-Verhalten

### Zoom-In/Out
```gdscript
# Kontinuierlich mit Mausrad
zoom_in(0.3)   # +0.3 Zoom
zoom_out(0.3)  # -0.3 Zoom

# Rechtsklick zum Rauszoomen
zoom_out(0.5)
```

### Smooth Zoom-Animation
```gdscript
# Smooth Interpolation statt abrupter Änderung
current_zoom = lerp(current_zoom, target_zoom, delta * camera_animation_speed)
scale = Vector2(current_zoom, current_zoom)
```

## Korrekte Polygon-Klickboxen

### Problem (vorher)
Klickboxen stimmten nicht mit sichtbaren Polygonen überein, weil die Transform nicht berücksichtigt wurde.

### Lösung (jetzt)
```gdscript
func _get_territory_at_position(screen_pos: Vector2) -> Dictionary:
    # Konvertiere Screen-Position zu World-Position
    var world_pos = _screen_to_world(screen_pos)

    # Prüfe Polygon in World-Koordinaten
    if _point_in_polygon(world_pos, polygon.polygon):
        return {"type": "province", "id": province_id}

func _screen_to_world(screen_pos: Vector2) -> Vector2:
    # Invertiere Transform: (screen_pos - position) / scale
    return (screen_pos - position) / scale.x
```

**Vorteile:**
- ✅ Klickboxen exakt auf Polygon-Grenzen
- ✅ Funktioniert bei jedem Zoom-Level
- ✅ Berücksichtigt Kamera-Position und Zoom

## Label-System

### CanvasLayer für Labels
Labels werden in einem separaten CanvasLayer gerendert (nicht transformiert):

```gdscript
label_layer = CanvasLayer.new()
label_layer.layer = 1  # Über anderen UI-Elementen
```

### Dynamische Label-Positionierung
```gdscript
func _update_label_positions() -> void:
    for label in region_labels.values():
        var polygon = label.get_meta("polygon")
        var center_world = _get_polygon_center(polygon)

        # Transformiere World → Screen
        var center_screen = _world_to_screen(center_world)
        label.position = center_screen
```

Labels werden **jedes Frame** aktualisiert, um immer an der korrekten Bildschirm-Position zu sein.

## Layer-Hierarchie

### Render-Reihenfolge (unten nach oben)
1. **region_layer** (Node2D) - Größte Polygone
2. **nation_layer** (Node2D) - Mittlere Polygone
3. **province_layer** (Node2D) - Kleine Polygone
4. **district_layer** (Node2D) - Kleinste Polygone
5. **label_layer** (CanvasLayer) - Labels (nicht skaliert)

### Klick-Priorität (umgekehrte Reihenfolge)
Kleinste sichtbare Einheit hat Priorität:
1. Distrikte (wenn sichtbar)
2. Provinzen (wenn sichtbar)
3. Nationen (wenn sichtbar)
4. Regionen (wenn sichtbar)

## Performance-Optimierung

### Layer-Culling
Nicht sichtbare Layer werden komplett ausgeblendet:
```gdscript
if not district_layer.visible:
    # Keine Klick-Prüfung, kein Rendering
    pass
```

### Smooth Interpolation
Zoom und Position werden interpoliert statt abrupt gesetzt:
```gdscript
position = position.lerp(target_position, delta * camera_animation_speed)
current_zoom = lerp(current_zoom, target_zoom, delta * camera_animation_speed)
```

**Vorteile:**
- Flüssige Animationen
- Keine abrupten Sprünge
- Natürliches "Gefühl" wie CK3/EU4

### Conditional Updates
Layer-Visibility wird nur bei Zoom-Änderung aktualisiert:
```gdscript
if abs(current_zoom - target_zoom) > 0.01:
    _update_layer_visibility()
```

## Zoom-Level-Beispiele

| Zoom-Level | Sichtbare Layer | Beschreibung |
|------------|-----------------|--------------|
| 0.3 - 0.8 | Regionen | Weltkarte-Ansicht |
| 0.8 - 2.0 | Regionen + Nationen | Kontinente mit Ländern |
| 2.0 - 5.0 | Nationen + Provinzen | Länder-Detail-Ansicht |
| 5.0 - 8.0 | Provinzen + Distrikte | Maximale Detail-Ansicht |

## Vergleich mit Paradox-Spielen

### Ähnlichkeiten zu Crusader Kings 3 / Europa Universalis 4
- ✅ Kontinuierlicher Zoom (statt fester Stufen)
- ✅ Dynamische Layer-Ein-/Ausblendung basierend auf Zoom
- ✅ Vektor-Rendering für scharfe Grenzen
- ✅ Smooth Zoom-Animationen
- ✅ Korrekte Klickboxen bei jedem Zoom-Level

### Unterschiede
- Simpler (4 Layer statt 6+)
- Keine Terrain-Textures (nur Farben)
- Einfachere Label-Logik (keine Zoom-basierte Schriftgröße)

## Technische Details

### Transform-Kette
```
Screen → World: (screen_pos - position) / scale
World → Screen: world_pos * scale + position
```

### Anti-Aliasing-Strategie
- Polygon2D: `antialiased = true`
- Line2D: `antialiased = true`
- Texture-Filter: `LINEAR` (statt NEAREST)

### Label-Rendering
- Labels in separatem CanvasLayer (keine Transform-Skalierung)
- Position wird jedes Frame aktualisiert
- Zentrum via Polygon-Schwerpunkt berechnet

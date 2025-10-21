# Map Coordinate System & Metrics

## Übersicht

MapController.gd implementiert ein vollständiges Koordinatensystem mit Metriken für geografische Berechnungen.

## Konstanten

### Kartengröße
- `MAP_WIDTH = 2000.0` - Pixel-Breite der Weltkarte
- `MAP_HEIGHT = 1200.0` - Pixel-Höhe der Weltkarte

### Maßstab
- `PIXELS_PER_KM = 0.5` - Ein Pixel entspricht 2 km
- `KM_PER_PIXEL = 2.0` - Ein Kilometer entspricht 0.5 Pixel
- **Weltkarten-Maßstab**: 2000px × 2km = 4000km Breite, 2400km Höhe

### Geografisches Koordinatensystem
- `GEO_LON_MIN = -180.0` - Westlichster Längengrad
- `GEO_LON_MAX = 180.0` - Östlichster Längengrad
- `GEO_LAT_MIN = -90.0` - Südlichster Breitengrad
- `GEO_LAT_MAX = 90.0` - Nördlichster Breitengrad

## API-Funktionen

### Koordinaten-Konvertierung

#### `pixel_to_geo(pixel_pos: Vector2) -> Vector2`
Konvertiert Pixel-Koordinaten zu geografischen Koordinaten.

**Parameter:**
- `pixel_pos`: Position in Pixel (x, y)

**Rückgabe:** `Vector2(longitude, latitude)` in Grad

**Beispiel:**
```gdscript
var pixel_pos = Vector2(1000, 600)  # Kartenmitte
var geo_coords = map_controller.pixel_to_geo(pixel_pos)
# Ergebnis: Vector2(0.0, 0.0) - Äquator, Greenwich
```

#### `geo_to_pixel(geo_pos: Vector2) -> Vector2`
Konvertiert geografische Koordinaten zu Pixel-Koordinaten.

**Parameter:**
- `geo_pos`: `Vector2(longitude, latitude)` in Grad

**Rückgabe:** Position in Pixel (x, y)

**Beispiel:**
```gdscript
var geo_pos = Vector2(45.0, 30.0)  # 45° Ost, 30° Nord
var pixel_pos = map_controller.geo_to_pixel(geo_pos)
```

### Entfernungs- und Flächenberechnungen

#### `calculate_distance_km(pixel_pos1: Vector2, pixel_pos2: Vector2) -> float`
Berechnet Entfernung zwischen zwei Pixel-Positionen in Kilometern.

**Parameter:**
- `pixel_pos1`, `pixel_pos2`: Positionen in Pixel

**Rückgabe:** Entfernung in Kilometern

**Beispiel:**
```gdscript
var berlin = Vector2(1100, 450)
var paris = Vector2(1050, 480)
var distance = map_controller.calculate_distance_km(berlin, paris)
# Ergebnis: ~70km (auf der vereinfachten Karte)
```

#### `calculate_area_km2(polygon: PackedVector2Array) -> float`
Berechnet Fläche eines Polygons in Quadratkilometern (Shoelace-Formel).

**Parameter:**
- `polygon`: Array von Polygon-Punkten in Pixel-Koordinaten

**Rückgabe:** Fläche in km²

**Beispiel:**
```gdscript
var province = GameState.get_province(province_id)
var area = map_controller.calculate_area_km2(province.boundary_polygon)
print("Provinzfläche: %.0f km²" % area)
```

## Kartensteuerung

### Edge Scrolling
- **Margin**: 50px vom Bildschirmrand
- **Max Speed**: 800 Pixel/s
- **Beschleunigung**: 0.25s von 0 bis max Speed (sanfter Start)

### Middle Mouse Button Panning
- Mittlere Maustaste gedrückt halten zum Verschieben
- Cursor ändert sich zu CURSOR_DRAG
- Keine Beschleunigung, direkte 1:1 Bewegung

### Scroll-Grenzen
- Verhindert Scrolling über Kartengrenzen hinaus
- Berücksichtigt aktuellen Zoom-Level
- Grenzen passen sich dynamisch an Scale an

## Verwendungsbeispiele

### Provinzfläche berechnen
```gdscript
func display_province_stats(province_id: String) -> void:
    var province = GameState.get_province(province_id)
    var area_km2 = map_controller.calculate_area_km2(province.boundary_polygon)
    var center = map_controller._get_polygon_center(province.boundary_polygon)
    var geo_coords = map_controller.pixel_to_geo(center)

    print("Provinz: %s" % province.name)
    print("Fläche: %.0f km²" % area_km2)
    print("Koordinaten: %.2f° Ost, %.2f° Nord" % [geo_coords.x, geo_coords.y])
```

### Entfernung zwischen Hauptstädten
```gdscript
func calculate_capital_distance(nation1_id: String, nation2_id: String) -> float:
    var nation1 = GameState.nations[nation1_id]
    var nation2 = GameState.nations[nation2_id]

    var capital1_pos = nation1.capital_position  # Vector2 in Pixel
    var capital2_pos = nation2.capital_position

    return map_controller.calculate_distance_km(capital1_pos, capital2_pos)
```

### Grenze zwischen Provinzen berechnen
```gdscript
func calculate_border_length(province1: Province, province2: Province) -> float:
    # Finde gemeinsame Grenzpunkte
    var border_points = []
    for point in province1.boundary_polygon:
        if point in province2.boundary_polygon:
            border_points.append(point)

    # Berechne Gesamtlänge
    var total_length_km = 0.0
    for i in range(border_points.size() - 1):
        total_length_km += map_controller.calculate_distance_km(
            border_points[i],
            border_points[i + 1]
        )

    return total_length_km
```

## Hinweise

- Das Koordinatensystem ist eine **vereinfachte Projektion** (keine Mercator/echte geografische Projektion)
- Entfernungen sind **lineare Approximationen** (keine Großkreis-Berechnung)
- Für die Spielmechanik ausreichend genau
- Bei Bedarf können echte geografische Projektionen implementiert werden

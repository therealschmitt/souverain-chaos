# Map Coordinate System

**Version:** 2.0 (MapScale-basiert)
**Datum:** 2025-10-21
**Status:** Implementiert

## Übersicht

Das Karten-Koordinatensystem von "Souverän" nutzt ein einheitliches, kartesisches System für die gesamte Weltkarte mit klaren Maßstäben und Konvertierungsfunktionen basierend auf der **MapScale Resource**.

## Architektur

### Drei Koordinatensysteme

Das System arbeitet mit drei verschiedenen Koordinatenräumen:

1. **Screen Coordinates** (Bildschirmkoordinaten)
   - Position im Viewport/Fenster
   - Abhängig von Zoom, Pan, Fensterposition
   - Beispiel: Mausklick bei `(1024, 768)`

2. **Map Pixel Coordinates** (Karten-Pixel-Koordinaten)
   - Absolute Position auf der Karten-Textur
   - Unabhängig von Viewport-Transformation
   - Bereich: `X[0, 2000]`, `Y[0, 1200]` (Standardkarte)

3. **World Coordinates** (Weltkoordinaten in km)
   - Physikalische Position in der Spielwelt
   - Einheit: Kilometer
   - Bereich: `X[0, 20000]`, `Y[0, 12000]` (Standardkarte = 20.000 × 12.000 km)

### Konvertierungskette

```
Screen ←→ MapPixel ←→ World
  ↓         ↓           ↓
(1024,768) (500,300)  (5000,3000 km)
```

## MapScale Resource

Die zentrale Ressource für alle Koordinaten- und Maßstabs-Berechnungen.

### Eigenschaften

```gdscript
@export var map_width_pixels: float = 2000.0    # Karte in Pixeln
@export var map_height_pixels: float = 1200.0

@export var map_width_km: float = 20000.0       # Welt in Kilometern
@export var map_height_km: float = 12000.0
```

### Berechnete Werte

```gdscript
var km_per_pixel_x: float      # ~10.0 km/px
var km_per_pixel_y: float      # ~10.0 km/px
var pixels_per_km_x: float     # ~0.1 px/km
var pixels_per_km_y: float     # ~0.1 px/km
var km_per_pixel: float        # Durchschnitt
```

### Resource-Dateien

- **Standard:** `data/map_scales/default_map_scale.tres`
  - 2000×1200 px = 20.000×12.000 km
  - ~10 km pro Pixel

- **Zukünftig möglich:**
  - `large_world_scale.tres` (40.000×24.000 km)
  - `detailed_region_scale.tres` (5.000×3.000 km)

## Koordinaten-Konvertierung

### MapScale API

```gdscript
# Pixel ↔ World
func pixel_to_world(pixel_pos: Vector2) -> Vector2
func world_to_pixel(world_pos: Vector2) -> Vector2

func pixel_array_to_world(pixel_array: PackedVector2Array) -> PackedVector2Array
func world_array_to_pixel(world_array: PackedVector2Array) -> PackedVector2Array
```

### MapController API (mit Viewport-Transformation)

```gdscript
# Private: Screen ↔ MapPixel (berücksichtigt Zoom/Pan)
func _screen_to_map_pixel(screen_pos: Vector2) -> Vector2
func _map_pixel_to_screen(map_pixel_pos: Vector2) -> Vector2

# Private: Screen ↔ World (komplette Kette)
func _screen_to_world(screen_pos: Vector2) -> Vector2
func _world_to_screen(world_pos: Vector2) -> Vector2

# Public: MapPixel ↔ World (ohne Viewport)
func pixel_to_world(pixel_pos: Vector2) -> Vector2
func world_to_pixel(world_pos: Vector2) -> Vector2
```

### Beispiel: Mausklick → Weltkoordinaten

```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        # Screen → MapPixel → World
        var screen_pos = event.position
        var map_pixel = _screen_to_map_pixel(screen_pos)
        var world_pos = map_scale.pixel_to_world(map_pixel)

        print("Klick bei %s km" % world_pos)
```

## Distanz-Berechnungen

### API

```gdscript
# MapScale
func calculate_distance_km(world_pos1: Vector2, world_pos2: Vector2) -> float
func calculate_distance_km_from_pixels(pixel_pos1: Vector2, pixel_pos2: Vector2) -> float

# MapController (Wrapper)
func calculate_distance_km(world_pos1: Vector2, world_pos2: Vector2) -> float
func calculate_distance_km_from_pixels(pixel_pos1: Vector2, pixel_pos2: Vector2) -> float
```

### Beispiele

```gdscript
# Distanz zwischen zwei Hauptstädten (World Coords)
var berlin = Vector2(8500, 5200)
var paris = Vector2(7200, 5800)
var distance = map_scale.calculate_distance_km(berlin, paris)
print("Berlin → Paris: %.0f km" % distance)  # ~1350 km

# Distanz zwischen zwei Polygonzentren (Pixel Coords)
var province_a_center = Vector2(500, 300)
var province_b_center = Vector2(800, 600)
var distance_km = map_scale.calculate_distance_km_from_pixels(
    province_a_center, province_b_center
)
```

## Flächen-Berechnungen

### API

```gdscript
# MapScale
func calculate_polygon_area_km2(world_polygon: PackedVector2Array) -> float
func calculate_polygon_area_km2_from_pixels(pixel_polygon: PackedVector2Array) -> float

# MapController (Wrapper)
func calculate_area_km2(world_polygon: PackedVector2Array) -> float
func calculate_area_km2_from_pixels(pixel_polygon: PackedVector2Array) -> float
```

### Shoelace-Formel

Die Fläche wird mit der Shoelace-Formel (Gaußsche Trapezformel) berechnet:

```
A = 1/2 * |Σ(x_i * y_(i+1) - x_(i+1) * y_i)|
```

### Beispiele

```gdscript
# Berechne Fläche einer Nation
var nation = GameState.nations["ger"]
var area = map_scale.calculate_polygon_area_km2_from_pixels(nation.boundary_polygon)
print("Deutschland: %.0f km²" % area)  # Sollte ~357.000 km² ergeben

# Berechne Bevölkerungsdichte
var province = GameState.provinces["ger_prov_0"]
if province.area_km2 > 0:
    var density = province.population / province.area_km2
    print("Dichte: %.1f Einwohner/km²" % density)
```

## Entity Area Storage

Alle politischen Entitäten speichern ihre Fläche:

```gdscript
# Region.gd, Nation.gd, Province.gd, District.gd
var area_km2: float = 0.0  # Fläche in Quadratkilometern
```

### Automatische Berechnung

Die Fläche wird während der Kartengenerierung automatisch berechnet:

```gdscript
# MapDataGenerator.gd
region.area_km2 = map_scale.calculate_polygon_area_km2_from_pixels(region.boundary_polygon)
nation.area_km2 = map_scale.calculate_polygon_area_km2_from_pixels(nation.boundary_polygon)
province.area_km2 = map_scale.calculate_polygon_area_km2_from_pixels(province.boundary_polygon)
district.area_km2 = map_scale.calculate_polygon_area_km2_from_pixels(district.boundary_polygon)

# Bei Distrikten: Aktualisiere Bevölkerungsdichte
if district.area_km2 > 0.0:
    district.density = district.population / district.area_km2
```

## Testing

Validierungstests in `scripts/tests/test_map_coordinates.gd`:

```bash
# In Godot: Öffne scenes/tests/TestMapCoordinates.tscn und drücke F6
```

### Test-Kategorien

1. **Koordinaten-Konvertierungen** - Round-trip Tests
2. **Distanz-Berechnungen** - Bekannte Dimensionen
3. **Flächen-Berechnungen** - Rechtecke, Dreiecke, Weltkarte
4. **Grenz-Validierung** - Gültige/ungültige Positionen, Clamping
5. **Real-World Szenarien** - Provinzen, Nationen, Hauptstadt-Distanzen

## Performance-Überlegungen

### Optimierungen

1. **Cached Calculations:**
   ```gdscript
   # area_km2 wird einmal bei Generierung berechnet
   province.area_km2 = map_scale.calculate_polygon_area_km2_from_pixels(polygon)
   ```

2. **Lazy Loading:**
   ```gdscript
   static var map_scale: MapScale  # Nur einmal geladen
   ```

## Zukünftige Erweiterungen

### Multi-Scale Maps

```gdscript
var world_scale = load("res://data/map_scales/world_scale.tres")
var region_scale = load("res://data/map_scales/region_scale.tres")
```

### Geografische Projektionen

Aktuell: **Simple Equirectangular** (lineare X/Y-Zuordnung)

Zukünftig möglich: Mercator, Lambert, Stereographic

## Referenzen

- **MapScale.gd**: `scripts/map/MapScale.gd`
- **MapController.gd**: `scripts/ui/map/MapController.gd`
- **MapDataGenerator.gd**: `scripts/procedural/MapDataGenerator.gd`
- **Entity Classes**: `scripts/simulation/world/*.gd`
- **Tests**: `scripts/tests/test_map_coordinates.gd`

## Changelog

**v2.0 (2025-10-21)** - MapScale Resource System
- ✅ MapScale Resource-Klasse implementiert
- ✅ Koordinaten-Konvertierungen (Screen ↔ MapPixel ↔ World)
- ✅ Distanz-Berechnungen (km)
- ✅ Flächen-Berechnungen (km²)
- ✅ Entity area_km2 Felder hinzugefügt
- ✅ MapDataGenerator area-Berechnungen integriert
- ✅ Test-Suite erstellt

**v1.0 (vorher)** - Hardcoded Constants
- Einfache Pixel/Geo-Konvertierungen
- Hardcoded MAP_WIDTH/HEIGHT/PIXELS_PER_KM

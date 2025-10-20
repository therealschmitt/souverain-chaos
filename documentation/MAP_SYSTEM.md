# Karten-System

## Übersicht

Das Karten-System besteht aus 5 Zoomstufen und ermöglicht die Darstellung einer vollständigen fiktiven Weltkarte mit territorialer Hierarchie.

## Territoriale Hierarchie

Die Welt ist in 5 Ebenen unterteilt:

1. **Welt** (Zoom 1): Gesamtansicht, nur Hintergrund
2. **Regionen** (Zoom 2): Geopolitische Großregionen (z.B. "Westliche Ozeanstaaten", "Mittelkontinent")
3. **Nationen** (Zoom 3): Einzelne Staaten innerhalb von Regionen
4. **Provinzen** (Zoom 4): Verwaltungsbezirke innerhalb von Nationen
5. **Distrikte** (Zoom 5): Landkreise und Großstädte innerhalb von Provinzen

## Implementierte Klassen

### Entity-Klassen

- **Region** (`scripts/simulation/world/Region.gd`)
  - Repräsentiert geopolitische Großregionen
  - Enthält: `nations` (Array von Nation-IDs), `boundary_polygon`, `color`, `total_gdp`, `total_population`

- **Nation** (`scripts/simulation/world/Nation.gd`)
  - Erweitert um: `region_id`, `color`, `boundary_polygon`

- **Province** (`scripts/simulation/world/Province.gd`)
  - Erweitert um: `districts` (Array von District-IDs), `boundary_polygon`, `color`

- **District** (`scripts/simulation/world/District.gd`)
  - Neue Klasse für Landkreise/Städte
  - Enthält: `is_urban`, `population`, `density`, `infrastructure_quality`, `has_university`, `has_major_factory`, `has_military_base`

### Karten-System

- **MapDataGenerator** (`scripts/procedural/MapDataGenerator.gd`)
  - Generiert vollständige Weltkarte mit allen territorialen Ebenen
  - Erstellt fiktive Welt mit:
    - 3 Regionen (Westliche Ozeanstaaten, Mittelkontinent, Südliche Steppen)
    - 5 Nationen (Thalassia, Azuria, Nordreich, Centralia, Südkonföderation)
    - ~20 Provinzen (4 pro Nation)
    - ~80 Distrikte (4 pro Provinz)
  - Generiert Polygon-Daten für alle Territorien

- **MapController** (`scripts/ui/map/MapController.gd`)
  - Hauptklasse für Karten-Darstellung
  - Verwaltet 5 Zoomstufen mit automatischem Layer-Switching
  - Funktionen:
    - Polygon-Rendering für alle territorialen Ebenen
    - Klick-Erkennung mit Point-in-Polygon-Tests
    - Hover-Effekte und Selektion
    - Zoom-Steuerung (0.5x - 3.0x) mit Mausrad
    - Kamera-Verschiebung per Drag
    - Automatischer Zoom-Level-Wechsel basierend auf Skalierung

### UI-Panels

- **RegionPanel** (`scripts/ui/panels/RegionPanel.gd`)
  - Zeigt Regionsinformationen: Bevölkerung, BIP, Stabilität, enthaltene Nationen

- **NationPanel** (`scripts/ui/panels/NationPanel.gd`)
  - Zeigt Nationsinformationen (bereits existierend, kompatibel mit neuem System)

- **ProvincePanel** (`scripts/ui/panels/ProvincePanel.gd`)
  - Zeigt Provinzinformationen (bereits existierend)

- **DistrictPanel** (`scripts/ui/panels/DistrictPanel.gd`)
  - Zeigt Distrikt/Stadt-Informationen: Bevölkerung, Dichte, Infrastruktur, Besonderheiten

## Zoom-System

### Automatischer Level-Wechsel

Der MapController wechselt automatisch den Zoom-Level basierend auf der Skalierung:

- **Zoom < 1.0**: Welt-Level (nur Hintergrund)
- **Zoom 1.0 - 1.5**: Regionen-Level
- **Zoom 1.5 - 2.0**: Nationen-Level
- **Zoom 2.0 - 2.5**: Provinzen-Level
- **Zoom > 2.5**: Distrikte-Level

### Layer-Sichtbarkeit

Jeder Zoom-Level zeigt nur die relevanten Layer:

```gdscript
region_layer.visible = current_zoom_level >= ZoomLevel.REGION
nation_layer.visible = current_zoom_level >= ZoomLevel.NATION
province_layer.visible = current_zoom_level >= ZoomLevel.PROVINCE
district_layer.visible = current_zoom_level >= ZoomLevel.DISTRICT
label_layer.visible = current_zoom_level == ZoomLevel.DISTRICT
```

## Interaktion

### Klick-Erkennung

Der MapController verwendet Point-in-Polygon-Tests um zu bestimmen, welches Territorium angeklickt wurde:

```gdscript
func _get_territory_at_position(pos: Vector2) -> Dictionary:
    # Prüft von kleinster zu größter Einheit (höchste Priorität zuerst)
    # 1. Distrikte (wenn Zoom 5)
    # 2. Provinzen (wenn Zoom 4+)
    # 3. Nationen (wenn Zoom 3+)
    # 4. Regionen (wenn Zoom 2+)
```

### Signals

Der MapController emittiert folgende Signals:

- `territory_clicked(territory_type: String, territory_id: String)`
- `territory_hovered(territory_type: String, territory_id: String)`

Diese werden mit EventBus verknüpft:

- `EventBus.province_selected.emit(province_id)` bei Provinz-Klick
- TODO: `EventBus.nation_selected`, `EventBus.region_selected`, etc.

### Kamera-Steuerung

- **Zoom**: Mausrad, Zoom-In/Out-Buttons
- **Pan**: Karte ziehen mit linker Maustaste
- **Focus**: `focus_on_territory(type, id)` zentriert die Karte auf ein Territorium

## Integration mit MainUI

### Erforderliche Schritte in Godot Editor:

1. **MapController zur MainUI.tscn hinzufügen:**
   - Öffne `scenes/ui/MainUI.tscn`
   - Füge einen Node2D unter `MapViewport/SubViewport/MapContainer` hinzu
   - Attach Script: `scripts/ui/map/MapController.gd`
   - Name: `MapController`

2. **Info-Panels hinzufügen:**
   - Erstelle PanelContainer-Nodes für:
     - RegionPanel (attach `scripts/ui/panels/RegionPanel.gd`)
     - DistrictPanel (attach `scripts/ui/panels/DistrictPanel.gd`)
   - Positioniere sie im `UILayer` (z.B. rechts neben der Karte)

3. **Verbindungen in MainUIController:**
   - Füge Referenzen zu den Panels hinzu:
     ```gdscript
     @onready var map_controller := $MapViewport/SubViewport/MapContainer/MapController
     @onready var region_panel := $UILayer/RegionPanel
     @onready var district_panel := $UILayer/DistrictPanel
     ```

   - Verbinde MapController-Signals:
     ```gdscript
     map_controller.territory_clicked.connect(_on_territory_clicked)
     ```

   - Handler implementieren:
     ```gdscript
     func _on_territory_clicked(territory_type: String, territory_id: String) -> void:
         match territory_type:
             "region":
                 region_panel.show_region(territory_id)
             "nation":
                 nation_panel.set_displayed_nation(territory_id)
             "province":
                 province_panel.show_province(territory_id)
             "district":
                 district_panel.show_district(territory_id)
     ```

4. **Zoom-Controls anpassen:**
   - Zoom-Buttons sollen `map_controller.set_zoom_scale()` aufrufen:
     ```gdscript
     func _on_zoom_in() -> void:
         if map_controller:
             map_controller.set_zoom_scale(map_controller.zoom_scale + 0.2)

     func _on_zoom_out() -> void:
         if map_controller:
             map_controller.set_zoom_scale(map_controller.zoom_scale - 0.2)
     ```

## GameState-Erweiterungen

GameState wurde erweitert um:

```gdscript
var regions: Dictionary = {}  # region_id -> Region
var districts: Dictionary = {}  # district_id -> District

func get_region(id: String) -> Region
func get_district(id: String) -> District
```

## WorldGenerator-Integration

`WorldGenerator.generate_test_world()` wurde aktualisiert:

- Nutzt jetzt `MapDataGenerator.generate_full_map()`
- Registriert Regionen, Nationen, Provinzen und Distrikte in GameState
- Generiert vollständige Polygon-Daten für alle Territorien

## Fiktive Weltkarte

Die generierte Welt enthält:

### Regionen

1. **Westliche Ozeanstaaten** (Blau)
   - Maritime Demokratien
   - Nationen: Thalassia (Spieler), Azuria

2. **Mittelkontinent** (Braun)
   - Große Landmächte
   - Nationen: Nordreich, (Centralia verschoben)

3. **Südliche Steppen** (Gelb-Braun)
   - Autoritäre Regime
   - Nationen: Südkonföderation, Centralia

### Nationen

- **Thalassische Republik** (Spieler): Demokratie, 45 Mio Einwohner, BIP $500 Mrd
- **Azurianische Föderation**: Bundesrepublik, 32 Mio, BIP $350 Mrd
- **Nordreich**: Konstitutionelle Monarchie, 28 Mio, BIP $300 Mrd
- **Kaiserreich Centralia**: Absolute Monarchie, 38 Mio, BIP $280 Mrd
- **Südkonföderation**: Militärjunta, 25 Mio, BIP $180 Mrd

## Visuelle Gestaltung

### Farben

- **Regionen**: Große Farbblöcke (Blau, Braun, Gelb-Braun)
- **Nationen**: Farbvariationen innerhalb der Region-Farben
- **Provinzen**: Leicht aufgehellte Varianten der Nationsfarbe
- **Distrikte**: Leicht abgedunkelte Provinzfarbe

### Grenzen

- **Nationen**: Schwarze Linie, 2px
- **Provinzen**: Dunkelgraue Linie, 1.5px
- **Distrikte**: Hellgraue Linie, 1px

### Labels

- Nur bei Zoom-Level 5 (Distrikte) sichtbar
- Zeigen Namen von Großstädten

## Performance-Optimierungen

- **Layer-System**: Nur sichtbare Layer werden gerendert
- **Point-in-Polygon**: Nur für aktuellen Zoom-Level berechnet
- **Lazy Loading**: Polygone werden einmalig bei _ready() erstellt
- **z_index**: Layer-Reihenfolge für korrekte Überlappung

## TODO

- [ ] EventBus-Signale für `region_selected`, `nation_selected`, `district_selected` hinzufügen
- [ ] Smooth Camera Scrolling/Zooming mit Tweens
- [ ] Provinz-/Distrikt-Namen als Labels auf der Karte
- [ ] Mini-Map für Übersicht
- [ ] Map Modes (Political, Terrain, Economic, Military)
- [ ] Bessere Polygon-Formen (nicht nur Rechtecke)
- [ ] Procedural Terrain-Textures für Hintergrund
- [ ] Flüsse, Gebirge, Küstenlinien als Overlays
- [ ] Hauptstädte mit Icons markieren
- [ ] Armeen/Flotten auf der Karte anzeigen

## Verwendung

### Karte initialisieren

Die Karte wird automatisch beim Spielstart initialisiert:

1. `GameInitializer` ruft `WorldGenerator.generate_test_world()` auf
2. `WorldGenerator` nutzt `MapDataGenerator.generate_full_map()`
3. Alle Territorien werden in GameState registriert
4. `MapController._load_map_data()` erstellt Polygon2D-Nodes für alle Territorien

### Territorium auswählen

```gdscript
# Via Klick auf Karte
map_controller.territory_clicked.connect(func(type, id):
    print("Angeklickt: %s %s" % [type, id])
)

# Programmatisch
map_controller.focus_on_territory("nation", "thalassia")
```

### Zoom-Level ändern

```gdscript
# Manuell
map_controller.set_zoom_level(MapController.ZoomLevel.PROVINCE)

# Via Skalierung (automatischer Level-Wechsel)
map_controller.set_zoom_scale(2.0)
```

## Dateien

### Neue Dateien

- `scripts/simulation/world/Region.gd`
- `scripts/simulation/world/District.gd`
- `scripts/procedural/MapDataGenerator.gd`
- `scripts/ui/map/MapController.gd` (komplett neu geschrieben)
- `scripts/ui/panels/RegionPanel.gd`
- `scripts/ui/panels/DistrictPanel.gd`
- `documentation/MAP_SYSTEM.md` (diese Datei)

### Geänderte Dateien

- `scripts/simulation/world/Nation.gd` (+ region_id, color, boundary_polygon)
- `scripts/simulation/world/Province.gd` (+ districts, boundary_polygon, color)
- `autoload/GameState.gd` (+ regions, districts, get_region(), get_district())
- `scripts/procedural/WorldGenerator.gd` (nutzt jetzt MapDataGenerator)

## Kompatibilität

Das neue Karten-System ist vollständig kompatibel mit dem bestehenden Simulation-System:

- Nationen, Provinzen und Charaktere funktionieren wie bisher
- EventBus-Integration bleibt bestehen
- Bestehende Panels (NationPanel, ProvincePanel) können weiterhin verwendet werden
- SaveManager muss erweitert werden um Regions und Districts zu speichern (TODO)

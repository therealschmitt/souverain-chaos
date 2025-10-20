# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"Souverän" is a grand strategy simulation game built with **Godot 4.5** using GDScript. Simulates nations, provinces, characters, and interconnected systems with historical memory and emergent narratives.

- **Version**: Alpha 0.2
- **Engine**: Godot 4.5 (Forward Plus)
- **Main Scene**: `scenes/ui/MainUI.tscn`
- **Language**: GDScript with German UI text

## Running the Game

Open in Godot 4.5 editor and press **F5**.

## Core Architecture Principles

1. **Data-Logic Separation (CRITICAL)**: ALL game content (event text, stats, names) goes in `data/templates/*.json`, NOT in GDScript. Code contains only algorithms and logic.
2. **Signal-Driven Communication**: All inter-system communication via EventBus
3. **Resource-Based Serialization**: Entities extend `Resource` for save/load
4. **Level-of-Detail Simulation**: World adjusts simulation granularity based on player relevance
5. **Historical Memory**: Entities maintain biographical/historical records

## Data-Logic Separation

**Data → `data/templates/*.json`**:
- Nation/character/province stats, names, descriptions
- Event text, options, effect values (`data/templates/events/gameplay_events.json`)
- Terrain-resource mapping (`data/templates/terrain/terrain_resources.json`)
- Name generation rules (`data/templates/naming/*.json`)
- UI strings (eventually move to `data/localization/`)

**Code → `scripts/*.gd`**:
- Algorithms, formulas, game loops
- JSON loading/parsing, signal handling
- Constants (MAP_WIDTH, enums)

**✅ Data-Logic Separation Status**:
- ✅ `EventManager.gd`: All 7 events now loaded from `data/templates/events/gameplay_events.json`
- ✅ `MapDataGenerator.gd`: Terrain rules loaded from `data/templates/terrain/terrain_resources.json`
- ✅ `MapDataGenerator.gd`: Name generation loaded from `data/templates/naming/*.json`

## Autoload Singletons (Load Order Matters)

1. **EventBus** - Signal hub for all communication
2. **GameState** - Central state repository (`nations`, `provinces`, `characters` dicts)
3. **TimeManager** - Event queue with auto-speed adjustment based on next scheduled event
4. **HistoricalContext** - Historical memory (formative eras, historical events, game events)
5. **EventManager** - Gameplay events with choices/effects (loads from `data/templates/events/`)
6. **GameInitializer** - World generation orchestrator (loads last)
7. **SaveManager** - Complete save/load system (JSON format)

## Core Entities

**World** (`scripts/simulation/world/World.gd`)
- Container for all entities with LOD simulation (detailed/simplified/background)

**5-Level Geographic Hierarchy**:
1. World (2000x1200 map)
2. Region (`Region.gd`) - Loaded from `regions.json`
3. Nation (`Nation.gd`) - Loaded from `nations.json` (economy, military, diplomacy)
4. Province (`Province.gd`) - Generated via Voronoi (terrain, resources, population)
5. District (`District.gd`) - Generated via Voronoi (urban/rural)

**Character** (`scripts/simulation/entities/Character.gd`)
- Personality (Big Five + extensions), ideology (3-axis), skills, biography, relationships

## Procedural Generation

**MapDataGenerator** (`scripts/procedural/MapDataGenerator.gd`)
- Loads regions/nations from `data/templates/maps/*.json`
- Loads terrain rules from `data/templates/terrain/terrain_resources.json`
- Loads naming rules from `data/templates/naming/*.json`
- Generates provinces/districts via Voronoi subdivision
- Uses `PolygonGenerator` for organic borders

**PolygonGenerator** (`scripts/procedural/PolygonGenerator.gd`)
- `generate_voronoi_subdivision()` - Subdivides parent polygon into N regions
- Lloyd's relaxation for natural borders

## Common Patterns

### Access Entities via GameState
```gdscript
var player_nation = GameState.get_player_nation()
var character = GameState.get_character(character_id)
```

### Connect to EventBus
```gdscript
func _ready():
    EventBus.day_passed.connect(_on_day_passed)
```

### Schedule Events
```gdscript
TimeManager.schedule_event(
    {"type": "minister_report", "message": "..."},
    24.0,  # hours from now
    1      # priority: 0=low, 1=normal, 2=high
)
```

### Load JSON Templates
```gdscript
static func _load_json_file(file_path: String) -> Dictionary:
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file: return {}
    var json = JSON.new()
    if json.parse(file.get_as_text()) != OK: return {}
    file.close()
    return json.get_data()
```

## When Adding New Systems

1. **Ask: Is this data or logic?** → Data goes in JSON, logic in GDScript
2. Register new signals in EventBus
3. Store persistent state in GameState
4. Update SaveManager for serialization
5. Use German for UI text ("Berater", "Militär", "Wirtschaft")
6. Create documentation in `documentation/` directory (NOT project root)

## Key Implementation Notes

- **Always** access entities via GameState dictionaries (by ID), never direct references
- **Emit signals** through EventBus only (no direct connections)
- **Respect LOD modes**: detailed (player nation), simplified (distant), background (irrelevant)
- UI text in German; eventually move to `data/localization/de.json`
- Characters age/die on Jan 1st annually
- Use `add_biography_event()` for character life events
- Economic crises trigger when `unemployment > 20%`

## Design Documents

- `documentation/Historical_Memory_System.md` - Historical memory design
- `documentation/Staatsführungs_Sandbox_Konzept.md` - Full game design

## JSON Template Structure

```
data/templates/
├── events/
│   └── gameplay_events.json       # All gameplay events with options/effects
├── maps/
│   ├── regions.json                # Region definitions
│   └── nations.json                # Nation definitions
├── terrain/
│   └── terrain_resources.json      # Terrain types and resource rules
└── naming/
    ├── province_names.json         # Province name generation rules
    └── district_names.json         # District name generation rules
```

## Next Priority TODOs

1. Move UI strings to `data/localization/de.json`
2. Create tech tree definition in `data/templates/technology/tech_tree.json`
3. Create character trait templates in `data/templates/characters/traits.json`

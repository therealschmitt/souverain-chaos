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

## Architecture: MVC Pattern

The project follows a **Model-View-Controller (MVC)** architecture for clean separation of concerns:

### Directory Structure

```
scripts/
├── core/                       # Core Systems (Autoloads/Singletons)
│   ├── EventBus.gd            # Signal hub for all communication
│   ├── GameState.gd           # Central state repository
│   ├── TimeManager.gd         # Time/event queue management
│   ├── HistoricalContext.gd   # Historical memory
│   ├── EventManager.gd        # Gameplay events system
│   ├── GameInitializer.gd     # World generation orchestrator
│   └── SaveManager.gd         # Save/load system
│
├── models/                     # MODEL - Data Layer
│   ├── entities/              # Playable entities
│   │   └── Character.gd       # Character with personality/skills
│   ├── world/                 # Geographic hierarchy
│   │   ├── World.gd           # World container
│   │   ├── Region.gd          # Regions (zoom level 2)
│   │   ├── Nation.gd          # Nations with economy/diplomacy
│   │   ├── Province.gd        # Provinces (zoom level 4)
│   │   └── District.gd        # Districts (zoom level 5)
│   └── resources/             # Configuration resources
│       └── MapScale.gd        # Coordinate scaling
│
├── controllers/                # CONTROLLER - Logic Layer
│   ├── ui/                    # UI logic
│   │   ├── MainUIController.gd    # Main UI coordinator
│   │   └── UILayoutManager.gd     # Panel layout management
│   ├── map/                   # Map interaction logic
│   │   ├── MapController.gd           # Main map controller
│   │   ├── MapInteractionLayer.gd    # Click/hover handling
│   │   ├── MapZoomController.gd      # Zoom management
│   │   ├── MapPanningController.gd   # Camera panning
│   │   └── ZoomLevelManager.gd       # Level-of-detail management
│   └── procedural/            # Procedural generation
│       ├── WorldGenerator.gd          # World generation orchestrator
│       ├── MapDataGenerator.gd       # Map data from templates
│       └── PolygonGenerator.gd       # Polygon generation (Voronoi)
│
├── views/                      # VIEW - Presentation Layer
│   ├── ui/                    # UI components
│   │   ├── panels/            # Info panels
│   │   │   ├── BasePanel.gd
│   │   │   ├── CharacterPanel.gd
│   │   │   ├── NationPanel.gd
│   │   │   ├── ProvincePanel.gd
│   │   │   ├── RegionPanel.gd
│   │   │   └── DistrictPanel.gd
│   │   ├── dialogs/           # Dialogs
│   │   │   ├── EventDialog.gd
│   │   │   ├── MainMenu.gd
│   │   │   └── SaveLoadMenu.gd
│   │   └── widgets/           # UI widgets
│   │       └── EventNotificationSystem.gd
│   └── map/                   # Map visualization
│       ├── PolygonRenderer.gd         # Polygon rendering
│       ├── MapLabelManager.gd        # Map labels
│       ├── MapZoomUI.gd              # Zoom UI elements
│       ├── MapDebugUI.gd             # Debug UI
│       ├── RenderingDebugger.gd      # Debug visualization
│       └── RenderingConfigExamples.gd # Rendering examples
│
└── tests/                      # Test scripts
    └── test_map_coordinates.gd
```

## Core Architecture Principles

1. **Data-Logic Separation (CRITICAL)**: ALL game content (event text, stats, names) goes in `data/templates/*.json`, NOT in GDScript. Code contains only algorithms and logic.
2. **Signal-Driven Communication**: All inter-system communication via EventBus (in `scripts/core/`)
3. **Resource-Based Serialization**: Entities extend `Resource` for save/load
4. **Level-of-Detail Simulation**: World adjusts simulation granularity based on player relevance
5. **Historical Memory**: Entities maintain biographical/historical records
6. **MVC Pattern**: Strict separation between Models (data), Views (UI), and Controllers (logic)

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
- ✅ `EventManager.gd`: All events loaded from `data/templates/events/gameplay_events.json`
- ✅ `MapDataGenerator.gd`: Terrain rules loaded from `data/templates/terrain/terrain_resources.json`
- ✅ `MapDataGenerator.gd`: Name generation loaded from `data/templates/naming/*.json`

## Autoload Singletons (Load Order Matters)

All autoloads are now in `scripts/core/`:

1. **EventBus** (`scripts/core/EventBus.gd`) - Signal hub for all communication
2. **GameState** (`scripts/core/GameState.gd`) - Central state repository (`nations`, `provinces`, `characters` dicts)
3. **UILayoutManager** (`scripts/controllers/ui/UILayoutManager.gd`) - Panel layout management
4. **TimeManager** (`scripts/core/TimeManager.gd`) - Event queue with auto-speed adjustment
5. **HistoricalContext** (`scripts/core/HistoricalContext.gd`) - Historical memory (formative eras, historical events, game events)
6. **EventManager** (`scripts/core/EventManager.gd`) - Gameplay events with choices/effects
7. **GameInitializer** (`scripts/core/GameInitializer.gd`) - World generation orchestrator
8. **SaveManager** (`scripts/core/SaveManager.gd`) - Complete save/load system

## MVC Component Responsibilities

### Models (`scripts/models/`)
- **Purpose**: Pure data classes, no logic
- **Extends**: `Resource` for serialization
- **Examples**: `Character.gd`, `Nation.gd`, `Province.gd`
- **Communication**: Accessed via GameState, never directly referenced

### Views (`scripts/views/`)
- **Purpose**: Display data, capture user input
- **Never**: Directly modify GameState
- **Examples**: UI panels, dialogs, map rendering components
- **Communication**: Listen to EventBus signals, display data from GameState

### Controllers (`scripts/controllers/`)
- **Purpose**: Game logic, state management, user input processing
- **Examples**: Map controllers, procedural generators, UI controllers
- **Communication**: Listen to EventBus, modify GameState, emit signals

### Core (`scripts/core/`)
- **Purpose**: Global systems (singletons)
- **Examples**: EventBus, GameState, TimeManager
- **Communication**: Provide services to all other layers

## Common Patterns

### Access Entities via GameState
```gdscript
var player_nation = GameState.get_player_nation()
var character = GameState.get_character(character_id)
var province = GameState.get_province(province_id)
```

### Connect to EventBus
```gdscript
func _ready():
    EventBus.day_passed.connect(_on_day_passed)
    EventBus.province_clicked.connect(_on_province_clicked)
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

1. **Determine MVC Category**: Is this a Model (data), View (UI), or Controller (logic)?
2. **Place in correct directory**:
   - Models → `scripts/models/`
   - Views → `scripts/views/`
   - Controllers → `scripts/controllers/`
   - Core systems → `scripts/core/`
3. Register new signals in EventBus (`scripts/core/EventBus.gd`)
4. Store persistent state in GameState (`scripts/core/GameState.gd`)
5. Update SaveManager for serialization (`scripts/core/SaveManager.gd`)
6. Use German for UI text ("Berater", "Militär", "Wirtschaft")
7. Create documentation in `documentation/` directory (NOT project root)

## Key Implementation Notes

- **Always** access entities via GameState dictionaries (by ID), never direct references
- **Emit signals** through EventBus only (no direct connections between systems)
- **Respect LOD modes**: detailed (player nation), simplified (distant), background (irrelevant)
- UI text in German; eventually move to `data/localization/de.json`
- Characters age/die on Jan 1st annually
- Use `add_biography_event()` for character life events
- Economic crises trigger when `unemployment > 20%`

## 5-Level Geographic Hierarchy (Models)

1. **World** (`scripts/models/world/World.gd`) - Top-level container
2. **Region** (`scripts/models/world/Region.gd`) - Large geographic regions (zoom level 2)
3. **Nation** (`scripts/models/world/Nation.gd`) - Countries with economy/military/diplomacy (zoom level 3)
4. **Province** (`scripts/models/world/Province.gd`) - States/provinces (zoom level 4)
5. **District** (`scripts/models/world/District.gd`) - Cities/districts (zoom level 5)

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

## MVC Benefits

The new MVC structure provides:
- **Clear Separation**: Each component has a single, well-defined responsibility
- **Easier Testing**: Models, Views, and Controllers can be tested independently
- **Better Maintainability**: Changes in one layer don't cascade to others
- **Improved Scalability**: New features can be added without affecting existing code
- **Team-Friendly**: Multiple developers can work on different layers simultaneously

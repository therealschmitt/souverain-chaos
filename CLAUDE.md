# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"Souverän" (also known as "Sovereign Chaos") is a grand strategy simulation game built with **Godot 4.5** using GDScript. The game simulates nations, provinces, characters, and interconnected systems (economy, politics, military, diplomacy, and a "reality_bending" mechanic) with emphasis on historical memory and emergent narratives.

**Tagline**: *"Regiere. Entscheide. Verändere die Realität."* ("Rule. Decide. Change Reality.")

- **Version**: Alpha 0.1
- **Engine**: Godot 4.5 (Forward Plus renderer)
- **Main Scene**: `scenes/ui/MainUI.tscn`
- **Language**: GDScript with German UI text

## Core Design Philosophy

### Unique Features
- **No fixed option system**: Actions constructed through parameter combinations
- **Reality Bending mechanics**: Supernatural abilities alongside realistic simulation
- **Procedural world generation**: Persistent causality and historical memory
- **Deep real-time simulation**: Millions of simulated actors
- **No moral limits**: But realistic consequences

### Key Architectural Principles
1. **Signal-Driven Communication**: All inter-system communication via EventBus prevents tight coupling
2. **Level-of-Detail Simulation**: World dynamically adjusts simulation granularity based on player relevance
3. **Historical Memory**: Entities maintain biographical/historical records for emergent storytelling
4. **Data-Driven Design**: Templates in `data/templates/` for procedural generation
5. **Resource-Based Serialization**: Entities extend Resource for save/load functionality
6. **Parameter-Based Actions**: No fixed choice menus, actions built from parameters

## Development Workflow

### Running the Game
Open project in Godot 4.5 editor and press **F5** or use the Play button.

### Working with GDScript
- All scripts use `.gd` extension
- Class files use `class_name` declaration (e.g., `class_name World`, `class_name Nation`)
- Resources extend `Resource` base class for serialization
- Autoload singletons extend `Node`
- UI text is in German (month names, labels, notifications)

### Documentation Guidelines
**IMPORTANT**: All documentation files (`.md` files) MUST be created in the `documentation/` directory.
- Technical documentation: `documentation/`
- Design documents: Already located in `documentation/`
- Never create `.md` files in the project root (except `CLAUDE.md` and `README.md`)
- Examples: `documentation/EVENT_SYSTEM.md`, `documentation/AUTOLOAD_SETUP.md`, `documentation/TEST_SIMULATION.md`

## Architecture

### Autoload Singletons (Global State Management)

Six core singletons form the game's backbone:

**1. EventBus** (`autoload/EventBus.gd`)
- Signal-based communication hub for decoupled system interactions
- Signal categories:
  - Game Flow: `game_started`, `game_paused`, `game_resumed`, `day_passed`, `month_passed`, `year_passed`
  - Time System: `time_started`, `time_paused`, `event_triggered`, `events_batch_triggered`
  - World Events: `nation_created`, `nation_destroyed`, `war_declared`, `war_ended`
  - Player Actions: `action_executed`, `decision_made`
  - UI Events: `ui_panel_opened`, `ui_panel_closed`, `map_zoom_changed`, `province_selected`
  - Character Events: `character_created`, `character_died`, `character_relationship_changed`
  - Economy Events: `economic_crisis`, `trade_route_established`, `corporation_bankrupt`
  - Historical Events: `historical_event_added`
  - Save/Load: `game_saved`, `game_loaded`, `game_state_changed`
- Use `emit_deferred_signal()` for safe emission during processing

**2. GameState** (`autoload/GameState.gd`)
- Central state repository storing all game entities
- Key dictionaries: `nations`, `provinces`, `characters` (all keyed by String IDs)
- Player state: `player_nation_id`, `player_character_id`, `player_resources`
  - `player_resources` includes: `money`, `legitimacy`, `reality_points` (for reality-bending mechanics)
- Game state: `current_date` (year/month/day/hour dict), `game_speed`, `is_paused`
- Settings: `world_seed`, `difficulty`, `ironman_mode`
- World reference: `world` (holds the World instance)
- Access entities via getter methods: `get_player_nation()`, `get_character(id)`, `get_province(id)`

**3. TimeManager** (`autoload/TimeManager.gd`)
- **Advanced event-driven time system** with automatic speed adjustment
- Time scale: Hour-based with dynamic speed (hourly/daily/monthly depending on next event)
- Calendar: 24 hours/day, 30 days/month, 12 months/year
- **Event Queue System**: Schedule events with `schedule_event(event_data, hours_from_now, priority)`
  - Priority 0 (low): Batched events (reports, notifications)
  - Priority 1 (normal): Individual events
  - Priority 2 (high): Immediate pause when triggered
- **Automatic Speed Adjustment**: Speeds up time when next event is far away
  - `SPEED_HOURS` (0.5 h/s): For events < 1 day away
  - `SPEED_DAYS_SLOW` (2 days/s): For events 1-7 days away
  - `SPEED_DAYS_FAST` (10 days/s): For events 7-30 days away
  - `SPEED_MONTHS` (3 months/s): For events > 30 days away
- Time control: `start_time()`, `pause_time()`, `continue_to_next_event()`
- Automatically pauses when events trigger
- Emits time signals through EventBus: `day_passed`, `month_passed`, `year_passed`

**4. HistoricalContext** (`autoload/HistoricalContext.gd`)
- **Global historical memory system** storing world history
- **Three temporal layers**:
  - `formative_eras`: Long-term cultural/political trends (1500-1900)
  - `historical_events`: Concrete historical events with dates (1900-2000)
  - `game_events`: Events during gameplay (2000+)
- Event structure: `{date, type, name, description, narrative_weight, legacy, ...}`
- **Legacy impact system**: Events contribute weighted legacy values (e.g., "militarism", "trauma")
- Key methods:
  - `add_formative_era(period, description, legacy)`: Add era-defining trend
  - `add_historical_event(year, month, day, type, name, desc, weight, legacy)`: Add historical event
  - `add_game_event(date, type, name, desc, weight, legacy)`: Add gameplay event
  - `get_legacy_impact(key)`: Calculate cumulative impact of a legacy value
  - `get_defining_moments(min_weight)`: Get only high-importance events
- Auto-generates realistic history on startup (WWI, WWII, Cold War, etc.)
- Events with `narrative_weight >= 60` emit `historical_event_added` signal

**5. GameInitializer** (`autoload/GameInitializer.gd`)
- **Initializes game world on startup**
- Generates world via `WorldGenerator.generate_test_world()`
- Connects simulation to TimeManager via `day_passed` signal
- Schedules initial test events (minister reports, diplomatic briefings)
- Automatically starts time simulation after initialization
- Access world instance via `GameInitializer.world` or `GameState.world`

**6. SaveManager** (`autoload/SaveManager.gd`)
- **Complete save/load system** for game state persistence
- Save format: JSON (human-readable, in `user://saves/`)
- Save version: `SAVE_VERSION = 1` (for compatibility checking)
- **Saves everything**:
  - GameState (date, player info, settings)
  - TimeManager (event queue, speed, running state)
  - HistoricalContext (all historical data)
  - World (all nations, provinces, characters)
- Key methods:
  - `save_game(save_name)`: Manual save
  - `auto_save()`: Creates timestamped autosave
  - `load_game(save_name)`: Load saved game
  - `get_save_list()`: Returns array of save metadata
  - `delete_save(save_name)`: Delete save file
- **Auto-save system**: Configurable interval (default 30 days)
- Ironman mode: Auto-saves every day
- Emits `game_saved` and `game_loaded` signals via EventBus

### Core Simulation Entities

**World** (`scripts/simulation/world/World.gd`)
- Container for all nations and provinces
- **Level-of-Detail Simulation**: Three modes for performance optimization
  - `"detailed"`: Full simulation for player nation + neighbors/war participants
  - `"simplified"`: Reduced simulation for distant nations
  - `"background"`: Macro trends only for irrelevant nations
- Uses `_is_relevant_for_player()` to determine simulation granularity
- Maintains `HistoricalMemory` instance (not yet implemented, see design doc)

**Nation** (`scripts/simulation/world/Nation.gd`)
- Extends `Resource` for serialization
- **Government**: `government_type` (democracy, dictatorship, theocracy, etc.), `leader_character_id`, `legitimacy`
- **Economy**: `gdp`, `gdp_growth`, `treasury`, `debt`, `inflation`, `unemployment`
- **Military**: `military_strength`, `armies` (array of IDs)
- **Diplomacy**: `relationships` (dict: nation_id → float -100 to 100), `alliances`, `wars`
- **Technology**: `tech_level` (1-7 scale from rückständig to sci-fi), `researched_technologies`
- **Demographics**: `population`, `population_groups`
- **AI**: `ai_personality`, `ai_goals` (for NPC nations)
- **Historical**: `historical_profile`, `defining_moments` (for narrative generation)
- Three tick methods: `simulate_detailed_tick()`, `simulate_simplified_tick()`, `simulate_background_tick()`
- Event triggering: Emits signals like `economic_crisis` when `unemployment > 20.0`

**Province** (`scripts/simulation/world/Province.gd`)
- Extends `Resource`
- **Geography**: `terrain_type`, `position`, `adjacent_provinces`
- **Economy**: `local_gdp`, `resources` (dict), `industries`
- **Demographics**: `population`, `urban_population`, `ethnic_makeup`
- **Infrastructure**: `infrastructure_level`, `has_port`, `has_airport`
- **Unrest**: `unrest_level`, `protest_risk`
  - Unrest calculation: `(nation.unemployment/10.0) + (100-nation.legitimacy)/50.0`

**Character** (`scripts/simulation/entities/Character.gd`)
- Extends `Resource`
- **Personality System**: Big Five traits + extensions (all 0-100 scale)
  - `openness`, `conscientiousness`, `extraversion`, `agreeableness`, `neuroticism`
  - `machiavellianism`, `authoritarianism`, `risk_tolerance`
- **Ideology**: 3-axis system (-100 to 100 scale)
  - `economic`: communist (-100) ↔ capitalist (100)
  - `social`: authoritarian (-100) ↔ libertarian (100)
  - `foreign`: isolationist (-100) ↔ interventionist (100)
- **Skills**: `economy`, `military`, `diplomacy`, `intrigue`, `oratory`, `administration`
- **Positions**: `current_position` (minister, general, opposition_leader, citizen, etc.)
- **Goals System**: `short_term_goals`, `long_term_goals`, `secret_agenda`
  - GOAP (Goal-Oriented Action Planning) planned for `_work_towards_goal()` (not yet implemented)
- **Biography System**: `biography` array tracks life events with year/impact metadata
  - Characters age annually (on month 1, day 1)
  - Health degrades over time; death triggers biographical recording
  - Use `add_biography_event(event_type, description, impact)` to record events
- **Relationships**: `relationships` dict (character_id → int -100 to 100), `loyalty_to_player`

### UI Architecture

**MainUIController** (`scripts/ui/MainUIController.gd`)
- Central UI controller managing all UI panels and displays
- **Camera Controls**:
  - WASD movement
  - Mouse wheel zoom (0.5x to 3.0x range)
  - Edge scrolling (10px margin)
- **Time Controls**: Pause, Speed 1x, 2x, 5x
- **Top Bar**: Date, money, legitimacy, reality_points display
- **Bottom Bar**: Province info, character info, action buttons
- **Panels**: Left panel for advisors/military/diplomacy/economy/technology/characters
- **German UI**: Month names ("Januar", "Februar", etc.), labels ("Berater", "Militär", "Wirtschaft", etc.)

**Signal Connections Pattern**:
- UI controllers connect to EventBus signals in `_connect_signals()`
- Button presses connected in `_connect_buttons()`
- Always use EventBus for cross-system communication, never direct signal connections

### Procedural World Generation

**WorldGenerator** (`scripts/procedural/WorldGenerator.gd`)
- Static class (extends `RefCounted`) for world generation
- Currently: Test world generator for development
- Planned: Seed-based procedural generation
- **Test World Configuration** (via `generate_test_world()`):
  - 3 nations: Thalassische Republik (player), Nordreich, Südkonföderation
  - 9 provinces (3 per nation) with varied terrain types
  - Leaders for each nation with distinct personalities and ideologies
  - Pre-configured relationships between nations
- **Generation Flow**:
  1. Creates World instance with seed
  2. Generates nations with government, economy, military stats
  3. Generates provinces with terrain, resources, population
  4. Generates characters (leaders) with personalities, skills, ideologies
  5. Registers all entities in GameState dictionaries
  6. Sets player nation (first nation by default)
- **Terrain-Based Resource Assignment**:
  - Coastal: Fish, oil
  - Mountains: Minerals, rare earth
  - Plains: Agriculture
  - Forest: Timber
  - Desert: Oil
- Called automatically by GameInitializer on startup

### Historical Memory System

See `Historical_Memory_System.md` for detailed design. Key concepts:

**Core Philosophy**: "History is not what happened - but how it is remembered, interpreted, and passed on."

**Key Features**:
- **Procedural historical generation**: Creates 500-5000 years of simulated history before game start
- **Defining moments**: Each entity has `defining_moments` array with narrative weight (0-100)
- **Perspectival memory**: Same event remembered differently by different entities
- **Memory decay**: Events fade over generations (but "defining events" persist as myths)
- **Causal chains**: System tracks revenge spirals, alliances, and long-term patterns
- **NPC memory**: Characters remember all interactions with player and reference them in dialogues
- **Historical records**: In-game archive system with timeline, biographical records, causal graphs

**Implementation Notes**:
- Events stored with: `narrative_weight` (0-100), `memory_persistence` (years), `affected_parties`
- Characters have `biography` array tracking life events
- Nations have `historical_profile` and `defining_moments`
- NPCs make decisions based on historical context via Utility AI + GOAP

### Parameter-Based Action System

**Design Concept** (from Staatsführungs_Sandbox_Konzept.md):

Instead of fixed multiple-choice options, actions are constructed from parameters:

1. **WAS** (Target): Person, Group, Infrastructure, Law, Resource, Information
2. **WIE** (Method): Legal, Heimlich, Gewaltsam, Diplomatisch, Wirtschaftlich, Propagandistisch
3. **INTENSITÄT** (Intensity): Slider 0-100% (affects effectiveness AND risk)
4. **SCOPE** (Scope): Einzelfall, Lokal, National, International
5. **RESSOURCENEINSATZ** (Budget): Affects success probability

**Example UI**:
```
Ziel: [Dropdown: Oppositionsführer]
Aktion: [Dropdown: Neutralisieren]
Methode: [Dropdown: Heimliche Tötung]
Intensität: [═══════░░░] 70%
Ressourcen: [$$$░░░░░] $5M

Erfolgswahrscheinlichkeit: 65%
Risiken: Skandal (Hoch), Destabilisierung (Mittel)
```

**Not yet implemented** - current code has placeholder action buttons

### Reality Bending Mechanics

**Design Concept** (from Staatsführungs_Sandbox_Konzept.md):

Supernatural abilities costing "reality_points" with escalating instability:

**Categories**:
- **Military**: Soldaten-Transformation, Waffen-Jam, Unsichtbarer Angriff
- **Economic**: Gelddruckmaschine (inflation-free), Ressourcen-Verdopplung
- **Social**: Massenhypnose, Erinnerungs-Rewrite, Charisma-Boost
- **Political**: Loyalitäts-Swap, Skandal-Unsichtbarkeit, Instant-Revolution
- **Scientific**: Instant-Technologie, Physik-Aussetzen, Zeit-Beschleunigung

**Consequences**:
- Reality instability (glitches, paradoxes, anomalies)
- International panic if discovered
- Population unrest from unnatural phenomena
- Arms race for reality-bending tech

**Current Status**: `reality_points` tracked in GameState.player_resources but mechanics not implemented

### Technology Levels

**7-Tier System** (from design docs):

1. **Rückständig** (1850-1920): Steam, early industry, telegraphs
2. **Früh-Modern** (1920-1960): Oil, mass production, radio, tanks
3. **Modern** (1960-2000): Computers, internet, nukes, jets
4. **Zeitgenössisch** (2000-2030): Smartphones, drones, cyberwarfare
5. **Nah-Zukunft** (2030-2070): AI assistants, autonomous vehicles, gene therapy
6. **Fern-Zukunft** (2070-2150): AGI, fusion power, nanotech, Mars colonies
7. **Sci-Fi-Übermacht** (Post-2150): Post-scarcity, dyson spheres, consciousness upload, interstellar

Nation `tech_level` property uses 1-7 scale

## Directory Organization

```
autoload/                         # Global singletons (6 total)
  EventBus.gd                     # Signal hub for all inter-system communication
  GameState.gd                    # Central state repository for all game entities
  TimeManager.gd                  # Event-driven time system with auto-speed adjustment
  HistoricalContext.gd            # Historical memory and legacy tracking
  GameInitializer.gd              # World generation and initialization orchestration
  SaveManager.gd                  # Complete save/load system

scripts/
  simulation/                     # Core simulation logic
    world/                        # World container and nation/province classes
      World.gd                    # Container for all nations/provinces with LOD simulation
      Nation.gd                   # Nation state (economy, military, diplomacy, etc.)
      Province.gd                 # Province state (terrain, resources, population)
    entities/                     # Character entities
      Character.gd                # Character with personality, skills, biography, goals
    economy/                      # (planned)
    politics/                     # (planned)
    military/                     # (planned)
    diplomacy/                    # (planned)
    technology/                   # (planned)
    reality_bending/              # Special mechanics (planned)
  ai/                             # AI systems (planned - will use Utility AI + GOAP, NOT LLMs)
  procedural/                     # Procedural generation
    WorldGenerator.gd             # Static class for world generation (test world implemented)
  ui/                             # UI controllers (dialogs, map, panels, widgets)
    MainUIController.gd           # Central UI controller
    MainMenu.gd                   # Main menu
    EventDialog.gd                # Event dialog system
    SaveLoadMenu.gd               # Save/load UI
    map/
      MapController.gd            # Map rendering (skeleton only)
    panels/                       # Info panels
      NationPanel.gd              # Nation info display (skeleton)
      ProvincePanel.gd            # Province info display (skeleton)
      CharacterPanel.gd           # Character info display (skeleton)
    widgets/                      # Reusable UI components
      BasePanel.gd                # Base class for all panels
      EventNotificationSystem.gd  # Event notification display
  core/                           # (planned)
  utils/                          # (planned)

scenes/
  ui/                             # UI scenes
    MainUI.tscn                   # Main game UI (entry point)
    MainMenu.tscn                 # Main menu scene
    EventDialog.tscn              # Event dialog scene
    SaveLoadMenu.tscn             # Save/load menu scene
  main/, map/, menus/, entities/  # (other scenes, not yet created)

data/
  templates/                      # Procedural generation templates (JSON-like, planned)
    characters/, events/, nations/, technologies/
  configs/                        # Game configuration (planned)
  localization/                   # Translations (planned)

assets/
  sprites/                        # Map, portraits, UI, effects (planned)
  audio/, fonts/, shaders/        # (planned)

documentation/                    # Technical documentation (CREATE ALL .md FILES HERE)
  Historical_Memory_System.md     # Historical memory design document
  Staatsführungs_Sandbox_Konzept.md  # Full game design document
```

## Important Implementation Notes

### Critical Rules
- **Always access entities through GameState dictionaries** by ID, not direct references
- **Emit all signals through EventBus**, never create direct signal connections between systems
- **Use German for UI text** to match existing codebase
- **Respect simulation modes**: detailed/simplified/background for performance

### Currently Implemented
- **Six autoload singletons**:
  - EventBus (signal hub with 50+ signals)
  - GameState (central state repository)
  - TimeManager (advanced event queue + auto-speed system)
  - HistoricalContext (historical memory with 100+ years of events)
  - GameInitializer (world generation orchestration)
  - SaveManager (complete save/load system with JSON serialization)
- **Core entity classes**: World, Nation, Province, Character (all extend Resource for serialization)
- **Procedural generation**: WorldGenerator with test world (3 nations, 9 provinces, leaders)
- **Main UI** with map controls, time controls, resource display
- **Advanced time system**:
  - Hour-based simulation with automatic speed adjustment
  - Event queue system with 3 priority levels
  - Dynamic time scaling (hourly → daily → monthly based on next event)
  - Time automatically pauses when events trigger
- **Historical memory**:
  - Pre-generated history (1500-2000) with formative eras and concrete events
  - Legacy impact tracking (militarism, trauma, etc.)
  - Game event recording during gameplay
- **Save/load system**:
  - Complete state serialization (GameState, World, TimeManager, HistoricalContext)
  - Auto-save with configurable intervals
  - Ironman mode support
  - Save metadata (date, nation name, timestamp)
- **Basic simulation**:
  - Character aging and death (on Jan 1st annually)
  - Economic crisis events (when unemployment > 20%)
  - Level-of-detail simulation (detailed/simplified/background modes)

### TODO Placeholders (Not Yet Implemented)
- **Economic simulation details**: Nation/Province `_update_economy` methods (placeholders only)
- **Political dynamics**: Nation `_update_politics` (placeholders only)
- **Military updates**: Nation `_update_military` (placeholders only)
- **Population dynamics**: Nation `_update_population` (placeholders only)
- **Character GOAP AI**: `_work_towards_goal()` for goal-driven NPC behavior
- **Parameter-based action system**: UI for constructing actions from parameters (WAS/WIE/INTENSITÄT/SCOPE)
- **Reality bending mechanics**: Supernatural abilities (reality_points tracked but mechanics not implemented)
- **NPC decision-making**: Utility AI + GOAP for NPC choices
- **Procedural text generation**: Template-based event text (not LLM-based)
- **Advanced historical memory**: NPC memory of player interactions, causal chain tracking
- **Map rendering**: Visual province map (MapController exists but rendering not implemented)
- **UI panels**: Full implementations of NationPanel, ProvincePanel, CharacterPanel (skeletons exist)

### AI Design Philosophy
- **NO LLMs**: Game uses Utility AI + GOAP for NPC decisions
- **Template-based text**: Events use multi-level templates with context injection
- **Emergent narratives**: Stories emerge from NPC interactions and historical memory
- NPCs evaluate actions via: `Score = Σ(Utility_Factor * Weight)`
- Utility factors: Ambition, Survival, Ideology Match, Loyalty, Risk Tolerance, Resources

### Performance Considerations
- **Abstraction levels**: Irrelevant states get macro-only simulation
- **Update frequencies**: Critical (every tick), Important (every 3rd), Background (every 10th)
- **Lazy evaluation**: Details computed only when player views them
- World uses `_is_relevant_for_player()` to determine which nations get detailed simulation

### Design Documents
- `Historical_Memory_System.md`: Comprehensive design for historical memory, causality, NPC memory
- `Staatsführungs_Sandbox_Konzept.md`: Full game design document with all systems, UI mockups, technical architecture

## Working with the Codebase

### When Adding New Systems

1. **Register signals in EventBus** if cross-system communication needed
   - Add signal declaration to `autoload/EventBus.gd`
   - Document in CLAUDE.md under EventBus section
2. **Store persistent state in GameState** if it needs global access
   - Add to appropriate GameState dictionary or property
   - Update SaveManager serialization methods
3. **Implement tick-based updates** respecting `GameState.is_paused` and `GameState.game_speed`
   - Connect to `EventBus.day_passed` for daily updates
   - Use `TimeManager.schedule_event()` for timed events
4. **Use Resource-based classes** for entities that need serialization
   - Extend `Resource` for all game entities (nations, characters, etc.)
   - Implement proper serialization in SaveManager
5. **Emit events through EventBus** for historical/biographical tracking
   - Use `EventBus.emit()` for immediate events
   - Use `EventBus.emit_deferred_signal()` during processing
   - Add to `HistoricalContext` if narratively significant
6. **Consider level-of-detail simulation** for performance-intensive systems
   - Implement detailed/simplified/background modes
   - Check relevance with `World._is_relevant_for_player()`
7. **Use German text for UI** to maintain consistency
   - Labels: "Berater", "Militär", "Wirtschaft", "Technologie"
   - Months: "Januar", "Februar", "März", etc.
8. **Follow parameter-based design** for actions (when implementing)
   - No fixed multiple-choice menus
   - Actions constructed from WAS/WIE/INTENSITÄT/SCOPE/RESSOURCENEINSATZ
9. **Track historical context** for all significant events
   - Use `HistoricalContext.add_game_event()` for events during gameplay
   - Include narrative_weight (0-100) and legacy impact
10. **Use Utility AI patterns** for NPC decision-making (not LLMs)
    - Template-based text generation, not AI-generated

### Autoload Loading Order

The order in `project.godot` matters for initialization dependencies:

1. **EventBus** - Must load first (no dependencies)
2. **GameState** - Must load second (only depends on EventBus)
3. **TimeManager** - Depends on GameState and EventBus
4. **HistoricalContext** - Depends on EventBus
5. **GameInitializer** - Must load near end (depends on all above)
6. **SaveManager** - Can load anytime (depends on all singletons)

**GameInitializer must load last** because it:
- Calls `WorldGenerator.generate_test_world()`
- Registers entities in GameState
- Connects to TimeManager
- Schedules initial events

### Adding New Autoload Singletons

If you need to add a new autoload:

1. Create the script in `autoload/` directory
2. Add to `project.godot` in correct order:
   ```ini
   [autoload]
   YourSingleton="*res://autoload/YourSingleton.gd"
   ```
3. Document in CLAUDE.md under "Autoload Singletons" section
4. If it stores state, update SaveManager serialization
5. Consider initialization order - add before GameInitializer

## Common Patterns

### Connecting to EventBus
```gdscript
func _ready():
    EventBus.day_passed.connect(_on_day_passed)
    EventBus.economic_crisis.connect(_on_economic_crisis)

func _on_day_passed(day: int):
    # Handle day passing
    pass
```

### Accessing Game State
```gdscript
var player_nation = GameState.get_player_nation()
var character = GameState.get_character(character_id)
var province = GameState.get_province(province_id)
```

### Emitting Events
```gdscript
EventBus.character_died.emit(character_id, "natural_causes")
EventBus.economic_crisis.emit(nation_id, severity)
```

### Time-Based Updates
```gdscript
func simulate_tick():
    if GameState.is_paused:
        return
    # Update logic here
```

### Recording Biography
```gdscript
character.add_biography_event(
    "promoted",
    "Appointed as Minister of Defense",
    {"loyalty_change": 10, "influence_change": 20}
)
```

### Scheduling Events (TimeManager)
```gdscript
# Schedule event in 2 hours (normal priority)
TimeManager.schedule_event(
    {"type": "minister_report", "minister": "finance", "message": "Economic report ready"},
    2.0,  # hours from now
    1     # priority: 0=low, 1=normal, 2=high
)

# Schedule high-priority event in 1 day (will pause game when triggered)
TimeManager.schedule_event(
    {"type": "crisis", "message": "Diplomatic incident requires attention"},
    24.0,  # 1 day
    2      # high priority
)

# Listen for triggered events
func _ready():
    EventBus.event_triggered.connect(_on_event_triggered)

func _on_event_triggered(event_data: Dictionary, priority: int):
    # Handle event based on type
    match event_data.type:
        "minister_report":
            show_minister_report(event_data)
        "crisis":
            show_crisis_dialog(event_data)
```

### Recording Historical Events
```gdscript
# Add game event to historical context
HistoricalContext.add_game_event(
    GameState.current_date,
    "war_outbreak",
    "War Declared Against Nordreich",
    "The Thalassic Republic declared war following border violations.",
    85,  # narrative_weight (0-100)
    {"militarism": 20, "international_tension": 40}  # legacy impact
)

# Query historical legacy
var militarism_impact = HistoricalContext.get_legacy_impact("militarism")
var defining_events = HistoricalContext.get_defining_moments(80)  # min_weight
```

### Save/Load Operations
```gdscript
# Save game
SaveManager.save_game("my_save_name")

# Load game
SaveManager.load_game("my_save_name")

# Get list of saves
var saves = SaveManager.get_save_list()
for save_info in saves:
    print("%s - %s (%s)" % [save_info.name, save_info.nation_name, save_info.timestamp])

# Auto-save (creates timestamped save)
SaveManager.auto_save()

# Listen for save/load events
func _ready():
    EventBus.game_saved.connect(_on_game_saved)
    EventBus.game_loaded.connect(_on_game_loaded)
```

### project.godot Configuration
When adding new autoload singletons, add them to `project.godot`:
```ini
[autoload]
EventBus="*res://autoload/EventBus.gd"
GameState="*res://autoload/GameState.gd"
TimeManager="*res://autoload/TimeManager.gd"
HistoricalContext="*res://autoload/HistoricalContext.gd"
GameInitializer="*res://autoload/GameInitializer.gd"
SaveManager="*res://autoload/SaveManager.gd"
```
Order matters: EventBus and GameState should load first, GameInitializer should load last.
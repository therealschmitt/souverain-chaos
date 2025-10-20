# Speicher- und Ladesystem

## Übersicht

Das Speichersystem ermöglicht das vollständige Speichern und Laden des Spielzustands. Es unterstützt manuelle Speicherstände, Schnellspeicherungen und Auto-Saves.

## Architektur

### SaveManager (autoload/SaveManager.gd)

Zentrale Singleton-Klasse für alle Speicher- und Ladevorgänge.

**Speicherformat**: JSON (menschenlesbar, versioniert)
**Speicherort**: `user://saves/` (plattformspezifisch)
**Dateiendung**: `.sav`

### Gespeicherte Daten

Das System speichert den **kompletten Spielzustand**:

#### 1. GameState
- Aktuelles Datum (Jahr, Monat, Tag, Stunde)
- Spieler-Nation und -Charakter IDs
- Spieler-Ressourcen (Geld, Legitimität, Reality Points)
- Spielgeschwindigkeit und Pause-Status
- Welt-Seed, Schwierigkeit, Ironman-Modus

#### 2. TimeManager
- Event-Queue mit allen geplanten Events
- Zeitstempel und Prioritäten
- Aktuelle Geschwindigkeit und Lauf-Status

#### 3. HistoricalContext
- Formative Epochen (1500-1900)
- Historische Events (1900-2000)
- Spiel-Events (während des Spiels aufgezeichnet)

#### 4. World (Komplette Simulation)
- **Nationen**: Alle 25+ Eigenschaften pro Nation
  - Wirtschaft (GDP, Schulden, Inflation, Arbeitslosigkeit)
  - Regierung (Typ, Führer, Legitimität)
  - Militär (Stärke, Armeen)
  - Diplomatie (Beziehungen, Allianzen, Kriege)
  - Technologie (Level, erforschte Technologien)
  - Demografie (Bevölkerung, Bevölkerungsgruppen)
  - Geschichte (Profil, definierende Momente)
  - KI (Persönlichkeit, Ziele)

- **Provinzen**: Alle Provinz-Eigenschaften
  - Geografie (Terrain, Position, angrenzende Provinzen)
  - Wirtschaft (GDP, Ressourcen, Industrien)
  - Demografie (Bevölkerung, ethnische Zusammensetzung)
  - Infrastruktur (Level, Hafen, Flughafen)
  - Unruhe (Level, Protestrisiko)

- **Charaktere**: Vollständige Charakterdaten
  - Identität (Name, Alter, Gesundheit, Geschlecht)
  - Persönlichkeit (Big Five + Machiavellismus, Autoritarismus, Risikobereitschaft)
  - Ideologie (Ökonomisch, Sozial, Außenpolitisch)
  - Fähigkeiten (6 Skills: Wirtschaft, Militär, Diplomatie, Intrige, Rhetorik, Verwaltung)
  - Ziele (Kurzfristig, Langfristig, Geheime Agenda)
  - Beziehungen und Loyalität
  - Biografie (komplette Lebensgeschichte)

## API

### Speichern

```gdscript
# Manuelles Speichern mit benutzerdefiniertem Namen
SaveManager.save_game("mein_spielstand")

# Automatisches Speichern
SaveManager.auto_save()

# Schnellspeicherung (F5)
SaveManager.save_game("quicksave")
```

### Laden

```gdscript
# Spielstand laden
SaveManager.load_game("mein_spielstand")

# Gibt true zurück bei Erfolg, false bei Fehler
var success = SaveManager.load_game("spielstand_name")
```

### Hilfsfunktionen

```gdscript
# Liste aller Speicherstände (Array von Dictionaries)
var saves = SaveManager.get_save_list()
# Struktur: [{name, exists, timestamp, date, nation_name, version}, ...]

# Informationen zu einem Speicherstand
var info = SaveManager.get_save_info("spielstand_name")

# Spielstand löschen
SaveManager.delete_save("alter_spielstand")

# Auto-Save prüfen (manuell aufrufen)
SaveManager.check_auto_save()
```

## Benutzeroberfläche

### SaveLoadMenu (scenes/ui/SaveLoadMenu.tscn)

Modaler Dialog mit zwei Modi:

#### Speichern-Modus
- Liste aller Speicherstände
- Eingabefeld für Speichernamen (mit Auto-Generierung)
- Speichern-Button
- Löschen-Button (für ausgewählten Speicherstand)

#### Laden-Modus
- Liste aller Speicherstände mit Details
- Laden-Button
- Löschen-Button

### Integration in MainUIController

```gdscript
# Speichern-Menü öffnen
save_load_menu.open_save_menu()

# Laden-Menü öffnen
save_load_menu.open_load_menu()
```

## Hotkeys

| Taste | Funktion |
|-------|----------|
| **F5** | Schnellspeicherung (speichert als "quicksave") |
| **F9** | Schnellladen (lädt "quicksave") |
| **ESC** | Öffnet/Schließt Speichern/Laden-Menü |

## Speicherstand-Format

### Dateistruktur

```json
{
  "version": 1,
  "timestamp": "2025-01-15T14:30:00",
  "game_state": {
    "current_date": {"year": 2000, "month": 3, "day": 15, "hour": 8},
    "player_nation_id": "thalassia",
    "player_character_id": "char_001",
    "player_resources": {
      "money": 50000000.0,
      "legitimacy": 65.0,
      "reality_points": 0.0
    },
    "game_speed": 1.0,
    "is_paused": true,
    "world_seed": "test_world_2000",
    "difficulty": "normal",
    "ironman_mode": false
  },
  "time_manager": {
    "current_speed": 0.5,
    "is_running": false,
    "event_queue": [
      {
        "timestamp": {"year": 2000, "month": 3, "day": 15, "hour": 10},
        "event_data": {"type": "minister_report", "message": "..."},
        "priority": 1
      }
    ]
  },
  "historical_context": {
    "formative_eras": [...],
    "historical_events": [...],
    "game_events": [...]
  },
  "world": {
    "seed_value": "test_world_2000",
    "simulation_mode": "detailed",
    "nations": [...],
    "provinces": [...],
    "characters": [...]
  }
}
```

### Speicherstand-Liste Format

Jeder Eintrag in der Save-Liste zeigt:
```
[Speichername] | [Nation] | [Datum] | [Zeitstempel]

Beispiel:
Thalassia_2000-03-15 | Thalassische Republik | 15.3.2000 | 2025-01-15 14:30
```

## Auto-Save System

### Konfiguration

```gdscript
const AUTO_SAVE_INTERVAL: int = 30  # Tage zwischen Auto-Saves
```

### Funktionsweise

**Normal-Modus**:
- Auto-Save alle 30 Spieltage
- Dateiname: `autosave_YYYY-MM-DD.sav`

**Ironman-Modus**:
- Auto-Save **jeden Tag**
- Überschreibt vorherigen Auto-Save
- Verhindert Savescumming

### Nutzung

```gdscript
# In GameInitializer oder TimeManager
EventBus.day_passed.connect(_on_day_passed)

func _on_day_passed(day: int) -> void:
    SaveManager.check_auto_save()
```

## Versionierung

**Aktuelle Version**: `SAVE_VERSION = 1`

Das System prüft beim Laden die Version:
- Warnung bei Versions-Mismatch
- Ermöglicht zukünftige Migration/Konvertierung
- Schutz vor inkompatiblen Speicherständen

## Fehlerbehandlung

### Speichern

```gdscript
if SaveManager.save_game("test"):
    print("Erfolgreich gespeichert")
else:
    print("Fehler beim Speichern")
```

**Mögliche Fehlerquellen**:
- Ungültiger Dateiname
- Fehlende Schreibrechte
- Disk voll
- Serialisierungsfehler

### Laden

```gdscript
if SaveManager.load_game("test"):
    print("Erfolgreich geladen")
else:
    print("Fehler beim Laden")
```

**Mögliche Fehlerquellen**:
- Datei existiert nicht
- Ungültiges JSON-Format
- Versions-Inkompatibilität
- Beschädigte Datei
- Fehlende Daten-Felder

## EventBus-Integration

### Signale

```gdscript
# Wird nach erfolgreichem Speichern emittiert
EventBus.game_saved.connect(_on_game_saved)
signal game_saved(save_name: String)

# Wird nach erfolgreichem Laden emittiert
EventBus.game_loaded.connect(_on_game_loaded)
signal game_loaded(save_name: String)

# Wird nach Änderung des Spielzustands emittiert
EventBus.game_state_changed.connect(_on_state_changed)
signal game_state_changed()
```

### Verwendung

```gdscript
func _ready() -> void:
    EventBus.game_saved.connect(_on_game_saved)
    EventBus.game_loaded.connect(_on_game_loaded)

func _on_game_saved(save_name: String) -> void:
    print("Spielstand gespeichert: ", save_name)
    _show_notification("Spielstand gespeichert!")

func _on_game_loaded(save_name: String) -> void:
    print("Spielstand geladen: ", save_name)
    _update_all_ui()
```

## Best Practices

### 1. Speichern während Simulation
- **Immer** Zeit pausieren vor dem Speichern
- SaveManager pausiert automatisch beim Laden
- Nach Laden: UI aktualisieren über `game_state_changed` Signal

### 2. Dateinamen
- Keine Sonderzeichen (außer `_`, `-`)
- Keine Leerzeichen (werden zu `_`)
- Empfohlen: `Nation_YYYY-MM-DD` Format
- Auto-Generierung nutzen wenn möglich

### 3. Ironman-Modus
- Nur ein Speicherstand erlaubt
- Kein manuelles Speichern
- Nur Auto-Save
- Kein Laden während Spiel läuft

### 4. Performance
- Speichern: ~100-500ms (abhängig von Weltgröße)
- Laden: ~200-800ms (abhängig von Weltgröße)
- JSON-Format: Lesbar aber größer als binär
- Komprimierung möglich (TODO)

## Zukünftige Erweiterungen

### Geplante Features

1. **Speicherstand-Screenshots**
   - Minimap-Thumbnail
   - Gespeichert als PNG neben .sav

2. **Komprimierung**
   - GZIP-Komprimierung für .sav Dateien
   - Reduziert Dateigröße um ~70%

3. **Cloud-Sync**
   - Optional: Steam Cloud / Epic Cloud
   - Automatische Synchronisation

4. **Metadaten-Erweiterung**
   - Spielzeit
   - Erfolge/Achievements
   - Statistiken

5. **Export/Import**
   - Spielstände teilen
   - Checksumme für Integrität

6. **Automatische Backups**
   - Backup vor Überschreiben
   - Konfigurierbare Backup-Anzahl

## Troubleshooting

### "Speicherstand nicht gefunden"
- Prüfe ob Datei in `user://saves/` existiert
- Auf Windows: `%APPDATA%\Godot\app_userdata\souverän\saves\`
- Auf Linux: `~/.local/share/godot/app_userdata/souverän/saves/`
- Auf macOS: `~/Library/Application Support/Godot/app_userdata/souverän/saves/`

### "Fehler beim Parsen"
- Speicherstand möglicherweise beschädigt
- Manuell mit JSON-Validator prüfen
- Backup verwenden falls vorhanden

### "Version unterscheidet sich"
- Warnung, kein Fehler
- Laden wird versucht
- Möglicherweise fehlende Felder
- Bei Problemen: Neues Spiel starten

### Speicherstände nicht sichtbar in Liste
- SaveLoadMenu-Refresh-Logik prüfen
- Console-Output für Fehler prüfen
- Dateirechte prüfen

## Beispiel-Workflow

```gdscript
# In GameInitializer.gd
func _ready() -> void:
    # Prüfe ob Auto-Save existiert
    var auto_save_info = SaveManager.get_save_info("autosave")

    if auto_save_info.exists:
        # Lade letzten Auto-Save
        SaveManager.load_game("autosave")
    else:
        # Neues Spiel starten
        _initialize_new_game()

    # Auto-Save aktivieren
    EventBus.day_passed.connect(_on_day_passed)

func _on_day_passed(day: int) -> void:
    SaveManager.check_auto_save()
```

## Technische Details

### Serialisierung

- **Resource-Klassen**: Nation, Province, Character erweitern `Resource`
- Eigenschaften werden direkt in Dictionary konvertiert
- `duplicate(true)` für tiefe Kopien von Arrays/Dicts
- Vector2 wird zu `{x, y}` Dictionary

### Deserialisierung

- Neue Instanzen werden erstellt (`Nation.new()`)
- Eigenschaften werden einzeln zugewiesen
- Referenzen werden über IDs wiederhergestellt
- GameState Dictionaries werden neu aufgebaut

### Speicherort

```gdscript
const SAVE_DIR: String = "user://saves/"

# Godot user:// Pfade (plattformabhängig):
# Windows: %APPDATA%\Godot\app_userdata\[Projektname]\
# Linux: ~/.local/share/godot/app_userdata/[Projektname]/
# macOS: ~/Library/Application Support/Godot/app_userdata/[Projektname]/
```

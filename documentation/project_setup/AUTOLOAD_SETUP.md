# Autoload Setup Anleitung

Die folgenden Singletons müssen in Godot als Autoload registriert werden:

## In Godot Editor:

1. Gehe zu **Projekt → Projekteinstellungen**
2. Wähle den Tab **Autoload**
3. Füge folgende Autoloads hinzu (in dieser Reihenfolge):

### 1. EventBus
- **Pfad**: `res://autoload/EventBus.gd`
- **Node-Name**: `EventBus`
- **Enable**: ✓ (aktiviert)

### 2. GameState
- **Pfad**: `res://autoload/GameState.gd`
- **Node-Name**: `GameState`
- **Enable**: ✓ (aktiviert)

### 3. TimeManager
- **Pfad**: `res://autoload/TimeManager.gd`
- **Node-Name**: `TimeManager`
- **Enable**: ✓ (aktiviert)

### 4. HistoricalContext
- **Pfad**: `res://autoload/HistoricalContext.gd`
- **Node-Name**: `HistoricalContext`
- **Enable**: ✓ (aktiviert)

### 5. GameInitializer (NEU)
- **Pfad**: `res://autoload/GameInitializer.gd`
- **Node-Name**: `GameInitializer`
- **Enable**: ✓ (aktiviert)

## Reihenfolge wichtig!

Die Reihenfolge ist wichtig, weil:
- `EventBus` muss zuerst geladen werden (wird von allen anderen genutzt)
- `GameState` muss vor `TimeManager` geladen werden
- `TimeManager` nutzt `GameState` und `EventBus`
- `HistoricalContext` nutzt `EventBus`
- `GameInitializer` muss ZULETZT geladen werden (nutzt alle anderen)

## Verwendung im Code:

```gdscript
# Zugriff auf Autoloads von überall:
EventBus.day_passed.emit(5)
TimeManager.schedule_event({}, 2.0, 1)
HistoricalContext.add_game_event(...)
GameState.current_date
```

## Nach dem Setup:

Das Spiel startet nun automatisch mit:
- Datum: 1. Januar 2000, 00:00 Uhr
- Zeit pausiert (wartet auf Events)
- Historischer Kontext geladen (1500-2000)
- Test-Welt mit 3 Nationen und 9 Provinzen generiert
- Test-Events eingeplant (in 2h, 1 Tag, 7 Tage, 30 Tage)
- Bevölkerungssimulation läuft (1% Wachstum pro Jahr)

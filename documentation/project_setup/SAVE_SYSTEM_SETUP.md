# SaveManager Setup-Anleitung

## Autoload-Registrierung

Um das Speichersystem zu aktivieren, muss SaveManager als Autoload registriert werden.

### Schritt 1: Godot Editor öffnen

Öffne das Projekt in Godot 4.5

### Schritt 2: Projekt-Einstellungen

1. Menü: **Projekt → Projekteinstellungen**
2. Tab: **Autoload**

### Schritt 3: SaveManager hinzufügen

| Feld | Wert |
|------|------|
| **Pfad** | `res://autoload/SaveManager.gd` |
| **Node-Name** | `SaveManager` |
| **Aktiviert** | ✓ |

Klicke auf **Hinzufügen**

### Schritt 4: Reihenfolge prüfen

Die Autoload-Reihenfolge sollte sein:

1. EventBus
2. GameState
3. TimeManager
4. HistoricalContext
5. GameInitializer
6. **SaveManager** ← Neu hinzugefügt

### Schritt 5: Testen

Nach Registrierung sollte SaveManager global verfügbar sein:

```gdscript
# Im Script-Editor oder Debug-Console testen:
print(SaveManager)  # Sollte <Node#...> ausgeben
```

## Verifikation

### Test 1: Speichern

```gdscript
# In der Debug-Console oder einem Test-Script:
SaveManager.save_game("test_save")
```

Erwartete Ausgabe:
```
[SaveManager] Speichere Spielstand: test_save
[SaveManager] Spielstand gespeichert: user://saves/test_save.sav
```

### Test 2: Laden

```gdscript
SaveManager.load_game("test_save")
```

Erwartete Ausgabe:
```
[SaveManager] Lade Spielstand: test_save
[SaveManager] Spielstand geladen: user://saves/test_save.sav
```

### Test 3: Liste abrufen

```gdscript
var saves = SaveManager.get_save_list()
print("Gefundene Speicherstände: ", saves.size())
```

## Hotkey-Test

Nach Spielstart:

- **F5** drücken → Console sollte "Schnellspeicherung erfolgreich!" anzeigen
- **ESC** drücken → Speichern/Laden-Menü sollte erscheinen
- **F9** drücken → Lädt Quicksave (falls vorhanden)

## Troubleshooting

### SaveManager nicht gefunden

**Symptom**: `Invalid get index 'save_game' (on base: 'Nil')`

**Lösung**:
1. Prüfe ob SaveManager in Autoload-Liste erscheint
2. Neustart des Godot-Editors
3. Prüfe Pfad: `res://autoload/SaveManager.gd`

### Speicherverzeichnis-Fehler

**Symptom**: `Fehler beim Öffnen der Datei`

**Lösung**:
- SaveManager erstellt automatisch `user://saves/` Verzeichnis
- Bei Problemen: Manuell prüfen ob Verzeichnis existiert
- Schreibrechte des Systems prüfen

### JSON-Parse-Fehler

**Symptom**: `Fehler beim Parsen der JSON-Datei`

**Lösung**:
- Speicherdatei könnte beschädigt sein
- Mit JSON-Validator prüfen
- Löschen und neu speichern

## Weitere Schritte

Nach erfolgreichem Setup:

1. Lies `documentation/SAVE_SYSTEM.md` für vollständige Dokumentation
2. Teste alle Hotkeys (F5, F9, ESC)
3. Teste SaveLoadMenu UI
4. Aktiviere Auto-Save in GameInitializer (optional)

## Auto-Save aktivieren (Optional)

Füge in `GameInitializer.gd` hinzu:

```gdscript
func _ready() -> void:
    # ... bestehender Code ...

    # Auto-Save aktivieren
    EventBus.day_passed.connect(_on_day_passed_for_autosave)

func _on_day_passed_for_autosave(day: int) -> void:
    SaveManager.check_auto_save()
```

Das war's! Das Speichersystem ist jetzt einsatzbereit.

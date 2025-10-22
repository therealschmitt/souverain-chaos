# UILayoutManager Setup - Schnellanleitung

## Schritt 1: Autoload Registrierung

1. Öffne Godot Editor
2. Gehe zu **Project → Project Settings**
3. Wähle den Tab **Autoload**
4. Konfiguriere:
   - **Path:** `res://scripts/autoload/UILayoutManager.gd`
   - **Node Name:** `UILayoutManager`
   - **Enable:** ✅ aktiviert
5. Klicke **Add**

## Schritt 2: Reihenfolge Prüfen

Der UILayoutManager sollte **VOR** anderen UI-Systemen geladen werden, aber **NACH** EventBus.

**Empfohlene Reihenfolge:**
```
1. EventBus
2. GameState
3. UILayoutManager  ← HIER
4. TimeManager
5. ...
```

Falls nötig, verschiebe UILayoutManager mit den Pfeilen ↑↓.

## Schritt 3: Testen

1. Starte das Spiel (F5)
2. Prüfe Output:
   ```
   UILayoutManager: Initialisiert (Viewport: 1920x1080)
   MapDebugUI: Mit UILayoutManager registriert
   ```

3. Die Debug-UI (F3) sollte jetzt automatisch unter der oberen Menüleiste positioniert sein

## Schritt 4: Konfiguration (Optional)

### Reservierte Bereiche anpassen

Falls deine Menüleisten andere Höhen haben, passe in `UILayoutManager.gd` an:

```gdscript
const RESERVED_TOP: float = 80.0     # Deine Menüleiste oben
const RESERVED_BOTTOM: float = 40.0  # Deine Menüleiste unten
```

### Margins anpassen

```gdscript
const DEFAULT_MARGIN: Vector2 = Vector2(20, 20)  # Größere Margins
const DEFAULT_SPACING: float = 15.0              # Mehr Spacing
```

## Fertig!

Der UILayoutManager ist jetzt aktiv und verwaltet automatisch alle registrierten UI-Panels.

**Nächste Schritte:**
- Siehe [UI_LAYOUT_MANAGER.md](documentation/UI_LAYOUT_MANAGER.md) für vollständige Dokumentation
- Registriere weitere Panels mit dem gleichen Pattern wie MapDebugUI
- Nutze verschiedene Anchor-Bereiche für optimales Layout

## Troubleshooting

**Problem:** UILayoutManager nicht gefunden
- **Lösung:** Prüfe dass Path korrekt ist: `res://scripts/autoload/UILayoutManager.gd`
- **Lösung:** Prüfe dass "Enable" aktiviert ist

**Problem:** Debug-UI nutzt manuelle Positionierung
- **Lösung:** Prüfe Console nach "UILayoutManager nicht verfügbar"
- **Lösung:** Neustart des Editors erforderlich nach Autoload-Änderungen

**Problem:** Debug-UI überlappt Menüleiste
- **Lösung:** Passe `RESERVED_TOP` in UILayoutManager.gd an
- **Lösung:** Erhöhe Wert entsprechend deiner Menüleisten-Höhe

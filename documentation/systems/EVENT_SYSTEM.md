# Event-System Dokumentation

## Übersicht

Das Event-System pausiert die Simulation automatisch wenn Events eintreten und ermöglicht dem Spieler, diese zu bestätigen und fortzusetzen.

## Komponenten

### 1. EventDialog (scenes/ui/EventDialog.tscn + scripts/ui/EventDialog.gd)

Zentraler Dialog zur Anzeige von Events mit:
- **TitleLabel**: Ereignistitel (farbcodiert nach Priorität)
- **MessageLabel**: Ereignisbeschreibung (unterstützt automatischen Zeilenumbruch)
- **ContinueButton**: Fortsetzen-Button

#### Funktionen:

```gdscript
# Einzelnes Event anzeigen
event_dialog.show_event(event_data: Dictionary, priority: int)

# Event-Batch anzeigen (mehrere Low-Priority Events)
event_dialog.show_event_batch(events: Array)
```

#### Prioritäts-Farbcodierung:
- **Priority 2 (Hoch)**: Rot - Wichtige diplomatische/militärische Ereignisse
- **Priority 1 (Normal)**: Weiß - Standard-Ministerberichte
- **Priority 0 (Niedrig)**: Grau - Routineberichte (werden gruppiert)

### 2. Integration in MainUIController

Der EventDialog ist als Child-Node der UILayer in MainUI.tscn eingebunden:
```
UILayer/EventDialog
```

Event-Handler:
- `_on_event_triggered()`: Zeigt einzelne Events an
- `_on_events_batch_triggered()`: Zeigt Event-Batches an

### 3. Fortsetzungsmechanismen

**Zwei Wege zum Fortsetzen:**

1. **LEERTASTE-Hotkey** (temporär, global verfügbar):
   - In `MainUIController._input()` implementiert
   - Ruft `TimeManager.continue_to_next_event()` auf
   - Funktioniert auch wenn Dialog nicht sichtbar

2. **Fortsetzen-Button im Dialog**:
   - In `EventDialog.gd` als `continue_button` implementiert
   - Versteckt Dialog und ruft `TimeManager.continue_to_next_event()` auf

## Zeitablauf

1. Simulation läuft mit automatischer Geschwindigkeitsanpassung
2. Event wird erreicht → `TimeManager.pause_time()`
3. Event-Signal wird gesendet → `EventBus.event_triggered`
4. MainUIController empfängt Signal → Zeigt EventDialog
5. Spieler klickt "Fortsetzen" oder drückt LEERTASTE
6. `TimeManager.continue_to_next_event()` startet Simulation neu
7. Wiederhole ab Schritt 1

## Event-Daten-Struktur

```gdscript
{
    "type": "minister_report",  # Event-Typ für Titel-Zuordnung
    "message": "Ereignistext",  # Anzuzeigende Nachricht
    # ... weitere optionale Felder
}
```

## Event-Typen und Titel

Definiert in `EventDialog._get_event_title()`:
- `minister_report` → "Ministerbericht"
- `diplomatic_briefing` → "Diplomatisches Briefing"
- `population_report` → "Bevölkerungsbericht"
- `monthly_report` → "Monatsbericht"
- `economic_crisis` → "WIRTSCHAFTSKRISE"
- Standard → "Ereignis"

## Beispiel-Events

Siehe `GameInitializer._schedule_initial_events()`:

```gdscript
# Finanzminister-Bericht in 2 Stunden
TimeManager.schedule_event(
    {
        "type": "minister_report",
        "minister": "finance",
        "message": "Exzellenz, der monatliche Wirtschaftsbericht liegt vor."
    },
    2.0,  # Stunden
    1     # Priorität
)
```

## Hinweise für Entwickler

- Events sollten aussagekräftige `message`-Texte haben
- `type` bestimmt den angezeigten Titel
- Priorität 0 für Routine-Events (werden gesammelt angezeigt)
- Priorität 1 für normale Events (Standard)
- Priorität 2 für kritische Events (sofortige Pausierung)
- Batch-Events zeigen max. 5 Einzelmeldungen + "... und X weitere"

## Erweiterungsmöglichkeiten

**Zukünftige Features:**
- Event-Optionen/Entscheidungen (Buttons für verschiedene Reaktionen)
- Charakterportraits im Dialog
- Sound-Effekte für verschiedene Event-Typen
- Event-Historie/Log
- Automatisches Fortsetzen für Low-Priority Events nach Timeout

# Event Manager System - Multi-Choice Events mit Effekten

## Übersicht

Das Event Manager System ermöglicht die Erstellung von Events mit **mehreren Auswahlmöglichkeiten**, die jeweils unterschiedliche **Effekte auf Spielwerte** haben. Events werden in der UI angezeigt, die Effekte werden in der Konsole ausgegeben.

## Architektur

### Komponenten

1. **EventManager** (`autoload/EventManager.gd`) - Autoload Singleton
   - Verwaltet Event-Bibliothek mit vordefinierten Events
   - Triggert Events und sendet sie an UI
   - Wendet Effekte an wenn Spieler Option wählt
   - Loggt alle Effekte ausführlich in Konsole

2. **EventDialog** (`scripts/ui/EventDialog.gd`)
   - Zeigt Event-Titel und Beschreibung
   - Generiert Buttons für jede Option dynamisch
   - Prüft Voraussetzungen (z.B. Reality Points)
   - Sendet gewählte Option zurück an EventManager

3. **EventBus** - Neues Signal
   - `choice_event_triggered(event_data: Dictionary)` - Für Multi-Choice Events

4. **GameInitializer** - Event-Planung
   - Plant Events über TimeManager
   - Events werden zu festgelegten Zeiten getriggert

## Event-Datenstruktur

```gdscript
{
	"id": "unique_event_id",
	"title": "Event-Titel",
	"description": "Ausführliche Beschreibung der Situation",
	"type": "economic" / "diplomatic" / "internal" / "technology" / "character" / "environmental" / "military",
	"options": [
		{
			"label": "Kurzer Titel der Option",
			"description": "Was diese Option macht",
			"effects": {
				# Spieler-Ressourcen
				"money": -500000,              # +/- Geld
				"legitimacy": 10,              # +/- Legitimität (0-100)
				"reality_points": -30,         # +/- Realitätspunkte

				# Nation-Werte
				"nation_gdp_growth": 2.0,      # +/- BIP-Wachstum
				"nation_unemployment": -3.0,   # +/- Arbeitslosigkeit
				"nation_debt": 1000000,        # +/- Staatsschulden
				"nation_military_strength": 50, # +/- Militärstärke
				"nation_tech_level": 0.5,      # +/- Tech-Level (1-7)

				# Beziehungen
				"relationship_nordreich": -20,        # Zu spezifischer Nation
				"relationship_suedkonfoederation": 15,
				"relationship_all": -5,               # Zu allen anderen Nationen

				# Provinz-Effekte
				"province_unrest_all": 15.0,          # Unruhe in allen Provinzen
				"province_unrest_coastal": -20.0      # Unruhe in Küstenprovinzen
			},
			"console_message": "Text der in Konsole angezeigt wird",
			"requires": {                    # Optional: Voraussetzungen
				"reality_points": 50
			},
			"triggers_war": "nation_id",     # Optional: Kriegserklärung
			"triggers_war_risk": true        # Optional: Kriegsgefahr-Warnung
		}
	]
}
```

## Implementierte Events

### 1. Wirtschaftskrise: Steuerpolitik (`economic_crisis_tax`)
**Situation:** Wirtschaft stagniert, 15% Arbeitslosigkeit

**Optionen:**
- **Steuern senken** - Marktlösung
  - Effekte: -$500k, -5 Legitimität, +2% BIP-Wachstum, -3% Arbeitslosigkeit
- **Staatsausgaben erhöhen** - Keynesianismus
  - Effekte: -$2M, +10 Legitimität, +3.5% BIP-Wachstum, -5% Arbeitslosigkeit, +$1M Schulden
- **Sparpolitik** - Austerität
  - Effekte: +$1M, -20 Legitimität, -1.5% BIP-Wachstum, +4% Arbeitslosigkeit
- **Realitäts-Verzerrung** - Übernatürlich
  - Effekte: +$5M, -50 Reality Points, -30 Legitimität, +5% BIP-Wachstum, -10% Arbeitslosigkeit
  - Voraussetzung: 50 Reality Points

### 2. Diplomatische Krise: Grenzkonflikt (`diplomatic_crisis_border`)
**Situation:** Nordreich zieht Truppen an Grenze zusammen

**Optionen:**
- **Verhandeln** - Friedlich
- **Zurückweisen** - Fest
- **Präventivschlag** - Kriegserklärung!
- **Bündnis aktivieren** - Südkonföderation um Hilfe bitten

### 3. Massenproteste in der Hauptstadt (`internal_crisis_protests`)
**Situation:** Hunderttausende demonstrieren

**Optionen:**
- **Zugeständnisse machen**
- **Ignorieren**
- **Polizeigewalt einsetzen**
- **Dialog suchen**

### 4. Technologischer Durchbruch (`tech_breakthrough`)
**Situation:** Durchbruch bei erneuerbaren Energien

**Optionen:**
- **Massiv investieren**
- **Vorsichtig investieren**
- **Technologie verkaufen**
- **Realitäts-Boost** - Sofortige Implementierung

### 5. Ministerrücktritt (`minister_resignation`)
**Situation:** Verteidigungsminister in Korruptionsskandal

**Optionen:**
- **Rücktritt akzeptieren**
- **Minister schützen**
- **Untersuchung anordnen**
- **Sündenbock opfern**

### 6. Umweltkatastrophe: Ölpest (`environmental_disaster`)
**Situation:** Massive Ölpest bedroht Küsten

**Optionen:**
- **Großeinsatz starten**
- **Minimale Maßnahmen**
- **Verursacher verklagen**
- **Realitäts-Reinigung** - Öl verschwinden lassen

### 7. Militärischer Zwischenfall (`military_incident`)
**Situation:** Ausländisches Spionageflugzeug im Luftraum

**Optionen:**
- **Zur Landung zwingen**
- **Eskorte aus Luftraum**
- **Abschießen** - Kriegsgefahr!
- **Ignorieren**

## Event-Zeitplan (GameInitializer)

```
3 Stunden:  Wirtschaftskrise (Priorität 2)
2 Tage:     Diplomatische Krise (Priorität 2)
5 Tage:     Massenproteste (Priorität 2)
10 Tage:    Tech-Durchbruch (Priorität 1)
15 Tage:    Minister-Skandal (Priorität 2)
20 Tage:    Umweltkatastrophe (Priorität 2)
25 Tage:    Militärischer Zwischenfall (Priorität 2)
```

## Konsolen-Ausgabe

Wenn Spieler eine Option wählt, wird in der Konsole ausgegeben:

```
================================================================================
[EventManager] EFFEKTE von 'Wirtschaftskrise: Steuerpolitik' - Option: 'Staatsausgaben erhöhen (Keynesianismus)'
================================================================================
💰 Geld: -$2.000.000 (Neu: $7.500.000)
⚖️  Legitimität: +10 (Neu: 60)
📈 BIP-Wachstum: +3.5% (Neu: 5.5%)
👷 Arbeitslosigkeit: -5.0% (Neu: 10.0%)
💸 Staatsschulden: +$1.000.000 (Neu: $5.000.000)

📜 Konjunkturprogramm gestartet. Große Infrastrukturprojekte schaffen Arbeitsplätze.
================================================================================
```

### Effekt-Icons
- 💰 Geld
- ⚖️ Legitimität
- ✨ Realitätspunkte
- 📈 BIP-Wachstum
- 👷 Arbeitslosigkeit
- 💸 Staatsschulden
- ⚔️ Militärstärke
- 🔬 Tech-Level
- 🤝 Beziehungen
- 🏛️ Unruhe (alle Provinzen)
- 🌊 Unruhe (Küstenprovinzen)

## Neue Events hinzufügen

### 1. Event in EventManager registrieren

In `EventManager._initialize_event_library()`:

```gdscript
event_library["my_event_id"] = {
	"id": "my_event_id",
	"title": "Mein Event-Titel",
	"description": "Beschreibung...",
	"type": "economic",
	"options": [
		{
			"label": "Option 1",
			"description": "Was passiert...",
			"effects": {
				"money": -1000000,
				"legitimacy": 5
			},
			"console_message": "Option 1 gewählt!"
		},
		# Weitere Optionen...
	]
}
```

### 2. Event in GameInitializer einplanen

In `GameInitializer._schedule_initial_events()`:

```gdscript
TimeManager.schedule_event(
	{
		"type": "choice_event",
		"event_id": "my_event_id"
	},
	24.0,  # Stunden bis Event
	2      # Priorität (0=niedrig, 1=normal, 2=hoch)
)
```

### 3. Event manuell triggern (z.B. in Code)

```gdscript
EventManager.trigger_event("my_event_id")
```

## UI-Verhalten

### Event-Anzeige
- Dialog erscheint zentriert mit orangefarbenem Titel
- Beschreibung mit Autowrap
- Optionen als Buttons (60px Höhe)
- Buttons deaktiviert wenn Voraussetzungen nicht erfüllt

### Optionen-Buttons
Format:
```
[Option-Label]
[Option-Beschreibung]
❌ Voraussetzungen nicht erfüllt (falls benötigt)
```

### Nach Wahl
- Dialog schließt
- Effekte werden angewendet
- Zeit läuft weiter (falls pausiert)

## Voraussetzungen-System

Events können Voraussetzungen für Optionen definieren:

```gdscript
"requires": {
	"reality_points": 50  # Spieler braucht mindestens 50 Reality Points
}
```

Wenn nicht erfüllt:
- Button wird deaktiviert (disabled)
- Text "❌ Voraussetzungen nicht erfüllt" wird angehängt

Erweiterbar für:
- `"money": 1000000` - Mindest-Geld
- `"legitimacy": 70` - Mindest-Legitimität
- `"tech_level": 5` - Mindest-Tech-Level
- etc.

## Effekt-Anwendung

### Spieler-Ressourcen
```gdscript
GameState.player_resources.money += effects.money
GameState.player_resources.legitimacy += effects.legitimacy
GameState.player_resources.reality_points += effects.reality_points
```

### Nation-Werte
```gdscript
var player_nation = GameState.get_player_nation()
player_nation.gdp_growth += effects.nation_gdp_growth
player_nation.unemployment += effects.nation_unemployment
# etc.
```

### Beziehungen
```gdscript
player_nation.relationships[nation_id] += change
# Clamped auf -100 bis 100
```

### Provinzen
- `province_unrest_all`: Alle Provinzen
- `province_unrest_coastal`: Nur Provinzen mit `has_port == true`

## Historische Aufzeichnung

Jede Event-Wahl wird automatisch in `HistoricalContext` gespeichert:

```gdscript
HistoricalContext.add_game_event(
	GameState.current_date,
	event_data.type,
	event_data.title,
	"Gewählt: %s - %s" % [chosen_option.label, chosen_option.console_message],
	70,  # narrative_weight
	{}
)
```

## Testing

### Spiel im Godot Editor starten (F5)

1. Spiel startet
2. Nach 3 Stunden: Erstes Event "Wirtschaftskrise"
3. Dialog öffnet mit 4 Optionen
4. Option wählen
5. Konsole zeigt alle Effekte
6. Weitere Events folgen nach Zeitplan

### Manuelles Triggern in der Konsole

Füge temporär in `MainUIController._ready()` hinzu:
```gdscript
# Test: Event sofort triggern
EventManager.trigger_event("economic_crisis_tax")
```

## Zukünftige Erweiterungen

### Bedingte Events
```gdscript
"trigger_conditions": {
	"min_unemployment": 15.0,
	"max_legitimacy": 50
}
```

### Event-Ketten
```gdscript
"triggers_followup_event": "next_event_id",
"followup_delay_hours": 24.0
```

### Dynamische Optionen
Optionen basierend auf Spielzustand generieren

### Charakterbezogene Events
Events die spezifische Charaktere betreffen

### Randomisierte Effekte
```gdscript
"effects": {
	"money": {"min": -1000000, "max": -500000}
}
```

## Code-Referenzen

- EventManager: `autoload/EventManager.gd`
- EventDialog: `scripts/ui/EventDialog.gd`
- EventDialog Scene: `scenes/ui/EventDialog.tscn`
- EventBus: `autoload/EventBus.gd:20` (choice_event_triggered Signal)
- MainUIController: `scripts/ui/MainUIController.gd:310` (_on_event_triggered)
- GameInitializer: `autoload/GameInitializer.gd:49` (_schedule_initial_events)
- Project Settings: `project.godot:25` (EventManager Autoload)

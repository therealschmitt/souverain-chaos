# Test-Simulation Dokumentation

## Generierte Welt

### 3 Nationen:

**1. Thalassische Republik** (Spieler-Nation)
- Bevölkerung: 45.000.000
- BIP: 500 Mrd
- Regierung: Demokratie
- Leader: Präsidentin Alexandra Petrov (52)
- Legitimität: 65%
- Arbeitslosigkeit: 6,5%
- Tech-Level: 4 (Zeitgenössisch)

**2. Nordreich**
- Bevölkerung: 28.000.000
- BIP: 300 Mrd
- Regierung: Konstitutionelle Monarchie
- Leader: König Harald VII (68)
- Legitimität: 80%
- Beziehung zu Thalassia: +45 (freundlich)

**3. Südkonföderation**
- Bevölkerung: 52.000.000
- BIP: 400 Mrd
- Regierung: Föderation
- Leader: General Marcus Chen (45)
- Legitimität: 55%
- Beziehung zu Thalassia: -20 (angespannt)

### 9 Provinzen (3 pro Nation)

Jede Provinz hat:
- Terrain-Typ (coastal, plains, mountains, forest, desert)
- Bevölkerung + urbane Bevölkerung
- Ressourcen (basierend auf Terrain)
- Infrastruktur-Level

## Laufende Simulation

### Bevölkerungswachstum
- **1% pro Jahr** (realistisch)
- **Pro Tag**: ca. 0,00274%
- Beispiel Thalassia: +1.233 Menschen/Tag
- Wird täglich aktualisiert
- Log-Ausgabe jeden Monat (Tag 1)

### Wirtschaft
- BIP wächst entsprechend `gdp_growth`
- Täglich ein 365stel des Jahreswachstums

### Charaktere
- 3 Leader-Charaktere generiert
- Volle Persönlichkeitsprofile
- Ideologische Positionen
- Skills definiert

## Eingeplante Test-Events

1. **In 2 Stunden**: Finanzminister-Bericht (Priorität 1)
2. **In 1 Tag**: Diplomatischer Zwischenfall (Priorität 2 - hohe Priorität)
3. **In 7 Tagen**: Bevölkerungsbericht (Priorität 0 - niedrig)
4. **In 30 Tagen**: Monatsbericht (Priorität 1)

## Testen der Simulation

### 1. Spiel starten
- Konsole zeigt: "=== SPIEL-INITIALISIERUNG ==="
- Welt wird generiert
- Events werden eingeplant

### 2. Zeit vorspulen (wenn "Weiter"-Button implementiert ist)
- Zeit läuft automatisch bis zum nächsten Event
- Geschwindigkeit passt sich an:
  - Stündlich (< 1 Tag entfernt)
  - Täglich langsam (1-7 Tage)
  - Täglich schnell (7-30 Tage)
  - Monatlich (> 30 Tage)

### 3. Events beobachten
- Bei Event-Trigger: Konsole zeigt "Event triggered: ..."
- Zeit pausiert automatisch
- Event-Daten werden ausgegeben

### 4. Bevölkerungswachstum beobachten
- Jeden Monat (Tag 1): Konsole zeigt Bevölkerungszahlen
- Nach 1 Jahr: Bevölkerung sollte um ~1% gewachsen sein
- Beispiel: 45.000.000 → 45.450.000 nach 1 Jahr

## Console-Output Beispiel

```
=== SPIEL-INITIALISIERUNG ===
WorldGenerator: Generiere Test-Welt...
WorldGenerator: Welt generiert - 3 Nationen, 9 Provinzen, 3 Charaktere
HistoricalContext: Generiert 4 Prägungen und 10 historische Events
GameInitializer: 4 Test-Events eingeplant
=== INITIALISIERUNG ABGESCHLOSSEN ===
Startdatum: 1.1.2000 00:00
Spieler-Nation: Thalassische Republik
Bevölkerung: 45000000

[Zeit läuft...]

Nation Thalassische Republik: Bevölkerung = 45037123 (+1233/Tag)
Nation Nordreich: Bevölkerung = 28023156 (+767/Tag)
Nation Südkonföderation: Bevölkerung = 52042891 (+1425/Tag)

[Event nach 2 Stunden]
Event triggered: {"type":"minister_report", ...} Priority: 1

[Zeit läuft weiter...]
```

## Erweiterungsmöglichkeiten

- Mehr Nationen/Provinzen generieren
- Komplexere Wirtschaftssimulation
- Politische Events
- Diplomatische Aktionen
- Kriegssystem
- Charakterentwicklung
- Mehr Event-Typen

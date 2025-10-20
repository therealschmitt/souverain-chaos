# SOVEREIGN CHAOS - Game Design Dokument

## 1. VISION & KERNKONZEPT

**Tagline**: *"Regiere. Entscheide. Verändere die Realität."*

Ein prozedural generiertes Sandbox-Staatsführungsspiel, das absolute Freiheit mit tiefer Simulation verbindet. Der Spieler führt einen Staat durch eine dynamische Welt, wo jede Entscheidung von pragmatisch-realistisch bis zu realitätsverzerrend übernatürlich reichen kann.

### Alleinstellungsmerkmale
- **Kein festes Optionssystem**: Aktionen werden durch Kombinationen von Parametern konstruiert
- **Übernatürliche "Reality Bending" Mechaniken** neben realistischer Simulation
- **Prozedurale Weltgenerierung** mit persistenter Kausalität
- **Tiefe Echtzeitssimulation** von Millionen simulierten Akteuren
- **Keine moralischen Grenzen** - aber realistische Konsequenzen

---

## 2. WELTGENERIERUNG & SEED-SYSTEM

### 2.1 Seed-Architektur

Der **Master Seed** generiert:
```
Seed-ID (8 Zeichen alphanumerisch)
├── Geografische Daten (Kontinente, Klimazonen, Ressourcen)
├── Historische Timeline (0-5000 Jahre simulierte Geschichte)
├── Kulturelle/ethnische Gruppen (30-200)
├── Technologische Entwicklungspfade
├── Ideologische Strömungen
└── Startbedingungen für alle Staaten
```

### 2.2 Konfigurier bare Parameter beim Start

**Weltparameter:**
- **Planetgröße**: Klein (50 Staaten) bis Massiv (500+ Staaten)
- **Ressourcenverteilung**: Gleichmäßig / Konzentriert / Chaotisch
- **Technologiedivergenz**: Gering (±20 Jahre) bis Extrem (Steinzeit bis Sci-Fi)
- **Ideologische Polarisierung**: Niedrig / Mittel / Extrem
- **Historische Konflikte**: Friedlich / Normal / Kriegsgebeutelt
- **Übernatürliche Anomalien**: Aus / Selten / Häufig / Allgegenwärtig

**Startstaat-Parameter:**
- **Staatsgröße**: Mikrostaat bis Supermacht
- **Technologielevel**: 7 Stufen (Rückständig → Post-Scarcity Sci-Fi)
- **Regierungsform**: 30+ Varianten (Demokratie, Diktatur, Theokratie, KI-Regierung, etc.)
- **Wirtschaftssystem**: Marktwirtschaft / Planwirtschaft / Hybrid / Post-Kapitalismus
- **Startkrisen**: Keine / Moderat / Mehrfachkrise
- **Persönlicher Herrschaftsstil**: Autokratisch / Beratend / Zeremoniell
- **Startressourcen**: Arm / Normal / Reich
- **Legitimität**: Niedrig (Coup) / Mittel (Gewählt) / Hoch (Dynastie)

### 2.3 Ausgangsstory-Generator

Basierend auf Seed + Parametern wird eine **Intro-Sequenz** generiert:

**Story-Komponenten:**
1. **Wie du an die Macht kamst** (12 Archetypen: Wahl, Coup, Erbfolge, Revolution, Intervention, etc.)
2. **Aktuelle Krise** (0-3 simultane Krisen: Wirtschaft, Aufstand, Krieg, Naturkatastrophe, etc.)
3. **Schlüsselfiguren** (5-15 wichtige Politiker, Militärs, Wirtschaftsbosse mit Beziehungen zu dir)
4. **Internationale Lage** (Bündnisse, Rivalitäten, aktive Konflikte)
5. **Öffentliche Stimmung** (Approval Rating, Protestpotential, Erwartungen)

**Präsentationsformat:**
- Briefing-Stil mit Karten
- Charakterporträts der Schlüsselfiguren
- Nachrichtenschnipsel
- Geheimdienst-Dossiers
- Wirtschaftsberichte

---

## 3. SIMULATIONSSYSTEME

### 3.1 Bevölkerungssimulation

**Abstraktionsebenen:**
- **Makro**: Gesamtbevölkerung in Provinzen (Statistiken, Trends)
- **Meso**: 1000-10000 "Bevölkerungsgruppen" (Kohorten mit geteilten Eigenschaften)
- **Mikro**: 100-1000 "simulierte Individuen" (Schlüsselfiguren mit voller Simulation)

**Bevölkerungsgruppen-Attribute:**
- Demografie (Alter, Geschlecht, Ethnizität, Religion)
- Sozioökonomisch (Einkommen, Bildung, Beruf, Vermögen)
- Politisch (Ideologie, Parteipräferenz, Aktivismus-Grad)
- Psychologisch (Zufriedenheit, Ängste, Hoffnungen, Wertesystem)
- Verhalten (Konsumverhalten, Mobilität, Medienkonsum)

**Simulierte Dynamiken:**
- **Meinungsbildung**: Netzwerkbasierte Meme-Verbreitung
- **Radikalisierung**: Trigger-basiert (Wirtschaftskrise, Repression, Propaganda)
- **Migration**: Zwischen Regionen und Staaten
- **Soziale Mobilität**: Bildung, Wirtschaftswachstum, Nepotismus
- **Generationenwechsel**: Neue Generationen mit anderen Werten

### 3.2 Wirtschaftssimulation

**Multi-Ebenen-Modell:**

**Makroökonomie:**
- BIP-Wachstum (sektorbasiert)
- Inflation / Deflation
- Arbeitslosenquote
- Staatshaushalt (Einnahmen vs. Ausgaben)
- Staatsverschuldung & Bonität
- Währungsstabilität & Wechselkurse

**Mesoökonomie (Sektoren):**
- Primär (Landwirtschaft, Rohstoffe)
- Sekundär (Industrie, Produktion)
- Tertiär (Dienstleistungen)
- Quartär (Informationstechnologie)
- Quintär (Wissenschaft, KI, Zukunftstechnologien)

Jeder Sektor hat:
- Produktionskapazität
- Beschäftigte
- Investitionsbedarf
- Technologie-Level
- Internationale Konkurrenzfähigkeit

**Mikroökonomie (Firmen):**
- 50-500 simulierte "Major Corporations"
- Monopolgrad & Marktmacht
- CEOs mit Persönlichkeiten & Ambitionen
- Lobbying-Aktivitäten
- Korruptionsanfälligkeit

**Ressourcenwirtschaft:**
- 20-30 Ressourcentypen (Öl, Seltene Erden, Nahrung, Wasser, etc.)
- Abbau, Verbrauch, Handel
- Strategische Bedeutung
- Umweltauswirkungen

**Handel:**
- Bilaterale Handelsabkommen
- Zölle & Sanktionen
- Handelsrouten (Land, See, Luft, Weltraum bei Sci-Fi)
- Handelskriege

### 3.3 Politiksimulation

**Individuelle Politiker (100-1000 pro Staat):**

**Kernattribute:**
- **Persönlichkeit**: Big Five + Machiavellismus, Autoritarismus, Risikobereitschaft
- **Ideologie**: Multi-Achsen-System (Wirtschaft, Gesellschaft, Außenpolitik, Technologie)
- **Kompetenzen**: 10+ Skills (Ökonomie, Militär, Diplomatie, Redekunst, Intrige, etc.)
- **Ambitionen**: Kurz- und Langzeitziele (Macht, Reichtum, Ideale, Rache, etc.)
- **Beziehungen**: Netzwerk mit anderen Politikern (Loyalität, Freundschaft, Rivalität, Erpressbarkeit)
- **Ressourcen**: Eigene Geldmittel, Kontakte, Medienpräsenz

**Fraktionen & Parteien:**
- Dynamische Bildung basierend auf Ideologie-Clustern
- Interne Flügelkämpfe
- Koalitionsbildung & -brüche
- Populistische vs. Elite-Bewegungen

**Machtstrukturen:**
Abhängig von Regierungsform:
- **Demokratie**: Parlament, Ministerien, Gerichte, Medien, Oppositionsführer
- **Diktatur**: Innerer Zirkel, Geheimdienst, Militär, Oligarchen
- **Theokratie**: Religiöse Hierarchie, Gelehrtenräte
- **Konzernherrschaft**: Vorstand, Aktionäre, Manager
- **KI-Regierung**: Subroutinen, Entwickler, Widerstandsgruppen
- **Anarchie**: Warlords, Räte, Milizen

**Politische Mechaniken:**
- **Machtkämpfe**: Coups, Putsche, Impeachment, Wahlen
- **Intrigen**: Komplotte, Erpressung, Mord, Skandale
- **Öffentliche Meinung**: Reden, PR-Kampagnen, Medienmanipulation
- **Korruption**: Bestechung, Vetternwirtschaft, Klientelismus

### 3.4 Außenpolitik & Internationale Ordnung

**Diplomatische Beziehungen:**
- Bilaterale Beziehungen (−100 bis +100)
- Bündnisse (Defensiv, Offensiv, Wirtschaft, Ideologisch)
- Rivalitäten & Feindschaften
- Abhängigkeiten (Wirtschaft, Militär, Technologie)

**Internationale Organisationen:**
- UN-ähnliche Weltorganisation
- Regionale Bündnisse (EU, NATO, etc. Äquivalente)
- Wirtschaftsbündnisse
- Militärpakte
- Ideologische Blöcke

**Konfliktdynamiken:**
- **Diplomatische Krisen**: Sanktionen, Botschaftsschließungen, Ultimaten
- **Stellvertreterkriege**: Unterstützung von Rebellengruppen
- **Konventionelle Kriege**: Mit Kriegszielverhandlungen
- **Totale Kriege**: Vernichtungsabsicht
- **Guerillakriege**: Asymmetrische Konflikte
- **Cyberkriege**: Bei entsprechendem Tech-Level
- **Nuklearoptionen**: Bei entsprechendem Tech-Level

**Geheimdienste:**
- Spionage (Informationsbeschaffung)
- Sabotage (Infrastruktur, Wirtschaft)
- Assassinationen
- Coup-Unterstützung
- Propaganda & Desinformation

### 3.5 Militärsimulation

**Streitkräftestruktur:**
- Heer, Marine, Luftwaffe (+ Weltraum bei Sci-Fi)
- Einheitentypen abhängig von Tech-Level
- Veteranität & Moral
- Ausrüstungsqualität
- Logistik & Versorgung

**Militärische Führung:**
- Generäle mit Loyalität & Kompetenz
- Fraktionen innerhalb des Militärs
- Coup-Risiko

**Kampfsystem:**
- Echtzeitschlachten auf Provinzebene (abstrahiert, nicht mikrokontrolliert)
- Faktoren: Zahlenverhältnis, Technologie, Terrain, Moral, Führung
- Kriegsverbrechen & deren Konsequenzen
- Besatzungsverwaltung

### 3.6 Technologie & Wissenschaft

**Tech-Tree:**
Nicht linear, sondern vernetzt mit 300+ Technologien in:
- Infrastruktur
- Militär
- Wirtschaft
- Medizin/Bio
- Informatik/KI
- Energie
- Raumfahrt
- Exotische Technologien (bei Sci-Fi Setting)

**Forschungssystem:**
- Budget-Allokation
- Wissenschaftler-Pool
- Internationale Kooperation vs. Geheimhaltung
- Technologie-Spionage & -Diebstahl
- Breakthrough Events (zufällige Durchbrüche)

**Technologieverbreitung:**
- Lizenzen & Patente
- Technologietransfer
- Industriespionage
- Reverse Engineering

### 3.7 Umwelt & Katastrophen

**Umweltparameter:**
- Klimawandel (bei entsprechendem Setting)
- Umweltverschmutzung
- Ressourcenerschöpfung
- Biodiversität

**Naturkatastrophen:**
- Erdbeben, Tsunamis, Vulkane (geografiebasiert)
- Stürme, Dürren, Überschwemmungen (klimabasiert)
- Epidemien (sozioökonomisch beeinflusst)
- Meteoriteneinschläge (selten, katastrophal)

**Vom Menschen verursachte Katastrophen:**
- Nuklearunfälle
- Industrieunglücke
- Dammbrüche
- Umweltkatastrophen (Ölpest, etc.)

---

## 4. KARTENBASIERTES UI-DESIGN

### 4.1 Kartensystem (Zentrale Interface-Komponente)

**5 Zoomstufen:**

1. **Weltkarte**
   - Alle Staaten sichtbar
   - Farbcodierung: Bündnisse, Ideologie, Wohlstand, Kriegszustand
   - Handelswege, Migrationsbewegungen (optional)
   - Globale Ereignisse (Kriege, Krisen)

2. **Regionalkarte** (Kontinent/Subkontinent)
   - 5-30 Staaten
   - Detailliertere Grenzen
   - Militärbewegungen
   - Wirtschaftszonen

3. **Staatskarte**
   - Alle Provinzen deines Staates
   - Infrastruktur (Straßen, Eisenbahn, Häfen, Flughäfen)
   - Ressourcenvorkommen
   - Unruheherde, Militärstützpunkte

4. **Provinzkarte**
   - Einzelne Provinz im Detail
   - Städte & Ortschaften
   - Industrieanlagen, Farmen
   - Demographische Daten
   - Lokale Ereignisse

5. **Hauptstadt-Detail**
   - Wichtige Gebäude (Regierungssitz, Militär, Konzerne, Medien)
   - Viertel mit sozioökonomischen Daten
   - Proteste, Events
   - Symbolische "Zentrale der Macht"

**Karteninteraktionen:**
- Klick auf Elemente → Info-Panel
- Kontextmenü für Schnellaktionen
- Layer-Toggle (Militär, Wirtschaft, Demografie, etc.)
- Zeitraffer (Entwicklungen über Zeit visualisieren)

### 4.2 Interface-Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [Menü] [Datum/Uhrzeit] [Pause/Speed]    [Geld] [Legitimität]│
├───────────────────────┬─────────────────────────────────────┤
│                       │  ┌───────────────────────────────┐  │
│                       │  │     EREIGNIS / DIALOG BOX     │  │
│                       │  │                               │  │
│       KARTE           │  │   [Charakterportrait(s)]      │  │
│     (Zentral)         │  │                               │  │
│                       │  │   [Ereignistext]              │  │
│                       │  │                               │  │
│                       │  │   [Handlungsparameter]        │  │
│                       │  └───────────────────────────────┘  │
│                       │  [Quick Stats Panel]               │
├───────────────────────┴─────────────────────────────────────┤
│  [Berater] [Reports] [Militär] [Diplomatie] [Wirtschaft]   │
└─────────────────────────────────────────────────────────────┘
```

**Quick Stats Panel (immer sichtbar):**
- Bevölkerungszufriedenheit
- BIP-Wachstum
- Staatsfinanzen
- Militärstärke
- Diplomatischer Status
- Aktive Krisen (mit Warnsymbolen)

### 4.3 Ereignis/Dialog-System

**Präsentationsformat:**
- **Charakterporträts**: Links/rechts oder oben (je nach Gesprächspartner-Anzahl)
- **Sprechblasen-Stil**: Wer sagt was
- **Körpersprache-Indikatoren**: Emotional state durch Gesichtsausdrücke/Posen
- **Hintergrundinformationen**: Einblendbare Dossiers zu Personen

**Dialog-Optionen:**
- NICHT fest vorgegeben (3 Optionen)
- Stattdessen: **Parameterbasiertes Aktionssystem** (siehe Kapitel 5)

---

## 5. ENTSCHEIDUNGS- & AKTIONSSYSTEM

### 5.1 Parameterbasierte Aktionskonstruktion

**Kernprinzip:** Statt fester Multiple Choice gibt es ein **Aktionskonstruktions-Interface**.

**Aktionsparameter:**

1. **WAS** (Ziel der Aktion)
   - Person (verhaften, befördern, assassinieren, etc.)
   - Gruppe (unterdrücken, fördern, umsiedeln, etc.)
   - Infrastruktur (bauen, zerstören, privatisieren, etc.)
   - Gesetz (erlassen, aufheben, ändern)
   - Ressource (beschlagnahmen, verteilen, exportieren, etc.)
   - Information (veröffentlichen, zensieren, fälschen, etc.)

2. **WIE** (Methode)
   - Legal
   - Heimlich
   - Gewaltsam
   - Diplomatisch
   - Wirtschaftlich
   - Propagandistisch

3. **INTENSITÄT** (Schieberegler 0-100%)
   - Moderat → Extrem
   - Beeinflusst Effektivität UND Risiko

4. **SCOPE** (Umfang)
   - Einzelfall
   - Lokal (Provinz)
   - National
   - International

5. **RESSOURCENEINSATZ** (Budget)
   - Wenig → Viel
   - Beeinflusst Erfolgswahrscheinlichkeit

**Beispiel-Interface:**
```
┌─────────────────────────────────────────┐
│ AKTION KONSTRUIEREN                     │
├─────────────────────────────────────────┤
│ Ziel: [Dropdown: Oppositionsführer]     │
│ Aktion: [Dropdown: Neutralisieren]      │
│ Methode: [Dropdown: Heimliche Tötung]   │
│ Intensität: [═══════░░░] 70%            │
│ Ressourcen: [$$$░░░░░] $5M              │
├─────────────────────────────────────────┤
│ Erfolgswahrscheinlichkeit: 65%          │
│ Risiken:                                │
│  • Skandal wenn aufgedeckt: Hoch        │
│  • Destabilisierung: Mittel             │
│  • Internationale Kritik: Mittel        │
├─────────────────────────────────────────┤
│ [AUSFÜHREN] [ABBRECHEN] [BERATER FRAGEN]│
└─────────────────────────────────────────┘
```

### 5.2 Schnellaktionen (Hotkeys & Vorlagen)

Für häufige Aktionen:
- **Vorlagen** (Templates): "Standard-Unterdrückung", "Wirtschaftsförderung", "Diplomatische Offensive"
- **Hotkeys**: Schneller Zugriff auf wichtige Aktionen
- **Berater-Vorschläge**: KI schlägt sinnvolle Parametereinstellungen vor (basierend auf Kontext)

### 5.3 Realitätsverzerrende Aktionen ("Reality Bending")

**Aktivierung:**
- Durch spezielle Technologien (Sci-Fi)
- Durch "Anomalien" in der Welt (wenn aktiviert)
- Durch mysteriöse Forschung
- Durch Pakte (mit ominösen Entitäten)

**Kostenmodell:**
- "Reality Points" (begrenzte Ressource)
- Regeneriert langsam
- Oder: Pro Einsatz wachsende "Instabilitätsrisiken"

**Beispiele für Reality Bending Aktionen:**

**Militärisch:**
- "Soldaten-Transformation": Feinde werden zu deinen Soldaten (temporär)
- "Waffen-Jam": Alle feindlichen Waffen versagen für X Stunden
- "Unsichtbarer Angriff": Deine Truppen sind für X Stunden unsichtbar
- "Logistik-Reverse": Feindliche Nachschublinien beliefern deine Armee

**Wirtschaftlich:**
- "Gelddruckmaschine": Inflation-freie Geldschöpfung (begrenzt)
- "Ressourcen-Verdopplung": Alle abgebauten Ressourcen verdoppeln sich (temporär)
- "Marktmanipulation": Aktienkurse/Rohstoffpreise nach Wunsch verändern
- "Universelles Grundeinkommen aus dem Nichts": Bevölkerung erhält Geld ohne Inflation

**Sozial:**
- "Massenhypnose": Eine Bevölkerungsgruppe glaubt temporär an X
- "Erinnerungs-Rewrite": Historisches Ereignis wird anders erinnert
- "Charisma-Boost": Deine Beliebtheit +50 für X Tage (unabhängig von Taten)
- "Generationenlöschung": Bestimmte Altersgruppe verschwindet (EXTREM)

**Politisch:**
- "Loyalitäts-Swap": Zwei Politiker tauschen ihre Loyalität
- "Skandal-Unsichtbarkeit": Ein Skandal wird von allen vergessen
- "Instant-Revolution": Revolutionäres Ereignis in Zielstaat
- "Ideologie-Shift": Masse von Menschen ändert Ideologie

**Wissenschaftlich:**
- "Instant-Technologie": Eine Technologie wird sofort erforscht
- "Physik-Aussetzen": Naturgesetze temporär außer Kraft (z.B. Schwerkraft)
- "Zeit-Beschleunigung": Ein Sektor entwickelt sich 10x schneller
- "Pandora-Box": Zufällige Supertechnologie (unkalkulierbare Folgen)

**Kosmisch/Bizarr:**
- "Tag/Nacht-Tausch": Tag und Nacht tauschen für X Zeit (psychologische Effekte)
- "Wetter-Diktatur": Wetter nach Wunsch in deinem Staat
- "Sprachen-Babel": Feindstaat verliert Kommunikationsfähigkeit (temporär)
- "Doppelgänger-Chaos": Alle Politiker haben Doppelgänger (Verwirrung)

**Konsquenzen von Reality Bending:**
- **Realitätsinstabilität**: Wiederholter Einsatz führt zu Glitches, Paradoxien, Anomalien
- **Internationale Reaktion**: Andere Staaten können es bemerken → Panik, Bündnisse gegen dich
- **Interne Unruhe**: Bevölkerung bemerkt unnatürliche Phänomene → Angst, Religion, Revolten
- **Technologie-Rüstungswettkampf**: Andere versuchen, eigene Reality-Bending-Fähigkeiten zu entwickeln

### 5.4 Konsequenzsystem

Jede Aktion wird ausgewertet durch:

**Direkte Effekte:**
- Sofortige Änderungen (Person tot, Gesetz in Kraft, etc.)

**Sekundäreffekte:**
- Reaktionen anderer Akteure (Politiker, Bevölkerung, Ausland)
- Ökonomische Auswirkungen
- Soziale Dynamiken

**Langzeitfolgen:**
- Präzedenzfälle (zukünftige Aktionen werden einfacher/schwerer)
- Reputationsänderungen
- Strukturelle Veränderungen

**Unvorhergesehene Konsequenzen:**
- Schwarze Schwäne (seltene Extremereignisse)
- Schmetterlingseffekte (kleine Aktion → große Folge nach Zeit)

---

## 6. EREIGNISSYSTEM

### 6.1 Prozedurale Event-Generierung

**Event-Kategorien:**

1. **Krisen-Events**
   - Wirtschaftskrisen (Rezession, Inflation, Staatspleite)
   - Politische Krisen (Regierungskrise, Skandale, Attentate)
   - Soziale Krisen (Massenproteste, Streiks, Aufstände)
   - Militärische Krisen (Invasion, Terroranschlag, Militärputsch)
   - Umweltkrisen (Naturkatastrophen, Epidemien)

2. **Chancen-Events**
   - Wirtschaftliche Chancen (Ressourcenfund, Handelsabkommen)
   - Wissenschaftliche Durchbrüche
   - Diplomatische Öffnungen
   - Interne Reform-Möglichkeiten

3. **Charakter-Events**
   - Persönliche Dilemmata (Familie vs. Staat)
   - Beziehungs-Events (Affären, Freundschaften, Rivalitäten)
   - Gesundheitsprobleme
   - Erpressungsversuche

4. **Internationale Events**
   - Kriege (zwischen anderen Staaten)
   - Bündnisverhandlungen
   - Sanktionen gegen dich/andere
   - Internationale Organisationen (Beitritt, Ausschluss)

5. **Schwarzer-Schwan-Events**
   - Völlig unvorhersehbar, selten, extrem
   - Beispiele: Alien-Kontakt (Sci-Fi), Mega-Erdbeben, KI-Singularität

### 6.2 Event-Trigger-System

Events werden getriggert durch:

**Schwellenwerte:**
- Arbeitslosigkeit > 20% → Massenproteste
- Staatsschulden > 150% BIP → Finanzkrise
- Militärbudget > 50% Ausgaben → Coup-Risiko
- Zufriedenheit < 20% → Revolution

**Zufallswürfel (gewichtet):**
- Basisprobabilität für jedes Event
- Modifikatoren durch Weltzustand
- MTTH (Mean Time To Happen) - Mechanik

**Kausalität:**
- Aktion A führt mit X% Wahrscheinlichkeit zu Event B nach Y Tagen
- Kausalketten (Event führt zu Event)

**Agenda-getrieben:**
- Charaktere mit Agenden triggern Events
- Fraktionen versuchen, ihre Ziele zu erreichen

### 6.3 Dynamische Event-Beschreibungen

**Ohne LLM:** Template-basiert mit hoher Variabilität

**Template-Struktur:**
```
[INTRO_VARIANTE] + [CHARAKTERISIERUNG] + [KERNPROBLEM] + [KONTEXTDETAIL] + [DRINGLICHKEIT]
```

**Beispiel-Event:** "Arbeitskrise in Fabrikstadt"

Generierte Varianten:
- "Berichte von deinem Arbeitsminister [Name] erreichen dich: In [Stadt] haben die Arbeiter der [Firma]-Fabrik die Produktion eingestellt. Sie fordern [Forderung]. Die Situation ist angespannt, da [Kontextdetail]."
- "[Stadt] brennt - bildlich gesprochen. [Name], der lokale Polizeichef, meldet Massenstreiks in der [Firma]-Anlage. [Gewerkschaftsführer] droht mit Eskalation, falls [Forderung] nicht erfüllt wird."
- "Dein Geheimdienst hat Wind von etwas bekommen: In [Stadt] plant die Belegschaft von [Firma] großflächige Streiks. Hintergrund: [Kontextdetail]. [Deine Vertrauensperson] rät zu schnellem Handeln."

**Variablenpool:**
- 1000+ Intro-Formulierungen
- 500+ Charakterisierungs-Sätze
- Kontextdetails aus Simulation gezogen
- Namen, Orte, Firmen aus Weltdaten

### 6.4 Event-Rhythmus

**Echtzeit-Geschwindigkeit:**
- Anpassbare Geschwindigkeit (1 Tag/Sekunde bis 1 Jahr/Sekunde)
- Pause-Funktion für Event-Entscheidungen
- "Wichtige Events" pausieren automatisch

**Event-Frequenz:**
- Kleine Events: Täglich (Berichte, Anfragen, Minor-Entscheidungen)
- Mittlere Events: Wöchentlich (Politische Entwicklungen, Wirtschaftsmeldungen)
- Große Events: Monatlich bis Jährlich (Krisen, Chancen, Systemänderungen)
- Megaevents: Sehr selten (Kriege, Revolutionen, Katastrophen)

---

## 7. GRAFIK & PRÄSENTATION

### 7.1 Kunststil

**Hybrid-Ansatz:**
- **Karten**: Stilisiert, klar, informativ (à la Paradox-Spiele, aber moderner)
- **Charakterporträts**: 2D-Illustrationen, vielfältige Stile je nach Kulturgruppe
  - Realistisch-gezeichnet für ernste Settings
  - Leicht karikiert für bizarrere Momente möglich
  - Prozedural generiert aus Templates (100+ Gesichtsteile, Frisuren, Kleidung)
- **UI-Elemente**: Clean, minimalistisch, funktional
- **Events/Briefings**: Zeitungsartikel-Ästhetik, Dossier-Stil, Hologram-Interface (bei Sci-Fi)

### 7.2 Charaktervisualisierung

**Prozedurale Portraits:**
- Basis: Ethnizität, Geschlecht, Alter
- Modifikatoren: Wohlstand (Kleidung), Beruf, Ideologie (Symbole)
- Emotionale Zustände: 5-7 Gesichtsausdrücke pro Charakter
- Alterung im Zeitverlauf

**Charakterinfo-Overlay:**
```
┌──────────────────────────────┐
│  [Bild]    Name               │
│            Titel/Position     │
│  Loyalität: ████░░ 67%        │
│  Kompetenz: ██████ 80%        │
│  Macht: ███░░░ 45%            │
│  Ideologie: [Symbol]          │
│  Agenda: "Militärputsch"      │
└──────────────────────────────┘
```

### 7.3 Kartendarstellung

**Stil:**
- Topografische Andeutungen (Berge, Flüsse)
- Politische Grenzen klar
- Dynamische Farbcodes je nach Layer

**Animations-Elemente:**
- Truppenbewegungen (animierte Pfeile)
- Handelsströme (pulsierende Linien)
- Unruhen (flackernde Gebiete)
- Entwicklung (Bauanimationen)

### 7.4 Statistik-Visualisierung

**Dashboard-Widgets:**
- Linien-Charts (Wirtschaftsentwicklung, Beliebtheit über Zeit)
- Balken-Diagramme (Vergleich Provinzen, Sektoren)
- Heat Maps (geografische Verteilung von Daten)
- Netzwerk-Graphen (Politische Beziehungen, Handelsbeziehungen)
- Sankey-Diagramme (Geldflüsse, Ressourcenströme)

**Drill-Down-Prinzip:**
- Klick auf jedes Widget → Detail-Report
- Export-Funktion (In-Game Screenshots, Daten als CSV)

---

## 8. SPIELSCHLEIFEN & PROGRESSION

### 8.1 Kurzfristige Spielschleife (Minuten)

1. **Event triggert** → Pause
2. **Information aufnehmen** (Event-Text, Kontext, Charaktere)
3. **Optionen erkunden** (Parameter einstellen, Berater fragen)
4. **Entscheidung treffen**
5. **Konsequenzen beobachten** (UI-Updates, neue Events, Reaktionen)
6. **Weiter**

### 8.2 Mittelfristige Spielschleife (Sessions)

1. **Krise bewältigen** oder **Chance nutzen**
2. **Position festigen** (Loyalitäten sichern, Opposition schwächen)
3. **Langfristiges Projekt starten** (Wirtschaftsreform, Militärausbau, etc.)
4. **Auf internationale Entwicklungen reagieren**
5. **Persönliche Agenda vorantreiben** (Selbstgewählte Ziele)

### 8.3 Langfristige Progression (Stunden bis Wochen)

**Spielziele (optional, frei wählbar):**

- **Überleben**: Regiere 10/25/50 Jahre
- **Supermacht**: Werde stärkste Nation (Wirtschaft, Militär, oder kombiniert)
- **Ideologischer Sieg**: Verbreite deine Ideologie (z.B. alle Demokratien oder alle Diktaturen)
- **Technologische Singularität**: Erreiche höchstes Tech-Level
- **Welteroberung**: Erobere/Vassalisiere alle Staaten
- **Utopie**: Maximale Bevölkerungszufriedenheit + Wohlstand + Freiheit
- **Dystopie**: Maximale Kontrolle + Unterdrückung (Anti-Ziel)
- **Anarchie**: Zerstöre deinen eigenen Staat
- **Transzendenz**: Erreiche übernatürliche Macht-Schwelle (bei Reality Bending)
- **Legacy**: Hinterlasse bleibendes Erbe (Denkmäler, Gesetze, Kultur)

**Freies Spiel:**
- Kein Endziel nötig
- Sandbox-Modus: Experimentiere mit "Was wäre wenn"
- Ironman-Modus: Keine Saves/Loads, permanente Konsequenzen
- Beobachter-Modus: Spiele mehrere Staaten oder beobachte KI-Welt

### 8.4 Meta-Progression

**Zwischen Durchläufen:**
- **Achievements** (mit merkwürdigen Anforderungen: "Regiere 100 Jahre", "Überlebe Nuklearkrieg", "Verwende nie Reality Bending", "Eliminiere 1000 Politiker")
- **Historical Hall of Fame**: Deine vergangenen Herrscher & ihre Taten
- **Weltarchiv**: Welten, die du kreiert hast, können exportiert/geteilt werden
- **Einmal erreichte Erkenntnisse**: "Du hast gelernt, wie X funktioniert" (in Form von Tipps/Tutorials, die freigeschalten werden)

---

## 9. TECHNISCHE ARCHITEKTUR

### 9.1 Kern-Engine

**Sprache:** C++ (Performance) + Python (Rapid Prototyping, Skripte)
**Framework:** Custom Engine (für Kontrolle) oder Godot/Unity (für schnellere Entwicklung)

**Module:**

1. **Simulation Core**
   - Multi-Threading (jeder Staat/Region eigener Thread bei großen Welten)
   - Event Queue System
   - Tick-basiert (jeder Tag = 1 Tick)

2. **Data Management**
   - ECS (Entity Component System) für Charaktere/Organisationen
   - Relationale Datenbank für historische Daten
   - Caching für häufig genutzte Berechnungen

3. **Procedural Generation**
   - Seed-basierte Welterzeugung
   - Noise-Funktionen (Perlin/Simplex) für Geografie
   - Template-Engine für Events/Texte

4. **AI/Behavior**
   - Utility AI für NPCs (nicht LLM!)
   - GOAP (Goal-Oriented Action Planning) für komplexe Entscheidungen
   - Behavior Trees für Fraktionen/Staaten

5. **Rendering**
   - 2D-Sprite-basiert mit modernen Shadern
   - Dynamische Layer-Komposition
   - Particle Effects für Animationen

### 9.2 NPC-Entscheidungs-KI (Ohne LLM)

**Utility-Based AI:**

Jeder NPC-Politiker bewertet Aktionen nach:
```
Score = Σ(Utility_Factor * Weight)

Utility_Factors:
- Ambition Fulfillment (wie sehr bringt mich das meinem Ziel näher?)
- Survival (wie sicher bin ich danach?)
- Ideology Match (passt das zu meinen Werten?)
- Loyalty (wie loyal bin ich gegenüber dem Herrscher?)
- Risk Tolerance (wie riskant ist das?)
- Resources (kann ich mir das leisten?)
```

**GOAP für komplexe Pläne:**
- NPC setzt Ziel: "Werde Minister"
- Planungsalgorithmus findet Aktionssequenz:
  1. Baue Unterstützung in Partei
  2. Diskreditiere aktuellen Minister
  3. Präsentiere mich als Alternative
- NPCs interagieren (kooperieren, konkurrieren) basierend auf ihren Plänen

**Emergente Narrative:**
- Storylines entstehen aus NPC-Interaktionen
- System trackt "wichtige Ereignisse" und präsentiert sie dramatisch
- Beispiel: Politische Intrige entwickelt sich über Monate → wird als "Storyline" im UI hervorgehoben

### 9.3 Textgenerierung (Ohne LLM)

**Mehrstufige Templates:**

**Ebene 1 - Satzbau:**
```
[SUBJEKT] [VERB] [OBJEKT] [MODIFIKATOR]
```

**Ebene 2 - Kontext-Injektion:**
```
"[CHARAKTER_NAME] aus [REGION] fordert [FORDERUNG], weil [GRUND]."

Variablen aus Simulation:
- CHARAKTER_NAME: "General Petrov"
- REGION: "Nordprovinz"
- FORDERUNG: "höheren Militärbudget"
- GRUND: "die Bedrohung durch [FEINDSTAAT]"
```

**Ebene 3 - Stil-Varianten:**
Für jedes Template 10-50 Varianten:
- Formell / Informell
- Dramatisch / Nüchtern
- Persönlich / Distanziert

**Kontext-Sensitivität:**
- Template-Wahl basiert auf:
  - Charakterpersönlichkeit (aggressiv → aggressivere Formulierungen)
  - Beziehung zu dir (loyal → respektvoll, feindlich → provokant)
  - Situation (Krise → dringlich, Routine → entspannt)

**Markov-Ketten für Variation:**
- Bei extrem häufigen Texten (z.B. Wirtschaftsberichte):
- Markov-Modell generiert neue Satzstellungen aus Corpus

### 9.4 Performance-Optimierung

**Abstraktionsgrade:**
- Irrelevante Staaten: Nur Makro-Simulation (keine einzelnen Politiker)
- Nachbarstaaten: Meso-Simulation (wichtige Politiker)
- Eigener Staat: Vollsimulation

**Update-Frequenzen:**
- Kritische Systeme: Jeder Tick
- Wichtige Systeme: Jeder 3. Tick
- Hintergrundsysteme: Jeder 10. Tick

**Lazy Evaluation:**
- Details werden erst berechnet, wenn Spieler sie anschaut
- Beispiel: Provinz-Details werden erst beim Zoom generiert

---

## 10. MORALITÄT & KONSEQUENZEN

### 10.1 Keine künstlichen Grenzen

Das Spiel verhindert KEINE Aktionen (Ausnahme: technische Unmöglichkeiten).

**Erlaubt (mit Konsequenzen):**
- Genozid
- Massenmord
- Folter
- Totale Überwachung
- Sklaverei (bei niedrigem Tech-Level oder Regression)
- Menschenexperimente
- Umweltzerstörung
- Nukleare Vernichtung
- Reality-Bending in extremem Ausmaß

### 10.2 Konsequenz-Realismus

**Kurzfristig:**
- Sofortige Reaktionen (Proteste, Putsche, Sanktionen)
- Wirtschaftliche Schäden
- Verlust von Bündnissen

**Mittelfristig:**
- Brain Drain (Kluge Leute fliehen)
- Internationale Isolation
- Aufstände & Guerilla
- Reputationsverlust (andere Staaten weigern sich zu kooperieren)

**Langfristig:**
- Generationentrauma (Bevölkerung traumatisiert, niedrige Produktivität)
- Historische Verurteilung (In-Game-Geschichtsbücher, Denkmäler gegen dich)
- Systemkollaps (zu viel Repression → totaler Staatsverfall)
- Invasionen (Humanitäre Interventionen)

**Extremfälle:**
- Bei Genozid / nuklearer Angriff: Internationale Allianz gegen dich möglich
- Bei Reality-Bending-Missbrauch: Realität beginnt zu kollabieren (Anomalien, Paradoxien)

### 10.3 Umgekehrte Konsequenzen

**"Gute Taten" sind nicht automatisch belohnt:**
- Demokratisierung → Instabilität (kurzfristig)
- Wohlfahrtsstaat → Hohe Steuern → Kapitalflucht
- Abrüstung → Schwäche → Invasion möglich
- Transparenz → Skandale kommen ans Licht

**Realismus über Moralität:**
- Autokratien können stabiler sein (kurzfristig)
- Unterdrückung kann funktionieren (wenn gut gemacht)
- Propaganda kann Realität ersetzen (für Bevölkerung)

---

## 11. ERWEITERBARKEIT & MODDING

### 11.1 Mod-Support

**Moddable Elemente:**
- Neue Technologien (CSV/JSON)
- Event-Templates (JSON)
- Charakterporträts (PNG + Metadata)
- Ideologien & Regierungsformen (JSON)
- Kartenskripte (Python)
- UI-Themes (CSS-ähnlich)

**Mod-Workshop:**
- Steam Workshop Integration (wenn auf Steam)
- In-Game Mod Browser
- Rating & Kommentare

### 11.2 Szenario-Editor

**Ermöglicht Erstellen von:**
- Vorgefertigten Welten (z.B. "Kalter Krieg", "Balkanisierte Zukunft")
- Startszenarien (z.B. "Coup-Versuch am ersten Tag")
- Herausforderungen ("Überlebe 10 Jahre mit 10% Approval")

**Tools:**
- Map-Editor (platziere Staaten, Ressourcen, Städte)
- Character-Editor (erstelle spezifische Politiker mit Backstories)
- Event-Chain-Editor (verknüpfe Events zu Storys)

---

## 12. BEISPIEL-SPIELSZENARIO

### Seed: "CHAOS42"
### Parameter: Mittelgroße Welt, Hohe Technologiedivergenz, Moderate Anomalien

**Generierte Welt:**
- 120 Staaten
- 3 Supermächte (1x Demokratische Föderation, 1x Autoritäres Imperium, 1x KI-regierte Technokratie)
- Technologie-Spektrum: Post-Apokalyptische Stammesgebiete bis Post-Scarcity-Städte
- 5 aktive Kriege
- 2 Anomalien aktiv (eine Zone mit Zeitverzerrungen, eine mit "Glück-Strahlung")

**Dein Staat: "Neue Republik Thalassia"**
- Mittelgroßer Küstenstaat (15 Provinzen)
- Demokratie (instabil)
- Tech-Level: Modern (2020s-äquivalent)
- Wirtschaft: Exportorientiert (High-Tech-Industrie)
- Probleme:
  - Populistische Partei gewinnt an Macht
  - Nachbarstaat droht mit Invasion wegen Grenzstreit
  - Wirtschaftsblase kurz vor Platzen
  - Deine persönliche Legitimität: Mittel (enges Wahlresultat)

**Intro-Ereignis:**
Du wirst als Premierminister vereidigt. Dein Vorgänger ist unter mysteriösen Umständen zurückgetreten (Gerüchte über Skandal). 

Sofort kommen 3 Leute in dein Büro:
1. **Verteidigungsminister Kowalski** (loyal, kompetent, militaristisch): Warnt vor Invasion, fordert Mobilmachung
2. **Finanzministerin Chen** (neutral, sehr kompetent, neoliberal): Warnt vor Finanzkrise, fordert Sparprogramm
3. **Oppositionsführer Novak** (feindlich, charismatisch, populistisch): Fordert Neuwahlen, droht mit Massenprotesten

**Deine erste Entscheidung - Konstruiere deine Antwort:**

Beispiel-Aktionen, die du konstruieren könntest:

**Realistisch:**
- Kompromiss schmieden (Gemäßigte Mobilmachung + Gemäßigtes Sparprogramm + Dialog mit Opposition)
- Auf Zeit spielen (weitere Informationen sammeln, Berater einberufen)
- Eine Fraktion priorisieren (Militär, Wirtschaft, oder Opposition befriedigen)

**Bizarr:**
- Alle drei einsperren lassen (sofortiger Autoritarismus)
- Finanzkrise als Kriegsgrund nutzen ("Angriffskrieg für Plünderung")
- Ankündigen, dass du freiwillig in 30 Tagen zurücktrittst (soziales Experiment)

**Reality Bending (falls freigeschaltet):**
- "Erinnerungs-Rewrite": Bevölkerung glaubt, Grenzstreit existiert nicht
- "Charisma-Boost": +50 Zustimmung für 3 Monate (kauft Zeit)
- "Gelddruckmaschine": Finanzkrise gelöst, aber Risiko für Realitätsinstabilität

**Das Spiel läuft weiter basierend auf deiner Wahl...**

---

## 13. TECHNOLOGIE-LEVEL IM DETAIL

### 13.1 Die 7 Tech-Stufen

**Stufe 1: Rückständig**
- 1850-1920 Tech
- Dampfmaschinen, frühe Industrialisierung
- Telegrafie
- Massenheere mit Gewehren
- Kolonialer Ausbeutungsstil möglich

**Stufe 2: Früh-Modern**
- 1920-1960 Tech
- Ölindustrie, Massenproduktion
- Radio, frühe Computer
- Panzer, Flugzeuge
- Weltkrieg-Ära Mechaniken

**Stufe 3: Modern**
- 1960-2000 Tech
- Computer, Internet (früh)
- Raketen, Jets
- Nuklearwaffen möglich
- Kalter-Krieg-Stil-Konflikte

**Stufe 4: Zeitgenössisch**
- 2000-2030 Tech
- Smartphones, soziale Medien
- Drohnen, präzisionsgelenkte Munition
- Cyberwarfare
- Globalisierte Wirtschaft

**Stufe 5: Nah-Zukunft**
- 2030-2070 Tech
- KI-Assistenten (nicht AGI)
- Autonome Fahrzeuge, Roboter
- Erneuerbare Energien dominant
- Gentherapie, Lebensverlängerung
- Weltraumkolonisierung beginnt

**Stufe 6: Fern-Zukunft**
- 2070-2150 Tech
- AGI, aber unter Kontrolle
- Fusionsenergie
- Nanotech-Medizin
- Weltraumstationen, Mars-Kolonien
- Transhumanismus (Cyborg-Upgrades)

**Stufe 7: Sci-Fi-Übermacht**
- Post-2150 Tech
- Post-Scarcity (Materie-Replikatoren)
- Dyson-Sphäre-Bau
- Genetische Perfektion
- Bewusstseins-Upload
- Interstellare Reisen
- Reality-Bending durch Technologie

### 13.2 Tech-Level-Konsequenzen

**Kriegführung:**
- Stufe 1 vs Stufe 7 = Instant-Loss (außer Guerilla)
- Aber: Niedrige Tech → Billiger, mehr Soldaten möglich
- Hohe Tech → Teuer, aber überlegen

**Wirtschaft:**
- Höhere Stufen = Höhere Produktivität
- Aber: Verletzlicher durch Cyberangriffe (ab Stufe 4)
- Stufe 7: Geld fast bedeutungslos (Post-Scarcity)

**Gesellschaft:**
- Niedrige Stufen: Traditionalismus dominiert
- Hohe Stufen: Transhumanismus, neue Ideologien

---

## 14. PRODUKTIONS-ROADMAP (Hypothetisch)

### Phase 1: Prototype (6 Monate)
- Kern-Simulationsloop
- Basis-Welterzeugung (1 Seed, feste Parameter)
- Rudimentäres UI (nur Karte + Text-Events)
- 1 Tech-Level (Modern)
- 50 Event-Templates
- Keine Reality Bending

### Phase 2: Vertical Slice (12 Monate)
- Alle 7 Tech-Levels
- Vollständiges UI (Karten, Portraits, Stats)
- Parameterbasiertes Aktionssystem
- 500 Event-Templates
- Basis-KI für NPCs
- 10 Szenarien

### Phase 3: Alpha (18 Monate)
- Vollständige Simulation (alle Systeme)
- Prozedurale Event-Generation
- Reality Bending Mechanics
- Multiplayer-Prototyp (optional)
- 1000+ Events
- Modding-Tools (Basis)

### Phase 4: Beta (24 Monate)
- Balancing
- 5000+ Events
- Erweiterte KI
- Vollständiger Modding-Support
- Szenario-Editor
- Performance-Optimierung
- Community-Feedback-Integration

### Phase 5: Release (30 Monate)
- Polish
- Tutorialsystem
- Achievements
- Multiplayer (falls included)
- Day-One Mod-Support

---

## 15. MONETARISIERUNG (Falls kommerziell)

**Kaufmodell:**
- Einmalkauf (40-60€), keine Subscriptions
- Große Expansions (15-20€ pro Expansion)
  - Expansion 1: "Galactic Conquest" (Space-Fokus, neue Tech-Stufe 8)
  - Expansion 2: "Underworld" (Kriminalität, Spionage tiefer)
  - Expansion 3: "Alternate History" (Historische Szenarien 1800-2000)
- Kosmetische DLCs (5€)
  - Portrait Packs
  - UI Themes
- Alles gameplay-relevante moddbar (kein Pay-to-Win)

---

## 16. SCHLUSSWORT

Dieses Konzept beschreibt ein extrem ambitioniertes Spiel, das Jahre der Entwicklung benötigt. Der Fokus liegt auf:
- **Systemische Tiefe** über Scripted Content
- **Spielerfreiheit** über Guided Experience  
- **Emergente Narrative** über Fixed Stories
- **Simulation** über Arcade

Das Spiel ist eine Mischung aus Grand Strategy, Government Simulator, Wirtschaftssimulation und Reality-Bending-Sandbox. Es gibt keine moralischen Grenzen, aber realistische Konsequenzen.

Der Verzicht auf LLMs bedeutet mehr Entwicklungsaufwand für prozedurale Systeme, garantiert aber Offline-Fähigkeit, volle Kontrolle und keine laufenden API-Kosten.

**Tagline zum Abschluss:**  
*"In SOVEREIGN CHAOS bist du nicht nur Herrscher – du bist der Gott eines lebendigen Staates in einer chaotischen Welt. Regiere weise. Oder nicht. Die Wahl ist dein. Die Konsequenzen auch."*

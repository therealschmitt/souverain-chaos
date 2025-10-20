extends Node

"""
EventManager - Verwaltet spielbare Events mit Optionen und Effekten.

Events haben:
- Titel und Beschreibung
- Mehrere Optionen zur Auswahl
- Effekte auf GameState (money, legitimacy, reality_points, nation stats, etc.)
- Triggerbedingungen
"""

# Event-Bibliothek (vordefinierte Events)
var event_library: Dictionary = {}

# Aktives Event (wird gerade angezeigt)
var active_event: Dictionary = {}

func _ready() -> void:
	_initialize_event_library()
	print("[EventManager] Event-System initialisiert mit %d Events" % event_library.size())

func _initialize_event_library() -> void:
	"""Initialisiert die Event-Bibliothek mit vordefinierten Events."""

	# Event 1: Wirtschaftskrise - Steuerpolitik
	event_library["economic_crisis_tax"] = {
		"id": "economic_crisis_tax",
		"title": "Wirtschaftskrise: Steuerpolitik",
		"description": """Die Wirtschaft stagniert. Arbeitslosigkeit steigt auf 15%.

Ihr Finanzminister empfiehlt dringend Maßnahmen. Verschiedene Berater schlagen unterschiedliche Ansätze vor.""",
		"type": "economic",
		"options": [
			{
				"label": "Steuern senken (Marktlösung)",
				"description": "Unternehmens- und Einkommenssteuern senken, um Investitionen anzukurbeln.",
				"effects": {
					"money": -500000,
					"legitimacy": -5,
					"nation_gdp_growth": 2.0,
					"nation_unemployment": -3.0
				},
				"console_message": "Steuersenkungen beschlossen. Staatseinnahmen sinken kurzfristig, Wirtschaft soll angekurbelt werden."
			},
			{
				"label": "Staatsausgaben erhöhen (Keynesianismus)",
				"description": "Massive öffentliche Infrastrukturprogramme starten.",
				"effects": {
					"money": -2000000,
					"legitimacy": 10,
					"nation_gdp_growth": 3.5,
					"nation_unemployment": -5.0,
					"nation_debt": 1000000
				},
				"console_message": "Konjunkturprogramm gestartet. Große Infrastrukturprojekte schaffen Arbeitsplätze."
			},
			{
				"label": "Sparpolitik (Austerität)",
				"description": "Staatsausgaben kürzen, um Haushalt zu konsolidieren.",
				"effects": {
					"money": 1000000,
					"legitimacy": -20,
					"nation_gdp_growth": -1.5,
					"nation_unemployment": 4.0
				},
				"console_message": "Sparmaßnahmen durchgesetzt. Bevölkerung protestiert, Staatsfinanzen verbessern sich."
			},
			{
				"label": "Realitäts-Verzerrung: Wohlstand manifestieren",
				"description": "Realitätspunkte nutzen, um wirtschaftlichen Wohlstand zu erzwingen.",
				"effects": {
					"money": 5000000,
					"reality_points": -50,
					"legitimacy": -30,
					"nation_gdp_growth": 5.0,
					"nation_unemployment": -10.0
				},
				"console_message": "REALITÄT MANIPULIERT. Plötzlicher Wohlstand erscheint... Bevölkerung ist verstört.",
				"requires": {"reality_points": 50}
			}
		]
	}

	# Event 2: Diplomatische Krise
	event_library["diplomatic_crisis_border"] = {
		"id": "diplomatic_crisis_border",
		"title": "Diplomatische Krise: Grenzkonflikt",
		"description": """Das Nordreich hat Truppen an unserer Grenze zusammengezogen!

Ihr Außenminister meldet: 'Sie fordern Zugang zu unseren Küstengewässern. Die Situation ist explosiv.'""",
		"type": "diplomatic",
		"options": [
			{
				"label": "Verhandeln (Friedlich)",
				"description": "Diplomatische Verhandlungen anbieten, Kompromiss suchen.",
				"effects": {
					"legitimacy": -5,
					"relationship_nordreich": 15,
					"nation_military_strength": -50
				},
				"console_message": "Friedensverhandlungen erfolgreich. Konzessionen gemacht, aber Krieg vermieden."
			},
			{
				"label": "Zurückweisen (Fest)",
				"description": "Forderungen ablehnen, militärische Bereitschaft signalisieren.",
				"effects": {
					"legitimacy": 10,
					"relationship_nordreich": -25,
					"nation_military_strength": 100
				},
				"console_message": "Harte Haltung eingenommen. Nordreich zieht Truppen zurück - vorerst. Spannungen bleiben."
			},
			{
				"label": "Präventivschlag (Aggressiv)",
				"description": "Überraschungsangriff auf Nordreich-Stellungen.",
				"effects": {
					"money": -3000000,
					"legitimacy": -15,
					"relationship_nordreich": -100,
					"nation_military_strength": -200
				},
				"console_message": "KRIEG AUSGEBROCHEN! Präventivschlag gestartet. Internationale Isolation droht.",
				"triggers_war": "nordreich"
			},
			{
				"label": "Bündnis aktivieren (Diplomatisch)",
				"description": "Südkonföderation um Unterstützung bitten.",
				"effects": {
					"legitimacy": 5,
					"relationship_nordreich": -15,
					"relationship_suedkonfoederation": 20
				},
				"console_message": "Südkonföderation signalisiert Unterstützung. Nordreich lenkt ein."
			}
		]
	}

	# Event 3: Innenpolitische Krise
	event_library["internal_crisis_protests"] = {
		"id": "internal_crisis_protests",
		"title": "Massenproteste in der Hauptstadt",
		"description": """Hunderttausende demonstrieren gegen die Regierung!

Forderungen: Höhere Löhne, bessere Arbeitsbedingungen, mehr Demokratie. Ihr Innenminister warnt vor Eskalation.""",
		"type": "internal",
		"options": [
			{
				"label": "Zugeständnisse machen",
				"description": "Lohnerhöhungen und Reformen zusagen.",
				"effects": {
					"money": -800000,
					"legitimacy": 15,
					"nation_gdp_growth": -0.5
				},
				"console_message": "Reformen angekündigt. Proteste enden friedlich. Bevölkerung zufriedener."
			},
			{
				"label": "Ignorieren",
				"description": "Proteste aussitzen, keine Zugeständnisse.",
				"effects": {
					"legitimacy": -10,
					"province_unrest_all": 15.0
				},
				"console_message": "Proteste ignoriert. Unruhe breitet sich auf Provinzen aus."
			},
			{
				"label": "Polizeigewalt einsetzen",
				"description": "Proteste mit Gewalt auflösen.",
				"effects": {
					"legitimacy": -25,
					"province_unrest_all": 30.0,
					"nation_military_strength": 50
				},
				"console_message": "Gewaltsame Unterdrückung! Internationale Verurteilung. Innere Spannungen eskalieren."
			},
			{
				"label": "Dialog suchen",
				"description": "Persönlich mit Protestführern sprechen.",
				"effects": {
					"legitimacy": 20,
					"money": -300000,
					"province_unrest_all": -10.0
				},
				"console_message": "Dialogbereitschaft zeigt Wirkung. Kompromiss gefunden, Situation beruhigt."
			}
		]
	}

	# Event 4: Technologischer Durchbruch
	event_library["tech_breakthrough"] = {
		"id": "tech_breakthrough",
		"title": "Wissenschaftlicher Durchbruch!",
		"description": """Unsere Wissenschaftler haben einen Durchbruch bei erneuerbaren Energien erzielt!

Die neue Technologie könnte unsere Energieversorgung revolutionieren - wenn wir richtig investieren.""",
		"type": "technology",
		"options": [
			{
				"label": "Massiv investieren",
				"description": "Alle verfügbaren Mittel in die Entwicklung stecken.",
				"effects": {
					"money": -5000000,
					"nation_tech_level": 0.5,
					"nation_gdp_growth": 2.0,
					"legitimacy": 10
				},
				"console_message": "Massive Investitionen in neue Technologie. Tech-Level steigt, langfristige Vorteile erwartet."
			},
			{
				"label": "Vorsichtig investieren",
				"description": "Moderate Investitionen, Risiken begrenzen.",
				"effects": {
					"money": -1500000,
					"nation_tech_level": 0.2,
					"nation_gdp_growth": 0.5
				},
				"console_message": "Ausgewogene Investitionsstrategie. Solides Wachstum bei kontrollierten Kosten."
			},
			{
				"label": "Technologie verkaufen",
				"description": "Patente an Höchstbietende verkaufen.",
				"effects": {
					"money": 3000000,
					"nation_tech_level": -0.1,
					"legitimacy": -15
				},
				"console_message": "Technologie verkauft. Kurzfristige Gewinne, langfristig Abhängigkeit von anderen."
			},
			{
				"label": "Realitäts-Boost: Sofortige Implementierung",
				"description": "Realitätspunkte nutzen für instant Technologie-Sprung.",
				"effects": {
					"money": 2000000,
					"reality_points": -30,
					"nation_tech_level": 1.0,
					"nation_gdp_growth": 4.0
				},
				"console_message": "REALITÄT MANIPULIERT. Technologie erscheint wie aus dem Nichts. Wissenschaftler sind verwirrt.",
				"requires": {"reality_points": 30}
			}
		]
	}

	# Event 5: Charakterereignis - Ministerrücktritt
	event_library["minister_resignation"] = {
		"id": "minister_resignation",
		"title": "Skandal: Minister bietet Rücktritt an",
		"description": """Ihr Verteidigungsminister ist in einen Korruptionsskandal verwickelt!

Die Opposition fordert seinen sofortigen Rücktritt. Ihre Partei will ihn schützen. Was tun Sie?""",
		"type": "character",
		"options": [
			{
				"label": "Rücktritt akzeptieren",
				"description": "Minister entlassen, Skandal eindämmen.",
				"effects": {
					"legitimacy": 5,
					"nation_military_strength": -100
				},
				"console_message": "Minister zurückgetreten. Schnelle Schadensbegrenzung, aber militärische Führung geschwächt."
			},
			{
				"label": "Minister schützen",
				"description": "Skandal als politische Kampagne abtun.",
				"effects": {
					"legitimacy": -20,
					"nation_military_strength": 50
				},
				"console_message": "Minister im Amt gehalten. Massive Legitimität verloren, aber Loyalität der Militärführung gestärkt."
			},
			{
				"label": "Untersuchung anordnen",
				"description": "Unabhängige Untersuchung einleiten.",
				"effects": {
					"money": -200000,
					"legitimacy": 10
				},
				"console_message": "Transparente Untersuchung läuft. Öffentliches Vertrauen steigt."
			},
			{
				"label": "Sündenbock opfern",
				"description": "Untergebene beschuldigen, Minister schützen.",
				"effects": {
					"legitimacy": -10,
					"nation_military_strength": 30
				},
				"console_message": "Sündenbock-Strategie. Kurzfristige Lösung, aber zynischer Präzedenzfall geschaffen."
			}
		]
	}

	# Event 6: Umweltkatastrophe
	event_library["environmental_disaster"] = {
		"id": "environmental_disaster",
		"title": "Umweltkatastrophe: Ölpest",
		"description": """Eine massive Ölpest bedroht unsere Küsten!

Tausende Seevögel sterben. Fischer verlieren ihre Existenz. Die Öffentlichkeit fordert Handlung.""",
		"type": "environmental",
		"options": [
			{
				"label": "Großeinsatz starten",
				"description": "Alle Ressourcen für Aufräumarbeiten mobilisieren.",
				"effects": {
					"money": -2500000,
					"legitimacy": 15,
					"province_unrest_coastal": -20.0
				},
				"console_message": "Massive Aufräumaktion gestartet. Kosten enorm, aber Umweltschaden minimiert."
			},
			{
				"label": "Minimale Maßnahmen",
				"description": "Nur Pflichtprogramm, Kosten minimieren.",
				"effects": {
					"money": -500000,
					"legitimacy": -25,
					"province_unrest_coastal": 40.0
				},
				"console_message": "Minimale Reaktion. Küstenbevölkerung empört, langfristige Umweltschäden."
			},
			{
				"label": "Verursacher verklagen",
				"description": "Internationale Ölfirma vor Gericht bringen.",
				"effects": {
					"money": 1500000,
					"legitimacy": 20,
					"relationship_all": -5
				},
				"console_message": "Klage erfolgreich! Schadenersatz erstritten, aber diplomatische Spannungen."
			},
			{
				"label": "Realitäts-Reinigung: Öl verschwinden lassen",
				"description": "Realitätspunkte nutzen, um Öl zu eliminieren.",
				"effects": {
					"reality_points": -40,
					"legitimacy": -20,
					"province_unrest_coastal": -50.0
				},
				"console_message": "REALITÄT MANIPULIERT. Öl verschwindet spurlos. Bevölkerung ist verstört und misstrauisch.",
				"requires": {"reality_points": 40}
			}
		]
	}

	# Event 7: Militärischer Vorfall
	event_library["military_incident"] = {
		"id": "military_incident",
		"title": "Militärischer Zwischenfall",
		"description": """Ein ausländisches Spionageflugzeug ist in unseren Luftraum eingedrungen!

Unsere Luftwaffe hat es abgefangen. Der Pilot verweigert die Landung. Was befehlen Sie?""",
		"type": "military",
		"options": [
			{
				"label": "Zur Landung zwingen",
				"description": "Flugzeug mit Warnschüssen zur Landung zwingen.",
				"effects": {
					"legitimacy": 10,
					"relationship_nordreich": -20,
					"nation_military_strength": 50
				},
				"console_message": "Flugzeug zur Landung gezwungen. Stärke demonstriert, diplomatische Protestnote erwartet."
			},
			{
				"label": "Eskorte aus Luftraum",
				"description": "Flugzeug ohne Gewalt aus Luftraum geleiten.",
				"effects": {
					"legitimacy": -5,
					"relationship_nordreich": 5
				},
				"console_message": "Flugzeug eskortiert. Deeskalation gelungen, aber Schwäche gezeigt."
			},
			{
				"label": "Abschießen",
				"description": "Flugzeug als feindlich einstufen und abschießen.",
				"effects": {
					"legitimacy": -15,
					"relationship_nordreich": -50,
					"nation_military_strength": 100
				},
				"console_message": "FLUGZEUG ABGESCHOSSEN! Internationale Empörung. Kriegsgefahr steigt massiv.",
				"triggers_war_risk": true
			},
			{
				"label": "Ignorieren",
				"description": "Vorfall herunterspielen, nichts tun.",
				"effects": {
					"legitimacy": -20,
					"nation_military_strength": -100
				},
				"console_message": "Vorfall ignoriert. Militär demoralisiert, internationale Wahrnehmung als schwach."
			}
		]
	}

func trigger_random_event() -> void:
	"""Triggert ein zufälliges Event aus der Bibliothek."""
	var event_ids = event_library.keys()
	if event_ids.size() == 0:
		print("[EventManager] Keine Events in Bibliothek!")
		return

	var random_id = event_ids[randi() % event_ids.size()]
	trigger_event(random_id)

func trigger_event(event_id: String) -> void:
	"""Triggert ein spezifisches Event."""
	if not event_library.has(event_id):
		print("[EventManager] Event '%s' nicht gefunden!" % event_id)
		return

	var event_data = event_library[event_id]
	print("\n[EventManager] Event getriggert: %s" % event_data.title)

	# Event an EventDialog senden
	EventBus.choice_event_triggered.emit(event_data)

func apply_event_choice(event_id: String, option_index: int) -> void:
	"""Wendet die Effekte einer gewählten Option an."""
	if not event_library.has(event_id):
		print("[EventManager] Event '%s' nicht gefunden!" % event_id)
		return

	var event_data = event_library[event_id]
	if option_index < 0 or option_index >= event_data.options.size():
		print("[EventManager] Ungültiger Option-Index: %d" % option_index)
		return

	var chosen_option = event_data.options[option_index]

	# Prüfe Voraussetzungen
	if chosen_option.has("requires"):
		if not _check_requirements(chosen_option.requires):
			print("[EventManager] ❌ Voraussetzungen nicht erfüllt!")
			return

	print("\n" + "=".repeat(80))
	print("[EventManager] EFFEKTE von '%s' - Option: '%s'" % [event_data.title, chosen_option.label])
	print("=".repeat(80))

	var effects = chosen_option.effects

	# Spieler-Ressourcen
	if effects.has("money"):
		GameState.player_resources.money += effects.money
		var sign = "+" if effects.money >= 0 else ""
		print("💰 Geld: %s$%s (Neu: $%s)" % [sign, _format_number(effects.money), _format_number(GameState.player_resources.money)])

	if effects.has("legitimacy"):
		GameState.player_resources.legitimacy += effects.legitimacy
		GameState.player_resources.legitimacy = clamp(GameState.player_resources.legitimacy, 0, 100)
		var sign = "+" if effects.legitimacy >= 0 else ""
		print("⚖️  Legitimität: %s%d (Neu: %d)" % [sign, effects.legitimacy, GameState.player_resources.legitimacy])

	if effects.has("reality_points"):
		GameState.player_resources.reality_points += effects.reality_points
		var sign = "+" if effects.reality_points >= 0 else ""
		print("✨ Realitätspunkte: %s%d (Neu: %d)" % [sign, effects.reality_points, GameState.player_resources.reality_points])

	# Nation-Werte
	var player_nation = GameState.get_player_nation()
	if player_nation:
		if effects.has("nation_gdp_growth"):
			player_nation.gdp_growth += effects.nation_gdp_growth
			var sign = "+" if effects.nation_gdp_growth >= 0 else ""
			print("📈 BIP-Wachstum: %s%.1f%% (Neu: %.1f%%)" % [sign, effects.nation_gdp_growth, player_nation.gdp_growth])

		if effects.has("nation_unemployment"):
			player_nation.unemployment += effects.nation_unemployment
			player_nation.unemployment = max(0, player_nation.unemployment)
			var sign = "+" if effects.nation_unemployment >= 0 else ""
			print("👷 Arbeitslosigkeit: %s%.1f%% (Neu: %.1f%%)" % [sign, effects.nation_unemployment, player_nation.unemployment])

		if effects.has("nation_debt"):
			player_nation.debt += effects.nation_debt
			var sign = "+" if effects.nation_debt >= 0 else ""
			print("💸 Staatsschulden: %s$%s (Neu: $%s)" % [sign, _format_number(effects.nation_debt), _format_number(player_nation.debt)])

		if effects.has("nation_military_strength"):
			player_nation.military_strength += effects.nation_military_strength
			player_nation.military_strength = max(0, player_nation.military_strength)
			var sign = "+" if effects.nation_military_strength >= 0 else ""
			print("⚔️  Militärstärke: %s%d (Neu: %d)" % [sign, effects.nation_military_strength, player_nation.military_strength])

		if effects.has("nation_tech_level"):
			player_nation.tech_level += effects.nation_tech_level
			player_nation.tech_level = clamp(player_nation.tech_level, 1, 7)
			var sign = "+" if effects.nation_tech_level >= 0 else ""
			print("🔬 Tech-Level: %s%.1f (Neu: %.1f)" % [sign, effects.nation_tech_level, player_nation.tech_level])

	# Beziehungen
	if effects.has("relationship_nordreich"):
		_modify_relationship("nordreich", effects.relationship_nordreich)

	if effects.has("relationship_suedkonfoederation"):
		_modify_relationship("suedkonfoederation", effects.relationship_suedkonfoederation)

	if effects.has("relationship_all"):
		for nation_id in GameState.nations.keys():
			if nation_id != GameState.player_nation_id:
				_modify_relationship(nation_id, effects.relationship_all)

	# Provinz-Effekte
	if effects.has("province_unrest_all"):
		_modify_all_provinces_unrest(effects.province_unrest_all)

	if effects.has("province_unrest_coastal"):
		_modify_coastal_provinces_unrest(effects.province_unrest_coastal)

	# Spezielle Effekte
	if chosen_option.has("triggers_war"):
		var enemy_nation_id = chosen_option.triggers_war
		print("⚔️  KRIEG AUSGERUFEN gegen %s!" % enemy_nation_id.capitalize())
		EventBus.war_declared.emit(GameState.player_nation_id, enemy_nation_id)

	if chosen_option.has("triggers_war_risk"):
		print("⚠️  KRIEGSGEFAHR ERHÖHT!")

	# Console Message
	print("\n📜 " + chosen_option.console_message)
	print("=".repeat(80) + "\n")

	# Event zu Historie hinzufügen
	HistoricalContext.add_game_event(
		GameState.current_date,
		event_data.type,
		event_data.title,
		"Gewählt: %s - %s" % [chosen_option.label, chosen_option.console_message],
		70,  # narrative_weight
		{}
	)

	# UI aktualisieren
	EventBus.game_state_changed.emit()

func _check_requirements(requirements: Dictionary) -> bool:
	"""Prüft ob Voraussetzungen erfüllt sind."""
	if requirements.has("reality_points"):
		if GameState.player_resources.reality_points < requirements.reality_points:
			print("[EventManager] Nicht genug Realitätspunkte! Benötigt: %d, Vorhanden: %d" %
				[requirements.reality_points, GameState.player_resources.reality_points])
			return false
	return true

func _modify_relationship(nation_id: String, change: float) -> void:
	"""Ändert Beziehung zu einer Nation."""
	var player_nation = GameState.get_player_nation()
	if not player_nation:
		return

	if not player_nation.relationships.has(nation_id):
		player_nation.relationships[nation_id] = 0.0

	player_nation.relationships[nation_id] += change
	player_nation.relationships[nation_id] = clamp(player_nation.relationships[nation_id], -100, 100)

	var sign = "+" if change >= 0 else ""
	print("🤝 Beziehung zu %s: %s%d (Neu: %d)" %
		[nation_id.capitalize(), sign, int(change), int(player_nation.relationships[nation_id])])

func _modify_all_provinces_unrest(change: float) -> void:
	"""Ändert Unruhe in allen Provinzen."""
	var count = 0
	for province in GameState.provinces.values():
		province.unrest_level += change
		province.unrest_level = clamp(province.unrest_level, 0, 100)
		count += 1

	var sign = "+" if change >= 0 else ""
	print("🏛️  Unruhe in ALLEN Provinzen: %s%.1f (Anzahl: %d)" % [sign, change, count])

func _modify_coastal_provinces_unrest(change: float) -> void:
	"""Ändert Unruhe in Küstenprovinzen."""
	var count = 0
	for province in GameState.provinces.values():
		if province.has_port:
			province.unrest_level += change
			province.unrest_level = clamp(province.unrest_level, 0, 100)
			count += 1

	var sign = "+" if change >= 0 else ""
	print("🌊 Unruhe in Küstenprovinzen: %s%.1f (Anzahl: %d)" % [sign, change, count])

func _format_number(num: float) -> String:
	"""Formatiert große Zahlen mit Tausendertrennzeichen."""
	var is_negative = num < 0
	var abs_num = abs(num)
	var str_num = str(int(abs_num))
	var result = ""
	var count = 0

	for i in range(str_num.length() - 1, -1, -1):
		if count == 3:
			result = "." + result
			count = 0
		result = str_num[i] + result
		count += 1

	if is_negative:
		result = "-" + result

	return result

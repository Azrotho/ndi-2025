extends Node2D

@onready var computer = $ComputerScene/AnimatedSprite2D
@onready var screen = $ScreenScene/AnimatedSprite2D
@onready var area = $Area2D

# Mini-jeu Snake
var snake_game = null
var snake_game_scene = preload("res://scenes/SnakeGame.tscn")
var is_snake_active: bool = false

# Visualiseur de musique
var music_visualizer = null
var music_visualizer_scene = preload("res://scenes/MusicVisualizer.tscn")
var is_visualizer_active: bool = false

enum IncidentType { NONE, BURNING, BLUESCREEN, BUGGRAPHIQUE, MAJ, POPUP, SHUFFLE }
var current_incident: IncidentType = IncidentType.NONE
var is_breaking: bool = false  # Animation de cassage en cours
var is_repairing: bool = false  # Animation de réparation en cours

# Timer pour vérifier les incidents
var incident_timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Renommer Area2D pour la détection par le joueur
	area.name = "RepairArea"
	
	# Initialiser en mode normal
	set_normal_state()
	
	# Créer un timer pour vérifier les incidents périodiquement
	incident_timer = Timer.new()
	incident_timer.wait_time = Globals.incident_check_interval
	incident_timer.autostart = true
	incident_timer.timeout.connect(_on_incident_timer_timeout)
	add_child(incident_timer)
	
	# Connecter le signal de fin d'animation pour passer de "debutcassage" à "casse"
	computer.animation_finished.connect(_on_computer_animation_finished)


func set_normal_state() -> void:
	current_incident = IncidentType.NONE
	screen.animation = "default"
	computer.animation = "default"
	screen.play()
	computer.play()


func set_burning_state() -> void:
	current_incident = IncidentType.BURNING
	is_breaking = true
	# D'abord l'animation de début de cassage
	computer.animation = "debutcassage"
	computer.play()
	# Écran noir
	screen.animation = "notworking"
	screen.play()


func set_bluescreen_state() -> void:
	current_incident = IncidentType.BLUESCREEN
	computer.animation = "default"
	computer.play()
	screen.animation = "bluescreen"
	screen.play()


func set_buggraphique_state() -> void:
	current_incident = IncidentType.BUGGRAPHIQUE
	computer.animation = "default"
	computer.play()
	screen.animation = "buggraphique"
	screen.play()


func set_maj_state() -> void:
	current_incident = IncidentType.MAJ
	computer.animation = "default"
	computer.play()
	screen.animation = "maj"
	screen.play()


func set_popup_state() -> void:
	current_incident = IncidentType.POPUP
	computer.animation = "default"
	computer.play()
	screen.animation = "popup"
	screen.play()


func set_shuffle_state() -> void:
	current_incident = IncidentType.SHUFFLE
	computer.animation = "default"
	computer.play()
	screen.animation = "shuffle"
	screen.play()


func _on_computer_animation_finished() -> void:
	# Quand l'animation "debutcassage" est finie, passer à "casse" en boucle
	if computer.animation == "debutcassage":
		is_breaking = false
		computer.animation = "casse"
		computer.play()
	# Quand l'animation "repare" est finie, passer à l'état normal
	elif computer.animation == "repare":
		is_repairing = false
		set_normal_state()


func _on_incident_timer_timeout() -> void:
	# Si game over, déjà en incident, ou mode triche, ne pas en créer un nouveau
	if Globals.is_game_over or current_incident != IncidentType.NONE or Globals.cheat_mode:
		return
	
	# Calculer les probabilités pour chaque type d'incident
	var probabilities = {
		IncidentType.BURNING: get_probability_from_stages(Globals.burning_probability_stages),
		IncidentType.BLUESCREEN: get_probability_from_stages(Globals.bluescreen_probability_stages),
		IncidentType.BUGGRAPHIQUE: get_probability_from_stages(Globals.buggraphique_probability_stages),
		IncidentType.MAJ: get_probability_from_stages(Globals.maj_probability_stages),
		IncidentType.POPUP: get_probability_from_stages(Globals.popup_probability_stages),
		IncidentType.SHUFFLE: get_probability_from_stages(Globals.shuffle_probability_stages)
	}
	
	# Tester chaque type d'incident indépendamment
	var triggered_incidents = []
	for incident_type in probabilities:
		if randf() < probabilities[incident_type]:
			triggered_incidents.append(incident_type)
	
	# Si au moins un incident est déclenché, en choisir un au hasard
	if triggered_incidents.size() > 0:
		var chosen_incident = triggered_incidents[randi() % triggered_incidents.size()]
		trigger_incident(chosen_incident)


func trigger_incident(incident_type: IncidentType) -> void:
	match incident_type:
		IncidentType.BURNING:
			set_burning_state()
		IncidentType.BLUESCREEN:
			set_bluescreen_state()
		IncidentType.BUGGRAPHIQUE:
			set_buggraphique_state()
		IncidentType.MAJ:
			set_maj_state()
		IncidentType.POPUP:
			set_popup_state()
		IncidentType.SHUFFLE:
			set_shuffle_state()


func get_probability_from_stages(stages: Dictionary) -> float:
	var current_score = Globals.score
	
	# Parcourir les paliers triés
	var sorted_keys = stages.keys()
	sorted_keys.sort()
	
	for threshold in sorted_keys:
		if threshold == -1:
			continue  # Skip le default pour l'instant
		if current_score < threshold:
			return stages[threshold]
	
	# Si on dépasse tous les paliers, retourner le max
	return stages[-1]


func is_broken() -> bool:
	# Retourne true si le poste a un incident
	return current_incident != IncidentType.NONE


func get_repair_time() -> float:
	# Retourne le temps de réparation selon le type d'incident
	match current_incident:
		IncidentType.BURNING:
			return Globals.burning_repair_time
		IncidentType.BLUESCREEN:
			return Globals.bluescreen_repair_time
		IncidentType.BUGGRAPHIQUE:
			return Globals.buggraphique_repair_time
		IncidentType.MAJ:
			return Globals.maj_repair_time
		IncidentType.POPUP:
			return Globals.popup_repair_time
		IncidentType.SHUFFLE:
			return Globals.shuffle_repair_time
		_:
			return 0.0


func get_incident_type() -> IncidentType:
	return current_incident


func repair() -> void:
	# Fonction pour réparer le poste (à appeler quand le joueur interagit)
	if current_incident == IncidentType.BURNING:
		# Pour un PC cassé, jouer l'animation de réparation d'abord
		is_repairing = true
		current_incident = IncidentType.NONE  # Marquer comme réparé pour is_broken()
		computer.animation = "repare"
		computer.play()
		screen.animation = "default"
		screen.play()
	elif current_incident != IncidentType.NONE:
		# Pour les autres anomalies, retour direct à l'état normal
		set_normal_state()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# ===== MINI-JEU SNAKE =====

signal snake_ended  # Signal pour informer le joueur que le snake est terminé

func can_play_snake() -> bool:
	# On peut jouer au snake si le poste n'est pas cassé et pas déjà en snake
	return current_incident == IncidentType.NONE and not is_snake_active


func start_snake() -> void:
	if current_incident != IncidentType.NONE:
		return
	
	is_snake_active = true
	
	# Créer l'instance du snake si elle n'existe pas
	if snake_game == null:
		snake_game = snake_game_scene.instantiate()
		# Centrer le snake sur l'écran (snake fait 160x160, écran à -9,-22)
		# On centre par rapport à l'écran : position écran + offset pour centrer
		snake_game.position = Vector2(-9 - 80, -22 - 80)  # Centre du snake sur l'écran
		snake_game.z_index = 100  # Devant tout le reste
		snake_game.game_over.connect(_on_snake_game_over)
		add_child(snake_game)
		# Première fois : démarrer une nouvelle partie
		snake_game.start_game()
	else:
		# Le snake existe déjà, juste reprendre (enlever la pause)
		snake_game.show()
		snake_game.is_paused = false
	
	# Cacher l'écran normal
	screen.hide()


func pause_snake() -> void:
	# Mettre en pause et cacher le snake (quand on quitte temporairement)
	if snake_game != null:
		snake_game.is_paused = true
		snake_game.hide()
	
	is_snake_active = false
	screen.show()
	emit_signal("snake_ended")


func stop_snake() -> void:
	# Arrêter complètement le snake (reset)
	if snake_game != null:
		snake_game.stop_game()
	
	is_snake_active = false
	screen.show()
	emit_signal("snake_ended")


func toggle_snake_pause() -> void:
	if snake_game != null and is_snake_active:
		snake_game.toggle_pause()


func _on_snake_game_over() -> void:
	# Quand le snake perd, on reset tout pour la prochaine partie
	if snake_game != null:
		snake_game.queue_free()
		snake_game = null
	
	is_snake_active = false
	screen.show()
	emit_signal("snake_ended")


# ===== VISUALISEUR DE MUSIQUE =====

signal visualizer_ended

func can_open_visualizer() -> bool:
	return current_incident == IncidentType.NONE and not is_visualizer_active and not is_snake_active


func start_visualizer() -> void:
	if not can_open_visualizer():
		return
	
	is_visualizer_active = true
	
	if music_visualizer == null:
		music_visualizer = music_visualizer_scene.instantiate()
		# Rectangle 240x160, centrer (-9 est le centre X du poste)
		# Position: -9 - (240/2) = -129 pour X, -22 - (160/2) = -102 pour Y
		music_visualizer.position = Vector2(-9 - 120, -22 - 80)
		music_visualizer.z_index = 100
		music_visualizer.visualizer_closed.connect(_on_visualizer_closed)
		# Connecter le signal big_beat aux effets globaux
		if music_visualizer.has_signal("big_beat"):
			music_visualizer.big_beat.connect(_on_visualizer_big_beat)
		add_child(music_visualizer)
	
	screen.hide()
	music_visualizer.start_visualizer()


func stop_visualizer() -> void:
	if music_visualizer != null:
		music_visualizer.stop_visualizer()
	
	is_visualizer_active = false
	screen.show()
	emit_signal("visualizer_ended")


func _on_visualizer_closed() -> void:
	is_visualizer_active = false
	screen.show()
	emit_signal("visualizer_ended")


func _on_visualizer_big_beat(intensity: float) -> void:
	# Transmettre l'effet aux effets globaux via le parent (GameScene)
	# Calculer la position globale du centre du visualisateur
	var viz_center = global_position + music_visualizer.position + Vector2(120, 80)  # Centre du rectangle 240x160
	print("[PosteScene] Received big_beat: ", intensity, " at ", viz_center)
	var game_scene = get_parent()
	if game_scene and game_scene.has_method("trigger_global_beat"):
		game_scene.trigger_global_beat(intensity, viz_center)
	else:
		print("[PosteScene] ERROR: Parent doesn't have trigger_global_beat!")

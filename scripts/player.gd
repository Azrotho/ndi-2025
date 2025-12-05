extends CharacterBody2D

@export var speed = 20
@onready var sprite = $AnimatedSprite2D  # Référence au sprite animé du joueur

@onready var dialogueDection : Area2D = $DialogueDetector
@onready var heyBubble = $Camera2D/Heybubble
@onready var dialogue = $Camera2D/Dialogue	
@onready var text = $Camera2D/Dialogue/Dialoguebubble/Text
@onready var bar = $bar  # Barre de réparation
@onready var fin_screen = $Camera2D/Fin  # Écran de fin
@onready var musique: AudioStreamPlayer = null  # Référence à la musique

@onready var list_dialogues = {
	"test": DialogueTest.new(),
	"DialogueRobotCasse": RobotCasseDialogue.new(),
	"DialoguePanneau1": Panneau1Dialogue.new(),
	"DialoguePanneau2": Panneau2Dialogue.new(),
	"DialoguePanneau3" : Panneau3Dialogue.new(),
	"DialoguePanneau4" : Panneau4Dialogue.new(),
	"DialoguePanneau5" : Panneau5Dialogue.new(),
	"DialoguePanneau6" : Panneau6Dialogue.new(),
	"DialoguePanneau7" : Panneau7Dialogue.new(),
	"DialogueRobotOeuf" : RobotOeufDialogue.new()
}

var inDialogue = false
var currentDialogue
var actualText = ""
var textIndex = 0
var deltaEveryLetter = 0.05
var timeSinceLastLetter = 0

# Variables pour le système de réparation
var is_repairing: bool = false
var repair_timer: float = 0.0
var repair_duration: float = 0.0
var current_repair_poste = null

# Variables pour le mini-jeu Snake
var is_playing_snake: bool = false
var current_snake_poste = null

# Variables pour le visualiseur de musique
var is_viewing_visualizer: bool = false
var current_visualizer_poste = null
var music_visualizer = null
var music_visualizer_scene = preload("res://scenes/MusicVisualizer.tscn")

# Konami Code: ↑↑↓↓←→←→BA
var konami_sequence = ["up", "up", "down", "down", "left", "right", "left", "right", "b", "a"]
var konami_index: int = 0
var konami_timer: float = 0.0
const KONAMI_TIMEOUT: float = 2.0  # Reset après 2 secondes sans input

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bar.hide()  # Cacher la barre au départ
	fin_screen.hide()  # Cacher l'écran de fin au départ
	# Récupérer la référence à la musique
	var game_scene = get_parent()
	if game_scene.has_node("Musique"):
		musique = game_scene.get_node("Musique")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Timer pour le Konami Code
	if konami_index > 0:
		konami_timer += delta
		if konami_timer > KONAMI_TIMEOUT:
			konami_index = 0
			konami_timer = 0.0
	
	# Vérifier game over
	check_game_over()
	
	# Mettre à jour le pitch de la musique
	update_music_pitch()
	
	# Si game over, ne rien faire
	if Globals.is_game_over:
		return
	
	# Si en train de jouer au Snake ou regarder le visualiseur, ne pas bouger
	if is_playing_snake or is_viewing_visualizer:
		return
	
	# Gérer la réparation en cours
	if is_repairing:
		repair_timer += delta
		var progress = repair_timer / repair_duration
		update_repair_bar(progress)
		
		if repair_timer >= repair_duration:
			complete_repair()
		return  # Ne pas bouger pendant la réparation
	
	# Détecter les zones de dialogue et de réparation
	var isOverlappingDialogue = false
	var isOverlappingRepair = false
	var nearby_broken_poste = null
	
	if(dialogueDection.has_overlapping_areas):
		for area in dialogueDection.get_overlapping_areas():
			if area.name.contains("Dialogue"):
				isOverlappingDialogue = true
			if area.name == "RepairArea":
				var poste = area.get_parent()
				if poste.is_broken():
					isOverlappingRepair = true
					nearby_broken_poste = poste
	
	var movement = 0.0
	if(Input.is_action_pressed("ui_left")):
		movement = -1
		sprite.flip_h = true  # Retourne le sprite horizontalement
	if(Input.is_action_pressed("ui_right")):
		movement = 1
		sprite.flip_h = false  # Remet le sprite à l'endroit
	velocity = Vector2(movement * speed, 0)
	move_and_slide()
	
	# Afficher la bulle uniquement pour les dialogues (pas pour les réparations)
	if(isOverlappingDialogue):
		heyBubble.show()
	else:
		heyBubble.hide()
	
	# Stocker le poste cassé à proximité pour l'interaction
	current_repair_poste = nearby_broken_poste
	if inDialogue:
		text.text = actualText
		dialogue.show()
		Engine.time_scale = 1
		if(currentDialogue.getDialogue()[textIndex]["type"] == "message"):
			if(timeSinceLastLetter >= deltaEveryLetter):
				text.text = actualText
				if(len(actualText) < len(currentDialogue.getDialogue()[textIndex]["text"])):
					actualText += currentDialogue.getDialogue()[textIndex]["text"][len(actualText)]
				timeSinceLastLetter = 0
			else:
				timeSinceLastLetter += delta
		if(currentDialogue.getDialogue()[textIndex]["type"] == "end"):
			inDialogue = false
			dialogue.hide()
			Engine.time_scale = 1
		if(currentDialogue.getDialogue()[textIndex]["type"] != "message" and currentDialogue.getDialogue()[textIndex]["type"] != "end"):
			if(currentDialogue.getDialogue().size() > textIndex):
				textIndex = 0
				actualText = ""
				dialogue.hide()
				inDialogue = false
			else:
				textIndex += 1
				actualText = ""
				timeSinceLastLetter = 0

func _input(event: InputEvent) -> void:
	# Détection du Konami Code (fonctionne tout le temps)
	if event is InputEventKey and event.pressed:
		check_konami_input(event)
		
		# Touche de debug: K pour tuer (game over instantané)
		if event.keycode == KEY_K:
			trigger_game_over()
			return
	
	# Si game over, ignorer les inputs
	if Globals.is_game_over:
		return
	
	# Si en réparation, ignorer les inputs
	if is_repairing:
		return
	
	# Si en train de jouer au Snake
	if is_playing_snake:
		# "parler" pour mettre en pause et quitter le snake
		if event.is_action_pressed("parler"):
			pause_snake()
		return  # Les autres inputs sont gérés par le snake lui-même
	
	# Si en train de regarder le visualiseur
	if is_viewing_visualizer:
		# "parler" pour quitter le visualiseur
		if event.is_action_pressed("parler"):
			stop_visualizer()
		return
	
	if event.is_action_pressed("ui_accept"):
		if(inDialogue):
			if(textIndex >= currentDialogue.getDialogue().size()-1):
				textIndex = 0
				actualText = ""
				dialogue.hide()
				inDialogue = false
			else:
				textIndex += 1
				actualText = ""
				timeSinceLastLetter = 0
	
	# Lancer le Snake avec ui_up près d'un PC fonctionnel
	if event.is_action_pressed("ui_up"):
		var nearby_poste = get_nearby_working_poste()
		if nearby_poste != null and nearby_poste.can_play_snake():
			start_snake(nearby_poste)
			return
	
	# Lancer le visualiseur avec ui_down près d'un PC fonctionnel
	if event.is_action_pressed("ui_down"):
		var nearby_poste = get_nearby_working_poste()
		if nearby_poste != null and nearby_poste.can_open_visualizer():
			start_visualizer(nearby_poste)
			return
	
	if(event.is_action_pressed("parler")):
		# Si un dialogue est visible, gérer le dialogue
		if(heyBubble.visible):
			var areaDialogueName = ""
			for areas in dialogueDection.get_overlapping_areas():
				if(areas.name.contains("Dialogue")):
					areaDialogueName = areas.name
			if areaDialogueName != "" and list_dialogues.has(areaDialogueName):
				currentDialogue = list_dialogues[areaDialogueName]
				inDialogue = true
				return
		
		# Sinon, tenter une réparation
		if current_repair_poste != null:
			# PC cassé à proximité : vraie réparation
			start_repair(current_repair_poste)
		else:
			# Pas de PC cassé : fausse réparation (pénalité)
			start_fake_repair()


func start_repair(poste) -> void:
	# Démarrer la réparation
	is_repairing = true
	repair_timer = 0.0
	repair_duration = poste.get_repair_time()
	current_repair_poste = poste
	bar.show()
	bar.animation = "0"
	bar.play()


func start_fake_repair() -> void:
	# Fausse réparation (pénalité) - le joueur appuie dans le vide
	is_repairing = true
	repair_timer = 0.0
	repair_duration = 2.0  # 2 secondes de pénalité
	current_repair_poste = null  # Pas de poste à réparer
	bar.show()
	bar.animation = "0"
	bar.play()


func update_repair_bar(progress: float) -> void:
	# Mettre à jour l'animation de la barre (0 à 6)
	var frame = int(progress * 6)
	frame = clamp(frame, 0, 6)
	bar.animation = str(frame)
	bar.play()


func complete_repair() -> void:
	# Terminer la réparation
	if current_repair_poste != null:
		current_repair_poste.repair()
	
	is_repairing = false
	repair_timer = 0.0
	repair_duration = 0.0
	current_repair_poste = null
	bar.hide()


func check_game_over() -> void:
	# Compter les PC cassés
	var broken_count = 0
	var game_scene = get_parent()
	
	for child in game_scene.get_children():
		if child.name.begins_with("PosteScene"):
			if child.is_broken():
				broken_count += 1
	
	# Si trop de PC cassés, game over
	if broken_count >= Globals.max_broken_computers and not Globals.is_game_over:
		trigger_game_over()


func trigger_game_over() -> void:
	Globals.is_game_over = true
	
	# Fermer le visualiseur s'il est ouvert
	if is_viewing_visualizer and current_visualizer_poste != null:
		current_visualizer_poste.stop_visualizer()
		is_viewing_visualizer = false
		current_visualizer_poste = null
	
	# Fermer le snake s'il est ouvert
	if is_playing_snake and current_snake_poste != null:
		current_snake_poste.stop_snake()
		is_playing_snake = false
		current_snake_poste = null
	
	fin_screen.show()
	
	# Jouer animation death si elle existe
	if sprite.sprite_frames.has_animation("death"):
		sprite.animation = "death"
		sprite.play()


func update_music_pitch() -> void:
	if musique == null:
		return
	
	# Compter les PC cassés
	var broken_count = 0
	var game_scene = get_parent()
	
	for child in game_scene.get_children():
		if child.name.begins_with("PosteScene"):
			if child.is_broken():
				broken_count += 1
	
	# Mettre à jour le compteur global pour le visualiseur
	Globals.broken_count = broken_count
	
	# Calculer le pitch : 1.0 par défaut, augmente légèrement avec les erreurs
	# 0 erreur = 1.0, 6 erreurs = 1.15 (game over)
	var target_pitch = 1.0 + (broken_count * 0.025)
	
	# Transition douce vers le pitch cible
	var new_pitch = lerp(musique.pitch_scale, target_pitch, 0.1)
	
	# Si très proche de 1.0 et pas d'erreurs, forcer à 1.0
	if broken_count == 0 and abs(new_pitch - 1.0) < 0.005:
		new_pitch = 1.0
	
	musique.pitch_scale = new_pitch


# ===== MINI-JEU SNAKE =====

func get_nearby_working_poste():
	# Trouver un poste fonctionnel à proximité
	if dialogueDection.has_overlapping_areas():
		for area in dialogueDection.get_overlapping_areas():
			if area.name == "RepairArea":
				var poste = area.get_parent()
				if poste.can_play_snake():
					return poste
	return null


func start_snake(poste) -> void:
	is_playing_snake = true
	current_snake_poste = poste
	poste.snake_ended.connect(_on_snake_ended)
	poste.start_snake()


func pause_snake() -> void:
	# Met en pause le snake (on peut reprendre plus tard)
	if current_snake_poste != null:
		if current_snake_poste.snake_ended.is_connected(_on_snake_ended):
			current_snake_poste.snake_ended.disconnect(_on_snake_ended)
		current_snake_poste.pause_snake()
	
	is_playing_snake = false
	current_snake_poste = null


func stop_snake() -> void:
	# Arrête complètement le snake (reset)
	if current_snake_poste != null:
		if current_snake_poste.snake_ended.is_connected(_on_snake_ended):
			current_snake_poste.snake_ended.disconnect(_on_snake_ended)
		current_snake_poste.stop_snake()
	
	is_playing_snake = false
	current_snake_poste = null


func _on_snake_ended() -> void:
	# Appelé quand le snake se termine (game over)
	if current_snake_poste != null:
		if current_snake_poste.snake_ended.is_connected(_on_snake_ended):
			current_snake_poste.snake_ended.disconnect(_on_snake_ended)
	
	is_playing_snake = false
	current_snake_poste = null


# ===== VISUALISEUR DE MUSIQUE =====

func start_visualizer(poste) -> void:
	is_viewing_visualizer = true
	current_visualizer_poste = poste
	
	# Créer le visualisateur centré dans la caméra
	if music_visualizer == null:
		music_visualizer = music_visualizer_scene.instantiate()
		# La caméra a un zoom de 3x
		# Le visualisateur fait 240x160 pixels, on veut qu'il prenne ~80% de l'écran visible
		# Avec zoom 3x, la vue fait ~213x120 pixels en coordonnées monde
		# On scale le visualisateur pour qu'il fasse environ 180x120 à l'écran
		var viz_scale = 0.5  # Réduire la taille pour tenir dans la vue zoomée
		music_visualizer.scale = Vector2(viz_scale, viz_scale)
		# Centrer : (240*0.5)/2 = 60, (160*0.5)/2 = 40
		music_visualizer.position = Vector2(-60, -40)
		music_visualizer.z_index = 50
		music_visualizer.visualizer_closed.connect(_on_visualizer_ended)
		# Connecter le signal big_beat aux effets globaux
		if music_visualizer.has_signal("big_beat"):
			music_visualizer.big_beat.connect(_on_visualizer_big_beat)
		$Camera2D.add_child(music_visualizer)
	
	music_visualizer.start_visualizer()


func _on_visualizer_big_beat(intensity: float) -> void:
	# Transmettre aux effets globaux
	print("[Player] Received big_beat from visualizer, intensity: ", intensity)
	var game_scene = get_parent()
	# Position globale du centre du visualisateur
	var viz_global_pos = $Camera2D.global_position + music_visualizer.position + Vector2(120, 80)
	if game_scene and game_scene.has_method("trigger_global_beat"):
		game_scene.trigger_global_beat(intensity, viz_global_pos)
	else:
		print("[Player] ERROR: game_scene missing or no trigger_global_beat method!")


func stop_visualizer() -> void:
	if music_visualizer != null:
		music_visualizer.stop_visualizer()
	
	is_viewing_visualizer = false
	current_visualizer_poste = null


func _on_visualizer_ended() -> void:
	is_viewing_visualizer = false
	current_visualizer_poste = null


# Vérification du Konami Code
func check_konami_input(event: InputEventKey) -> void:
	var expected = konami_sequence[konami_index]
	var matched = false
	
	match expected:
		"up":
			matched = event.keycode == KEY_UP
		"down":
			matched = event.keycode == KEY_DOWN
		"left":
			matched = event.keycode == KEY_LEFT
		"right":
			matched = event.keycode == KEY_RIGHT
		"b":
			matched = event.keycode == KEY_B
		"a":
			matched = event.keycode == KEY_A
	
	if matched:
		konami_index += 1
		konami_timer = 0.0
		
		# Code complet !
		if konami_index >= konami_sequence.size():
			activate_cheat_mode()
			konami_index = 0
	else:
		# Mauvaise touche, reset
		konami_index = 0
		konami_timer = 0.0


func activate_cheat_mode() -> void:
	Globals.cheat_mode = true
	print("🎮 CHEAT MODE ACTIVATED! 🎮")

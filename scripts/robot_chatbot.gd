extends Control

# 🤖 ROBO-CONSEIL - Le chatbot nul 🤖

@onready var robot_sprite = $RobotSprite if has_node("RobotSprite") else null
@onready var speech_bubble = $SpeechBubble if has_node("SpeechBubble") else null
@onready var speech_label = $SpeechBubble/Label if has_node("SpeechBubble/Label") else null
@onready var input_field = $InputField if has_node("InputField") else null
@onready var send_button = $SendButton if has_node("SendButton") else null
@onready var back_button = $BackButton if has_node("BackButton") else null

var is_showing_tip: bool = true
var click_count: int = 0

func _ready() -> void:
	# Attendre un frame pour que les nœuds soient prêts
	await get_tree().process_frame
	
	# Récupérer les références
	if has_node("RobotSprite"):
		robot_sprite = $RobotSprite
	if has_node("SpeechBubble/Label"):
		speech_label = $SpeechBubble/Label
	if has_node("InputField"):
		input_field = $InputField
	if has_node("SendButton"):
		send_button = $SendButton
	if has_node("BackButton"):
		back_button = $BackButton
	
	# Afficher un conseil aléatoire au démarrage
	show_random_tip()
	
	# Connecter les signaux
	if robot_sprite and robot_sprite.has_signal("gui_input"):
		robot_sprite.gui_input.connect(_on_robot_clicked)
	if send_button:
		send_button.pressed.connect(_on_send_pressed)
	if input_field:
		input_field.text_submitted.connect(_on_text_submitted)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	# Se connecter à la visibilité pour rafraîchir le conseil
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		click_count = 0
		is_showing_tip = true
		show_random_tip()
		if input_field:
			input_field.text = ""


func show_random_tip() -> void:
	if Globals.robot_tips.size() > 0 and speech_label:
		var tip_index = randi() % Globals.robot_tips.size()
		speech_label.text = Globals.robot_tips[tip_index]
		is_showing_tip = true


func show_random_response() -> void:
	if Globals.robot_random_responses.size() > 0 and speech_label:
		var response_index = randi() % Globals.robot_random_responses.size()
		speech_label.text = Globals.robot_random_responses[response_index]
		is_showing_tip = false


func _on_robot_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_count += 1
		
		# Easter egg après plusieurs clics
		if click_count >= 10:
			speech_label.text = "ARRÊTE DE ME CLIQUER DESSUS !!!"
			click_count = 0
		else:
			show_random_response()


func _on_send_pressed() -> void:
	send_message()


func _on_text_submitted(_text: String) -> void:
	send_message()


func send_message() -> void:
	if input_field and input_field.text.strip_edges() != "":
		var message = input_field.text.strip_edges().to_lower()
		
		# Commande de test pour déclencher game over
		if message == "suicide":
			Globals.broken_count = Globals.max_broken_computers
			return
		
		# Le joueur a écrit quelque chose, le robot répond au pif
		show_random_response()
		input_field.text = ""
		input_field.grab_focus()


func _on_back_pressed() -> void:
	# Retour au menu principal
	Globals.reset_game_state()
	get_tree().change_scene_to_file("res://scenes/MainTitle.tscn")

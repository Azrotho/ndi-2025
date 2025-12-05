extends Control


@onready var playButtons = $MarginContainer/VBoxContainer/Play
@onready var howtoplayscene = preload("res://scenes/HowToPlayScene.tscn")
@onready var gameScene = preload("res://scenes/GameScene.tscn")
@onready var creditScene = preload("res://scenes/CreditScene.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	playButtons.grab_focus()

func _on_play_pressed() -> void:
	Globals.reset_game_state()  # Reset toutes les données de jeu
	get_tree().change_scene_to_packed(gameScene)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_packed(howtoplayscene)



func _on_quit_pressed() -> void:
	get_tree().change_scene_to_packed(creditScene)

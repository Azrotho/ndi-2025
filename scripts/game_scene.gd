extends Node2D

# 🎮 GAME SCENE 🎮
# Scène principale du jeu avec gestion des effets globaux

# Référence aux effets globaux
var global_effects: CanvasLayer = null
var global_effects_script = preload("res://scripts/global_effects.gd")

func _ready() -> void:
	# Créer le layer d'effets globaux
	global_effects = CanvasLayer.new()
	global_effects.set_script(global_effects_script)
	add_child(global_effects)


func trigger_global_beat(intensity: float, center_pos: Vector2 = Vector2.ZERO) -> void:
	# Déclencher un effet plein écran lors d'un gros beat
	print("[GameScene] trigger_global_beat at: ", center_pos)
	if global_effects and global_effects.has_method("trigger_big_beat"):
		global_effects.trigger_big_beat(intensity, center_pos)
	else:
		print("[GameScene] ERROR: global_effects missing or no method!")

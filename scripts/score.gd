extends Node2D

@onready var label = $Label
@onready var timer = $ScoreTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Créer et configurer le timer
	if not has_node("ScoreTimer"):
		var new_timer = Timer.new()
		new_timer.name = "ScoreTimer"
		new_timer.wait_time = 2.0
		new_timer.autostart = true
		new_timer.timeout.connect(_on_timer_timeout)
		add_child(new_timer)
		timer = new_timer
	else:
		timer.timeout.connect(_on_timer_timeout)
		timer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	label.text = "Score: " + str(Globals.score)
	
	# Score jaune en mode triche
	if Globals.cheat_mode:
		label.modulate = Color.YELLOW
	else:
		label.modulate = Color.WHITE


func _on_timer_timeout() -> void:
	# Ne pas incrémenter si game over
	if Globals.is_game_over:
		return
	Globals.score += 1

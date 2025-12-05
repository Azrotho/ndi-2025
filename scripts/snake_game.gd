extends Node2D

# Mini-jeu Snake - Grille 10x10 (avec murs) = 8x8 jouable

signal game_over
signal pizza_eaten

const GRID_SIZE = 10  # 10x10 total avec murs
const PLAYABLE_SIZE = 8  # 8x8 jouable
const CELL_SIZE = 16
const GAME_SIZE = 160  # 10 * 16

var move_interval: float = 0.2
var move_timer: float = 0.0
var score_timer: float = 0.0

var is_playing: bool = false
var is_paused: bool = false

var snake_body: Array = []  # Array de Vector2i (positions dans la grille jouable 0-7)
var direction: Vector2i = Vector2i(1, 0)
var next_direction: Vector2i = Vector2i(1, 0)
var pizza_pos: Vector2i = Vector2i(4, 4)

var snake_texture: Texture2D
var assets_texture: Texture2D
var black_screen_texture: Texture2D

# Régions des sprites dans snake.png
const HEAD_RIGHT = Rect2(0, 0, 16, 16)
const TAIL_UP = Rect2(48, 0, 16, 16)
const BODY_HORIZONTAL = Rect2(16, 16, 16, 16)
const BODY_CORNER = Rect2(16, 32, 16, 16)

# Régions des sprites dans snakeassets.png
const PIZZA = Rect2(0, 0, 16, 16)
const DAMIER_1 = Rect2(16, 16, 16, 16)
const DAMIER_2 = Rect2(16, 32, 16, 16)
const WALL_SIDE = Rect2(0, 32, 16, 16)
const WALL_CORNER = Rect2(0, 48, 16, 16)


func _ready() -> void:
	snake_texture = preload("res://assets/sprites/snake.png")
	assets_texture = preload("res://assets/sprites/snakeassets.png")
	black_screen_texture = preload("res://assets/sprites/écran noir.png")
	# Activer le filtre nearest pour les textures pixel art
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hide()


func _process(delta: float) -> void:
	if not is_playing or is_paused:
		return
	
	# Score x3 : ajouter 2 points supplémentaires toutes les 2 secondes
	# (le score normal ajoute 1, donc total = 3)
	score_timer += delta
	if score_timer >= 2.0:
		score_timer = 0.0
		Globals.score += 2  # +2 en plus du +1 normal = x3
	
	move_timer += delta
	if move_timer >= move_interval:
		move_timer = 0.0
		move_snake()


func _input(event: InputEvent) -> void:
	if not is_playing or is_paused:
		return
	
	# Changer de direction (pas de retour en arrière)
	if event.is_action_pressed("ui_up") and direction != Vector2i(0, 1):
		next_direction = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down") and direction != Vector2i(0, -1):
		next_direction = Vector2i(0, 1)
	elif event.is_action_pressed("ui_left") and direction != Vector2i(1, 0):
		next_direction = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right") and direction != Vector2i(-1, 0):
		next_direction = Vector2i(1, 0)


func start_game() -> void:
	snake_body.clear()
	snake_body.append(Vector2i(2, 3))  # Tête
	snake_body.append(Vector2i(1, 3))  # Corps
	
	direction = Vector2i(1, 0)
	next_direction = Vector2i(1, 0)
	move_timer = 0.0
	score_timer = 0.0
	
	spawn_pizza()
	
	is_playing = true
	is_paused = false
	show()
	queue_redraw()


func stop_game() -> void:
	is_playing = false
	is_paused = false
	hide()


func toggle_pause() -> void:
	is_paused = not is_paused


func move_snake() -> void:
	direction = next_direction
	
	var new_head = snake_body[0] + direction
	
	# Vérifier collision avec les murs
	if new_head.x < 0 or new_head.x >= PLAYABLE_SIZE or new_head.y < 0 or new_head.y >= PLAYABLE_SIZE:
		emit_signal("game_over")
		stop_game()
		return
	
	# Vérifier collision avec soi-même
	if new_head in snake_body:
		emit_signal("game_over")
		stop_game()
		return
	
	snake_body.insert(0, new_head)
	
	# Vérifier si on mange la pizza
	if new_head == pizza_pos:
		emit_signal("pizza_eaten")
		Globals.score += 10
		spawn_pizza()
	else:
		snake_body.pop_back()
	
	queue_redraw()


func spawn_pizza() -> void:
	var free_positions: Array = []
	for x in range(PLAYABLE_SIZE):
		for y in range(PLAYABLE_SIZE):
			var pos = Vector2i(x, y)
			if pos not in snake_body:
				free_positions.append(pos)
	
	if free_positions.size() > 0:
		pizza_pos = free_positions[randi() % free_positions.size()]
	else:
		# Victoire ! Le snake remplit tout
		emit_signal("game_over")
		stop_game()


func _draw() -> void:
	if not is_playing:
		return
	
	# Fond noir uni (un seul rectangle)
	draw_rect(Rect2(0, 0, GAME_SIZE, GAME_SIZE), Color.BLACK)
	
	# Dessiner les murs (bordure)
	draw_walls()
	
	# Dessiner le damier (zone jouable)
	for x in range(PLAYABLE_SIZE):
		for y in range(PLAYABLE_SIZE):
			var dest = Vector2((x + 1) * CELL_SIZE, (y + 1) * CELL_SIZE)
			var src = DAMIER_1 if (x + y) % 2 == 0 else DAMIER_2
			draw_texture_rect_region(assets_texture, Rect2(dest, Vector2(CELL_SIZE, CELL_SIZE)), src)
	
	# Dessiner la pizza
	var pizza_dest = Vector2((pizza_pos.x + 1) * CELL_SIZE, (pizza_pos.y + 1) * CELL_SIZE)
	draw_texture_rect_region(assets_texture, Rect2(pizza_dest, Vector2(CELL_SIZE, CELL_SIZE)), PIZZA)
	
	# Dessiner le snake
	draw_snake()


func draw_walls() -> void:
	# 4 Coins
	# Haut-gauche
	draw_texture_rect_region(assets_texture, Rect2(0, 0, CELL_SIZE, CELL_SIZE), WALL_CORNER)
	# Haut-droite (rotation 90°)
	draw_set_transform(Vector2((GRID_SIZE - 1) * CELL_SIZE + CELL_SIZE, 0), PI / 2, Vector2.ONE)
	draw_texture_rect_region(assets_texture, Rect2(0, 0, CELL_SIZE, CELL_SIZE), WALL_CORNER)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# Bas-droite (rotation 180°)
	draw_set_transform(Vector2((GRID_SIZE - 1) * CELL_SIZE + CELL_SIZE, (GRID_SIZE - 1) * CELL_SIZE + CELL_SIZE), PI, Vector2.ONE)
	draw_texture_rect_region(assets_texture, Rect2(0, 0, CELL_SIZE, CELL_SIZE), WALL_CORNER)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# Bas-gauche (rotation -90°)
	draw_set_transform(Vector2(0, (GRID_SIZE - 1) * CELL_SIZE + CELL_SIZE), -PI / 2, Vector2.ONE)
	draw_texture_rect_region(assets_texture, Rect2(0, 0, CELL_SIZE, CELL_SIZE), WALL_CORNER)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	
	# Murs horizontaux (haut et bas)
	for x in range(1, GRID_SIZE - 1):
		# Haut (rotation 90°)
		draw_set_transform(Vector2(x * CELL_SIZE + CELL_SIZE, 0), PI / 2, Vector2.ONE)
		draw_texture_rect_region(assets_texture, Rect2(0, 0, CELL_SIZE, CELL_SIZE), WALL_SIDE)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		# Bas (rotation -90°)
		draw_set_transform(Vector2(x * CELL_SIZE, (GRID_SIZE - 1) * CELL_SIZE + CELL_SIZE), -PI / 2, Vector2.ONE)
		draw_texture_rect_region(assets_texture, Rect2(0, 0, CELL_SIZE, CELL_SIZE), WALL_SIDE)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	
	# Murs verticaux (gauche et droite)
	for y in range(1, GRID_SIZE - 1):
		# Gauche (pas de rotation, mur va de haut en bas)
		draw_texture_rect_region(assets_texture, Rect2(0, y * CELL_SIZE, CELL_SIZE, CELL_SIZE), WALL_SIDE)
		# Droite (rotation 180°)
		draw_set_transform(Vector2((GRID_SIZE - 1) * CELL_SIZE + CELL_SIZE, y * CELL_SIZE + CELL_SIZE), PI, Vector2.ONE)
		draw_texture_rect_region(assets_texture, Rect2(0, 0, CELL_SIZE, CELL_SIZE), WALL_SIDE)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func draw_snake() -> void:
	for i in range(snake_body.size()):
		var pos = snake_body[i]
		var dest = Vector2((pos.x + 1) * CELL_SIZE, (pos.y + 1) * CELL_SIZE)
		
		if i == 0:
			# Tête - rotation selon direction
			var angle = 0.0
			if direction == Vector2i(0, -1):  # Haut
				angle = -PI / 2
			elif direction == Vector2i(0, 1):  # Bas
				angle = PI / 2
			elif direction == Vector2i(-1, 0):  # Gauche
				angle = PI
			# Droite = 0 (défaut)
			
			draw_set_transform(dest + Vector2(CELL_SIZE / 2, CELL_SIZE / 2), angle, Vector2.ONE)
			draw_texture_rect_region(snake_texture, Rect2(-Vector2(CELL_SIZE / 2, CELL_SIZE / 2), Vector2(CELL_SIZE, CELL_SIZE)), HEAD_RIGHT)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		elif i == snake_body.size() - 1:
			# Queue
			var prev_pos = snake_body[i - 1]
			var diff = prev_pos - pos
			var angle = 0.0
			if diff == Vector2i(0, -1):  # Corps au-dessus
				angle = 0  # Queue vers le haut (défaut)
			elif diff == Vector2i(0, 1):  # Corps en-dessous
				angle = PI
			elif diff == Vector2i(-1, 0):  # Corps à gauche
				angle = -PI / 2
			elif diff == Vector2i(1, 0):  # Corps à droite
				angle = PI / 2
			
			draw_set_transform(dest + Vector2(CELL_SIZE / 2, CELL_SIZE / 2), angle, Vector2.ONE)
			draw_texture_rect_region(snake_texture, Rect2(-Vector2(CELL_SIZE / 2, CELL_SIZE / 2), Vector2(CELL_SIZE, CELL_SIZE)), TAIL_UP)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		else:
			# Corps
			var prev_pos = snake_body[i - 1]
			var next_pos = snake_body[i + 1]
			var diff_prev = prev_pos - pos
			var diff_next = next_pos - pos
			
			# Vérifier si c'est un coin ou un segment droit
			if (diff_prev.x != 0 and diff_next.y != 0) or (diff_prev.y != 0 and diff_next.x != 0):
				# Coin
				var angle = get_corner_angle(diff_prev, diff_next)
				draw_set_transform(dest + Vector2(CELL_SIZE / 2, CELL_SIZE / 2), angle, Vector2.ONE)
				draw_texture_rect_region(snake_texture, Rect2(-Vector2(CELL_SIZE / 2, CELL_SIZE / 2), Vector2(CELL_SIZE, CELL_SIZE)), BODY_CORNER)
				draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			else:
				# Segment droit
				var angle = 0.0
				if diff_prev.x != 0:  # Horizontal
					angle = 0
				else:  # Vertical
					angle = PI / 2
				
				draw_set_transform(dest + Vector2(CELL_SIZE / 2, CELL_SIZE / 2), angle, Vector2.ONE)
				draw_texture_rect_region(snake_texture, Rect2(-Vector2(CELL_SIZE / 2, CELL_SIZE / 2), Vector2(CELL_SIZE, CELL_SIZE)), BODY_HORIZONTAL)
				draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func get_corner_angle(diff_prev: Vector2i, diff_next: Vector2i) -> float:
	# BODY_CORNER va de bas vers droite
	# On doit calculer l'angle pour les autres combinaisons
	
	# Combinaisons possibles: (prev, next) ou (next, prev)
	var dirs = [diff_prev, diff_next]
	
	if Vector2i(0, 1) in dirs and Vector2i(1, 0) in dirs:
		# Bas-Droite (défaut)
		return 0.0
	elif Vector2i(0, 1) in dirs and Vector2i(-1, 0) in dirs:
		# Bas-Gauche
		return PI / 2
	elif Vector2i(0, -1) in dirs and Vector2i(-1, 0) in dirs:
		# Haut-Gauche
		return PI
	elif Vector2i(0, -1) in dirs and Vector2i(1, 0) in dirs:
		# Haut-Droite
		return -PI / 2
	
	return 0.0

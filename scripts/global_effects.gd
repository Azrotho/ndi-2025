extends CanvasLayer

# 🎆 EFFETS PLEIN ÉCRAN 🎆
# Effets visuels déclenchés par le visualisateur de musique

# Dimensions de l'écran (mises à jour dynamiquement)
var SCREEN_WIDTH: float = 640.0
var SCREEN_HEIGHT: float = 360.0

# Position du centre des effets (mise à jour dynamiquement)
var effect_center: Vector2 = Vector2(320, 180)

# Effets actifs
var flash_intensity: float = 0.0
var pulse_scale: float = 1.0
var glitch_offset: Vector2 = Vector2.ZERO
var particles: Array = []
var wave_rings: Array = []
var scanline_offset: float = 0.0
var screen_shake: Vector2 = Vector2.ZERO
var color_shift: float = 0.0
var strobe_timer: float = 0.0
var mega_particles: Array = []  # Grosses particules qui traversent l'écran

# Couleurs
var flash_color: Color = Color.WHITE

# Noeuds de dessin (avant et arrière)
@onready var draw_node_back: Node2D = null  # Derrière le visualisateur
@onready var draw_node_front: Node2D = null  # Devant le visualisateur

func _ready() -> void:
	# Récupérer la vraie taille du viewport
	_update_screen_size()
	
	# Configuration du CanvasLayer pour ignorer la caméra
	layer = 100
	follow_viewport_enabled = false  # NE PAS suivre le viewport/caméra
	
	# Créer un nœud pour dessiner DERRIÈRE (particules)
	draw_node_back = Node2D.new()
	draw_node_back.z_index = 40  # Derrière le visualisateur (z_index 50)
	add_child(draw_node_back)
	draw_node_back.set_script(load("res://scripts/global_effects_draw.gd"))
	draw_node_back.effects_parent = self
	draw_node_back.draw_mode = "back"
	
	# Créer un nœud pour dessiner DEVANT (flash, ondes)
	draw_node_front = Node2D.new()
	draw_node_front.z_index = 1000  # Devant tout
	add_child(draw_node_front)
	draw_node_front.set_script(load("res://scripts/global_effects_draw.gd"))
	draw_node_front.effects_parent = self
	draw_node_front.draw_mode = "front"
	


func _update_screen_size() -> void:
	var vp = get_viewport()
	if vp:
		var size = vp.get_visible_rect().size
		SCREEN_WIDTH = size.x
		SCREEN_HEIGHT = size.y
		effect_center = Vector2(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)


func trigger_big_beat(intensity: float, _center_pos: Vector2 = Vector2.ZERO) -> void:
	# Mettre à jour la taille de l'écran au cas où elle a changé
	_update_screen_size()
	
	# FLASH MASSIF
	flash_intensity = 1.0
	flash_color = Color.from_hsv(randf(), 0.3, 1.0, 0.7)
	
	# SHAKE D'ÉCRAN
	screen_shake = Vector2(
		(randf() - 0.5) * 30 * intensity,
		(randf() - 0.5) * 30 * intensity
	)
	
	# MEGA PARTICULES qui traversent l'écran
	spawn_mega_particles(intensity)
	
	# Beaucoup de particules normales
	spawn_beat_particles(intensity)
	
	# Plusieurs ondes de choc
	spawn_wave_ring(intensity)
	spawn_wave_ring(intensity * 0.7)
	
	# Strobe effect
	strobe_timer = 0.3
	
	# Color shift
	color_shift = intensity


func spawn_mega_particles(intensity: float) -> void:
	# Grosses particules qui apparaissent aléatoirement sur TOUT l'écran
	var num_particles = int(intensity * 6) + 3
	
	# Couleur basée sur le nombre d'ordis cassés
	var broken = Globals.broken_count
	var max_broken = Globals.max_broken_computers
	var broken_ratio = clamp(float(broken) / float(max_broken), 0.0, 1.0)
	
	# Hue: 0.55 (cyan) -> 0.0 (rouge) selon les ordis cassés
	var base_hue = lerp(0.55, 0.0, broken_ratio)
	
	for i in range(num_particles):
		# Position aléatoire sur TOUT l'écran
		var spawn_pos = Vector2(
			randf() * SCREEN_WIDTH,
			randf() * SCREEN_HEIGHT
		)
		
		# Direction aléatoire
		var angle = randf() * TAU
		var speed = 200 + randf() * 400
		var dir = Vector2.from_angle(angle)
		
		# Couleur avec variation
		var hue_var = (randf() - 0.5) * 0.2
		var hue = fmod(base_hue + hue_var + 1.0, 1.0)
		var sat = 0.7 + broken_ratio * 0.3
		
		mega_particles.append({
			"pos": spawn_pos,
			"vel": dir * speed,
			"life": 1.2,
			"length": 50 + (randi() % 100),
			"width": 3 + (randi() % 5),
			"color": Color.from_hsv(hue, sat, 1.0, 1.0)
		})


func spawn_beat_particles(intensity: float) -> void:
	# Particules qui apparaissent dans la zone du visualisateur
	var viz_half_width = 60.0
	var viz_half_height = 40.0
	
	var num_particles = int(intensity * 20) + 8
	
	# Couleur basée sur le nombre d'ordis cassés
	var broken = Globals.broken_count
	var max_broken = Globals.max_broken_computers
	var broken_ratio = clamp(float(broken) / float(max_broken), 0.0, 1.0)
	
	# Hue: 0.55 (cyan) -> 0.0 (rouge) selon les ordis cassés
	var base_hue = lerp(0.55, 0.0, broken_ratio)
	
	for i in range(num_particles):
		# Position aléatoire dans le visualisateur
		var spawn_pos = Vector2(
			effect_center.x + (randf() - 0.5) * viz_half_width * 2,
			effect_center.y + (randf() - 0.5) * viz_half_height * 2
		)
		
		# Direction vers l'extérieur (depuis le centre)
		var dir_from_center = (spawn_pos - effect_center).normalized()
		if dir_from_center.length() < 0.1:
			dir_from_center = Vector2.from_angle(randf() * TAU)
		var angle_variation = (randf() - 0.5) * 0.8
		var dir = dir_from_center.rotated(angle_variation)
		var speed = 150 + randf() * 250 * intensity
		
		# Couleur avec variation
		var hue = fmod(base_hue + (randf() - 0.5) * 0.15 + 1.0, 1.0)
		var sat = 0.6 + broken_ratio * 0.4
		
		particles.append({
			"pos": spawn_pos,
			"vel": dir * speed,
			"life": 1.0,
			"size": 3 + randi() % 6,
			"color": Color.from_hsv(hue, sat, 1.0, 1.0)
		})


func spawn_wave_ring(intensity: float) -> void:
	# Couleur basée sur le nombre d'ordis cassés
	var broken = Globals.broken_count
	var max_broken = Globals.max_broken_computers
	var broken_ratio = clamp(float(broken) / float(max_broken), 0.0, 1.0)
	
	# Hue: 0.55 (cyan) -> 0.0 (rouge)
	var hue = lerp(0.55, 0.0, broken_ratio)
	
	wave_rings.append({
		"center": effect_center,
		"radius": 0.0,
		"life": 1.0,
		"max_radius": 600 * intensity,
		"thickness": 8 + intensity * 10,
		"color": Color.from_hsv(hue, 0.6 + broken_ratio * 0.3, 1.0, 0.8)
	})


func _process(delta: float) -> void:
	# Atténuer le flash
	flash_intensity = lerp(flash_intensity, 0.0, delta * 4)
	
	# Atténuer le shake
	screen_shake = screen_shake.lerp(Vector2.ZERO, delta * 8)
	
	# Atténuer le color shift
	color_shift = lerp(color_shift, 0.0, delta * 3)
	
	# Strobe
	if strobe_timer > 0:
		strobe_timer -= delta
	
	# Scanlines
	scanline_offset += delta * 200
	
	# Mettre à jour les mega particules
	var mega_to_remove = []
	for p in mega_particles:
		p.pos += p.vel * delta
		p.life -= delta * 1.5
		if p.life <= 0:
			mega_to_remove.append(p)
	for p in mega_to_remove:
		mega_particles.erase(p)
	
	# Mettre à jour les particules
	var particles_to_remove = []
	for p in particles:
		p.pos += p.vel * delta
		p.vel *= 0.98  # Friction légère
		p.life -= delta * 1.5
		if p.life <= 0:
			particles_to_remove.append(p)
	for p in particles_to_remove:
		particles.erase(p)
	
	# Mettre à jour les anneaux
	var rings_to_remove = []
	for ring in wave_rings:
		ring.radius += delta * 800  # Plus rapide
		ring.life -= delta * 1.2
		if ring.life <= 0 or ring.radius > ring.max_radius:
			rings_to_remove.append(ring)
	for ring in rings_to_remove:
		wave_rings.erase(ring)
	
	# Redessiner les deux couches
	if draw_node_back:
		draw_node_back.position = screen_shake
		draw_node_back.queue_redraw()
	if draw_node_front:
		draw_node_front.position = screen_shake
		draw_node_front.queue_redraw()

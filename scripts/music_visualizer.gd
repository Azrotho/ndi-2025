extends Node2D

# 🎵 PIXEL ART MUSIC VISUALIZER 🎵
# Un visualiseur rétro style console 8-bit / arcade
# Utilise des données pré-analysées depuis un fichier JSON

signal visualizer_closed
signal big_beat(intensity: float)  # Signal pour effets plein écran

const WIDTH = 240   # Rectangle plus large
const HEIGHT = 160
const PIXEL = 4  # Taille d'un "gros pixel" pour l'effet rétro
const GRID_X = 60   # 240 / 4
const GRID_Y = 40   # 160 / 4

var is_active: bool = false
var time: float = 0.0
var score_timer: float = 0.0

# Données spectrales pré-analysées
var spectrum_data: Dictionary = {}
var spectrum_frames: Array = []
var spectrum_beats: Array = []
var spectrum_fps: float = 30.0
var spectrum_duration: float = 0.0
var current_frame_idx: int = 0

# Référence au lecteur de musique pour obtenir la position et le pitch
var music_player: AudioStreamPlayer = null

# Données audio
var bars: Array = []
var prev_bars: Array = []
var peak_bars: Array = []  # Pour le "peak hold"
const NUM_BARS = 24  # 24 barres pour un rectangle plus large

# Couleurs palette - sera modifiée dynamiquement selon les anomalies
# Palette normale (tons cyan/bleu)
var palette_normal = [
	Color(0.02, 0.05, 0.08),   # Noir profond
	Color(0.05, 0.12, 0.18),   # Bleu très sombre
	Color(0.08, 0.18, 0.28),   # Bleu sombre
	Color(0.1, 0.3, 0.5),      # Bleu
	Color(0.15, 0.45, 0.65),   # Bleu clair
	Color(0.2, 0.6, 0.8),      # Cyan
	Color(0.3, 0.75, 0.9),     # Cyan clair
	Color(0.5, 0.85, 0.95),    # Cyan très clair
	Color(0.2, 0.8, 0.6),      # Turquoise
	Color(0.3, 0.9, 0.7),      # Vert cyan
	Color(0.5, 0.95, 0.8),     # Vert clair
	Color(1.0, 1.0, 1.0),      # Blanc
]

# Palette danger (tons rouge/orange)
var palette_danger = [
	Color(0.1, 0.02, 0.02),    # Noir rougeâtre
	Color(0.2, 0.05, 0.03),    # Rouge très sombre
	Color(0.35, 0.08, 0.05),   # Rouge sombre
	Color(0.5, 0.1, 0.05),     # Rouge foncé
	Color(0.7, 0.15, 0.05),    # Rouge
	Color(0.85, 0.25, 0.08),   # Rouge orangé
	Color(0.95, 0.4, 0.1),     # Orange rouge
	Color(1.0, 0.55, 0.15),    # Orange
	Color(1.0, 0.7, 0.2),      # Orange clair
	Color(1.0, 0.85, 0.3),     # Jaune orangé
	Color(1.0, 0.95, 0.5),     # Jaune
	Color(1.0, 1.0, 1.0),      # Blanc
]

# Palette actuelle (interpolée)
var palette: Array = []

# Étoiles de fond
var stars: Array = []

# Onde circulaire
var wave_rings: Array = []

# Particules flottantes
var particles: Array = []

# Lignes de scan (effet CRT)
var scan_line_offset: float = 0.0

# Caractères pour l'affichage pixel art
var beat_flash: float = 0.0
var bass_level: float = 0.0
var prev_bass_level: float = 0.0
var energy_accumulator: float = 0.0  # Pour les effets cumulatifs

# Nouveaux effets
var pulse_zoom: float = 1.0  # Effet de zoom sur les beats
var glitch_timer: float = 0.0  # Timer pour l'effet glitch
var glitch_intensity: float = 0.0  # Intensité du glitch
var bar_trails: Array = []  # Historique des barres pour les trainées
const TRAIL_LENGTH = 4  # Nombre de frames de trainée
var bar_particles: Array = []  # Particules émises par les barres hautes
var last_big_beat_time: float = 0.0  # Pour éviter les beats trop rapprochés


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Initialiser la palette
	for i in range(palette_normal.size()):
		palette.append(palette_normal[i])
	
	# Initialiser les barres
	for i in range(NUM_BARS):
		bars.append(0.0)
		prev_bars.append(0.0)
		peak_bars.append(0.0)
	
	# Créer les étoiles de fond (plus d'étoiles pour le rectangle)
	for i in range(50):
		stars.append({
			"x": randi() % GRID_X,
			"y": randi() % GRID_Y,
			"blink": randf() * TAU,
			"speed": randf() * 2 + 1
		})
	
	# Créer des particules flottantes
	for i in range(20):
		particles.append({
			"x": randf() * WIDTH,
			"y": randf() * HEIGHT,
			"vx": (randf() - 0.5) * 20,
			"vy": (randf() - 0.5) * 20,
			"life": randf(),
			"size": randi() % 2 + 1
		})
	
	# Configurer l'analyseur de spectre audio
	setup_spectrum_analyzer()
	
	hide()


func setup_spectrum_analyzer() -> void:
	# Charger les données pré-analysées depuis le JSON
	load_spectrum_data()
	
	if spectrum_frames.size() > 0:
		print("Visualizer: Données spectrales chargées - %d frames" % spectrum_frames.size())
	else:
		print("Visualizer: Utilisation de la simulation (pas de données JSON)")


func load_spectrum_data() -> void:
	# Charger le fichier JSON pré-analysé
	var json_path = "res://assets/musics/zone3_spectrum.json"
	
	if not FileAccess.file_exists(json_path):
		print("Visualizer: Fichier JSON non trouvé: ", json_path)
		return
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		print("Visualizer: Impossible d'ouvrir le fichier JSON")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		print("Visualizer: Erreur parsing JSON: ", json.get_error_message())
		return
	
	spectrum_data = json.data
	spectrum_frames = spectrum_data.get("frames", [])
	spectrum_beats = spectrum_data.get("beats", [])
	spectrum_fps = spectrum_data.get("fps", 30.0)
	spectrum_duration = spectrum_data.get("duration", 0.0)
	
	print("Visualizer: JSON chargé - FPS: %s, Durée: %s s, Beats: %d" % [
		str(spectrum_fps), 
		str(snapped(spectrum_duration, 0.01)), 
		spectrum_beats.size()
	])


func _connect_music_to_bus() -> void:
	# Plus besoin de rediriger - on analyse directement sur Master
	pass


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found = _find_node_by_name(child, target_name)
		if found:
			return found
	return null


func _process(delta: float) -> void:
	if not is_active:
		return
	
	# Vérifier le game over - fermer automatiquement
	if Globals.is_game_over:
		stop_visualizer()
		return
	
	time += delta
	scan_line_offset += delta * 50  # Effet CRT
	
	# Score x5 : ajouter 4 points supplémentaires toutes les 2 secondes
	score_timer += delta
	if score_timer >= 2.0:
		score_timer = 0.0
		Globals.score += 4  # +4 en plus du +1 normal = x5
	
	# Mettre à jour la palette selon le nombre d'anomalies
	update_palette()
	
	# Mettre à jour depuis l'audio réel
	update_audio_from_spectrum()
	
	# Mettre à jour les effets
	update_effects(delta)
	
	# Mettre à jour les particules
	update_particles(delta)
	
	queue_redraw()


func update_audio_from_spectrum() -> void:
	# Utiliser les données JSON pré-analysées
	if spectrum_frames.size() == 0:
		update_audio_simulation_fallback()
		return
	
	# Trouver le lecteur de musique si pas encore fait
	if music_player == null:
		var root = get_tree().root
		music_player = _find_node_of_type(root, "AudioStreamPlayer")
	
	# Calculer la position dans les données JSON
	var music_position: float = 0.0
	var pitch_scale: float = 1.0
	
	if music_player != null and music_player.playing:
		music_position = music_player.get_playback_position()
		pitch_scale = music_player.pitch_scale
	else:
		# Fallback: utiliser le temps local (moins précis)
		music_position = fmod(time, spectrum_duration)
	
	# Compenser le pitch: si pitch > 1, la musique va plus vite
	# donc on doit avancer plus vite dans les données
	var frame_idx = int(music_position * spectrum_fps)
	frame_idx = clamp(frame_idx, 0, spectrum_frames.size() - 1)
	
	# Obtenir les données de la frame
	var frame_data = spectrum_frames[frame_idx]
	
	# Sauvegarder les anciennes valeurs pour les trails
	for i in range(NUM_BARS):
		prev_bars[i] = lerp(prev_bars[i], bars[i], 0.3)
	
	prev_bass_level = bass_level
	
	# Appliquer les données du JSON aux barres
	for i in range(NUM_BARS):
		if i < frame_data.size():
			var value = frame_data[i]
			# Réduire la sensibilité pour le web (barres moins réactives)
			value = value * 0.6
			# Smooth avec l'ancienne valeur pour une animation fluide
			bars[i] = lerp(bars[i], value, 0.4)
		
		# Mettre à jour le peak hold
		if bars[i] > peak_bars[i]:
			peak_bars[i] = bars[i]
		else:
			peak_bars[i] = lerp(peak_bars[i], bars[i], 0.05)
	
	# Niveau des basses pour les effets (les 4 premières barres)
	bass_level = (bars[0] + bars[1] + bars[2] + bars[3]) / 4.0
	
	# Détection de beat depuis les données JSON
	var is_beat = false
	for beat_time in spectrum_beats:
		# Vérifier si on est proche d'un beat (tolérance de 0.05s)
		if abs(music_position - beat_time) < 0.05:
			is_beat = true
			break
	
	if is_beat and bass_level > 0.2:
		beat_flash = 1.0
		# Émettre un signal pour les effets plein écran (pas trop souvent)
		if time - last_big_beat_time > 0.4 and bass_level > 0.25:
			last_big_beat_time = time
			print("[Visualizer] Emitting big_beat: ", bass_level)
			emit_signal("big_beat", bass_level)
	
	# Fallback: détection de beat par delta si JSON beats pas détectés
	var bass_delta = bass_level - prev_bass_level
	if bass_delta > 0.1 and bass_level > 0.2:
		beat_flash = max(beat_flash, 0.8)
		# Aussi émettre sur les gros deltas
		if bass_delta > 0.15 and time - last_big_beat_time > 0.4:
			last_big_beat_time = time
			print("[Visualizer] Emitting big_beat (delta): ", bass_level)
			emit_signal("big_beat", bass_level)


func _find_node_of_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var found = _find_node_of_type(child, type_name)
		if found:
			return found
	return null


func update_palette() -> void:
	# Interpoler entre palette normale et danger selon le nombre d'anomalies
	# 0 anomalies = bleu/cyan, 6+ anomalies = rouge/orange
	var danger_ratio = clamp(float(Globals.broken_count) / float(Globals.max_broken_computers), 0.0, 1.0)
	
	# Transition douce
	for i in range(palette.size()):
		if i < palette_normal.size() and i < palette_danger.size():
			palette[i] = palette_normal[i].lerp(palette_danger[i], danger_ratio)


func update_audio_simulation_fallback() -> void:
	# Simulation musicale dynamique et réaliste
	# Sauvegarde des anciennes valeurs
	prev_bass_level = bass_level
	
	for i in range(NUM_BARS):
		prev_bars[i] = lerp(prev_bars[i], bars[i], 0.3)
	
	# Patterns rythmiques multiples pour simuler différents éléments musicaux
	var beat_main = sin(time * 7.5) > 0.6  # Beat principal ~120 BPM
	var beat_sub = sin(time * 15) > 0.75   # Hi-hat
	var beat_bass = sin(time * 3.75) > 0.8  # Grosse caisse
	
	for i in range(NUM_BARS):
		# Facteur de fréquence (basses à gauche, aigus à droite)
		var freq_factor = 1.0 - (float(i) / NUM_BARS)
		var high_freq_factor = float(i) / NUM_BARS
		
		# Couche 1: Rythme de base (kick/snare)
		var kick = sin(time * 7.5 + 0.1) * 0.5 * freq_factor * freq_factor
		
		# Couche 2: Ligne de basse
		var bassline = sin(time * 4 + i * 0.3) * 0.35 * freq_factor
		
		# Couche 3: Mélodie mid
		var melody = sin(time * 12 + i * 0.8) * 0.25 * (1.0 - abs(freq_factor - 0.5) * 2)
		
		# Couche 4: Hi-hats et cymbales (hautes fréquences)
		var hihat = sin(time * 20 + i * 0.2) * 0.2 * high_freq_factor
		
		# Couche 5: Ambiance/pad
		var pad = sin(time * 2 + i * 0.5) * 0.15
		
		# Pulses sur les beats
		var pulse = 0.0
		if beat_main:
			pulse += 0.35 * freq_factor
		if beat_sub:
			pulse += 0.15 * high_freq_factor
		if beat_bass and i < 6:
			pulse += 0.4
		
		# Variation aléatoire subtile
		var noise = (randf() - 0.5) * 0.1
		
		# Combiner toutes les couches
		var value = 0.15 + kick + bassline + melody + hihat + pad + pulse + noise
		value = clamp(value, 0.0, 1.0)
		
		# Smooth pour éviter les sauts brusques
		bars[i] = lerp(bars[i], value, 0.5)
		
		# Peak hold
		if bars[i] > peak_bars[i]:
			peak_bars[i] = bars[i]
		else:
			peak_bars[i] = lerp(peak_bars[i], bars[i], 0.08)
	
	# Calculer le niveau des basses
	bass_level = (bars[0] + bars[1] + bars[2] + bars[3]) / 4.0
	
	# Flash sur les gros beats
	var bass_delta = bass_level - prev_bass_level
	if (beat_main or beat_bass) and bass_delta > 0.1 and bass_level > 0.5:
		beat_flash = 1.0


func update_effects(delta: float) -> void:
	# Diminuer le flash
	beat_flash = max(0, beat_flash - delta * 4)
	
	# Accumuler l'énergie pour les effets
	energy_accumulator = lerp(energy_accumulator, bass_level, delta * 2)
	
	# Ajouter des anneaux d'onde sur les gros beats
	if beat_flash > 0.9:
		wave_rings.append({
			"radius": 0.0,
			"life": 1.0,
			"color_offset": randf()
		})
	
	# Mettre à jour les anneaux
	var to_remove = []
	for ring in wave_rings:
		ring.radius += delta * 40
		ring.life -= delta * 1.2
		if ring.life <= 0:
			to_remove.append(ring)
	for ring in to_remove:
		wave_rings.erase(ring)


func update_particles(delta: float) -> void:
	for p in particles:
		# Mouvement influencé par la musique
		p.x += p.vx * delta * (1 + bass_level)
		p.y += p.vy * delta * (1 + bass_level)
		
		# Rebond sur les bords
		if p.x < 0 or p.x > WIDTH:
			p.vx = -p.vx
			p.x = clamp(p.x, 0, WIDTH)
		if p.y < 0 or p.y > HEIGHT:
			p.vy = -p.vy
			p.y = clamp(p.y, 0, HEIGHT)
		
		# Réaction aux beats
		if beat_flash > 0.8:
			p.vx += (randf() - 0.5) * 30
			p.vy += (randf() - 0.5) * 30
		
		# Atténuation
		p.vx = lerp(p.vx, 0.0, delta * 0.5)
		p.vy = lerp(p.vy, 0.0, delta * 0.5)
		
		# Cycle de vie
		p.life += delta * 0.5
		if p.life > 1.0:
			p.life = 0.0


func start_visualizer() -> void:
	is_active = true
	time = 0.0
	score_timer = 0.0
	beat_flash = 0.0
	last_big_beat_time = -1.0  # Reset pour permettre un beat dès le début
	prev_bass_level = 0.0  # Reset pour éviter faux deltas
	wave_rings.clear()
	show()
	queue_redraw()
	print("[Visualizer] Started, is_active=", is_active)


func stop_visualizer() -> void:
	print("[Visualizer] Stopped")
	is_active = false
	hide()
	emit_signal("visualizer_closed")


func _draw() -> void:
	if not is_active:
		return
	
	# === FOND ===
	draw_background()
	
	# === ÉTOILES ===
	draw_stars()
	
	# === PARTICULES FLOTTANTES ===
	draw_floating_particles()
	
	# === ANNEAUX D'ONDE ===
	draw_wave_rings()
	
	# === BARRES DE SPECTRE PIXEL ART ===
	draw_spectrum()
	
	# === EFFET MIROIR / REFLET ===
	draw_reflection()
	
	# === LIGNE D'ONDE (WAVEFORM) ===
	draw_waveform()
	
	# === PARTICULES DE BEAT ===
	draw_beat_particles()
	
	# === EFFET SCANLINES CRT ===
	draw_scanlines()
	
	# === BORDURE PIXEL ART ===
	draw_border()
	
	# === VIGNETTE ===
	draw_vignette()
	
	# === FLASH DE BEAT ===
	if beat_flash > 0:
		var flash_color = Color(1, 1, 1, beat_flash * 0.4)
		draw_rect(Rect2(0, 0, WIDTH, HEIGHT), flash_color)


func draw_background() -> void:
	# Dégradé vertical pixel art
	for y in range(GRID_Y):
		var t = float(y) / GRID_Y
		var color_idx = int(t * 3)
		var color = palette[color_idx].lerp(palette[color_idx + 1], fmod(t * 3, 1.0))
		
		# Ajouter une pulsation basée sur les basses
		color = color.lightened(bass_level * 0.15)
		
		# Légère ondulation horizontale
		var wave_offset = sin(time * 2 + y * 0.2) * energy_accumulator * 2
		draw_rect(Rect2(wave_offset, y * PIXEL, WIDTH + abs(wave_offset), PIXEL), color)


func draw_stars() -> void:
	for star in stars:
		var blink = sin(time * star.speed + star.blink)
		if blink > 0.2:
			var brightness = (blink - 0.2) / 0.8
			var color = Color(1, 1, 1, brightness * 0.9)
			
			# Étoile qui pulse avec la musique
			var size = PIXEL
			if bass_level > 0.5 and randf() > 0.6:
				size = PIXEL * 2
				color = palette[6 + int(time * 3) % 4]
			
			# Mouvement léger avec la musique
			var mx = sin(time + star.blink) * bass_level * 2
			var my = cos(time + star.blink) * bass_level * 2
			
			draw_rect(Rect2(star.x * PIXEL + mx, star.y * PIXEL + my, size, size), color)


func draw_floating_particles() -> void:
	for p in particles:
		var alpha = sin(p.life * PI)  # Fade in/out
		var color = palette[5 + int(p.life * 5) % 6]
		color.a = alpha * 0.6
		
		var px = int(p.x) / PIXEL * PIXEL
		var py = int(p.y) / PIXEL * PIXEL
		
		draw_rect(Rect2(px, py, PIXEL * p.size, PIXEL * p.size), color)


func draw_wave_rings() -> void:
	var center = Vector2(WIDTH / 2, HEIGHT / 2)
	for ring in wave_rings:
		var color_t = ring.get("color_offset", 0.0)
		var color = palette[6 + int(color_t * 5) % 5].lerp(palette[10], ring.radius / 60)
		color.a = ring.life * 0.6
		
		# Dessiner un cercle pixelisé (ellipse pour le rectangle)
		var r = int(ring.radius)
		for angle in range(0, 360, 10):
			var rad = deg_to_rad(angle)
			var px = int(center.x + cos(rad) * r * 1.2) / PIXEL * PIXEL
			var py = int(center.y + sin(rad) * r) / PIXEL * PIXEL
			if px >= 0 and px < WIDTH and py >= 0 and py < HEIGHT:
				draw_rect(Rect2(px, py, PIXEL, PIXEL), color)


func draw_spectrum() -> void:
	var bar_width = (WIDTH - PIXEL * 4) / NUM_BARS
	var start_x = PIXEL * 2
	var base_y = HEIGHT * 0.75  # Plus bas pour que les barres montent plus haut
	
	for i in range(NUM_BARS):
		var height = bars[i] * HEIGHT * 0.65  # Barres plus hautes (65% au lieu de 45%)
		var peak_height = peak_bars[i] * HEIGHT * 0.65
		
		var x = start_x + i * bar_width
		
		# Couleur arc-en-ciel basée sur la position
		var hue = float(i) / NUM_BARS
		var color_idx = int(hue * 8) + 3
		color_idx = min(color_idx, palette.size() - 1)
		var bar_color = palette[color_idx]
		
		# Pulsation de couleur plus forte
		if bars[i] > 0.6:
			bar_color = bar_color.lightened(0.4)
		
		# Dessiner la barre pixel par pixel (de bas en haut)
		var num_pixels = int(height / PIXEL)
		for p in range(num_pixels):
			var py = base_y - (p + 1) * PIXEL
			
			# Dégradé de luminosité du bas vers le haut
			var brightness = float(p) / max(num_pixels, 1)
			var pixel_color = bar_color.lightened(brightness * 0.4)
			
			# Effet de bordure 3D
			draw_rect(Rect2(x, py, bar_width - 1, PIXEL), pixel_color)
			
			# Highlight en haut
			if p == num_pixels - 1:
				draw_rect(Rect2(x, py, bar_width - 1, 1), Color.WHITE.lerp(pixel_color, 0.3))
		
		# "Peak hold" - petit carré qui reste en haut (utilise peak_bars)
		var peak_y = base_y - peak_height - PIXEL
		if peak_height > PIXEL:
			draw_rect(Rect2(x, peak_y, bar_width - 1, PIXEL), Color.WHITE)


func draw_reflection() -> void:
	var bar_width = (WIDTH - PIXEL * 4) / NUM_BARS
	var start_x = PIXEL * 2
	var base_y = HEIGHT * 0.75
	
	for i in range(NUM_BARS):
		var height = bars[i] * HEIGHT * 0.15  # Reflet plus court
		
		var x = start_x + i * bar_width
		
		var hue = float(i) / NUM_BARS
		var color_idx = int(hue * 8) + 3
		color_idx = min(color_idx, palette.size() - 1)
		var bar_color = palette[color_idx]
		bar_color.a = 0.25
		
		# Dessiner le reflet (inversé, avec fade)
		var num_pixels = int(height / PIXEL)
		for p in range(num_pixels):
			var py = base_y + PIXEL + p * PIXEL
			var fade = 1.0 - float(p) / max(num_pixels, 1)
			var pixel_color = bar_color
			pixel_color.a = 0.25 * fade
			
			if py < HEIGHT - PIXEL * 2:
				draw_rect(Rect2(x, py, bar_width - 1, PIXEL), pixel_color)


func draw_waveform() -> void:
	# Dessiner une ligne d'onde au dessus des barres
	var wave_y = HEIGHT * 0.15
	var prev_y = wave_y
	
	for x in range(0, WIDTH, PIXEL):
		var bar_idx = int(float(x) / WIDTH * NUM_BARS)
		bar_idx = min(bar_idx, NUM_BARS - 1)
		var amplitude = bars[bar_idx] * 15
		
		var y = wave_y + sin(time * 4 + x * 0.1) * amplitude
		y = int(y) / PIXEL * PIXEL
		
		var color = palette[7 + int(time * 2 + x * 0.05) % 4]
		color.a = 0.7
		
		draw_rect(Rect2(x, y, PIXEL, PIXEL), color)
		
		# Ligne connectant les points
		if abs(y - prev_y) > PIXEL:
			var steps = int(abs(y - prev_y) / PIXEL)
			var dir = 1 if y > prev_y else -1
			for s in range(steps):
				draw_rect(Rect2(x - PIXEL, prev_y + s * PIXEL * dir, PIXEL, PIXEL), color)
		
		prev_y = y


func draw_beat_particles() -> void:
	if beat_flash > 0.3:
		# Particules explosives sur le beat - plus nombreuses
		var center = Vector2(WIDTH / 2, HEIGHT * 0.4)
		var num_particles = int(beat_flash * 16)
		
		for p in range(num_particles):
			var angle = (float(p) / num_particles) * TAU + time * 2
			var dist = beat_flash * 50 + randf() * 20
			var px = int(center.x + cos(angle) * dist * 1.3) / PIXEL * PIXEL
			var py = int(center.y + sin(angle) * dist) / PIXEL * PIXEL
			
			var color = palette[5 + int(time * 5 + p) % 6]
			color.a = beat_flash
			
			if px >= PIXEL and px < WIDTH - PIXEL and py >= PIXEL and py < HEIGHT - PIXEL:
				draw_rect(Rect2(px, py, PIXEL, PIXEL), color)


func draw_scanlines() -> void:
	# Effet CRT scanlines
	var scan_alpha = 0.08 + bass_level * 0.05
	for y in range(0, HEIGHT, PIXEL * 2):
		var offset_y = int(scan_line_offset) % (PIXEL * 2)
		draw_rect(Rect2(0, y + offset_y, WIDTH, 1), Color(0, 0, 0, scan_alpha))


func draw_vignette() -> void:
	# Assombrir les coins
	var vignette_strength = 0.3
	
	# Coins
	for i in range(5):
		var alpha = vignette_strength * (1 - float(i) / 5)
		var size = PIXEL * (5 - i)
		var color = Color(0, 0, 0, alpha)
		
		# Coins supérieurs
		draw_rect(Rect2(0, 0, size, size), color)
		draw_rect(Rect2(WIDTH - size, 0, size, size), color)
		# Coins inférieurs
		draw_rect(Rect2(0, HEIGHT - size, size, size), color)
		draw_rect(Rect2(WIDTH - size, HEIGHT - size, size, size), color)


func draw_border() -> void:
	# Bordure style arcade avec coins
	var border_color = palette[9].lerp(palette[10], sin(time * 2) * 0.5 + 0.5)
	
	# Pulsation avec la musique
	border_color = border_color.lightened(bass_level * 0.2)
	
	# Haut et bas
	for x in range(0, WIDTH, PIXEL):
		draw_rect(Rect2(x, 0, PIXEL, PIXEL), border_color)
		draw_rect(Rect2(x, HEIGHT - PIXEL, PIXEL, PIXEL), border_color)
	
	# Gauche et droite
	for y in range(PIXEL, HEIGHT - PIXEL, PIXEL):
		draw_rect(Rect2(0, y, PIXEL, PIXEL), border_color)
		draw_rect(Rect2(WIDTH - PIXEL, y, PIXEL, PIXEL), border_color)
	
	# Coins décorés (style arcade)
	var corner_color = palette[11]
	# Coin haut-gauche
	draw_rect(Rect2(0, 0, PIXEL * 2, PIXEL), corner_color)
	draw_rect(Rect2(0, 0, PIXEL, PIXEL * 2), corner_color)
	# Coin haut-droite
	draw_rect(Rect2(WIDTH - PIXEL * 2, 0, PIXEL * 2, PIXEL), corner_color)
	draw_rect(Rect2(WIDTH - PIXEL, 0, PIXEL, PIXEL * 2), corner_color)
	# Coin bas-gauche
	draw_rect(Rect2(0, HEIGHT - PIXEL, PIXEL * 2, PIXEL), corner_color)
	draw_rect(Rect2(0, HEIGHT - PIXEL * 2, PIXEL, PIXEL * 2), corner_color)
	# Coin bas-droite
	draw_rect(Rect2(WIDTH - PIXEL * 2, HEIGHT - PIXEL, PIXEL * 2, PIXEL), corner_color)
	draw_rect(Rect2(WIDTH - PIXEL, HEIGHT - PIXEL * 2, PIXEL, PIXEL * 2), corner_color)
	
	# Petite animation dans les coins - plus dynamique
	var anim_offset = int(time * 10) % 6
	var anim_color = palette[6 + int(time * 4) % 5]
	anim_color = anim_color.lightened(beat_flash * 0.5)
	
	if anim_offset < 3:
		draw_rect(Rect2(PIXEL * 2, PIXEL, PIXEL, PIXEL), anim_color)
		draw_rect(Rect2(WIDTH - PIXEL * 3, PIXEL, PIXEL, PIXEL), anim_color)
		draw_rect(Rect2(PIXEL * 2, HEIGHT - PIXEL * 2, PIXEL, PIXEL), anim_color)
		draw_rect(Rect2(WIDTH - PIXEL * 3, HEIGHT - PIXEL * 2, PIXEL, PIXEL), anim_color)

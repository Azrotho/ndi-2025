extends Node2D

# Nœud de dessin pour les effets globaux

var effects_parent = null
var draw_mode: String = "front"  # "back" = derrière visualisateur, "front" = devant

func _draw() -> void:
	if effects_parent == null:
		return
	
	var screen_size = get_viewport_rect().size
	
	if draw_mode == "back":
		# PARTICULES (derrière le visualisateur)
		draw_particles()
		draw_mega_particles()
	else:
		# EFFETS DEVANT (flash, ondes, bordures)
		draw_flash(screen_size)
		draw_strobe(screen_size)
		draw_wave_rings()
		draw_border_pulse(screen_size)
		draw_scanlines(screen_size)


func draw_flash(screen_size: Vector2) -> void:
	if effects_parent.flash_intensity > 0.01:
		var flash_color = effects_parent.flash_color
		flash_color.a = effects_parent.flash_intensity * 0.5
		draw_rect(Rect2(-100, -100, screen_size.x + 200, screen_size.y + 200), flash_color)


func draw_strobe(screen_size: Vector2) -> void:
	if effects_parent.strobe_timer > 0:
		var strobe_alpha = 0.3 if int(effects_parent.strobe_timer * 20) % 2 == 0 else 0.0
		if strobe_alpha > 0:
			draw_rect(Rect2(-100, -100, screen_size.x + 200, screen_size.y + 200), Color(1, 1, 1, strobe_alpha))


func draw_mega_particles() -> void:
	for p in effects_parent.mega_particles:
		var color = p.color
		color.a = p.life
		
		# Dessiner une ligne épaisse avec trainée
		var dir = p.vel.normalized()
		var start = p.pos
		var end_pos = p.pos - dir * p.length
		
		# Ligne principale
		draw_line(start, end_pos, color, p.width)
		
		# Halo autour
		var halo_color = color
		halo_color.a = p.life * 0.3
		draw_line(start, end_pos, halo_color, p.width * 3)


func draw_wave_rings() -> void:
	for ring in effects_parent.wave_rings:
		var color = ring.color
		color.a = ring.life * 0.8
		var thickness = ring.get("thickness", 5)
		
		# Dessiner un cercle simple (plus performant)
		var segments = 48
		var r = ring.radius
		if r > 0:
			for i in range(segments):
				var angle1 = float(i) / segments * TAU
				var angle2 = float(i + 1) / segments * TAU
				var center = ring.center
				var p1 = center + Vector2(cos(angle1), sin(angle1)) * r
				var p2 = center + Vector2(cos(angle2), sin(angle2)) * r
				draw_line(p1, p2, color, thickness)


func draw_particles() -> void:
	for p in effects_parent.particles:
		var color = p.color
		color.a = p.life
		var size = p.size
		
		# Carré principal
		draw_rect(Rect2(p.pos - Vector2(size/2, size/2), Vector2(size, size)), color)
		
		# Halo
		var halo_color = color
		halo_color.a = p.life * 0.3
		draw_rect(Rect2(p.pos - Vector2(size, size), Vector2(size * 2, size * 2)), halo_color)


func draw_border_pulse(screen_size: Vector2) -> void:
	if effects_parent.flash_intensity > 0.1:
		var border_color = effects_parent.flash_color
		border_color.a = effects_parent.flash_intensity * 0.6
		var border_size = effects_parent.flash_intensity * 30
		
		# Bordures
		draw_rect(Rect2(0, 0, screen_size.x, border_size), border_color)  # Haut
		draw_rect(Rect2(0, screen_size.y - border_size, screen_size.x, border_size), border_color)  # Bas
		draw_rect(Rect2(0, 0, border_size, screen_size.y), border_color)  # Gauche
		draw_rect(Rect2(screen_size.x - border_size, 0, border_size, screen_size.y), border_color)  # Droite


func draw_scanlines(screen_size: Vector2) -> void:
	if effects_parent.flash_intensity > 0.2:
		var scan_alpha = effects_parent.flash_intensity * 0.15
		for y in range(0, int(screen_size.y), 3):
			var offset = int(effects_parent.scanline_offset) % 6
			if (y + offset) % 6 < 2:
				draw_line(
					Vector2(0, y),
					Vector2(screen_size.x, y),
					Color(0, 0, 0, scan_alpha),
					2.0
				)

extends AudioStreamPlayer

# Script pour gérer le loop de la musique manuellement
# Nécessaire car le loop natif ne fonctionne pas toujours en export web

func _ready() -> void:
	# Connecter le signal finished pour relancer la musique
	finished.connect(_on_finished)


func _on_finished() -> void:
	# Relancer la musique depuis le début
	play(0.0)

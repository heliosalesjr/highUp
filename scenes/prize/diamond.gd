# diamond.gd
extends Area2D

func _ready():
	# Configuração de collision
	collision_layer = 24  # ← MUDA AQUI
	collision_mask = 1    # Detecta player
	
	# Conecta sinal de colisão
	body_entered.connect(_on_body_entered)
	
	# Opcional: adiciona uma animação de brilho/rotação
	create_idle_animation()

func _on_body_entered(body):
	if body.name == "Player":
		collect()

func collect():
	"""Chamado quando o player coleta o diamante"""
	print("💎 Diamante coletado!")
	GameManager.add_diamond()
	queue_free()

func create_idle_animation():
	"""Animação simples de flutuação (opcional)"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 5, 0.5)
	tween.tween_property(self, "position:y", position.y + 5, 0.5)

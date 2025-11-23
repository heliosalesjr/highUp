# diamond.gd (e faça o mesmo no heart.gd)
extends Area2D

var is_being_attracted = false
var idle_tween = null  # ← NOVO: Guarda referência do tween

func _ready():
	add_to_group("collectible")
	collision_layer = 24
	collision_mask = 1
	
	body_entered.connect(_on_body_entered)
	create_idle_animation()

func _on_body_entered(body):
	if body.name == "Player":
		collect()

func collect():
	print("💎 Diamante coletado!")
	GameManager.add_diamond()
	queue_free()

func create_idle_animation():
	"""Animação simples de flutuação"""
	idle_tween = create_tween()
	idle_tween.set_loops(0)
	var start_y = position.y
	idle_tween.tween_property(self, "position:y", start_y - 5, 0.5)
	idle_tween.tween_property(self, "position:y", start_y + 5, 0.5)

func _process(delta):
	# Quando está sendo atraído, para a animação de flutuação
	if is_being_attracted:
		if idle_tween:
			idle_tween.kill()  # ← PARA o tween
			idle_tween = null
		
		# Efeito visual de rotação
		rotation += delta * 10.0
		modulate = lerp(modulate, Color(1.5, 1.5, 1.5), delta * 5.0)
	else:
		# Restaura animação se parou
		if not idle_tween or not idle_tween.is_running():
			create_idle_animation()
		modulate = lerp(modulate, Color(1, 1, 1), delta * 5.0)

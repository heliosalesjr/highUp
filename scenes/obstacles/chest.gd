# chest.gd
extends Area2D

@export_enum("mist", "magnet", "invincible", "metal") var powerup_type: String = "mist"

# Sprites dos powerups para mostrar no chest
var powerup_icons = {
	"mist": preload("res://assets/png/skull.png"),
	"magnet": preload("res://assets/powerups/magnet_icon.png"),
	"invincible": preload("res://assets/potion.png"),
	"metal": preload("res://assets/potion.png")
}

var is_opened = false
var sprite_node: Sprite2D = null

func _ready():
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)

	# Pega referência ao sprite
	sprite_node = get_node("Sprite2D")

	print("📦 Chest criado com powerup: ", powerup_type)

func _on_body_entered(body):
	if is_opened:
		return

	if body.name == "Player":
		print("📦 Chest sendo aberto pelo player!")
		open_chest()

func open_chest():
	"""Abre o chest com efeito visual instantâneo"""
	is_opened = true

	# Desabilita colisão
	collision_layer = 0
	collision_mask = 0

	# Tudo acontece DURANTE a pausa
	apply_pause_and_shake()

	# Chest some INSTANTANEAMENTE
	if sprite_node:
		sprite_node.visible = false

	# Ícone aparece instantaneamente
	show_powerup_icon()

func apply_pause_and_shake():
	"""Pausa super breve + camera shake discreto"""
	# Pausa curtíssima
	Engine.time_scale = 0.15
	get_tree().create_timer(0.08, true, false, true).timeout.connect(func():
		Engine.time_scale = 1.0
	)

	# Camera shake discreto
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("apply_shake"):
		camera.apply_shake(2.5, 0.1)  # Bem sutil

func show_powerup_icon():
	"""Mostra o ícone do powerup de forma instantânea"""
	if not powerup_icons.has(powerup_type):
		print("❌ Powerup icon inválido: ", powerup_type)
		activate_powerup()
		queue_free()
		return

	# Pega a posição exata do chest no mundo
	var chest_world_pos = global_position

	# Cria sprite do ícone exatamente onde o chest está
	var icon = Sprite2D.new()
	icon.texture = powerup_icons[powerup_type]
	icon.global_position = chest_world_pos  # EXATAMENTE onde o chest estava
	icon.modulate.a = 0.0  # Começa invisível
	icon.scale = Vector2(1.5, 1.5)

	get_parent().add_child(icon)

	# Animação SUPER rápida: aparece e sobe um pouco
	var tween = create_tween()
	tween.set_parallel(true)

	# Fade in instantâneo
	tween.tween_property(icon, "modulate:a", 1.0, 0.05)

	# Sobe só um pouco, como se "pulasse" do chest
	tween.tween_property(icon, "global_position:y", chest_world_pos.y - 25, 0.2).set_ease(Tween.EASE_OUT)

	# Scale pulse curtíssimo
	tween.set_parallel(false)
	tween.tween_property(icon, "scale", Vector2(1.8, 1.8), 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", Vector2(1.5, 1.5), 0.06).set_ease(Tween.EASE_IN)

	# Aguarda um tempo muito curto
	await get_tree().create_timer(0.35).timeout

	# Fade out rápido
	var fade_tween = create_tween()
	fade_tween.tween_property(icon, "modulate:a", 0.0, 0.15)
	await fade_tween.finished

	# Ativa o powerup
	activate_powerup()

	# Remove o ícone e o chest
	icon.queue_free()
	queue_free()

func activate_powerup():
	"""Ativa o powerup correspondente"""
	print("✨ Powerup ativado: ", powerup_type)

	match powerup_type:
		"mist":
			GameManager.activate_mist_mode()
		"magnet":
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("activate_magnet"):
				player.activate_magnet()
		"invincible":
			GameManager.activate_invincible_mode()
		"metal":
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("activate_metal_mode"):
				player.activate_metal_mode()

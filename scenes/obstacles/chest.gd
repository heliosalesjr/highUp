# chest.gd
extends Area2D

@export_enum("mist", "magnet", "invincible", "metal") var powerup_type: String = "mist"

# Cenas dos powerups para mostrar no chest (já vêm com escala correta)
var powerup_scenes = {
	"mist": preload("res://scenes/powerups/mist.tscn"),
	"magnet": preload("res://scenes/powerups/magnet.tscn"),
	"invincible": preload("res://scenes/powerups/invincible.tscn"),
	"metal": preload("res://scenes/powerups/metal_potion.tscn")
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

	# Desabilita colisão (usa deferred pois estamos em callback de colisão)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

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
	if not powerup_scenes.has(powerup_type):
		print("❌ Powerup scene inválido: ", powerup_type)
		activate_powerup()
		queue_free()
		return

	# Pega a posição exata do chest no mundo
	var chest_world_pos = global_position

	# Instancia a cena do powerup (já vem com sprite e escala corretos)
	var icon = powerup_scenes[powerup_type].instantiate()
	icon.global_position = chest_world_pos  # EXATAMENTE onde o chest estava
	icon.modulate.a = 0.0  # Começa invisível

	# Remove o script para que não execute lógica de colisão/animação
	icon.set_script(null)

	# Desabilita colisão e monitoring ANTES de adicionar (só visual)
	if icon is Area2D:
		icon.monitoring = false
		icon.monitorable = false
		icon.collision_layer = 0
		icon.collision_mask = 0

	# Pega a escala original do powerup
	var original_scale = icon.scale

	# Adiciona à árvore usando call_deferred para evitar conflitos durante callback de colisão
	get_parent().call_deferred("add_child", icon)

	# Aguarda 1 frame para garantir que o icon foi adicionado à árvore
	await get_tree().process_frame

	# Animação SUPER rápida: aparece e sobe um pouco
	var tween = create_tween()
	tween.set_parallel(true)

	# Fade in instantâneo
	tween.tween_property(icon, "modulate:a", 1.0, 0.05)

	# Sobe só um pouco, como se "pulasse" do chest
	tween.tween_property(icon, "global_position:y", chest_world_pos.y - 25, 0.2).set_ease(Tween.EASE_OUT)

	# Scale pulse curtíssimo (baseado na escala original)
	tween.set_parallel(false)
	tween.tween_property(icon, "scale", original_scale * 1.2, 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", original_scale, 0.06).set_ease(Tween.EASE_IN)

	# Aguarda um tempo muito curto
	await get_tree().create_timer(0.35).timeout

	# Fade out rápido
	var fade_tween = create_tween()
	fade_tween.tween_property(icon, "modulate:a", 0.0, 0.15)
	await fade_tween.finished

	# Ativa o powerup
	activate_powerup()

	# Remove o ícone e o chest
	if is_instance_valid(icon):
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

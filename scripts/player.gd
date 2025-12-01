# player.gd
extends CharacterBody2D

var is_invulnerable = false
const INVULNERABILITY_TIME = 1.5
var damaged_enemies = []
var is_launched = false
var launch_invulnerability = false
var magnet_active = false
var magnet_icon = null
const MAGNET_RANGE = 300.0
var attracted_collectibles = []

# Constantes de movimento
const SPEED = 400.0
const JUMP_VELOCITY = -600.0
const ACCELERATION = 2000.0
const FRICTION = 800.0
const AIR_RESISTANCE = 100.0
const JUMP_RELEASE_FORCE = -200.0

# Escada
const CLIMB_SPEED = 250.0
var is_on_ladder = false
var current_ladder: Area2D = null

# Coiote time e buffer de pulo
const COYOTE_TIME = 0.1
var coyote_timer = 0.0
const JUMP_BUFFER_TIME = 0.1
var jump_buffer_timer = 0.0

# Gravidade
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Direção automática
var direction = 1

# Referências visuais
var shader_sprite = null

func _ready():
	add_to_group("player")
	
	collision_layer = 1
	collision_mask = 25
	
	# Cria visual com shader
	create_player_visual()
	
	var detection_area = get_node_or_null("DetectionArea")
	if detection_area:
		detection_area.collision_layer = 1
		detection_area.collision_mask = 2
		detection_area.area_entered.connect(_on_area_entered)
		detection_area.area_exited.connect(_on_area_exited)
		print("DetectionArea configurada!")
	else:
		print("ERRO: DetectionArea não encontrada!")

func create_player_visual():
	"""Cria visual geométrico do player com shader"""
	var old_sprite = get_node_or_null("ShaderSprite")
	if old_sprite:
		old_sprite.queue_free()
	
	var old_animated = get_node_or_null("AnimatedSprite2D")
	if old_animated:
		old_animated.visible = false
	
	var sprite = Sprite2D.new()
	sprite.name = "ShaderSprite"
	
	# Cria textura QUADRADA proceduralmente
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center = Vector2(32, 32)
	var size = 28.0  # Tamanho do quadrado
	
	for x in range(64):
		for y in range(64):
			var offset = Vector2(x, y) - center
			
			# Quadrado com bordas suaves
			var dist_x = abs(offset.x)
			var dist_y = abs(offset.y)
			var dist = max(dist_x, dist_y)
			
			if dist < size:
				# Gradiente suave nas bordas
				var alpha = 1.0 - smoothstep(size - 4.0, size, dist)
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.position = Vector2(0, 0)
	add_child(sprite)
	
	shader_sprite = sprite
	
	apply_glow_shader(sprite)
	create_dust_particles()  # ← NOVO: partículas de poeira

func smoothstep(edge0: float, edge1: float, x: float) -> float:
	"""Função smoothstep (interpolação suave)"""
	var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func apply_glow_shader(sprite: Sprite2D):
	"""Aplica shader de brilho ao sprite"""
	var shader_material = ShaderMaterial.new()
	var shader = load("res://shaders/player_glow.gdshader")
	shader_material.shader = shader
	
	# Cor do centro (escuro)
	shader_material.set_shader_parameter("core_color", Vector3(0.05, 0.1, 0.2))
	
	# Cor das bordas (brilhante ciano)
	shader_material.set_shader_parameter("border_color", Vector3(0.2, 0.8, 1.0))
	
	# Espessura da borda brilhante
	shader_material.set_shader_parameter("border_thickness", 0.2)
	
	# Intensidade do glow
	shader_material.set_shader_parameter("glow_intensity", 5.0)
	
	# Velocidades de animação
	shader_material.set_shader_parameter("pulse_speed", 2.5)
	shader_material.set_shader_parameter("wave_speed", 2.0)
	
	sprite.material = shader_material



func create_fade_curve() -> Curve:
	"""Cria curva de fade out para partículas"""
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

func set_player_color(color: Color):
	"""Muda a cor do brilho do player"""
	if shader_sprite and shader_sprite.material:
		shader_sprite.material.set_shader_parameter("glow_color", Vector3(color.r, color.g, color.b))

func _physics_process(delta):
	attract_collectibles(delta)
	
	if is_launched and velocity.y >= 0 and is_on_floor():
		end_launch()
	
	if is_launched:
		velocity.y += gravity * delta
		velocity.x = direction * SPEED * 0.5
		move_and_slide()
		update_visual()
		return
	
	if is_on_ladder:
		climb_ladder(delta)
	else:
		apply_gravity(delta)
		handle_jump(delta)
		auto_walk(delta)
	
	move_and_slide()
	update_timers(delta)
	check_wall_collision()
	update_visual()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_jump(_delta):
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	
	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0):
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0
	
	if Input.is_action_just_released("ui_accept") and velocity.y < JUMP_RELEASE_FORCE:
		velocity.y = JUMP_RELEASE_FORCE

func auto_walk(delta):
	if is_on_floor():
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, direction * SPEED, AIR_RESISTANCE * delta)

func check_wall_collision():
	if is_on_wall():
		direction *= -1

func update_timers(delta):
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

func update_visual():
	"""Atualiza visual baseado no estado"""
	if not shader_sprite:
		return
	
	# Flip horizontal
	shader_sprite.flip_h = direction < 0
	
	# Muda cor baseado no estado
	if is_launched:
		set_player_color(Color(1.0, 0.5, 0.0))  # Laranja no canhão
	elif is_invulnerable and not magnet_active:
		# Piscar durante invulnerabilidade
		pass  # Já está implementado com modulate
	else:
		set_player_color(Color(0.3, 0.8, 1.0))  # Azul normal

func climb_ladder(_delta):
	velocity.y = -CLIMB_SPEED
	velocity.x = 0
	
	if current_ladder and global_position.y < current_ladder.global_position.y - 10:
		is_on_ladder = false
		
		var ladder_parent = current_ladder.get_parent()
		if ladder_parent and "ladder_side" in ladder_parent:
			var side = ladder_parent.ladder_side
			if side == 0:
				direction = 1
			else:
				direction = -1
		else:
			var ladder_x = current_ladder.global_position.x
			direction = 1 if global_position.x < ladder_x else -1
		
		current_ladder = null

func _on_area_entered(area: Area2D):
	if is_launched:
		return
	
	if area.name == "Ladder":
		is_on_ladder = true
		current_ladder = area
		print("Entrando na escada!")

func _on_area_exited(area: Area2D):
	if is_launched:
		return
	
	if area.name == "Ladder":
		if not is_on_ladder:
			current_ladder = null
			print("Saindo da escada!")

func reverse_direction():
	direction *= -1
	print("🔄 Direção invertida!")

func take_damage(enemy):
	"""Chamado quando o player leva dano"""
	if is_invulnerable or launch_invulnerability or is_launched:
		return
	
	if enemy in damaged_enemies:
		return
	
	var survived = GameManager.take_damage()
	
	if survived:
		deactivate_magnet()
		damaged_enemies.append(enemy)
		start_invulnerability()
	else:
		die()

func start_invulnerability():
	"""Ativa invulnerabilidade temporária"""
	is_invulnerable = true
	print("🛡️ Invulnerável por ", INVULNERABILITY_TIME, " segundos")
	
	if shader_sprite:
		var tween = create_tween()
		tween.set_loops(int(INVULNERABILITY_TIME * 5))
		tween.tween_property(shader_sprite, "modulate:a", 0.3, 0.1)
		tween.tween_property(shader_sprite, "modulate:a", 1.0, 0.1)
	
	await get_tree().create_timer(INVULNERABILITY_TIME).timeout
	is_invulnerable = false
	damaged_enemies.clear()
	if shader_sprite:
		shader_sprite.modulate.a = 1.0
	print("🛡️ Invulnerabilidade encerrada")

func die():
	"""Chamado quando o player morre"""
	print("💀 GAME OVER")
	set_physics_process(false)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	await get_tree().create_timer(1.0).timeout
	show_game_over()

func show_game_over():
	"""Carrega a tela de Game Over"""
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")

func launch_from_cannon(launch_velocity: float):
	"""Chamado quando o player é lançado pelo canhão"""
	if is_launched:
		return
	
	print("🚀 LANÇAMENTO!")
	
	velocity.y = launch_velocity
	is_launched = true
	launch_invulnerability = true
	
	is_on_ladder = false
	current_ladder = null
	
	collision_mask = 17
	
	start_camera_shake()
	is_invulnerable = true
	
	if shader_sprite:
		var tween = create_tween()
		tween.set_loops(8)
		tween.tween_property(shader_sprite, "modulate", Color(1.5, 1.5, 1.5), 0.1)
		tween.tween_property(shader_sprite, "modulate", Color(1, 1, 1), 0.1)
		tween.finished.connect(func(): 
			if shader_sprite:
				shader_sprite.modulate = Color(1, 1, 1)
		)

func end_launch():
	"""Termina o estado de lançamento"""
	print("🛬 Aterrissagem!")
	is_launched = false
	
	collision_mask = 25
	
	await get_tree().create_timer(0.5).timeout
	launch_invulnerability = false
	is_invulnerable = false
	if shader_sprite:
		shader_sprite.modulate = Color(1, 1, 1)

func start_camera_shake():
	"""Inicia o efeito de tremor na câmera"""
	var camera = get_tree().get_first_node_in_group("camera")
	
	if camera and camera.has_method("shake"):
		camera.shake(1.5, 30.0)
		print("✅ Camera shake ativado!")
	else:
		print("❌ Câmera não encontrada no grupo 'camera'")

func activate_magnet():
	"""Ativa o poder do ímã"""
	if magnet_active:
		return

	magnet_active = true
	attracted_collectibles.clear()
	print("🧲 Ímã ATIVADO!")
	create_magnet_icon()

func deactivate_magnet():
	"""Desativa o poder do ímã"""
	if not magnet_active:
		return
	
	magnet_active = false
	attracted_collectibles.clear()
	print("🧲 Ímã DESATIVADO!")
	
	if magnet_icon:
		magnet_icon.queue_free()
		magnet_icon = null

func create_magnet_icon():
	if magnet_icon:
		magnet_icon.queue_free()
	
	magnet_icon = Sprite2D.new()
	magnet_icon.texture = load("res://assets/powerups/magnet_icon.png")
	magnet_icon.position = Vector2(0, -40)
	add_child(magnet_icon)

	start_magnet_spin()

func start_magnet_spin():
	if !magnet_icon or !is_instance_valid(magnet_icon):
		return

	var tween = create_tween().bind_node(magnet_icon)
	tween.set_loops(1)
	tween.tween_property(magnet_icon, "rotation", TAU, 2.0)

	tween.tween_callback(func():
		if magnet_icon and is_instance_valid(magnet_icon):
			start_magnet_spin()
	)

func attract_collectibles(delta):
	"""Atrai diamantes e corações próximos"""
	if not magnet_active:
		return
	
	var collectibles = get_tree().get_nodes_in_group("collectible")
	
	for collectible in collectibles:
		if not is_instance_valid(collectible):
			continue
		
		var distance = global_position.distance_to(collectible.global_position)
		
		if distance < MAGNET_RANGE and collectible not in attracted_collectibles:
			attracted_collectibles.append(collectible)
			print("🧲 GRUDOU: ", collectible.name)
		
		if collectible in attracted_collectibles:
			if "is_being_attracted" in collectible:
				collectible.is_being_attracted = true
			
			var speed = 1000.0
			if distance < 100:
				speed = 2000.0
			
			collectible.global_position = collectible.global_position.move_toward(
				global_position,
				speed * delta
			)

func create_dust_particles():
	"""Cria partículas de poeira pixelada no chão"""
	var particles = CPUParticles2D.new()
	particles.name = "DustParticles"
	particles.emitting = true
	
	# Configurações básicas
	particles.amount = 8  # Poucos pixels
	particles.lifetime = 0.8
	particles.lifetime_randomness = 0.4
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	particles.position = Vector2(0, 15)  # Perto do "chão" do player
	
	# Explosão pequena para trás
	particles.direction = Vector2(-1, -0.3)  # Ligeiramente pra cima
	particles.spread = 40.0
	particles.gravity = Vector2(0, 100)  # Cai depois
	
	# Velocidade
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 80.0
	
	# Visual pixelado (pequeno)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	
	# Fade out
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.5, 0.8))
	curve.add_point(Vector2(1.0, 0.0))
	particles.scale_amount_curve = curve
	
	# Cor da poeira (azul claro brilhante)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.4, 0.9, 1.0, 0.8))
	gradient.add_point(0.5, Color(0.2, 0.6, 0.8, 0.4))
	gradient.add_point(1.0, Color(0.1, 0.3, 0.5, 0.0))
	particles.color_ramp = gradient
	
	# IMPORTANTE: emite apenas quando no chão
	particles.emitting = false  # Começa desligado
	particles.one_shot = false
	
	add_child(particles)
	
	# Controla emissão
	control_dust_emission(particles)

func control_dust_emission(particles: CPUParticles2D):
	"""Controla quando emitir poeira"""
	# Timer aleatório para emissão intermitente
	var timer = Timer.new()
	timer.wait_time = randf_range(0.1, 0.3)
	timer.one_shot = false
	timer.timeout.connect(func():
		# Só emite se estiver no chão E se movendo
		if is_on_floor() and abs(velocity.x) > 100:
			particles.emitting = true
			# Desliga depois de um burst
			await get_tree().create_timer(0.05).timeout
			if particles:
				particles.emitting = false
		
		# Randomiza próximo intervalo
		timer.wait_time = randf_range(0.15, 0.4)
	)
	
	add_child(timer)
	timer.start()

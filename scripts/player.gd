extends CharacterBody2D

var is_invulnerable = false
const INVULNERABILITY_TIME = 1.5
var damaged_enemies = []
var is_launched = false
var launch_invulnerability = false
var magnet_active = false
var magnet_icon = null
const MAGNET_RANGE = 150.0 
var attracted_collectibles = []
var metal_shader_material = null

# Constantes de movimento
const SPEED = 400.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 1000.0
const FRICTION = 200.0
const AIR_RESISTANCE = 50.0
const JUMP_RELEASE_FORCE = -250.0

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

# Direção automática (1 = direita, -1 = esquerda)
var direction = 1

# Referência ao AnimatedSprite2D
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	add_to_group("player")
	collision_layer = 1
	collision_mask = 27  # 1 + 2 + 8 + 16 (paredes, rocks, inimigos) 
	
	GameManager.metal_mode_changed.connect(_on_metal_mode_changed)
	
	prepare_metal_shader()
	
	var detection_area = get_node_or_null("DetectionArea")
	if detection_area:
		detection_area.collision_layer = 1
		detection_area.collision_mask = 2
		detection_area.area_entered.connect(_on_area_entered)
		detection_area.area_exited.connect(_on_area_exited)
		print("DetectionArea configurada!")
	else:
		print("ERRO: DetectionArea não encontrada!")

func _physics_process(delta):
	attract_collectibles(delta)
	# Verifica se terminou o lançamento
	if is_launched and velocity.y >= 0 and is_on_floor():
		end_launch()
	
	# Durante o lançamento, só aplica movimento básico
	if is_launched:
		# Aplica gravidade para o arco de voo
		velocity.y += gravity * delta
		# Mantém movimento horizontal mínimo
		velocity.x = direction * SPEED * 0.5
		move_and_slide()
		update_animation()
		return  # ← IMPORTANTE: Sai da função, ignora todo o resto
	
	# Física normal (só quando NÃO está lançado)
	if is_on_ladder:
		climb_ladder(delta)
	else:
		apply_gravity(delta)
		handle_jump(delta)
		auto_walk(delta)
	
	move_and_slide()
	update_timers(delta)
	check_wall_collision()
	update_animation()

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

func update_animation():
	"""Atualiza a animação baseada no estado do player"""
	animated_sprite.flip_h = direction < 0
	
	if is_launched:
		# Animação especial durante lançamento
		if velocity.y < 0:
			animated_sprite.play("climb")  # Subindo
		else:
			animated_sprite.play("fall")   # Descendo
	elif is_on_ladder:
		animated_sprite.play("climb")
	elif not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("climb")
		else:
			animated_sprite.play("fall")
	else:
		animated_sprite.play("run")

func climb_ladder(_delta):
	velocity.y = -CLIMB_SPEED
	velocity.x = 0
	
	if current_ladder and global_position.y < current_ladder.global_position.y - 5:
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
	# Ignora escadas durante o lançamento
	if is_launched:
		return
	
	if area.name == "Ladder":
		is_on_ladder = true
		current_ladder = area
		print("Entrando na escada!")

func _on_area_exited(area: Area2D):
	# Ignora escadas durante o lançamento
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
		# Desativa o ímã ao tomar dano  ← NOVO
		deactivate_magnet()
		
		damaged_enemies.append(enemy)
		start_invulnerability()
	else:
		die()

func start_invulnerability():
	"""Ativa invulnerabilidade temporária"""
	is_invulnerable = true
	print("🛡️ Invulnerável por ", INVULNERABILITY_TIME, " segundos")
	
	var tween = create_tween()
	tween.set_loops(int(INVULNERABILITY_TIME * 5))
	tween.tween_property(animated_sprite, "modulate:a", 0.3, 0.1)
	tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.1)
	
	await get_tree().create_timer(INVULNERABILITY_TIME).timeout
	is_invulnerable = false
	damaged_enemies.clear()
	animated_sprite.modulate.a = 1.0
	print("🛡️ Invulnerabilidade encerrada")

func die():
	"""Chamado quando o player morre"""
	print("💀 GAME OVER")
	set_physics_process(false)

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)

	# Guarda referência à tree antes do await
	var tree = get_tree()
	if tree:
		await tree.create_timer(1.0).timeout
		show_game_over()

func show_game_over():
	"""Carrega a tela de Game Over"""
	# Verifica se ainda está na árvore antes de tentar mudar de cena
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")
	else:
		# Se não está na árvore, acessa direto pelo SceneTree
		var tree = Engine.get_main_loop() as SceneTree
		if tree:
			tree.change_scene_to_file("res://scenes/ui/game_over.tscn")

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

	collision_mask = 17  # Durante lançamento: 1 + 16 (paredes sim, rocks não)
	
	start_camera_shake()
	is_invulnerable = true
	
	# Efeito visual de brilho - CORRIGIDO  ← MUDOU AQUI
	var tween = create_tween()
	tween.set_loops(8)  # ← Número fixo de loops em vez de infinito
	tween.tween_property(animated_sprite, "modulate", Color(1.5, 1.5, 1.5), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.1)
	
	# Para garantir que volta ao normal
	tween.finished.connect(func(): animated_sprite.modulate = Color(1, 1, 1))
func end_launch():
	"""Termina o estado de lançamento"""
	print("🛬 Aterrissagem!")
	is_launched = false

	# REABILITA COLISÃO COM INIMIGOS E ROCKS
	collision_mask = 27  # Volta ao normal: 1 + 2 + 8 + 16
	
	# Pequeno delay antes de remover invulnerabilidade
	await get_tree().create_timer(0.5).timeout
	launch_invulnerability = false
	is_invulnerable = false
	animated_sprite.modulate = Color(1, 1, 1)
	
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
	attracted_collectibles.clear()  # ← NOVO
	print("🧲 Ímã DESATIVADO!")
	
	if magnet_icon:
		magnet_icon.queue_free()
		magnet_icon = null


func create_magnet_icon():
	if magnet_icon:
		magnet_icon.queue_free()
	
	magnet_icon = Sprite2D.new()
	magnet_icon.texture = load("res://assets/powerups/magnet_icon.png")
	magnet_icon.position = Vector2(0, -20)
	add_child(magnet_icon)

	# Inicia spin seguro (usa start_magnet_spin que já está seguro)
	start_magnet_spin()

func start_magnet_spin():
	if !magnet_icon or !is_instance_valid(magnet_icon):
		return

	var tween = create_tween().bind_node(magnet_icon)
	tween.set_loops(1)
	tween.tween_property(magnet_icon, "rotation", TAU, 2.0)

	# Quando terminar, reinicia – mas apenas se ainda existe
	tween.tween_callback(func():
		if magnet_icon and is_instance_valid(magnet_icon):
			start_magnet_spin()
	)

func attract_collectibles(delta):
	"""Atrai diamantes e corações - VERSÃO DEBUG"""
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
			
			# DEBUG - vamos ver as posições
			print("Player pos: ", global_position)
			print("Collectible pos ANTES: ", collectible.global_position)
			
			# Movimento direto
			var target = global_position
			var current = collectible.global_position
			
			# Move diretamente para o player
			collectible.global_position = current.move_toward(target, 400.0 * delta)
			
			print("Collectible pos DEPOIS: ", collectible.global_position)
			print("---")
func prepare_metal_shader():
	"""Prepara o material do shader metálico"""
	metal_shader_material = ShaderMaterial.new()
	var shader = load("res://shaders/metal_effect.gdshader")
	metal_shader_material.shader = shader
	metal_shader_material.set_shader_parameter("metal_intensity", 0.0)  # Começa desativado

func _on_metal_mode_changed(is_active: bool):
	"""Chamado quando o modo metal muda"""
	if is_active:
		activate_visual_metal_mode()
	else:
		deactivate_visual_metal_mode()

func activate_visual_metal_mode():
	"""Ativa efeito visual metálico"""
	if animated_sprite and metal_shader_material:
		animated_sprite.material = metal_shader_material
		
		# Anima a transição
		var tween = create_tween()
		tween.tween_method(
			func(value): metal_shader_material.set_shader_parameter("metal_intensity", value),
			0.0,
			1.0,
			0.5
		)
		
		print("🛡️ Visual metálico ATIVADO")

func deactivate_visual_metal_mode():
	"""Desativa efeito visual metálico"""
	if animated_sprite and metal_shader_material:
		# Anima a transição de saída
		var tween = create_tween()
		tween.tween_method(
			func(value): metal_shader_material.set_shader_parameter("metal_intensity", value),
			1.0,
			0.0,
			0.5
		)
		
		# Remove o shader depois
		tween.finished.connect(func():
			if animated_sprite:
				animated_sprite.material = null
		)
		
		print("🛡️ Visual metálico DESATIVADO")

func activate_metal_mode():
	"""Ativa modo metal (chamado ao coletar poção)"""
	GameManager.activate_metal_mode()

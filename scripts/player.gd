extends CharacterBody2D
var is_invulnerable = false
const INVULNERABILITY_TIME = 1.5
var damaged_enemies = []

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

# Direção automática (1 = direita, -1 = esquerda)
var direction = 1

# Referência ao AnimatedSprite2D
@onready var animated_sprite = $AnimatedSprite2D  # ← NOVO

func _ready():
	collision_layer = 1
	collision_mask = 25 
	
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
	if is_on_ladder:
		climb_ladder(delta)
	else:
		apply_gravity(delta)
		handle_jump(delta)
		auto_walk(delta)
	
	move_and_slide()
	update_timers(delta)
	check_wall_collision()
	update_animation()  # ← NOVO

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_jump(delta):
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

func update_animation():  # ← FUNÇÃO NOVA
	"""Atualiza a animação baseada no estado do player"""
	
	# Flip horizontal baseado na direção
	animated_sprite.flip_h = direction < 0
	
	# Escolhe a animação
	if is_on_ladder:
		animated_sprite.play("climb")
	elif not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("climb")  # Usa climb para subir
		else:
			animated_sprite.play("fall")
	else:
		animated_sprite.play("run")

func climb_ladder(delta):
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
	if area.name == "Ladder":
		is_on_ladder = true
		current_ladder = area
		print("Entrando na escada!")

func _on_area_exited(area: Area2D):
	if area.name == "Ladder":
		if not is_on_ladder:
			current_ladder = null
			print("Saindo da escada!")

func reverse_direction():
	direction *= -1
	print("🔄 Direção invertida!")

# Adicione esta função no player.gd

func take_damage(enemy):
	"""Chamado quando o player leva dano"""
	if is_invulnerable:
		return
	
	# Verifica se já levou dano desse inimigo específico
	if enemy in damaged_enemies:
		return
	
	var survived = GameManager.take_damage()
	
	if survived:
		# Sobreviveu - ativa invulnerabilidade temporária
		damaged_enemies.append(enemy)  # Marca esse inimigo
		start_invulnerability()
	else:
		# Morreu - game over
		die()

func start_invulnerability():
	"""Ativa invulnerabilidade temporária"""
	is_invulnerable = true
	print("🛡️ Invulnerável por ", INVULNERABILITY_TIME, " segundos")
	
	# Efeito visual de piscar
	var tween = create_tween()
	tween.set_loops(int(INVULNERABILITY_TIME * 5))
	tween.tween_property(animated_sprite, "modulate:a", 0.3, 0.1)
	tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.1)
	
	# Remove invulnerabilidade após o tempo
	await get_tree().create_timer(INVULNERABILITY_TIME).timeout
	is_invulnerable = false
	damaged_enemies.clear()  # ← LIMPA a lista de inimigos
	animated_sprite.modulate.a = 1.0
	print("🛡️ Invulnerabilidade encerrada")

func die():
	"""Chamado quando o player morre"""
	print("💀 GAME OVER")
	set_physics_process(false)
	
	# Animação de morte
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	await get_tree().create_timer(1.0).timeout
	
	# Mostra a tela de Game Over em vez de ir direto ao menu
	show_game_over()

func show_game_over():
	"""Carrega a tela de Game Over"""
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")

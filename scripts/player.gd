extends CharacterBody2D

# Constantes de movimento
const SPEED = 200.0
const JUMP_VELOCITY = -700.0
const ACCELERATION = 1500.0
const FRICTION = 1200.0
const AIR_RESISTANCE = 200.0

# Pulo variável (segurar o botão pula mais alto)
const JUMP_RELEASE_FORCE = -200.0

# Escada
const CLIMB_SPEED = 250.0
var is_on_ladder = false
var current_ladder: Area2D = null

# Coiote time (permite pular logo após sair da borda)
const COYOTE_TIME = 0.1
var coyote_timer = 0.0

# Buffer de pulo (registra o input de pulo antes de tocar no chão)
const JUMP_BUFFER_TIME = 0.1
var jump_buffer_timer = 0.0

# Gravidade customizada
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Configura collision layer do player
	collision_layer = 1
	collision_mask = 1
	
	# Conecta sinais da área de detecção
	var detection_area = get_node_or_null("DetectionArea")
	if detection_area:
		detection_area.collision_layer = 1
		detection_area.collision_mask = 2  # Detecta layer 2 (escadas)
		detection_area.area_entered.connect(_on_area_entered)
		detection_area.area_exited.connect(_on_area_exited)
		print("DetectionArea configurada!")
	else:
		print("ERRO: DetectionArea não encontrada!")

func _physics_process(delta):
	# Se estiver na escada, sobe automaticamente
	if is_on_ladder:
		climb_ladder(delta)
	else:
		apply_gravity(delta)
		handle_jump(delta)
		handle_movement(delta)
	
	move_and_slide()
	update_timers(delta)

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_jump(delta):
	# Coiote time - permite pular por um breve momento após sair do chão
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	
	# Registra o input de pulo
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	
	# Executa o pulo se estiver no chão ou no coiote time
	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0):
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0
	
	# Pulo variável - se soltar o botão, cai mais rápido
	if Input.is_action_just_released("ui_accept") and velocity.y < JUMP_RELEASE_FORCE:
		velocity.y = JUMP_RELEASE_FORCE

func handle_movement(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		# Acelera na direção do input
		if is_on_floor():
			velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		else:
			# Controle de ar levemente reduzido
			velocity.x = move_toward(velocity.x, direction * SPEED, AIR_RESISTANCE * delta)
	else:
		# Aplica fricção quando não há input
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, AIR_RESISTANCE * delta)

func update_timers(delta):
	if coyote_timer > 0:
		coyote_timer -= delta
	
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

func climb_ladder(delta):
	# Sobe automaticamente
	velocity.y = -CLIMB_SPEED
	velocity.x = 0  # Trava movimento horizontal
	
	# Verifica se saiu da escada por cima
	if current_ladder and global_position.y < current_ladder.global_position.y - 10:
		is_on_ladder = false
		current_ladder = null

func _on_area_entered(area: Area2D):
	if area.name == "Ladder":
		is_on_ladder = true
		current_ladder = area
		print("Entrando na escada!")

func _on_area_exited(area: Area2D):
	if area.name == "Ladder":
		is_on_ladder = false
		current_ladder = null
		print("Saindo da escada!")

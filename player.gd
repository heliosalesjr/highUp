extends CharacterBody2D

# Constantes de movimento
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 1500.0
const FRICTION = 1200.0
const AIR_RESISTANCE = 200.0

# Pulo variável (segurar o botão pula mais alto)
const JUMP_RELEASE_FORCE = -200.0

# Coiote time (permite pular logo após sair da borda)
const COYOTE_TIME = 0.1
var coyote_timer = 0.0

# Buffer de pulo (registra o input de pulo antes de tocar no chão)
const JUMP_BUFFER_TIME = 0.1
var jump_buffer_timer = 0.0

# Gravidade customizada
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
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

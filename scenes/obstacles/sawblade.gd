# sawblade.gd
extends Area2D

enum Speed { SLOW, MEDIUM, FAST }

var speed = 0.0
var current_corner = 0  # 0=superior direito, 1=inferior direito, 2=inferior esquerdo, 3=superior esquerdo
var target_position = Vector2.ZERO
var corners = []

# Velocidades
const SPEED_SLOW = 50.0
const SPEED_MEDIUM = 100.0
const SPEED_FAST = 175.0

# Margens das paredes
const MARGIN = 25

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	collision_layer = 4
	collision_mask = 1
	
	body_entered.connect(_on_body_entered)
	
	# Inicia a animação de rotação
	if animated_sprite:
		animated_sprite.play("spin")  # Ajuste o nome da animação
	
	# Define velocidade aleatória
	randomize_speed()
	
	# Aguarda um frame para garantir que está posicionado corretamente
	await get_tree().process_frame
	
	# Calcula os cantos baseado na posição inicial (canto superior direito)
	setup_corners()
	
	# Define primeiro alvo (canto inferior direito)
	current_corner = 0
	set_next_target()

func setup_corners():
	"""Define as posições dos 4 cantos da sala"""
	var room_width = 360
	var room_height = 160
	
	# Posições relativas à sala (local coordinates)
	corners = [
		Vector2(room_width - MARGIN, MARGIN),           # 0: Superior direito
		Vector2(room_width - MARGIN, room_height - MARGIN),  # 1: Inferior direito
		Vector2(MARGIN, room_height - MARGIN),          # 2: Inferior esquerdo
		Vector2(MARGIN, MARGIN)                         # 3: Superior esquerdo
	]
	
	print("🪚 Sawblade cantos definidos: ", corners)

func _physics_process(delta):
	# Move em direção ao alvo
	var direction = (target_position - position).normalized()
	var distance_to_target = position.distance_to(target_position)
	
	# Se chegou perto do alvo, vai para o próximo canto
	if distance_to_target < 10:
		set_next_target()
	
	# Move
	position += direction * speed * delta

func set_next_target():
	"""Define o próximo canto como alvo"""
	current_corner = (current_corner + 1) % 4  # Vai para o próximo (0→1→2→3→0)
	target_position = corners[current_corner]
	print("🪚 Sawblade indo para canto: ", current_corner, " - Posição: ", target_position)

func randomize_speed():
	"""Define velocidade aleatória"""
	var speed_type = randi() % 3
	
	match speed_type:
		0:
			speed = SPEED_SLOW
			print("🪚 Sawblade - Velocidade: LENTA (", speed, ")")
		1:
			speed = SPEED_MEDIUM
			print("🪚 Sawblade - Velocidade: MÉDIA (", speed, ")")
		2:
			speed = SPEED_FAST
			print("🪚 Sawblade - Velocidade: RÁPIDA (", speed, ")")

func _on_body_entered(body):
	"""Detecta colisão com o player"""
	if body.name == "Player" and body.has_method("take_damage"):
		# Ignora se player está invencível
		if GameManager.invincible_mode_active:
			print("🪚 Sawblade ignorou player invencível!")
			return

		body.take_damage(self)
		print("🪚 Sawblade atingiu o player!")

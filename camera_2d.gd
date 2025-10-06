extends Camera2D

@export var target: Node2D  # O player
@export var smoothing_enabled = true
@export var smoothing_speed = 5.0

var fixed_x_position = 540  # Meio da tela (1080 / 2)

func _ready():
	# Fixa a posição X no centro da tela
	position.x = fixed_x_position
	
	# Configura a câmera
	zoom = Vector2(1, 1)
	position_smoothing_enabled = smoothing_enabled
	position_smoothing_speed = smoothing_speed

func _process(_delta):
	if target:
		# Só segue o player no eixo Y
		# A câmera só sobe, nunca desce
		if target.global_position.y < global_position.y:
			global_position.y = target.global_position.y

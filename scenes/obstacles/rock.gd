# rock.gd
extends StaticBody2D

func _ready():
	# Configuração de colisão
	collision_layer = 2  # Layer separada para rocks (diferente das paredes)
	collision_mask = 0   # Não precisa detectar nada

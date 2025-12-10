# layout_spit.gd - ROOM EXCLUSIVA DO SPIT (só escada + spit)
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 160

var spit_scene = preload("res://scenes/enemies/spit.tscn")
var spit_instance = null

func _ready():
	# NÃO cria label, NÃO cria obstáculos - apenas o spit
	await get_tree().process_frame  # Espera um frame para garantir que a escada existe
	create_spit_enemy()
	create_room_entry_detector()

func create_spit_enemy():
	"""Cria o spit no mesmo lado da escada"""
	var room = get_parent()

	# Verifica se é split room (sem escada)
	if room.is_split_room:
		print("⚠️ Split room - Spit não será spawnado")
		return

	var spawn_x: float
	var spawn_y: float
	var direction: int

	# Usa a variável ladder_side da room (0=LEFT, 1=RIGHT)
	if room.ladder_side == 1:
		# Escada à DIREITA
		spawn_x = ROOM_WIDTH - 40  # Lado direito (X=320)
		direction = -1  # Olha para esquerda
		print("🐸 Escada RIGHT (1) → Spit à direita X=", spawn_x, " olhando esquerda")
	else:
		# Escada à ESQUERDA
		spawn_x = 40  # Lado esquerdo (X=40)
		direction = 1  # Olha para direita
		print("🐸 Escada LEFT (0) → Spit à esquerda X=", spawn_x, " olhando direita")

	spawn_y = ROOM_HEIGHT - 100 - 30  # Acima da escada (Y=30)

	spit_instance = spit_scene.instantiate()
	spit_instance.position = Vector2(spawn_x, spawn_y)
	add_child(spit_instance)  # Adiciona PRIMEIRO à árvore
	spit_instance.set_direction(direction)  # DEPOIS seta direção (animated_sprite já está disponível)
	print("🐸 Spit spawnado em: ", spit_instance.position, " direção: ", direction)

func create_room_entry_detector():
	"""Detecta quando o player entra na sala"""
	var detector = Area2D.new()
	detector.name = "EntryDetector"
	detector.collision_layer = 0
	detector.collision_mask = 1

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ROOM_WIDTH, 40)
	collision.shape = shape
	collision.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - 20)

	detector.add_child(collision)
	detector.body_entered.connect(_on_room_entered)
	add_child(detector)

func _on_room_entered(body):
	if body.name == "Player":
		GameManager.add_room()
		print("🎯 Sala SPIT alcançada!")

		# Notifica o spit que o player entrou
		if spit_instance and is_instance_valid(spit_instance):
			spit_instance.on_player_entered_room()

		get_node("EntryDetector").queue_free()

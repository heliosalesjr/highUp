# layout_split_bird.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 160
const WALL_THICKNESS = 6  # ← Atualizado para pixel art (paredes laterais)
const FLOOR_THICKNESS = 6  # ← Atualizado para pixel art
const FLOOR_TILE_WIDTH = 16  # Largura de cada tile do piso

var diamond_scene = preload("res://scenes/prize/diamond.tscn")
var heart_scene = preload("res://scenes/prize/heart.tscn")
var bird_scene = preload("res://scenes/enemies/bird.tscn")

# Texturas do piso (carregadas uma vez)
var floor_tiles = [
	preload("res://assets/aseprite-floor/piso1.png"),
	preload("res://assets/aseprite-floor/piso2.png"),
	preload("res://assets/aseprite-floor/piso3.png"),
	preload("res://assets/aseprite-floor/piso4.png")
]

func _ready():
	# create_label("SPLIT BIRD")  # Hidden for now
	create_middle_floor()
	spawn_prize_randomly()
	create_bird_enemies()  # ← MUDOU
	create_room_entry_detector()
	create_second_floor_detector()

func create_label(text: String):
	var label = Label.new()
	label.text = text
	label.position = Vector2(ROOM_WIDTH / 2.0 - 60, 20)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(label)

func create_middle_floor():
	var middle_floor = StaticBody2D.new()
	middle_floor.name = "MiddleFloor"

	var floor_width = ROOM_WIDTH - (WALL_THICKNESS * 2)
	var floor_x = WALL_THICKNESS

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	# Collision shape bem fina no TOPO do piso (1 pixel)
	shape.size = Vector2(floor_width, 1)
	collision.shape = shape
	# Posiciona no topo do floor visual (linha mais alta)
	collision.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 2.0 - FLOOR_THICKNESS / 2.0)
	collision.one_way_collision = true

	# TILES ALEATÓRIOS: Criar tiles de 16x6px usando as 4 texturas
	var num_tiles = ceil(float(floor_width) / FLOOR_TILE_WIDTH)
	var floor_y = ROOM_HEIGHT / 2.0 - FLOOR_THICKNESS / 2.0

	for i in range(num_tiles):
		var tile = Sprite2D.new()
		# Escolhe aleatoriamente uma das 4 texturas
		tile.texture = floor_tiles[randi() % floor_tiles.size()]
		tile.centered = false
		# Posiciona cada tile sequencialmente
		tile.position = Vector2(floor_x + i * FLOOR_TILE_WIDTH, floor_y)
		middle_floor.add_child(tile)

	middle_floor.add_child(collision)
	add_child(middle_floor)

func create_bird_enemies():
	"""
	Cria birds em posições aleatórias:
	- 40% chance: Bird em cima (esquerda → direita)
	- 40% chance: Bird embaixo (direita → esquerda)
	- 20% chance: Birds em cima E embaixo
	"""
	var spawn_type = randf()
	
	if spawn_type < 0.4:
		# Apenas em cima
		spawn_bird_top()
		print("🦅 Configuração: Bird somente em CIMA")
	
	elif spawn_type < 0.8:
		# Apenas embaixo
		spawn_bird_bottom()
		print("🦅 Configuração: Bird somente EMBAIXO")
	
	else:
		# Ambos (cima e baixo)
		spawn_bird_top()
		spawn_bird_bottom()
		print("🦅 Configuração: Birds em CIMA e EMBAIXO")

func spawn_bird_top():
	"""Spawna bird na parte de cima (esquerda → direita)"""
	var bird_y = ROOM_HEIGHT / 4.0  # Meio da parte superior
	var spawn_x = 25  # Lado ESQUERDO
	
	var bird = bird_scene.instantiate()
	bird.position = Vector2(spawn_x, bird_y)
	
	# Configura para ir para a DIREITA
	bird.direction = 1
	
	add_child(bird)
	
	# Aguarda um frame para garantir que o sprite existe
	await get_tree().process_frame
	
	# Aplica o flip inicial
	if bird.has_node("AnimatedSprite2D"):
		bird.get_node("AnimatedSprite2D").flip_h = true
	
	print("🦅 Bird spawnado em CIMA (esquerda→direita) em: ", bird.position)

func spawn_bird_bottom():
	"""Spawna bird na parte de baixo (direita → esquerda)"""
	var bird_y = ROOM_HEIGHT * 0.75  # Meio da parte inferior
	var spawn_x = ROOM_WIDTH - 25  # Lado DIREITO
	
	var bird = bird_scene.instantiate()
	bird.position = Vector2(spawn_x, bird_y)
	
	# Configura para ir para a ESQUERDA (direção padrão = -1)
	bird.direction = -1
	
	add_child(bird)
	
	# Aguarda um frame para garantir que o sprite existe
	await get_tree().process_frame
	
	# Aplica o flip inicial (false para esquerda, já que sprite original aponta para esquerda)
	if bird.has_node("AnimatedSprite2D"):
		bird.get_node("AnimatedSprite2D").flip_h = false
	
	print("🦅 Bird spawnado EMBAIXO (direita→esquerda) em: ", bird.position)

func create_room_entry_detector():
	"""Detecta quando o player ENTRA na sala split"""
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

func create_second_floor_detector():
	"""Detecta quando o player alcança o piso do MEIO (segundo andar)"""
	var detector = Area2D.new()
	detector.name = "SecondFloorDetector"
	detector.collision_layer = 0
	detector.collision_mask = 1
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ROOM_WIDTH - 100, 30)
	collision.shape = shape
	collision.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 2.0 - 30)
	
	detector.add_child(collision)
	detector.body_entered.connect(_on_second_floor_reached)
	add_child(detector)

func _on_room_entered(body):
	if body.name == "Player":
		GameManager.add_room()
		print("🎯 Sala split bird alcançada! (+1)")
		get_node("EntryDetector").queue_free()

func _on_second_floor_reached(body):
	if body.name == "Player":
		GameManager.add_room()
		print("🎯 Segundo piso alcançado! (+1)")
		get_node("SecondFloorDetector").queue_free()

func spawn_prize_randomly():
	"""50% de chance de spawnar um prêmio (diamante ou coração)"""
	if randf() > 0.5:
		return
	
	var prize_position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 2.0 - 40)
	
	if GameManager.can_spawn_heart():
		var heart = heart_scene.instantiate()
		heart.position = prize_position
		add_child(heart)
		print("❤️ Coração spawnado!")
	else:
		var diamond = diamond_scene.instantiate()
		diamond.position = prize_position
		add_child(diamond)
		print("💎 Diamante spawnado!")

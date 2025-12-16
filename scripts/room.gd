# room.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 160
const WALL_THICKNESS = 6  # ← Atualizado para pixel art (paredes laterais)
const FLOOR_THICKNESS = 6  # ← Atualizado para pixel art
const LADDER_START_HEIGHT = 100
const LADDER_WIDTH = 15
const FLOOR_TILE_WIDTH = 16  # Largura de cada tile do piso

enum LadderSide { LEFT, RIGHT }

# Texturas do piso (carregadas uma vez)
var floor_tiles = [
	preload("res://assets/aseprite-floor/piso1.png"),
	preload("res://assets/aseprite-floor/piso2.png"),
	preload("res://assets/aseprite-floor/piso3.png"),
	preload("res://assets/aseprite-floor/piso4.png")
]

@export var ladder_side: LadderSide = LadderSide.RIGHT
var is_split_room = false  # ← NOVA VARIÁVEL

func _ready():
	print("Room criada na posição: ", global_position)
	create_floor()
	create_walls()
	
	# Só cria escada se NÃO for split room
	if not is_split_room:
		create_ladder()
	
	print("Room configurada com ", get_child_count(), " filhos")

func create_floor():
	var floor_body = StaticBody2D.new()
	floor_body.name = "Floor"

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	# Collision shape bem fina no TOPO do piso (1 pixel)
	shape.size = Vector2(ROOM_WIDTH, 1)
	collision.shape = shape
	# Posiciona no topo do floor visual (linha mais alta)
	collision.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - FLOOR_THICKNESS)
	collision.one_way_collision = true

	# TILES ALEATÓRIOS: Criar tiles de 16x6px usando as 4 texturas
	var num_tiles = ceil(float(ROOM_WIDTH) / FLOOR_TILE_WIDTH)  # 23 tiles (22.5 arredondado)
	var floor_y = ROOM_HEIGHT - FLOOR_THICKNESS

	for i in range(num_tiles):
		var tile = Sprite2D.new()
		# Escolhe aleatoriamente uma das 4 texturas
		tile.texture = floor_tiles[randi() % floor_tiles.size()]
		tile.centered = false
		# Posiciona cada tile sequencialmente
		tile.position = Vector2(i * FLOOR_TILE_WIDTH, floor_y)
		floor_body.add_child(tile)

	floor_body.add_child(collision)
	add_child(floor_body)

func create_walls():
	# PAREDE ESQUERDA
	var left_wall = StaticBody2D.new()
	left_wall.name = "LeftWall"

	var left_collision = CollisionShape2D.new()
	var left_shape = RectangleShape2D.new()
	left_shape.size = Vector2(WALL_THICKNESS, ROOM_HEIGHT)
	left_collision.shape = left_shape
	left_collision.position = Vector2(WALL_THICKNESS / 2.0, ROOM_HEIGHT / 2.0)

	# SIMULAÇÃO VISUAL: Textura de tronco de árvore (6px de largura)
	# Base - marrom escuro
	var left_base = ColorRect.new()
	left_base.size = Vector2(WALL_THICKNESS, ROOM_HEIGHT)
	left_base.color = Color(0.3, 0.2, 0.15)  # Marrom tronco base
	left_base.position = Vector2(0, 0)

	# Highlight/Luz - 2px mais claro no meio
	var left_highlight = ColorRect.new()
	left_highlight.size = Vector2(2, ROOM_HEIGHT)
	left_highlight.color = Color(0.45, 0.3, 0.2)  # Marrom mais claro
	left_highlight.position = Vector2(2, 0)

	left_wall.add_child(left_collision)
	left_wall.add_child(left_base)
	left_wall.add_child(left_highlight)
	add_child(left_wall)

	# PAREDE DIREITA
	var right_wall = StaticBody2D.new()
	right_wall.name = "RightWall"

	var right_collision = CollisionShape2D.new()
	var right_shape = RectangleShape2D.new()
	right_shape.size = Vector2(WALL_THICKNESS, ROOM_HEIGHT)
	right_collision.shape = right_shape
	right_collision.position = Vector2(ROOM_WIDTH - WALL_THICKNESS / 2.0, ROOM_HEIGHT / 2.0)

	# SIMULAÇÃO VISUAL: Textura de tronco de árvore (6px de largura)
	# Base - marrom escuro
	var right_base = ColorRect.new()
	right_base.size = Vector2(WALL_THICKNESS, ROOM_HEIGHT)
	right_base.color = Color(0.3, 0.2, 0.15)  # Marrom tronco base
	right_base.position = Vector2(ROOM_WIDTH - WALL_THICKNESS, 0)

	# Highlight/Luz - 2px mais claro no meio
	var right_highlight = ColorRect.new()
	right_highlight.size = Vector2(2, ROOM_HEIGHT)
	right_highlight.color = Color(0.45, 0.3, 0.2)  # Marrom mais claro
	right_highlight.position = Vector2(ROOM_WIDTH - WALL_THICKNESS + 2, 0)

	right_wall.add_child(right_collision)
	right_wall.add_child(right_base)
	right_wall.add_child(right_highlight)
	add_child(right_wall)

func create_ladder():
	var ladder = Area2D.new()
	ladder.name = "Ladder"
	ladder.collision_layer = 2
	ladder.collision_mask = 1
	
	var ladder_height = LADDER_START_HEIGHT
	
	var ladder_x = 0
	if ladder_side == LadderSide.RIGHT:
		ladder_x = ROOM_WIDTH - WALL_THICKNESS - LADDER_WIDTH - 15
	else:
		ladder_x = WALL_THICKNESS + 15
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(LADDER_WIDTH, ladder_height)
	collision.shape = shape
	collision.position = Vector2(ladder_x + LADDER_WIDTH / 2.0, ladder_height / 2.0)
	
	var visual = ColorRect.new()
	visual.size = Vector2(LADDER_WIDTH, ladder_height)
	visual.color = Color(0.8, 0.6, 0.2)
	visual.position = Vector2(ladder_x, 0)
	
	for i in range(5):
		var step = ColorRect.new()
		step.size = Vector2(LADDER_WIDTH, 3)
		step.color = Color(0.6, 0.4, 0.1)
		step.position = Vector2(ladder_x, i * (ladder_height / 5.0))
		ladder.add_child(step)
	
	ladder.add_child(collision)
	ladder.add_child(visual)
	add_child(ladder)

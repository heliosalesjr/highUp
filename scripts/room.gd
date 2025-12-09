# room.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 160
const WALL_THICKNESS = 2
const FLOOR_THICKNESS = 2
const LADDER_START_HEIGHT = 100
const LADDER_WIDTH = 15

enum LadderSide { LEFT, RIGHT }

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
	shape.size = Vector2(ROOM_WIDTH, FLOOR_THICKNESS)
	collision.shape = shape
	collision.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - FLOOR_THICKNESS / 2.0)
	collision.one_way_collision = true
	
	var visual = ColorRect.new()
	visual.size = Vector2(ROOM_WIDTH, FLOOR_THICKNESS)
	visual.color = Color(0.5, 0.3, 0.2)
	visual.position = Vector2(0, ROOM_HEIGHT - FLOOR_THICKNESS)
	
	floor_body.add_child(collision)
	floor_body.add_child(visual)
	add_child(floor_body)

func create_walls():
	# Parede esquerda
	var left_wall = StaticBody2D.new()
	left_wall.name = "LeftWall"
	
	var left_collision = CollisionShape2D.new()
	var left_shape = RectangleShape2D.new()
	left_shape.size = Vector2(WALL_THICKNESS, ROOM_HEIGHT)
	left_collision.shape = left_shape
	left_collision.position = Vector2(WALL_THICKNESS / 2.0, ROOM_HEIGHT / 2.0)
	
	var left_visual = ColorRect.new()
	left_visual.size = Vector2(WALL_THICKNESS, ROOM_HEIGHT)
	left_visual.color = Color(0.3, 0.3, 0.3)
	left_visual.position = Vector2(0, 0)
	
	left_wall.add_child(left_collision)
	left_wall.add_child(left_visual)
	add_child(left_wall)
	
	# Parede direita
	var right_wall = StaticBody2D.new()
	right_wall.name = "RightWall"
	
	var right_collision = CollisionShape2D.new()
	var right_shape = RectangleShape2D.new()
	right_shape.size = Vector2(WALL_THICKNESS, ROOM_HEIGHT)
	right_collision.shape = right_shape
	right_collision.position = Vector2(ROOM_WIDTH - WALL_THICKNESS / 2.0, ROOM_HEIGHT / 2.0)
	
	var right_visual = ColorRect.new()
	right_visual.size = Vector2(WALL_THICKNESS, ROOM_HEIGHT)
	right_visual.color = Color(0.3, 0.3, 0.3)
	right_visual.position = Vector2(ROOM_WIDTH - WALL_THICKNESS, 0)
	
	right_wall.add_child(right_collision)
	right_wall.add_child(right_visual)
	add_child(right_wall)

func create_ladder():
	var ladder = Area2D.new()
	ladder.name = "Ladder"
	ladder.collision_layer = 2
	ladder.collision_mask = 1
	
	var ladder_height = LADDER_START_HEIGHT
	
	var ladder_x = 0
	if ladder_side == LadderSide.RIGHT:
		ladder_x = ROOM_WIDTH - WALL_THICKNESS - LADDER_WIDTH - 20
	else:
		ladder_x = WALL_THICKNESS + 20
	
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

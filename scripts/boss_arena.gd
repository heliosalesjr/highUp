# boss_arena.gd
extends Node2D

signal boss_defeated
signal boss_failed

const ARENA_WIDTH = 360
const ARENA_HEIGHT = 640
const WALL_THICKNESS = 10
const FLOOR_Y = 620
const TOTAL_BOXES = 10
const BOX_DESCENT_SPEED = 10.0
const BOX_SPEED_INCREASE = 0.5

var boxes_remaining = TOTAL_BOXES
var car: CharacterBody2D = null

func _ready():
	create_background()
	create_walls()
	create_car()
	create_boxes()
	print("🏟️ Boss Arena criada! Caixas: ", boxes_remaining)

func create_background():
	var bg = ColorRect.new()
	bg.size = Vector2(ARENA_WIDTH, ARENA_HEIGHT)
	bg.position = Vector2(0, 0)
	bg.color = Color(0.08, 0.08, 0.12)
	bg.z_index = -10
	add_child(bg)

func create_walls():
	# Floor
	var floor_body = StaticBody2D.new()
	floor_body.position = Vector2(ARENA_WIDTH / 2.0, FLOOR_Y)
	var floor_col = CollisionShape2D.new()
	var floor_shape = RectangleShape2D.new()
	floor_shape.size = Vector2(ARENA_WIDTH, WALL_THICKNESS)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	add_child(floor_body)

	# Floor visual
	var floor_visual = ColorRect.new()
	floor_visual.size = Vector2(ARENA_WIDTH, WALL_THICKNESS)
	floor_visual.position = Vector2(0, FLOOR_Y - WALL_THICKNESS / 2.0)
	floor_visual.color = Color(0.3, 0.3, 0.35)
	add_child(floor_visual)

	# Left wall
	var left_wall = StaticBody2D.new()
	left_wall.position = Vector2(0, ARENA_HEIGHT / 2.0)
	var left_col = CollisionShape2D.new()
	var left_shape = RectangleShape2D.new()
	left_shape.size = Vector2(WALL_THICKNESS, ARENA_HEIGHT)
	left_col.shape = left_shape
	left_wall.add_child(left_col)
	left_wall.collision_layer = 1
	left_wall.collision_mask = 0
	add_child(left_wall)

	# Right wall
	var right_wall = StaticBody2D.new()
	right_wall.position = Vector2(ARENA_WIDTH, ARENA_HEIGHT / 2.0)
	var right_col = CollisionShape2D.new()
	var right_shape = RectangleShape2D.new()
	right_shape.size = Vector2(WALL_THICKNESS, ARENA_HEIGHT)
	right_col.shape = right_shape
	right_wall.add_child(right_col)
	right_wall.collision_layer = 1
	right_wall.collision_mask = 0
	add_child(right_wall)

	# Ceiling (visual only, no physics needed)
	var ceiling_visual = ColorRect.new()
	ceiling_visual.size = Vector2(ARENA_WIDTH, WALL_THICKNESS)
	ceiling_visual.position = Vector2(0, 0)
	ceiling_visual.color = Color(0.3, 0.3, 0.35)
	add_child(ceiling_visual)

func create_car():
	var car_script = load("res://scripts/boss_car.gd")
	car = CharacterBody2D.new()
	car.set_script(car_script)
	car.position = Vector2(ARENA_WIDTH / 2.0, FLOOR_Y - 13)  # Slightly above floor
	car.arena = self
	add_child(car)

func create_boxes():
	var box_script = load("res://scripts/boss_box.gd")

	# Layout: inverted pyramid 3-4-3
	# Line 1 (top): 3 boxes
	# Line 2: 4 boxes
	# Line 3: 3 boxes
	var box_spacing_x = 70
	var start_y = 60
	var line_spacing_y = 50
	var center_x = ARENA_WIDTH / 2.0

	var layout = [
		# Line 1: 3 boxes
		[center_x - box_spacing_x, center_x, center_x + box_spacing_x],
		# Line 2: 4 boxes
		[center_x - box_spacing_x * 1.5, center_x - box_spacing_x * 0.5, center_x + box_spacing_x * 0.5, center_x + box_spacing_x * 1.5],
		# Line 3: 3 boxes
		[center_x - box_spacing_x, center_x, center_x + box_spacing_x],
	]

	for line_index in range(layout.size()):
		var line = layout[line_index]
		var y = start_y + (line_index * line_spacing_y)
		for x in line:
			spawn_box(Vector2(x, y), box_script)

func spawn_box(pos: Vector2, box_script):
	var box = Area2D.new()
	box.set_script(box_script)
	box.position = pos
	box.death_line_y = global_position.y + FLOOR_Y - 20
	box.descent_speed = BOX_DESCENT_SPEED
	box.box_destroyed.connect(_on_box_destroyed)
	box.box_reached_floor.connect(_on_box_reached_floor)
	add_child(box)

func _on_box_destroyed():
	boxes_remaining -= 1
	print("📦 Caixa destruida! Restam: ", boxes_remaining)

	if boxes_remaining <= 0:
		print("🎉 BOSS DERROTADO!")
		boss_defeated.emit()

func _on_box_reached_floor():
	print("💀 Caixa chegou ao chao! GAME OVER!")
	boss_failed.emit()

# boss_room.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 320  # 2x normal room height
const WALL_THICKNESS = 6
const FLOOR_THICKNESS = 6
const FLOOR_TILE_WIDTH = 16
const WALL_TILE_HEIGHT = 32
const LADDER_WIDTH = 15

const TOTAL_BOXES = 10
const BOX_DESCENT_SPEED = 10.0

# Texturas (mesmas do room.gd)
var floor_tiles = [
	preload("res://assets/aseprite-floor/piso1.png"),
	preload("res://assets/aseprite-floor/piso2.png"),
	preload("res://assets/aseprite-floor/piso3.png"),
	preload("res://assets/aseprite-floor/piso4.png")
]
var wall_tiles = [
	preload("res://assets/aseprite-walls/wall1.png"),
	preload("res://assets/aseprite-walls/wall2.png"),
	preload("res://assets/aseprite-walls/wall3.png"),
	preload("res://assets/aseprite-walls/wall4.png")
]

var ladder_side = 0  # Player exits to the right after climbing victory ladder
var boxes_remaining = TOTAL_BOXES
var car = null
var fight_active = false
var fight_over = false

func _ready():
	create_background()
	create_floor()
	create_walls()
	create_entry_detector()
	create_car()
	create_boxes()
	print("🏟️ Boss Room criada na posicao: ", global_position)

func _on_car_player_entered():
	if fight_active or fight_over:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player:
		start_fight(player)

func start_fight(player):
	fight_active = true
	player.enter_boss_fight(car, self)

	# Start the car moving
	if car:
		car.start_moving()

	# Lock camera centered on this room
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.is_locked = true
		camera.global_position.y = global_position.y + ROOM_HEIGHT / 2.0

	# Activate all boxes now that the player is on the car
	for box in get_tree().get_nodes_in_group("boss_box"):
		box.activate()

	print("🏟️ BOSS FIGHT STARTED!")

func create_background():
	var bg = ColorRect.new()
	bg.size = Vector2(ROOM_WIDTH, ROOM_HEIGHT)
	bg.position = Vector2(0, 0)
	bg.color = Color(0.05, 0.05, 0.1)
	bg.z_index = -5
	add_child(bg)

func create_floor():
	var floor_body = StaticBody2D.new()
	floor_body.name = "Floor"

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ROOM_WIDTH, 1)
	collision.shape = shape
	collision.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - FLOOR_THICKNESS)
	collision.one_way_collision = true

	# Floor tiles (same pattern as room.gd)
	var num_tiles = ceil(float(ROOM_WIDTH) / FLOOR_TILE_WIDTH)
	var floor_y = ROOM_HEIGHT - FLOOR_THICKNESS

	for i in range(num_tiles):
		var tile = Sprite2D.new()
		tile.texture = floor_tiles[randi() % floor_tiles.size()]
		tile.centered = false
		tile.position = Vector2(i * FLOOR_TILE_WIDTH, floor_y)
		floor_body.add_child(tile)

	floor_body.add_child(collision)
	add_child(floor_body)

func create_walls():
	# Left wall
	var left_wall = StaticBody2D.new()
	left_wall.name = "LeftWall"
	var left_collision = CollisionShape2D.new()
	var left_shape = RectangleShape2D.new()
	left_shape.size = Vector2(WALL_THICKNESS, ROOM_HEIGHT)
	left_collision.shape = left_shape
	left_collision.position = Vector2(WALL_THICKNESS / 2.0, ROOM_HEIGHT / 2.0)

	var num_tiles = ceil(float(ROOM_HEIGHT) / WALL_TILE_HEIGHT)
	for i in range(num_tiles):
		var tile = Sprite2D.new()
		tile.texture = wall_tiles[randi() % wall_tiles.size()]
		tile.centered = false
		tile.flip_h = true
		tile.position = Vector2(0, i * WALL_TILE_HEIGHT)
		left_wall.add_child(tile)

	left_wall.add_child(left_collision)
	add_child(left_wall)

	# Right wall
	var right_wall = StaticBody2D.new()
	right_wall.name = "RightWall"
	var right_collision = CollisionShape2D.new()
	var right_shape = RectangleShape2D.new()
	right_shape.size = Vector2(WALL_THICKNESS, ROOM_HEIGHT)
	right_collision.shape = right_shape
	right_collision.position = Vector2(ROOM_WIDTH - WALL_THICKNESS / 2.0, ROOM_HEIGHT / 2.0)

	for i in range(num_tiles):
		var tile = Sprite2D.new()
		tile.texture = wall_tiles[randi() % wall_tiles.size()]
		tile.centered = false
		tile.position = Vector2(ROOM_WIDTH - WALL_THICKNESS, i * WALL_TILE_HEIGHT)
		right_wall.add_child(tile)

	right_wall.add_child(right_collision)
	add_child(right_wall)

func create_entry_detector():
	# Same pattern as layout scripts - calls add_room when player enters
	var detector = Area2D.new()
	detector.name = "EntryDetector"
	detector.collision_layer = 0
	detector.collision_mask = 1
	detector.monitoring = true

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
		print("🏟️ Boss Room alcancada!")
		var det = get_node_or_null("EntryDetector")
		if det:
			det.queue_free()

func create_car():
	var car_script = load("res://scenes/boss/boss_car.gd")
	car = CharacterBody2D.new()
	car.set_script(car_script)
	car.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - FLOOR_THICKNESS - 10)
	add_child(car)
	car.player_entered.connect(_on_car_player_entered)

func create_boxes():
	var box_script = load("res://scenes/boss/boss_box.gd")

	var box_spacing_x = 60
	var start_y = 30
	var line_spacing_y = 35
	var center_x = ROOM_WIDTH / 2.0

	# Layout: inverted pyramid 3-4-3
	var layout = [
		[center_x - box_spacing_x, center_x, center_x + box_spacing_x],
		[center_x - box_spacing_x * 1.5, center_x - box_spacing_x * 0.5, center_x + box_spacing_x * 0.5, center_x + box_spacing_x * 1.5],
		[center_x - box_spacing_x, center_x, center_x + box_spacing_x],
	]

	for line_index in range(layout.size()):
		var line = layout[line_index]
		var y = start_y + (line_index * line_spacing_y)
		for x in line:
			var box = Area2D.new()
			box.set_script(box_script)
			box.position = Vector2(x, y)
			box.death_line_y = global_position.y + ROOM_HEIGHT - FLOOR_THICKNESS - 10
			box.descent_speed = BOX_DESCENT_SPEED
			box.add_to_group("boss_box")
			box.box_destroyed.connect(_on_box_destroyed)
			box.box_reached_floor.connect(_on_box_reached_floor)
			add_child(box)

func _on_box_destroyed():
	boxes_remaining -= 1
	print("📦 Caixa destruida! Restam: ", boxes_remaining)

	if boxes_remaining <= 0 and not fight_over:
		fight_over = true
		on_boss_defeated()

func _on_box_reached_floor():
	if fight_over:
		return
	fight_over = true
	print("💀 Caixa chegou ao chao! GAME OVER!")
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")

func on_boss_defeated():
	fight_active = false
	GameManager.boss_defeated = true

	# Deactivate boss fight on player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.exit_boss_fight()

	# Stop the car
	if car:
		car.set_physics_process(false)

	# Unlock camera
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.is_locked = false

	# Create ladder so player can continue climbing
	create_victory_ladder()
	print("🎉 BOSS DERROTADO!")

func create_victory_ladder():
	var ladder = Area2D.new()
	ladder.name = "Ladder"
	ladder.collision_layer = 2
	ladder.collision_mask = 1

	var ladder_height = ROOM_HEIGHT - 50
	var ladder_x = ROOM_WIDTH / 2.0 - LADDER_WIDTH / 2.0

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(LADDER_WIDTH, ladder_height)
	collision.shape = shape
	collision.position = Vector2(ladder_x + LADDER_WIDTH / 2.0, ladder_height / 2.0)

	var visual = ColorRect.new()
	visual.size = Vector2(LADDER_WIDTH, ladder_height)
	visual.color = Color(0.8, 0.6, 0.2)
	visual.position = Vector2(ladder_x, 0)

	for i in range(int(ladder_height / 20)):
		var step = ColorRect.new()
		step.size = Vector2(LADDER_WIDTH, 3)
		step.color = Color(0.6, 0.4, 0.1)
		step.position = Vector2(ladder_x, i * 20)
		ladder.add_child(step)

	ladder.add_child(collision)
	ladder.add_child(visual)
	add_child(ladder)

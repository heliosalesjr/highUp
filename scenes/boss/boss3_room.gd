# boss3_room.gd — Gravity flip challenge room
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 320
const WALL_THICKNESS = 6
const FLOOR_THICKNESS = 6
const FLOOR_TILE_WIDTH = 16
const WALL_TILE_HEIGHT = 32
const LADDER_WIDTH = 15

const TOTAL_WAVES = 5
const BIRDS_PER_WAVE = 3
const WAVE_PAUSE = 1.5
const BIRD_SPEED = 120.0
const INITIAL_DELAY = 1.0

# Y positions for birds in each half (3 birds covering the half)
const BOTTOM_HALF_Y = [195, 235, 275]
const TOP_HALF_Y = [45, 85, 125]

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

var ladder_side = 0
var ceiling_ref = null
var fight_active = false
var fight_over = false
var waiting_for_player = false
var player_ref = null
var current_wave = 0
var wave_birds = []
var wave_in_progress = false
var between_waves = false
var warning_rect = null

func _ready():
	create_background()
	create_floor()
	create_ceiling()
	create_walls()
	create_entry_detector()

func _physics_process(_delta):
	if waiting_for_player and player_ref and is_instance_valid(player_ref):
		if player_ref.is_on_floor() and not player_ref.is_on_ladder:
			waiting_for_player = false
			start_fight(player_ref)

	if wave_in_progress:
		# Clean up freed birds and check if wave is done
		wave_birds = wave_birds.filter(func(b): return is_instance_valid(b))
		if wave_birds.is_empty():
			wave_in_progress = false
			wave_complete()

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

func create_ceiling():
	ceiling_ref = StaticBody2D.new()
	ceiling_ref.name = "Ceiling"

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ROOM_WIDTH, FLOOR_THICKNESS)
	collision.shape = shape
	collision.position = Vector2(ROOM_WIDTH / 2.0, FLOOR_THICKNESS / 2.0)

	var num_tiles = ceil(float(ROOM_WIDTH) / FLOOR_TILE_WIDTH)
	for i in range(num_tiles):
		var tile = Sprite2D.new()
		tile.texture = floor_tiles[randi() % floor_tiles.size()]
		tile.centered = false
		tile.flip_v = true
		tile.position = Vector2(i * FLOOR_TILE_WIDTH, 0)
		ceiling_ref.add_child(tile)

	ceiling_ref.add_child(collision)
	add_child(ceiling_ref)

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
		var det = get_node_or_null("EntryDetector")
		if det:
			det.queue_free()
		if not fight_active and not fight_over:
			waiting_for_player = true
			player_ref = body

func start_fight(player):
	fight_active = true
	player.enter_boss3_fight(self)

	# Lock camera
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.is_locked = true
		camera.global_position.y = global_position.y + ROOM_HEIGHT / 2.0

	await get_tree().create_timer(INITIAL_DELAY).timeout
	if fight_over:
		return
	start_wave()

func flash_warning(use_bottom: bool):
	# Create a red overlay covering the danger half
	warning_rect = ColorRect.new()
	warning_rect.size = Vector2(ROOM_WIDTH, ROOM_HEIGHT / 2.0)
	warning_rect.color = Color(1.0, 0.1, 0.1, 0.0)
	warning_rect.z_index = 5
	if use_bottom:
		warning_rect.position = Vector2(0, ROOM_HEIGHT / 2.0)
	else:
		warning_rect.position = Vector2(0, 0)
	add_child(warning_rect)

	# 3 quick red flashes (~0.75s)
	for flash in range(3):
		if fight_over or not is_instance_valid(warning_rect):
			break
		warning_rect.color.a = 0.35
		await get_tree().create_timer(0.15).timeout
		if fight_over or not is_instance_valid(warning_rect):
			break
		warning_rect.color.a = 0.0
		await get_tree().create_timer(0.10).timeout

	# Pause after flashes so player has time to react
	if not fight_over:
		await get_tree().create_timer(0.4).timeout

	if warning_rect and is_instance_valid(warning_rect):
		warning_rect.queue_free()
		warning_rect = null

func start_wave():
	if fight_over or current_wave >= TOTAL_WAVES:
		return

	# Wave 0: always bottom half (teaches gravity flip — player must jump)
	# Waves 1+: random half
	var use_bottom = true
	if current_wave > 0:
		use_bottom = randi() % 2 == 0

	# Flash warning before birds arrive
	await flash_warning(use_bottom)
	if fight_over:
		return

	var y_positions = BOTTOM_HALF_Y if use_bottom else TOP_HALF_Y

	wave_birds.clear()
	var obstacle_script = load("res://scenes/boss/boss3_obstacle.gd")

	for i in range(BIRDS_PER_WAVE):
		var bird = Node2D.new()
		bird.set_script(obstacle_script)
		bird.direction = 1  # fly left to right
		bird.speed = BIRD_SPEED
		bird.position = Vector2(-30, y_positions[i])
		add_child(bird)
		wave_birds.append(bird)

	wave_in_progress = true
	print("Boss 3 Wave ", current_wave + 1, "/", TOTAL_WAVES)

func wave_complete():
	if fight_over or between_waves:
		return

	current_wave += 1

	# Small camera shake as feedback
	var camera = get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("shake"):
		camera.shake(0.15, 8.0)

	print("Boss 3 Wave ", current_wave, "/", TOTAL_WAVES, " complete!")

	if current_wave >= TOTAL_WAVES:
		on_boss_defeated()
		return

	between_waves = true
	await get_tree().create_timer(WAVE_PAUSE).timeout
	between_waves = false
	if not fight_over:
		start_wave()

func on_boss_defeated():
	fight_active = false
	fight_over = true
	wave_in_progress = false
	GameManager.boss_3_defeated = true

	# Clean up warning overlay if active
	if warning_rect and is_instance_valid(warning_rect):
		warning_rect.queue_free()
		warning_rect = null

	# Clean up any remaining birds
	for bird in wave_birds:
		if is_instance_valid(bird):
			bird.queue_free()
	wave_birds.clear()

	# Exit boss fight mode on player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.exit_boss3_fight()

	# Remove ceiling so player can climb out
	if ceiling_ref and is_instance_valid(ceiling_ref):
		ceiling_ref.queue_free()
		ceiling_ref = null

	# Unlock camera
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.is_locked = false

	create_victory_ladder()

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

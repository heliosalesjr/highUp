# boss2_room.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 320  # 2x normal room height
const WALL_THICKNESS = 6
const FLOOR_THICKNESS = 6
const FLOOR_TILE_WIDTH = 16
const WALL_TILE_HEIGHT = 32
const LADDER_WIDTH = 15

const CREATURE_HP = 5

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

var ladder_side = 0  # Player exits to the right
var creature = null
var fight_active = false
var fight_over = false
var hits_landed = 0

func _ready():
	create_background()
	create_floor()
	create_walls()
	create_entry_detector()
	create_creature()
	create_shield_pickup()
	print("🏟️ Boss 2 Room criada na posicao: ", global_position)

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
		print("🏟️ Boss 2 Room alcancada!")
		var det = get_node_or_null("EntryDetector")
		if det:
			det.queue_free()

func create_creature():
	var creature_script = load("res://scenes/boss/boss2_creature.gd")
	creature = CharacterBody2D.new()
	creature.set_script(creature_script)
	creature.position = Vector2(ROOM_WIDTH / 2.0, 40)
	creature.room = self
	creature.creature_hit.connect(_on_creature_hit)
	add_child(creature)

func create_shield_pickup():
	var pickup_script = load("res://scenes/boss/boss2_shield_pickup.gd")
	var pickup = Area2D.new()
	pickup.set_script(pickup_script)
	# Position on the floor, center of room
	pickup.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - FLOOR_THICKNESS - 15)
	pickup.pickup_collected.connect(_on_shield_collected)
	add_child(pickup)

func _on_shield_collected():
	if fight_active or fight_over:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player:
		start_fight(player)

func start_fight(player):
	fight_active = true
	player.enter_boss2_fight(self)

	if creature:
		creature.start_attacking()

	# Lock camera centered on this room
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.is_locked = true
		camera.global_position.y = global_position.y + ROOM_HEIGHT / 2.0

	print("🏟️ BOSS 2 FIGHT STARTED!")

func _on_creature_hit():
	hits_landed += 1
	print("🏟️ Hits: ", hits_landed, "/", CREATURE_HP)

	if hits_landed >= CREATURE_HP:
		on_boss_defeated()

func on_boss_defeated():
	fight_active = false
	fight_over = true
	GameManager.boss_2_defeated = true

	# Deactivate boss fight on player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.exit_boss2_fight()

	# Creature dies
	if creature and is_instance_valid(creature):
		creature.die()

	# Unlock camera
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.is_locked = false

	# Create ladder so player can continue climbing
	create_victory_ladder()
	print("🎉 BOSS 2 DERROTADO!")

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

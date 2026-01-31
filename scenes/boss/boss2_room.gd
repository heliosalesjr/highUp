# boss2_room.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 320
const WALL_THICKNESS = 6
const FLOOR_THICKNESS = 6
const FLOOR_TILE_WIDTH = 16
const WALL_TILE_HEIGHT = 32
const LADDER_WIDTH = 15

const CREATURE_HP = 3
const ROUND_DELAY = 1.5
const COLOR_REVEAL_DELAY = 0.8
const ROUND_TIME_LIMIT = 1.5

# Boss grows and descends incrementally each round (hit or miss)
const SCALE_PER_STEP = 0.15
const Y_PER_STEP = 25.0
const MAX_SCALE = 2.5
const MAX_Y = 190.0

# 5 platforms spread across the room at jump height
const PLATFORM_POSITIONS = [
	Vector2(50, 258),
	Vector2(120, 248),
	Vector2(180, 255),
	Vector2(240, 248),
	Vector2(310, 258),
]

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
var creature = null
var fight_active = false
var fight_over = false
var hits_landed = 0
var waiting_for_player = false
var player_ref = null
var round_active = false
var active_targets = []
var escalation_step = 0

func _ready():
	create_background()
	create_floor()
	create_walls()
	create_entry_detector()
	create_creature()

func _physics_process(_delta):
	if waiting_for_player and player_ref and is_instance_valid(player_ref):
		if player_ref.is_on_floor() and not player_ref.is_on_ladder:
			waiting_for_player = false
			start_fight(player_ref)

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

func create_creature():
	var creature_script = load("res://scenes/boss/boss2_creature.gd")
	creature = CharacterBody2D.new()
	creature.set_script(creature_script)
	creature.position = Vector2(ROOM_WIDTH / 2.0, 40)
	creature.creature_hit.connect(_on_creature_hit)
	creature.color_changed.connect(_on_boss_color_changed)
	add_child(creature)

func start_fight(player):
	fight_active = true
	player.enter_boss2_fight(self)

	if creature:
		creature.start_attacking()

	# Lock camera
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.is_locked = true
		camera.global_position.y = global_position.y + ROOM_HEIGHT / 2.0

	start_round()

# === ROUND MANAGEMENT ===

func start_round():
	if fight_over:
		return
	spawn_platforms()
	await get_tree().create_timer(COLOR_REVEAL_DELAY).timeout
	if fight_over:
		return
	round_active = true
	creature.start_round()
	assign_platform_colors()
	# Time limit — if player doesn't hit the right one, round ends
	await get_tree().create_timer(ROUND_TIME_LIMIT).timeout
	if not round_active or fight_over:
		return
	on_round_timeout()

func on_round_timeout():
	round_active = false
	# All platforms fall
	for t in active_targets:
		if is_instance_valid(t):
			t.fall()
	active_targets.clear()
	# Boss grows even without taking damage
	escalate_boss()
	await get_tree().create_timer(ROUND_DELAY).timeout
	if not fight_over:
		start_round()

func escalate_boss():
	escalation_step += 1
	if creature and is_instance_valid(creature):
		creature.set_color_white()
		var new_scale = min(1.0 + escalation_step * SCALE_PER_STEP, MAX_SCALE)
		var new_y = min(40 + escalation_step * Y_PER_STEP, MAX_Y)
		creature.grow_closer(new_scale, new_y)

func spawn_platforms():
	active_targets.clear()
	var target_script = load("res://scenes/boss/boss2_target.gd")
	for pos in PLATFORM_POSITIONS:
		var target = Area2D.new()
		target.set_script(target_script)
		target.position = pos
		add_child(target)
		active_targets.append(target)

func assign_platform_colors():
	if not creature:
		return
	var boss_color = creature.get_current_color()
	var other_color = "magenta" if boss_color == "cyan" else "cyan"

	# One random platform matches the boss, the other 4 get the opposite
	var correct_index = randi() % active_targets.size()
	for i in range(active_targets.size()):
		if is_instance_valid(active_targets[i]):
			if i == correct_index:
				active_targets[i].set_target_color(boss_color)
			else:
				active_targets[i].set_target_color(other_color)

func on_target_touched(target_node):
	if not fight_active or fight_over or not round_active:
		return
	if not is_instance_valid(target_node) or target_node.consumed:
		return
	if not creature or not is_instance_valid(creature):
		return

	var target_col = target_node.target_color
	var boss_col = creature.get_current_color()

	if target_col == boss_col:
		# Correct color — boss takes hit, all platforms fall
		round_active = false
		creature.take_hit()
		var camera = get_tree().get_first_node_in_group("camera")
		if camera and camera.has_method("shake"):
			camera.shake(0.3, 15.0)
		for t in active_targets:
			if is_instance_valid(t):
				t.fall()
		active_targets.clear()
	else:
		# Wrong color — player loses heart, only this platform falls
		var player = get_tree().get_first_node_in_group("player")
		if player and not player.is_invulnerable:
			player.trigger_hit_camera_shake()
			var survived = GameManager.take_damage()
			if survived:
				player.start_invulnerability()
			else:
				player.die()
				return
		active_targets.erase(target_node)
		target_node.fall()

func _on_boss_color_changed(_new_color):
	pass

func _on_creature_hit():
	hits_landed += 1

	if hits_landed >= CREATURE_HP:
		on_boss_defeated()
	else:
		# Boss grows even on successful hits
		escalate_boss()
		await get_tree().create_timer(ROUND_DELAY).timeout
		if not fight_over:
			start_round()

func on_boss_defeated():
	fight_active = false
	fight_over = true
	round_active = false
	GameManager.boss_2_defeated = true

	# Drop remaining targets
	for t in active_targets:
		if is_instance_valid(t):
			t.fall()
	active_targets.clear()

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

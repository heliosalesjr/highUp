# boss3_room.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 320
const WALL_THICKNESS = 6
const FLOOR_THICKNESS = 6
const FLOOR_TILE_WIDTH = 16
const WALL_TILE_HEIGHT = 32
const LADDER_WIDTH = 15

const CREATURE_HP = 3
const TOTAL_WAVES = 3
const WAVE_DURATION = 7.0
const WAVE_PAUSE = 2.0
const SPAWN_INTERVALS = [2.0, 1.5, 1.0]
const OBSTACLE_SPEEDS = [100, 140, 180]
const OBSTACLE_Y_MIN = 30
const OBSTACLE_Y_MAX = 290

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
var ceiling_ref = null
var fight_active = false
var fight_over = false
var waiting_for_player = false
var player_ref = null
var wave_active = false
var current_wave = 0
var wave_timer = 0.0
var spawn_timer = 0.0
var active_obstacles = []
var wave_label = null
var center_label = null

func _ready():
	create_background()
	create_floor()
	create_ceiling()
	create_walls()
	create_entry_detector()
	create_creature()
	create_hud()

func _physics_process(delta):
	if waiting_for_player and player_ref and is_instance_valid(player_ref):
		if player_ref.is_on_floor() and not player_ref.is_on_ladder:
			waiting_for_player = false
			start_fight(player_ref)

	if wave_active:
		wave_timer += delta
		spawn_timer += delta

		var interval = SPAWN_INTERVALS[current_wave]
		if spawn_timer >= interval:
			spawn_timer -= interval
			spawn_obstacle()

		if wave_timer >= WAVE_DURATION:
			end_wave()

		# Update wave timer display
		if wave_label:
			var remaining = max(0, WAVE_DURATION - wave_timer)
			wave_label.text = "WAVE %d/%d  -  %.1f" % [current_wave + 1, TOTAL_WAVES, remaining]

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
	# NO one_way_collision — solid ceiling for gravity flip

	# Visual tiles on ceiling
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

func create_creature():
	var creature_script = load("res://scenes/boss/boss3_creature.gd")
	creature = Node2D.new()
	creature.set_script(creature_script)
	creature.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 2.0)
	creature.creature_hit.connect(_on_creature_hit)
	add_child(creature)

func create_hud():
	# Wave counter label (top of room)
	wave_label = Label.new()
	wave_label.name = "WaveLabel"
	wave_label.text = ""
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.position = Vector2(0, 10)
	wave_label.size = Vector2(ROOM_WIDTH, 30)
	wave_label.add_theme_font_size_override("font_size", 14)
	wave_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	wave_label.z_index = 10
	add_child(wave_label)

	# Center message label (big text for announcements)
	center_label = Label.new()
	center_label.name = "CenterLabel"
	center_label.text = ""
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_label.position = Vector2(0, ROOM_HEIGHT / 2.0 - 50)
	center_label.size = Vector2(ROOM_WIDTH, 100)
	center_label.add_theme_font_size_override("font_size", 24)
	center_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	center_label.z_index = 10
	add_child(center_label)

func show_center_message(text: String, duration: float = 1.5):
	if not center_label:
		return
	center_label.text = text
	center_label.modulate.a = 1.0
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(center_label):
		var tween = create_tween()
		tween.tween_property(center_label, "modulate:a", 0.0, 0.3)

func start_fight(player):
	fight_active = true
	player.enter_boss3_fight(self)

	# Lock camera
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.is_locked = true
		camera.global_position.y = global_position.y + ROOM_HEIGHT / 2.0

	# Show instruction
	show_center_message("SOBREVIVA!\nPule para inverter a gravidade!", 1.5)

	# Pause before starting waves
	await get_tree().create_timer(1.5).timeout
	if fight_over:
		return
	start_wave()

func start_wave():
	if fight_over or current_wave >= TOTAL_WAVES:
		return

	# Show wave announcement
	show_center_message("WAVE %d" % [current_wave + 1], 1.0)
	await get_tree().create_timer(1.0).timeout
	if fight_over:
		return

	wave_active = true
	wave_timer = 0.0
	spawn_timer = 0.0
	print("Boss 3 Wave ", current_wave + 1, " started!")

func spawn_obstacle():
	var obstacle_script = load("res://scenes/boss/boss3_obstacle.gd")
	var obstacle = Area2D.new()
	obstacle.set_script(obstacle_script)

	# Random Y between min and max
	var y = randf_range(OBSTACLE_Y_MIN, OBSTACLE_Y_MAX)

	# Random direction
	var dir = 1 if randi() % 2 == 0 else -1
	obstacle.move_direction = dir
	obstacle.speed = OBSTACLE_SPEEDS[current_wave]

	# Start position based on direction
	if dir == 1:
		obstacle.position = Vector2(-30, y)
	else:
		obstacle.position = Vector2(ROOM_WIDTH + 30, y)

	obstacle.body_entered.connect(_on_obstacle_body_entered.bind(obstacle))
	add_child(obstacle)
	active_obstacles.append(obstacle)

func _on_obstacle_body_entered(body, obstacle):
	if body.name == "Player" and not body.is_invulnerable:
		body.trigger_hit_camera_shake()
		var survived = GameManager.take_damage()
		if survived:
			body.start_invulnerability()
		else:
			body.die()
			return
	if is_instance_valid(obstacle):
		obstacle.queue_free()
		active_obstacles.erase(obstacle)

func end_wave():
	wave_active = false

	# Destroy all active obstacles
	for obs in active_obstacles:
		if is_instance_valid(obs):
			obs.queue_free()
	active_obstacles.clear()

	# Boss takes damage
	if creature and is_instance_valid(creature):
		creature.take_hit()
		var camera = get_tree().get_first_node_in_group("camera")
		if camera and camera.has_method("shake"):
			camera.shake(0.3, 15.0)

	current_wave += 1
	print("Boss 3 Wave ", current_wave, " / ", TOTAL_WAVES, " complete!")

	# Show hit feedback
	if current_wave < TOTAL_WAVES:
		show_center_message("ACERTOU!", 1.0)
	else:
		show_center_message("DERROTADO!", 1.5)

	if current_wave >= TOTAL_WAVES:
		# Small delay so player sees the message
		await get_tree().create_timer(1.0).timeout
		on_boss_defeated()
		return

	# Pause between waves — update wave label during pause
	if wave_label:
		wave_label.text = "WAVE %d/%d  -  COMPLETA!" % [current_wave, TOTAL_WAVES]

	await get_tree().create_timer(WAVE_PAUSE).timeout
	if not fight_over:
		start_wave()

func _on_creature_hit():
	pass  # Hit tracking handled in end_wave

func on_boss_defeated():
	fight_active = false
	fight_over = true
	wave_active = false
	GameManager.boss_3_defeated = true

	# Destroy remaining obstacles
	for obs in active_obstacles:
		if is_instance_valid(obs):
			obs.queue_free()
	active_obstacles.clear()

	# Deactivate boss fight on player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.exit_boss3_fight()

	# Creature dies
	if creature and is_instance_valid(creature):
		creature.die()

	# Remove ceiling so player can climb out
	if ceiling_ref and is_instance_valid(ceiling_ref):
		ceiling_ref.queue_free()
		ceiling_ref = null

	# Clear HUD
	if wave_label:
		wave_label.text = ""

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

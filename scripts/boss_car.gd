# boss_car.gd
extends CharacterBody2D

const CAR_SPEED = 200.0
const SHOOT_COOLDOWN = 0.3
const CAR_WIDTH = 48
const CAR_HEIGHT = 16

var direction = 1
var shoot_timer = 0.0
var arena: Node2D = null  # Reference to boss_arena to add bullets as children

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	add_to_group("boss_car")
	collision_layer = 1
	collision_mask = 1  # Collide with walls

	# Visual: red/orange rectangle
	var visual = ColorRect.new()
	visual.size = Vector2(CAR_WIDTH, CAR_HEIGHT)
	visual.position = Vector2(-CAR_WIDTH / 2.0, -CAR_HEIGHT / 2.0)
	visual.color = Color(0.9, 0.3, 0.1)
	add_child(visual)

	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(CAR_WIDTH, CAR_HEIGHT)
	collision.shape = shape
	add_child(collision)

func _physics_process(delta):
	# Apply gravity
	velocity.y += gravity * delta

	# Auto-move horizontally
	velocity.x = direction * CAR_SPEED

	move_and_slide()

	# Bounce off walls
	if is_on_wall():
		direction *= -1

	# Shoot cooldown
	if shoot_timer > 0:
		shoot_timer -= delta

	# Shoot on jump input (space bar = "jump" action)
	if Input.is_action_just_pressed("jump") and shoot_timer <= 0:
		shoot()
		shoot_timer = SHOOT_COOLDOWN

func shoot():
	var bullet_script = load("res://scripts/boss_bullet.gd")
	var bullet = Area2D.new()
	bullet.set_script(bullet_script)

	var spawn_pos = Vector2(global_position.x, global_position.y - CAR_HEIGHT)

	if arena:
		arena.add_child(bullet)
	else:
		get_parent().add_child(bullet)

	# Set position AFTER adding to tree (global_position only works in tree)
	bullet.global_position = spawn_pos

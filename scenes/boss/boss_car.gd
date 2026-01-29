# boss_car.gd
extends CharacterBody2D

signal player_entered

const CAR_SPEED = 200.0
const CAR_WIDTH = 48
const CAR_HEIGHT = 16

var direction = 1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	add_to_group("boss_car")
	# Start with no collision so the player can walk through
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)  # Start stationary

	# Visual: red/orange rectangle
	var visual = ColorRect.new()
	visual.size = Vector2(CAR_WIDTH, CAR_HEIGHT)
	visual.position = Vector2(-CAR_WIDTH / 2.0, -CAR_HEIGHT / 2.0)
	visual.color = Color(0.9, 0.3, 0.1)
	add_child(visual)

	# Collision shape (inactive until start_moving)
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(CAR_WIDTH, CAR_HEIGHT)
	collision.shape = shape
	add_child(collision)

	# Detection area: detects when player walks into the car
	var detect = Area2D.new()
	detect.name = "PlayerDetector"
	detect.collision_layer = 0
	detect.collision_mask = 1  # Detect player body (layer 1)
	detect.monitoring = true

	var detect_collision = CollisionShape2D.new()
	var detect_shape = RectangleShape2D.new()
	detect_shape.size = Vector2(CAR_WIDTH, CAR_HEIGHT + 8)
	detect_collision.shape = detect_shape
	detect.add_child(detect_collision)

	detect.body_entered.connect(_on_player_detected)
	add_child(detect)

func _on_player_detected(body):
	if body.is_in_group("player"):
		player_entered.emit()
		# Remove detector so it doesn't fire again
		var det = get_node_or_null("PlayerDetector")
		if det:
			det.queue_free()

func start_moving():
	collision_layer = 1
	collision_mask = 1  # Collide with walls
	set_physics_process(true)

func _physics_process(delta):
	velocity.y += gravity * delta
	velocity.x = direction * CAR_SPEED
	move_and_slide()
	if is_on_wall():
		direction *= -1

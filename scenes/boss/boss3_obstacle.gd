# boss3_obstacle.gd
extends Area2D

const OBSTACLE_WIDTH = 60
const OBSTACLE_HEIGHT = 8

var speed = 100.0
var move_direction = 1  # 1 = right, -1 = left

func _ready():
	collision_layer = 0
	collision_mask = 1
	monitoring = true

	# Visual: red bar
	var visual = ColorRect.new()
	visual.size = Vector2(OBSTACLE_WIDTH, OBSTACLE_HEIGHT)
	visual.position = Vector2(-OBSTACLE_WIDTH / 2.0, -OBSTACLE_HEIGHT / 2.0)
	visual.color = Color(0.9, 0.15, 0.1)
	visual.name = "Visual"
	add_child(visual)

	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(OBSTACLE_WIDTH, OBSTACLE_HEIGHT)
	collision.shape = shape
	add_child(collision)

func _physics_process(delta):
	position.x += speed * move_direction * delta

	# Remove when out of room bounds
	if position.x < -OBSTACLE_WIDTH or position.x > 360 + OBSTACLE_WIDTH:
		queue_free()

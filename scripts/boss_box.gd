# boss_box.gd
extends Area2D

signal box_destroyed
signal box_reached_floor

var death_line_y = 600.0
var descent_speed = 10.0
var time_alive = 0.0

const BOX_WIDTH = 32
const BOX_HEIGHT = 24
const SPEED_INCREASE_RATE = 0.5  # px/s increase per second alive

func _ready():
	collision_layer = 0
	collision_mask = 33  # 32 (boss bullets) + 1 (car body)
	monitoring = true
	monitorable = true

	# Visual: brown box
	var visual = ColorRect.new()
	visual.size = Vector2(BOX_WIDTH, BOX_HEIGHT)
	visual.position = Vector2(-BOX_WIDTH / 2.0, -BOX_HEIGHT / 2.0)
	visual.color = Color(0.55, 0.35, 0.15)
	visual.name = "Visual"
	add_child(visual)

	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(BOX_WIDTH, BOX_HEIGHT)
	collision.shape = shape
	add_child(collision)

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	time_alive += delta
	var current_speed = descent_speed + (SPEED_INCREASE_RATE * time_alive)
	global_position.y += current_speed * delta

	# Check if reached the floor
	if global_position.y >= death_line_y:
		box_reached_floor.emit()

func _on_area_entered(area: Area2D):
	if area.is_in_group("boss_bullet"):
		area.queue_free()
		_hit_flash()

func _on_body_entered(body):
	if body.is_in_group("boss_car"):
		box_reached_floor.emit()

func _hit_flash():
	var visual = get_node_or_null("Visual")
	if visual:
		visual.color = Color(1, 1, 1)
	await get_tree().create_timer(0.05).timeout
	box_destroyed.emit()
	queue_free()

# boss2_projectile.gd
extends Area2D

const PROJECTILE_SPEED = 200.0
const LIFETIME = 4.0
const WIDTH = 6
const HEIGHT = 10

var direction_y = 1
var is_reflected = false
var visual: ColorRect = null

func _ready():
	collision_layer = 64  # Bit 7 - boss 2 projectile layer
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("boss2_projectile")

	# Visual: red/magenta rectangle
	visual = ColorRect.new()
	visual.size = Vector2(WIDTH, HEIGHT)
	visual.position = Vector2(-WIDTH / 2.0, -HEIGHT / 2.0)
	visual.color = Color(1.0, 0.2, 0.4)
	add_child(visual)

	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(WIDTH, HEIGHT)
	collision.shape = shape
	add_child(collision)

	# Auto-destroy after lifetime
	await get_tree().create_timer(LIFETIME).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta):
	global_position.y += direction_y * PROJECTILE_SPEED * delta

func reflect():
	direction_y = -1
	is_reflected = true
	if visual:
		visual.color = Color(0.0, 1.0, 1.0)  # Cyan

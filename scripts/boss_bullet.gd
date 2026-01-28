# boss_bullet.gd
extends Area2D

const BULLET_SPEED = 500.0
const LIFETIME = 2.0

const BULLET_WIDTH = 4
const BULLET_HEIGHT = 8

func _ready():
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("boss_bullet")

	# Visual: yellow/white rectangle
	var visual = ColorRect.new()
	visual.size = Vector2(BULLET_WIDTH, BULLET_HEIGHT)
	visual.position = Vector2(-BULLET_WIDTH / 2.0, -BULLET_HEIGHT / 2.0)
	visual.color = Color(1.0, 1.0, 0.6)
	add_child(visual)

	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(BULLET_WIDTH, BULLET_HEIGHT)
	collision.shape = shape
	add_child(collision)

	# Auto-destroy after lifetime
	await get_tree().create_timer(LIFETIME).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta):
	global_position.y -= BULLET_SPEED * delta

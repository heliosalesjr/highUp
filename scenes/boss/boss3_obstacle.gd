# boss3_obstacle.gd — Bird that flies across the boss room
extends Node2D

var speed = 150.0
var direction = 1  # 1 = right, -1 = left

func _ready():
	create_animated_sprite()
	create_hitbox()

func create_animated_sprite():
	var bird_texture = preload("res://assets/BirdSprite.png")

	var frames = SpriteFrames.new()
	for i in range(8):
		var atlas = AtlasTexture.new()
		atlas.atlas = bird_texture
		atlas.region = Rect2(i * 16, 16, 16, 16)
		frames.add_frame("default", atlas)
	frames.set_animation_loop("default", true)
	frames.set_animation_speed("default", 10.0)

	var sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.sprite_frames = frames
	sprite.scale = Vector2(2.375, 2.375)
	sprite.position = Vector2(-1, -4)
	sprite.flip_h = direction > 0
	sprite.play("default")
	add_child(sprite)

func create_hitbox():
	var hitbox = Area2D.new()
	hitbox.name = "HitBox"
	hitbox.collision_layer = 0
	hitbox.collision_mask = 1
	hitbox.monitoring = true

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(39, 23)
	collision.shape = shape
	collision.position = Vector2(-0.5, -0.5)

	hitbox.add_child(collision)
	hitbox.body_entered.connect(_on_body_entered)
	add_child(hitbox)

func _process(delta):
	position.x += direction * speed * delta

	# Remove when off screen
	if direction > 0 and position.x > 410:
		queue_free()
	elif direction < 0 and position.x < -50:
		queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		if body.is_invulnerable or body.is_launched:
			return
		body.trigger_hit_camera_shake()
		var survived = GameManager.take_damage()
		if survived:
			body.start_invulnerability()
		else:
			body.die()

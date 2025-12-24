# layout_invincible.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 160

var invincible_scene = preload("res://scenes/powerups/invincible.tscn")

func _ready():
	spawn_invincible()
	create_room_entry_detector()

func spawn_invincible():
	"""Spawna o powerup de invincible no centro da sala"""
	# Verifica se pode spawnar invincible
	if not GameManager.can_spawn_invincible():
		print("💪 Não spawnou invincible: modo já ativo")
		return

	var invincible = invincible_scene.instantiate()
	invincible.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 2.0)
	add_child(invincible)
	print("💪 Invincible powerup spawnado!")

func create_room_entry_detector():
	"""Detecta quando o player entra na sala"""
	var detector = Area2D.new()
	detector.name = "EntryDetector"
	detector.collision_layer = 0
	detector.collision_mask = 1

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
		print("🎯 Sala invincible alcançada!")
		get_node("EntryDetector").queue_free()

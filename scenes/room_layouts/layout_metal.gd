# layout_metal.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 160

var chest_scene = preload("res://scenes/obstacles/chest.tscn")

func _ready():
	spawn_metal_chest()
	create_room_entry_detector()

func spawn_metal_chest():
	"""Spawna o chest com powerup de metal no chão da sala"""
	# Verifica se pode spawnar metal (precisa de 3 corações cheios!)
	if not GameManager.can_spawn_metal_potion():
		print("🛡️ Não spawnou chest de metal: requisitos não atendidos")
		return

	var chest = chest_scene.instantiate()
	chest.powerup_type = "metal"
	# Posiciona no chão, centro horizontal
	chest.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - 25)
	add_child(chest)
	print("📦 Chest de Metal spawnado!")

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
		print("🎯 Sala metal alcançada!")
		get_node("EntryDetector").queue_free()

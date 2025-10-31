# layout_simple_01.gd
extends Node2D

const ROOM_WIDTH = 720
const ROOM_HEIGHT = 320

var rock_scene = preload("res://scenes/obstacles/rock.tscn")

func _ready():
	create_label("SIMPLE 01")
	create_obstacles()

func create_label(text: String):
	var label = Label.new()
	label.text = text
	label.position = Vector2(ROOM_WIDTH / 2.0 - 50, 20)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)

func create_obstacles():
	# Pedra no chão - como sprite tem 40px e está centralizada,
	# precisa subtrair metade da altura (20px) + pequeno ajuste
	create_rock(Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - 20))
func create_rock(pos: Vector2):
	var rock = rock_scene.instantiate()
	rock.position = pos
	add_child(rock)  

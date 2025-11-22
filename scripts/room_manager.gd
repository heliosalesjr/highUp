# room_manager.gd
extends Node

var layouts = {
	"simple": [
		preload("res://scenes/room_layouts/layout_simple_01.tscn"),
		preload("res://scenes/room_layouts/layout_simple_02.tscn"),
		preload("res://scenes/room_layouts/layout_simple_03.tscn"),
		preload("res://scenes/room_layouts/layout_simple_04.tscn"),
		preload("res://scenes/room_layouts/layout_simple_05.tscn"),
		preload("res://scenes/room_layouts/layout_saw.tscn"),
		preload("res://scenes/room_layouts/layout_saw_floor.tscn"),
		preload("res://scenes/room_layouts/layout_cannon.tscn"),
		preload("res://scenes/room_layouts/layout_magnet.tscn")
	],
	"split": [
		preload("res://scenes/room_layouts/layout_split.tscn"),
		preload("res://scenes/room_layouts/layout_split_01.tscn"),
		preload("res://scenes/room_layouts/layout_split_bird.tscn") 
	]
}

var last_layouts = []
const MAX_RECENT = 2

func populate_room(room: Node2D, room_index: int):
	print("  → Populando Room ", room_index)
	
	# Verifica se a sala já foi marcada como split
	var layout_type = "split" if room.is_split_room else "simple"
	
	var layout_scene = _pick_random_layout(layout_type)
	var layout_instance = layout_scene.instantiate()
	layout_instance.name = "Layout"
	
	room.add_child(layout_instance)
	
	print("  ✓ Layout aplicado: ", layout_type)

func _pick_random_layout(type: String):
	var available = layouts[type].duplicate()
	
	if type == "simple" and available.size() > 1:
		for recent in last_layouts:
			if recent in available:
				available.erase(recent)
	
	if available.is_empty():
		available = layouts[type].duplicate()
	
	var chosen = available[randi() % available.size()]
	
	last_layouts.append(chosen)
	if last_layouts.size() > MAX_RECENT:
		last_layouts.pop_front()
	
	return chosen

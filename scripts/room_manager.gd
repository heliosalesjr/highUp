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
		preload("res://scenes/room_layouts/layout_magnet.tscn"),
		preload("res://scenes/room_layouts/layout_mist.tscn"),
		preload("res://scenes/room_layouts/layout_invincible.tscn"),
		preload("res://scenes/room_layouts/layout_metal.tscn"),
		preload("res://scenes/room_layouts/layout_spit.tscn")
	],
	"split": [
		preload("res://scenes/room_layouts/layout_split.tscn"),
		preload("res://scenes/room_layouts/layout_split_01.tscn"),
		preload("res://scenes/room_layouts/layout_split_bird.tscn"),
		preload("res://scenes/room_layouts/layout_split_spike.tscn")
	]
}

# Referências aos layouts especiais para filtragem
var layout_mist_scene = preload("res://scenes/room_layouts/layout_mist.tscn")
var layout_magnet_scene = preload("res://scenes/room_layouts/layout_magnet.tscn")
var layout_invincible_scene = preload("res://scenes/room_layouts/layout_invincible.tscn")
var layout_metal_scene = preload("res://scenes/room_layouts/layout_metal.tscn")

var last_layouts = []
const MAX_RECENT = 2

func populate_room(room: Node2D, room_index: int):
	print("  → Populando Room ", room_index)

	# PRIMEIRA ROOM (index 0) É SEMPRE VAZIA - sem layout
	if room_index == 0:
		print("  ✓ Room 0 (primeira) - VAZIA (sem layout)")
		return

	# Verifica se a sala já foi marcada como split
	var layout_type = "split" if room.is_split_room else "simple"

	var layout_scene = _pick_random_layout(layout_type)
	var layout_instance = layout_scene.instantiate()
	layout_instance.name = "Layout"

	room.add_child(layout_instance)

	print("  ✓ Layout aplicado: ", layout_type)

func _pick_random_layout(type: String):
	var available = layouts[type].duplicate()

	# Remove layouts especiais se seus modos estiverem ativos
	if type == "simple":
		if GameManager.mist_mode_active and layout_mist_scene in available:
			available.erase(layout_mist_scene)
			print("🌫️ Layout mist removido (modo mist ativo)")

		if GameManager.magnet_active and layout_magnet_scene in available:
			available.erase(layout_magnet_scene)
			print("🧲 Layout magnet removido (modo magnet ativo)")

		if GameManager.invincible_mode_active and layout_invincible_scene in available:
			available.erase(layout_invincible_scene)
			print("💪 Layout invincible removido (modo invincible ativo)")

		# Metal precisa de 3 corações cheios E modo não ativo
		if not GameManager.can_spawn_metal_potion() and layout_metal_scene in available:
			available.erase(layout_metal_scene)
			print("🛡️ Layout metal removido (requisitos não atendidos)")

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

extends Node2D

const ROOM_HEIGHT = 320
const SCREEN_HEIGHT = 1280
const INITIAL_ROOMS = 10

var room_scene = preload("res://room.tscn")
var rooms = []
var debug_label: Label

func _ready():
	print("=== MAIN READY ===")
	
	# Pega o label de debug
	debug_label = get_node_or_null("DebugLabel")
	if debug_label:
		debug_label.text = "Main Ready!"
	
	create_rooms()

func create_rooms():
	# Cria salas empilhadas
	# Sala 0 = mais embaixo (Y = 960)
	# Sala 1 = acima dela (Y = 640)
	# Sala 2 = acima dela (Y = 320)
	# Sala 3 = acima dela (Y = 0)
	# etc...
	
	for i in range(INITIAL_ROOMS):
		var room = room_scene.instantiate()
		
		# Alterna escada: par = direita, ímpar = esquerda
		if i % 2 == 0:
			room.ladder_side = 1  # RIGHT
		else:
			room.ladder_side = 0  # LEFT
		
		# Posição Y: primeira sala em 960 (perto do bottom)
		# Cada sala acima tem Y menor
		var y_pos = (SCREEN_HEIGHT - ROOM_HEIGHT) - (i * ROOM_HEIGHT)
		room.position = Vector2(0, y_pos)
		room.name = "Room_" + str(i)
		
		add_child(room)
		rooms.append(room)
		
		print("Room ", i, " criada em Y = ", y_pos)
	
	print("Total de rooms criadas: ", rooms.size())

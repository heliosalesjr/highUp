extends Node2D

const ROOM_HEIGHT = 320
const SCREEN_HEIGHT = 1280
const INITIAL_ROOMS = 10

var room_scene = preload("res://room.tscn")
var rooms = []

func _ready():
	print("=== MAIN READY ===")
	create_rooms()

func create_rooms():
	# Cria salas empilhadas de baixo para cima
	for i in range(INITIAL_ROOMS):
		var room = room_scene.instantiate()
		
		# Alterna escada: par = direita, ímpar = esquerda
		if i % 2 == 0:
			room.ladder_side = 1  # RIGHT
		else:
			room.ladder_side = 0  # LEFT
		
		# Primeira sala em Y=960, cada sala acima tem Y menor
		var y_pos = (SCREEN_HEIGHT - ROOM_HEIGHT) - (i * ROOM_HEIGHT)
		room.position = Vector2(0, y_pos)
		room.name = "Room_" + str(i)
		
		add_child(room)
		rooms.append(room)
		
		print("Room ", i, " criada em Y = ", y_pos)
	
	print("Total de rooms criadas: ", rooms.size())

# Função para criar mais salas conforme o jogador sobe
func create_room_above():
	var i = rooms.size()
	var room = room_scene.instantiate()
	
	if i % 2 == 0:
		room.ladder_side = 1
	else:
		room.ladder_side = 0
	
	var y_pos = (SCREEN_HEIGHT - ROOM_HEIGHT) - (i * ROOM_HEIGHT)
	room.position = Vector2(0, y_pos)
	room.name = "Room_" + str(i)
	
	add_child(room)
	rooms.append(room)

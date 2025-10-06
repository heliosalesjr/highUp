extends Node2D

const ROOM_HEIGHT = 320
const INITIAL_ROOMS = 10  # Número de salas iniciais

var room_scene = preload("res://room.tscn")
var rooms = []
var current_room_count = 0

func _ready():
	create_initial_rooms()

func create_initial_rooms():
	for i in range(INITIAL_ROOMS):
		create_room(i)

func create_room(index: int):
	var room = room_scene.instantiate()
	
	# Alterna o lado da escada: par = direita, ímpar = esquerda
	if index % 2 == 0:
		room.ladder_side = 1  # RIGHT
	else:
		room.ladder_side = 0  # LEFT
	
	# Posiciona a sala (de baixo para cima, começando do topo)
	# Sala 0 fica no topo, sala 1 abaixo dela, etc
	room.position = Vector2(0, -index * ROOM_HEIGHT)
	room.name = "Room" + str(index)
	
	add_child(room)
	rooms.append(room)
	current_room_count += 1

# Função para criar mais salas conforme o jogador sobe
func create_room_above():
	create_room(current_room_count)

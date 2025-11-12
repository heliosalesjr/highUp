# game_manager.gd
extends Node

signal rooms_changed(new_value)
signal diamonds_changed(new_value)
signal hearts_changed(filled_hearts)
signal player_died()

# Dados da partida atual
var rooms_count = 0
var diamonds_count = 0
var filled_hearts = 0
var diamonds_since_last_heart = 0

const DIAMONDS_BEFORE_HEART = 2

# Estatísticas globais (todas as partidas)
var total_diamonds = 0
var highest_room = 0

const SAVE_FILE = "user://save_data.json"

func _ready():
	load_stats()

func add_room():
	rooms_count += 1
	rooms_changed.emit(rooms_count)
	
	# Atualiza recorde
	if rooms_count > highest_room:
		highest_room = rooms_count
		save_stats()
	
	print("📊 Rooms: ", rooms_count)

func add_diamond():
	diamonds_count += 1
	total_diamonds += 1  # ← Adiciona ao total global
	diamonds_changed.emit(diamonds_count)
	diamonds_since_last_heart += 1
	save_stats()  # ← Salva sempre que pega diamante
	
	print("💎 Diamonds: ", diamonds_count, " | Total global: ", total_diamonds)

func add_heart():
	if filled_hearts < 3:
		filled_hearts += 1
		diamonds_since_last_heart = 0
		hearts_changed.emit(filled_hearts)
		print("❤️ Coração adicionado! Total: ", filled_hearts)
	else:
		print("❤️ Já tem 3 corações! (máximo)")

func should_spawn_heart() -> bool:
	return diamonds_since_last_heart >= DIAMONDS_BEFORE_HEART and filled_hearts < 3

func take_damage() -> bool:
	if filled_hearts > 0:
		filled_hearts -= 1
		hearts_changed.emit(filled_hearts)
		print("💔 Perdeu um coração! Restam: ", filled_hearts)
		return true
	else:
		print("💀 Player morreu!")
		player_died.emit()
		return false

func reset():
	"""Reseta apenas os dados da partida atual"""
	rooms_count = 0
	diamonds_count = 0
	filled_hearts = 0
	diamonds_since_last_heart = 0
	rooms_changed.emit(rooms_count)
	diamonds_changed.emit(diamonds_count)
	hearts_changed.emit(filled_hearts)

func save_stats():
	"""Salva as estatísticas globais"""
	var save_data = {
		"total_diamonds": total_diamonds,
		"highest_room": highest_room
	}
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_stats():
	"""Carrega as estatísticas globais"""
	if not FileAccess.file_exists(SAVE_FILE):
		print("📁 Nenhum save encontrado, começando do zero")
		return
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			total_diamonds = save_data.get("total_diamonds", 0)
			highest_room = save_data.get("highest_room", 0)
			print("📁 Save carregado! Diamantes: ", total_diamonds, " | Recorde: ", highest_room)

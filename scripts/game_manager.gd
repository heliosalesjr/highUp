# game_manager.gd
extends Node

signal rooms_changed(new_value)
signal diamonds_changed(new_value)
signal hearts_changed(filled_hearts)
signal player_died()
signal metal_mode_changed(is_active)
signal animal_freed(animal_name)

var rooms_count = 0
var diamonds_count = 0
var filled_hearts = 3
var diamonds_since_last_heart = 0
var metal_mode_active = false
var animals_freed = 0

const DIAMONDS_BEFORE_HEART = 2
const SAVE_FILE = "user://save_data.json"

var total_diamonds = 0
var highest_room = 0

func _ready():
	load_stats()
	filled_hearts = 3
	hearts_changed.emit(filled_hearts)
	print("🧪 TESTE: Começando com 3 corações")
func add_room():
	rooms_count += 1
	rooms_changed.emit(rooms_count)
	
	if rooms_count > highest_room:
		highest_room = rooms_count
		save_stats()
	
	print("📊 Rooms: ", rooms_count)

func add_diamond():
	diamonds_count += 1
	total_diamonds += 1
	diamonds_changed.emit(diamonds_count)
	diamonds_since_last_heart += 1
	save_stats()
	
	print("💎 Diamonds: ", diamonds_count, " | Total global: ", total_diamonds)

func add_heart():
	if filled_hearts < 3:
		filled_hearts += 1
		diamonds_since_last_heart = 0
		hearts_changed.emit(filled_hearts)
		print("❤️ Coração adicionado! Total: ", filled_hearts)
	else:
		print("❤️ Já tem 3 corações! (máximo)")

func can_spawn_heart() -> bool:
	"""Verifica se pode spawnar coração"""
	# NÃO spawna se:
	# - Já tem 3 corações OU
	# - Modo metal está ativo OU
	# - Ainda não coletou diamantes suficientes
	if filled_hearts >= 3:
		print("❌ Não spawna coração: já tem 3")
		return false
	
	if metal_mode_active:
		print("❌ Não spawna coração: modo metal ativo")
		return false
	
	if diamonds_since_last_heart < DIAMONDS_BEFORE_HEART:
		print("❌ Não spawna coração: faltam diamantes")
		return false
	
	print("✅ PODE spawnar coração!")
	return true

func can_spawn_metal_potion() -> bool:
	"""Verifica se pode spawnar poção de metal"""
	# SÓ spawna se:
	# - Modo metal NÃO está ativo E
	# - Tem EXATAMENTE 3 corações cheios
	
	if metal_mode_active:
		print("❌ Não spawna poção: modo metal já ativo")
		return false
	
	if filled_hearts < 3:
		print("❌ Não spawna poção: faltam corações (tem ", filled_hearts, "/3)")
		return false
	
	print("✅ PODE spawnar poção de metal!")
	return true

func activate_metal_mode():
	"""Ativa o modo metal"""
	if metal_mode_active:
		return
	
	metal_mode_active = true
	metal_mode_changed.emit(true)
	print("🛡️ MODO METAL ATIVADO!")

func deactivate_metal_mode():
	"""Desativa o modo metal"""
	if not metal_mode_active:
		return
	
	metal_mode_active = false
	metal_mode_changed.emit(false)
	print("🛡️ Modo metal DESATIVADO!")

func free_animal(animal_name: String):
	"""Registra que um animal foi libertado"""
	animals_freed += 1
	animal_freed.emit(animal_name)
	print("🦋 Animal libertado: ", animal_name, " | Total: ", animals_freed)

func take_damage() -> bool:
	"""Player leva dano"""
	# Se está no modo metal, só desativa o modo (não perde coração)  ← CORRIGIDO
	if metal_mode_active:
		deactivate_metal_mode()
		print("🛡️ Armadura destruída por obstáculo!")
		return true  # Sobreviveu
	
	# Lógica normal de dano
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
	metal_mode_active = false
	animals_freed = 0
	rooms_changed.emit(rooms_count)
	diamonds_changed.emit(diamonds_count)
	hearts_changed.emit(filled_hearts)
	metal_mode_changed.emit(false)

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

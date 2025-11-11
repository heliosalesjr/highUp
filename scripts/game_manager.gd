# game_manager.gd
extends Node

signal rooms_changed(new_value)
signal diamonds_changed(new_value)
signal hearts_changed(filled_hearts)  # ← NOVO

var rooms_count = 0
var diamonds_count = 0
var filled_hearts = 0  # ← NOVO (0 a 3)

const DIAMONDS_PER_HEART = 3  # ← NOVO

func add_room():
	"""Adiciona um ponto de sala"""
	rooms_count += 1
	rooms_changed.emit(rooms_count)
	print("📊 Rooms: ", rooms_count)

func add_diamond():
	"""Adiciona um diamante coletado"""
	diamonds_count += 1
	diamonds_changed.emit(diamonds_count)
	
	# Verifica se completa um coração
	check_hearts()
	
	print("💎 Diamonds: ", diamonds_count)

func check_hearts():
	"""Verifica quantos corações devem estar preenchidos"""
	var new_filled = min(diamonds_count / DIAMONDS_PER_HEART, 3)  # Máximo 3 corações
	
	if new_filled != filled_hearts:
		filled_hearts = new_filled
		hearts_changed.emit(filled_hearts)
		print("❤️ Corações preenchidos: ", filled_hearts)

func reset():
	"""Reseta os contadores"""
	rooms_count = 0
	diamonds_count = 0
	filled_hearts = 0
	rooms_changed.emit(rooms_count)
	diamonds_changed.emit(diamonds_count)
	hearts_changed.emit(filled_hearts)

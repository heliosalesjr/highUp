# game_manager.gd
extends Node

# Sinais para notificar mudanças
signal rooms_changed(new_value)
signal diamonds_changed(new_value)

# Contadores
var rooms_count = 0
var diamonds_count = 0

func add_room():
	"""Adiciona um ponto de sala"""
	rooms_count += 1
	rooms_changed.emit(rooms_count)
	print("📊 Rooms: ", rooms_count)

func add_diamond():
	"""Adiciona um diamante coletado"""
	diamonds_count += 1
	diamonds_changed.emit(diamonds_count)
	print("💎 Diamonds: ", diamonds_count)

func reset():
	"""Reseta os contadores"""
	rooms_count = 0
	diamonds_count = 0
	rooms_changed.emit(rooms_count)
	diamonds_changed.emit(diamonds_count)

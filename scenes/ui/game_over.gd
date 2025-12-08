# game_over.gd
extends Control

@onready var rooms_label = $Panel/StatsContainer/RoomsLabel
@onready var diamonds_label = $Panel/StatsContainer/DiamondsLabel
@onready var stats_container_2 = $Panel/StatsContainer2 
@onready var slugs_saved_label = $Panel/StatsContainer2/SlugsSavedLabel  # ← NOVO
@onready var birds_saved_label = $Panel/StatsContainer2/BirdsSavedLabel  # ← NOVO
@onready var total_animals_saved_label = $Panel/StatsContainer2/TotalAnimalsSavedLabel  # ← NOVO
@onready var ok_button = $Panel/OkButton

func _ready():
	ok_button.pressed.connect(_on_ok_pressed)
	update_stats()

func update_stats():
	"""Atualiza os números da partida"""
	rooms_label.text = "Rooms: " + str(GameManager.rooms_count)
	diamonds_label.text = "Diamonds: " + str(GameManager.diamonds_count)
	
	# Estatísticas de animais salvos  ← NOVO
	slugs_saved_label.text = "Slugs saved: " + str(GameManager.slugs_freed)
	birds_saved_label.text = "Birds saved: " + str(GameManager.birds_freed)
	total_animals_saved_label.text = "Total animals saved: " + str(GameManager.animals_freed)
	if GameManager.animals_freed > 0:
		slugs_saved_label.text = "Slugs saved: " + str(GameManager.slugs_freed)
		birds_saved_label.text = "Birds saved: " + str(GameManager.birds_freed)
		total_animals_saved_label.text = "Total animals saved: " + str(GameManager.animals_freed)
		stats_container_2.visible = true
	else:
		stats_container_2.visible = false
		
	print("📊 Game Over")
	print("  Rooms: ", GameManager.rooms_count)
	print("  Diamonds: ", GameManager.diamonds_count)
	print("  Slugs: ", GameManager.slugs_freed)
	print("  Birds: ", GameManager.birds_freed)
	print("  Total Animals: ", GameManager.animals_freed)

func _on_ok_pressed():
	"""Volta para o menu principal"""
	print("👋 Voltando ao menu...")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

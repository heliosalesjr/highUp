# game_over.gd - Versão que cria labels dinamicamente
extends Control

@onready var rooms_label = $Panel/StatsContainer/RoomsLabel
@onready var diamonds_label = $Panel/StatsContainer/DiamondsLabel
@onready var stats_container = $Panel/StatsContainer
@onready var ok_button = $Panel/OkButton

var slugs_saved_label: Label
var birds_saved_label: Label
var total_animals_saved_label: Label

func _ready():
	ok_button.pressed.connect(_on_ok_pressed)
	
	# Cria labels de animais salvos
	create_animal_labels()
	
	update_stats()

func create_animal_labels():
	"""Cria labels para estatísticas de animais"""
	# Slugs
	slugs_saved_label = Label.new()
	slugs_saved_label.name = "SlugsSavedLabel"
	stats_container.add_child(slugs_saved_label)
	
	# Birds
	birds_saved_label = Label.new()
	birds_saved_label.name = "BirdsSavedLabel"
	stats_container.add_child(birds_saved_label)
	
	# Total
	total_animals_saved_label = Label.new()
	total_animals_saved_label.name = "TotalAnimalsSavedLabel"
	stats_container.add_child(total_animals_saved_label)

func update_stats():
	"""Atualiza os números da partida"""
	rooms_label.text = "Rooms: " + str(GameManager.rooms_count)
	diamonds_label.text = "Diamonds: " + str(GameManager.diamonds_count)
	slugs_saved_label.text = "Slugs saved: " + str(GameManager.slugs_freed)
	birds_saved_label.text = "Birds saved: " + str(GameManager.birds_freed)
	total_animals_saved_label.text = "Total animals saved: " + str(GameManager.animals_freed)
	
	print("📊 Game Over")
	print("  Rooms: ", GameManager.rooms_count)
	print("  Diamonds: ", GameManager.diamonds_count)
	print("  Slugs: ", GameManager.slugs_freed)
	print("  Birds: ", GameManager.birds_freed)
	print("  Total: ", GameManager.animals_freed)

func _on_ok_pressed():
	"""Volta para o menu principal"""
	print("👋 Voltando ao menu...")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

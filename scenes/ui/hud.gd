# hud.gd
extends CanvasLayer

@onready var rooms_label = $ScoreContainer/RoomsLabel
@onready var diamonds_label = $ScoreContainer/DiamondsLabel
@onready var heart1 = $HeartsContainer/Heart1
@onready var heart2 = $HeartsContainer/Heart2
@onready var heart3 = $HeartsContainer/Heart3

# Preload das texturas dos corações
var heart_empty_texture = preload("res://assets/heart_empty.png")  # Ajuste o caminho
var heart_full_texture = preload("res://assets/heart_full.png")    # Ajuste o caminho

func _ready():
	# Conecta aos sinais do GameManager
	GameManager.rooms_changed.connect(_on_rooms_changed)
	GameManager.diamonds_changed.connect(_on_diamonds_changed)
	GameManager.hearts_changed.connect(_on_hearts_changed)  # ← NOVO
	
	# Atualiza valores iniciais
	_on_rooms_changed(GameManager.rooms_count)
	_on_diamonds_changed(GameManager.diamonds_count)
	_on_hearts_changed(GameManager.filled_hearts)  # ← NOVO

func _on_rooms_changed(value: int):
	rooms_label.text = "Rooms: " + str(value)

func _on_diamonds_changed(value: int):
	diamonds_label.text = "Diamonds: " + str(value)

func _on_hearts_changed(filled_count: int):
	"""Atualiza a aparência dos corações"""
	# Array com os 3 corações
	var hearts = [heart1, heart2, heart3]
	
	# Atualiza cada coração
	for i in range(3):
		if i < filled_count:
			hearts[i].texture = heart_full_texture  # Preenchido
		else:
			hearts[i].texture = heart_empty_texture  # Vazio
	
	print("💖 HUD atualizada: ", filled_count, " corações cheios")

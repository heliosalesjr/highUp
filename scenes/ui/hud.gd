# hud.gd
extends CanvasLayer

@onready var rooms_label = $ScoreContainer/RoomsLabel
@onready var diamonds_label = $ScoreContainer/DiamondsLabel

func _ready():
	# Conecta aos sinais do GameManager
	GameManager.rooms_changed.connect(_on_rooms_changed)
	GameManager.diamonds_changed.connect(_on_diamonds_changed)
	
	# Atualiza valores iniciais
	_on_rooms_changed(GameManager.rooms_count)
	_on_diamonds_changed(GameManager.diamonds_count)

func _on_rooms_changed(value: int):
	rooms_label.text = "Rooms: " + str(value)

func _on_diamonds_changed(value: int):
	diamonds_label.text = "Diamonds: " + str(value)

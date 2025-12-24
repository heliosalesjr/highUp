# magnet.gd
extends Area2D

func _ready():
	add_to_group("collectible")  # Para outros magnets poderem atraí-lo
	collision_layer = 64
	collision_mask = 1

	body_entered.connect(_on_body_entered)

	# Conecta ao signal para se esconder se o modo magnet for ativado
	GameManager.magnet_mode_changed.connect(_on_magnet_mode_changed)

	# Verifica se já está ativo ao spawnar
	if GameManager.magnet_active:
		visible = false
		collision_layer = 0
		collision_mask = 0
		print("🧲 Magnet powerup spawnado mas ESCONDIDO (modo já ativo)")
	else:
		create_idle_animation()
		print("🧲 Magnet powerup criado!")

func _on_body_entered(body):
	if body.name == "Player" and body.has_method("activate_magnet"):
		body.activate_magnet()
		print("🧲 Ímã coletado!")
		queue_free()

func _on_magnet_mode_changed(is_active: bool):
	"""Chamado quando o modo magnet muda"""
	if is_active:
		# Se o modo foi ativado, esconde este powerup
		visible = false
		collision_layer = 0
		collision_mask = 0
		print("🧲 Magnet powerup escondido (modo ativado em outro lugar)")
	else:
		# Se o modo foi desativado, mostra novamente
		visible = true
		collision_layer = 64
		collision_mask = 1
		print("🧲 Magnet powerup visível novamente!")

func create_idle_animation():
	var original_y = position.y
	_float(original_y)
	

func _float(original_y):
	if !is_inside_tree(): 
		return  # evita erro caso esteja sendo destruído

	var tween = create_tween().bind_node(self)
	tween.set_loops(1) # executa só uma vez
	
	tween.tween_property(self, "position:y", original_y - 8, 0.6)
	tween.tween_property(self, "position:y", original_y + 8, 0.6)

	# quando o ciclo terminar, chama de novo → animação infinita segura
	tween.tween_callback(func():
		_float(original_y)
	)

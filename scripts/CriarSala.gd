extends Node2D

func _ready():
	$VoltarBotao.pressed.connect(_on_botao_voltar_pressed)
	$ProximoBotao.pressed.connect(_on_botao_proximo_pressed)

func _on_botao_voltar_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_botao_proximo_pressed():
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")


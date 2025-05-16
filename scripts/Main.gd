extends Node2D

func _ready():
	$BotaoStart.pressed.connect(_on_botao_iniciar_pressed)

func _on_botao_iniciar_pressed():
	get_tree().change_scene_to_file("res://scenes/CriarSala1.tscn")

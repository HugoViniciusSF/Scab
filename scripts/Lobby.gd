extends Node2D


func _ready():
	$VoltarBotao.pressed.connect(_on_botao_voltar_pressed)
	$ComecarBotao.pressed.connect(_on_botao_comecar_pressed)

func _on_botao_voltar_pressed():
	get_tree().change_scene_to_file("res://scenes/CriarSala1.tscn")
	
func _on_botao_comecar_pressed():
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

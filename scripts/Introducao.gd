extends Node


@onready var seguir_botao = $SeguirBotao
@onready var voltar_botao = $VoltarBotao

func _ready():
	seguir_botao.pressed.connect(_on_botao_seguir_pressed)
	voltar_botao.pressed.connect(_on_botao_voltar_pressed)
	
func _on_botao_voltar_pressed():
	get_tree().change_scene_to_file("res://scenes/RevelarFuncoes.tscn")

func _on_botao_seguir_pressed():
	get_tree().change_scene_to_file("res://scenes/Introducao.tscn")

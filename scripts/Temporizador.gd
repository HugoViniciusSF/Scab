extends Node2D  # ou Control

@onready var timer = $Timer
@onready var tempo_label = $TempoLabel
@onready var botao_iniciar = $BotaoIniciar
@onready var botao_aumentar = $BotaoAumentar
@onready var botao_diminuir = $BotaoDiminuir
@onready var botao_finalizar = $BotaoFinalizar

var tempo_restante = 120  # 2 minutos em segundos
var em_execucao = false

func _ready():
	atualizar_label()
	botao_iniciar.text = "▶️"
	botao_iniciar.pressed.connect(_on_botao_iniciar_pressed)
	botao_aumentar.pressed.connect(_on_botao_aumentar_pressed)
	botao_diminuir.pressed.connect(_on_botao_diminuir_pressed)
	botao_finalizar.pressed.connect(_on_botao_finalizar_pressed)
	timer.wait_time = 1.0
	timer.timeout.connect(_on_timer_timeout)

func _on_botao_iniciar_pressed():
	if em_execucao:
		parar_temporizador()
	else:
		iniciar_temporizador()

func iniciar_temporizador():
	em_execucao = true
	timer.start()
	botao_iniciar.text = "II"

func parar_temporizador():
	em_execucao = false
	timer.stop()
	botao_iniciar.text = "▶️"

func _on_botao_aumentar_pressed():
	tempo_restante += 60  # adiciona 1 minuto
	atualizar_label()

func _on_botao_diminuir_pressed():
	tempo_restante = max(tempo_restante - 30, 0)  # tira 30 segundos, mas nunca abaixo de 0
	atualizar_label()

func _on_botao_finalizar_pressed():
	parar_temporizador()
	get_tree().change_scene_to_file("res://scenes/Votacao.tscn")

func _on_timer_timeout():
	if tempo_restante > 0:
		tempo_restante -= 1
		atualizar_label()
	else:
		parar_temporizador()

func atualizar_label():
	var minutos = tempo_restante / 60
	var segundos = tempo_restante % 60
	tempo_label.text = "%02d:%02d" % [minutos, segundos]

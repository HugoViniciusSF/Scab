extends Node2D

@onready var proximo_botao = $ProximoBotao
@onready var quantidade_input = $QuantidadeJogadoresLabel/QuantidadeJogadoresLine

func _ready():
	$VoltarBotao.pressed.connect(_on_botao_voltar_pressed)
	proximo_botao.pressed.connect(_on_botao_proximo_pressed)
	quantidade_input.text_changed.connect(_on_quantidade_text_changed)

	# Desativa botão inicialmente
	proximo_botao.disabled = true

func _on_botao_voltar_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_botao_proximo_pressed():
	var configuracoes = {
		"revelar_funcoes": $GeralLabel/RevelarCheckBox.button_pressed,
		"sem_mortes_noite": $GeralLabel/SemMortesCheckBox.button_pressed,
		"habilitar_acoes": $GeralLabel/AcoesCheckBox.button_pressed,

		"pular_votacao": $VotacaoLabel/PularVotosCheckBox.button_pressed,
		"esconder_votos": $VotacaoLabel/EsconderVotosCheckBox.button_pressed,

		"quantidade_jogadores": int(quantidade_input.text)
	}

	JogoGlobal.configuracoes_sala = configuracoes
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _on_quantidade_text_changed(new_text):
	# Ativa o botão apenas se for número válido maior que 0
	var valor = new_text.strip_edges()
	if valor.is_valid_int() and int(valor) > 0:
		proximo_botao.disabled = false
	else:
		proximo_botao.disabled = true

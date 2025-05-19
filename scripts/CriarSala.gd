extends Node2D

func _ready():
	$VoltarBotao.pressed.connect(_on_botao_voltar_pressed)
	$ProximoBotao.pressed.connect(_on_botao_proximo_pressed)

func _on_botao_voltar_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_botao_proximo_pressed():
	# Coletar as configurações dos CheckBoxes e LineEdit
	var configuracoes = {
		"revelar_funcoes": $GeralLabel/RevelarCheckBox.button_pressed,
		"sem_mortes_noite": $GeralLabel/SemMortesCheckBox.button_pressed,
		"habilitar_acoes": $GeralLabel/AcoesCheckBox.button_pressed,
		
		"pular_votacao": $VotacaoLabel/PularVotosCheckBox.button_pressed,
		"esconder_votos": $VotacaoLabel/EsconderVotosCheckBox.button_pressed,

		"quantidade_jogadores": int($QuantidadeJogadoresLabel/QuantidadeJogadoresLine.text)
	}

	# Salvar no autoload (singleton)
	JogoGlobal.configuracoes_sala = configuracoes

	# Ir para próxima cena
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

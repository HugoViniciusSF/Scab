extends Node2D

@onready var container = $ScrollContainer/ConfiguracoesContainer

func _ready():
	$VoltarBotao.pressed.connect(_on_botao_voltar_pressed)
	$ComecarBotao.pressed.connect(_on_botao_comecar_pressed)

	mostrar_configuracoes()

func _on_botao_voltar_pressed():
	get_tree().change_scene_to_file("res://scenes/CriarSala1.tscn")

func _on_botao_comecar_pressed():
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func mostrar_configuracoes():
	container.add_child(criar_titulo("Configurações da Sala:"))

	for chave in JogoGlobal.configuracoes_sala.keys():
		var valor = JogoGlobal.configuracoes_sala[chave]

		# Sempre mostrar a quantidade de jogadores
		if chave == "quantidade_jogadores":
			var label = Label.new()
			label.text = "Quantidade de Jogadores: %s" % valor
			container.add_child(label)
			continue

		# Mostrar apenas as opções booleanas que estão como true
		if typeof(valor) == TYPE_BOOL and valor:
			var nome_formatado = chave.capitalize().replace("_", " ")
			var label = Label.new()
			label.text = "%s: Sim" % nome_formatado
			container.add_child(label)

func criar_titulo(texto: String) -> Label:
	var titulo = Label.new()
	titulo.text = texto
	titulo.add_theme_color_override("font_color", Color(1, 1, 1)) # branco
	titulo.add_theme_font_size_override("font_size", 20)
	return titulo

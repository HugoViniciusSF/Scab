extends Node2D

var jogadores = []
var indice_jogador_atual = 0
var configuracoes = {}
var voto_selecionado = null
var botao_selecionado = null
var votacao_path = "user://Votacao.txt"

@onready var container_botoes = $VBoxContainer/GridContainer
@onready var label_jogador = $VBoxContainer/Label
@onready var botao_pular = $VBoxContainer/ButtonPular
@onready var botao_confirmar = $VBoxContainer/ButtonConfirmar

func _ready():
	# Conecta os sinais dos botões
	botao_confirmar.pressed.connect(_on_ButtonConfirmar_pressed)
	botao_pular.pressed.connect(_on_ButtonPular_pressed)

	carregar_configuracoes()
	carregar_jogadores()
	configurar_pular_visivel()
	exibir_jogador_atual()

func carregar_jogadores():
	var file = FileAccess.open("user://jogadores.txt", FileAccess.READ)
	if file == null:
		push_error("Erro ao abrir jogadores.txt")
		return

	jogadores.clear()
	while not file.eof_reached():
		var line = file.get_line()
		if line.begins_with("ID "):
			var partes = line.split(" - ")
			if partes.size() >= 2:
				var nome_completo = partes[1].split(":")[0].strip_edges()
				jogadores.append(nome_completo)
	file.close()

func carregar_configuracoes():
	var file = FileAccess.open("user://configuracoes_sala.txt", FileAccess.READ)
	if file == null:
		push_error("Erro ao abrir configuracoes_sala.txt")
		return

	while not file.eof_reached():
		var line = file.get_line()
		var partes = line.split(":")
		if partes.size() == 2:
			var chave = partes[0].strip_edges()
			var valor = partes[1].strip_edges().to_lower()
			configuracoes[chave] = valor == "true"
	file.close()

func exibir_jogador_atual():
	if indice_jogador_atual >= jogadores.size():
		print("Todos já votaram.")
		get_tree().change_scene_to_file("res://prox_cena.tscn")
		return

	voto_selecionado = null
	botao_selecionado = null
	label_jogador.text = "Você é: " + jogadores[indice_jogador_atual]
	gerar_botoes_votacao()

func gerar_botoes_votacao():
	# Limpa os botões antigos
	for child in container_botoes.get_children():
		child.queue_free()

	var atual = jogadores[indice_jogador_atual]
	for jogador in jogadores:
		if jogador != atual:
			var botao = Button.new()
			botao.text = jogador
			# Captura o valor da variável jogador para cada botão
			botao.pressed.connect(func(nome = jogador) -> void:
				_on_voto_selecionado(nome)
			)
			container_botoes.add_child(botao)

	# Botão pular extra (opcional)
	if configuracoes.get("pular_votacao", false):
		var botao_pular_extra = Button.new()
		botao_pular_extra.text = "Pular Votação"
		botao_pular_extra.pressed.connect(func() -> void:
			_on_voto_selecionado("PULAR")
		)
		container_botoes.add_child(botao_pular_extra)

func _on_voto_selecionado(nome):
	voto_selecionado = nome
	print("Voto selecionado:", nome)

	# Remove cor do botão anterior
	if botao_selecionado:
		botao_selecionado.remove_theme_color_override("font_color")
		botao_selecionado = null

	# Marca o botão selecionado com verde
	for botao in container_botoes.get_children():
		if botao.text == nome:
			botao.add_theme_color_override("font_color", Color(0,1,0))
			botao_selecionado = botao
			break

func configurar_pular_visivel():
	botao_pular.visible = configuracoes.get("pular_votacao", false)

func _on_ButtonPular_pressed():
	_on_voto_selecionado("PULAR")

func _on_ButtonConfirmar_pressed():
	if voto_selecionado:
		confirmar_voto()
	else:
		print("Selecione um jogador ou pule a votação.")

func confirmar_voto():
	var atual = jogadores[indice_jogador_atual]
	var registro = "%s votou em %s\n" % [atual, voto_selecionado]

	var file = FileAccess.open(votacao_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end() # posiciona o ponteiro no fim do arquivo para acrescentar conteúdo
		file.store_string(registro)
		file.close()
		print("Voto salvo:", registro)
	else:
		push_error("Erro ao salvar voto.")

	indice_jogador_atual += 1
	exibir_jogador_atual()

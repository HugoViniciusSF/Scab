extends Node2D

var jogadores = []
var lider_sindical_nome: String = "" 
var indice_jogador_atual = 0
var configuracoes = {}
var voto_selecionado = null
var botao_selecionado = null
var votacao_path = "user://Votacao.txt"
var resultados_votacao_path = "user://RevelarVotacao.txt"
var lider_sindical_primeiro_voto_concluido = false

@onready var container_botoes = $ScrollContainer/CenterContainer/GridContainer
@onready var label_jogador = $LabelJogador
@onready var botao_pular = $VBoxContainer/ButtonPular
@onready var botao_confirmar = $VBoxContainer/ButtonConfirmar
@onready var botao_revelar_votacao = $"VBoxContainer/ButtonRevelarVotacao"  

func _ready():
	# Limpa o arquivo de votação no início de cada nova sessão
	limpar_arquivo_votacao() # <--- ADIÇÃO IMPORTANTE AQUI

	# Conecta os sinais dos botões
	botao_confirmar.pressed.connect(_on_ButtonConfirmar_pressed)
	botao_pular.pressed.connect(_on_ButtonPular_pressed)
	botao_revelar_votacao.pressed.connect(_on_ButtonRevelarVotacao_pressed)

	carregar_configuracoes()
	carregar_jogadores()
	
	configurar_pular_visivel()
	botao_revelar_votacao.visible = false 
	lider_sindical_primeiro_voto_concluido = false 
	exibir_jogador_atual()

func limpar_arquivo_votacao():
	# Abre o arquivo em modo de escrita, o que o apaga se existir ou cria se não existir.
	var file = FileAccess.open(votacao_path, FileAccess.WRITE)
	if file == null:
		push_error("Erro ao limpar Votacao.txt. O arquivo pode estar bloqueado ou o caminho inválido.")
		return
	file.close()
	print("Votacao.txt limpo com sucesso para uma nova rodada.")

func carregar_jogadores():
	var file = FileAccess.open("user://jogadores.txt", FileAccess.READ)
	if file == null:
		push_error("Erro ao abrir jogadores.txt")
		return

	jogadores.clear()
	lider_sindical_nome = ""
	
	while not file.eof_reached():
		var line = file.get_line()
		if line.begins_with("ID "):
			var partes = line.split(" - ")
			if partes.size() >= 2:
				var info_jogador_e_papel = partes[1].split("|")[0].strip_edges()
				
				var nome_completo = info_jogador_e_papel.split(":")[0].strip_edges()
				var papel_com_faccao = info_jogador_e_papel.split(":")[1].strip_edges()
				
				var papel_somente = papel_com_faccao.split(" (")[0].strip_edges()
				
				jogadores.append(nome_completo)
				
				if papel_somente == "Líder Sindical":
					lider_sindical_nome = nome_completo
					print("Líder Sindical identificado: ", lider_sindical_nome)

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
		print("Todos já votaram. Exibindo botão de revelar votação.")
		label_jogador.text = "Votação Concluída!"
		container_botoes.hide()
		botao_pular.hide()
		botao_confirmar.hide()
		botao_revelar_votacao.visible = true
		return

	voto_selecionado = null
	botao_selecionado = null 
	
	var nome_jogador_atual = jogadores[indice_jogador_atual]
	var texto_label_jogador = "Você é: " + nome_jogador_atual
	
	
	if nome_jogador_atual == lider_sindical_nome and lider_sindical_primeiro_voto_concluido:
		texto_label_jogador += " (Segundo Voto)"
		
	label_jogador.text = texto_label_jogador
	gerar_botoes_votacao() 
	
func gerar_botoes_votacao():
	for child in container_botoes.get_children():
		child.queue_free()

	var atual = jogadores[indice_jogador_atual]
	for jogador in jogadores:
		if jogador != atual and jogador != lider_sindical_nome:
			var botao = Button.new()
			botao.text = jogador
			botao.custom_minimum_size = Vector2(120, 120)

			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0)
			style.set_border_width_all(0)
			style.corner_radius_top_left = 60
			style.corner_radius_top_right = 60
			style.corner_radius_bottom_left = 60
			style.corner_radius_bottom_right = 60

			botao.add_theme_stylebox_override("normal", style)
			botao.add_theme_stylebox_override("hover", style)
			botao.add_theme_stylebox_override("pressed", style)
			botao.add_theme_stylebox_override("disabled", style)
			botao.add_theme_stylebox_override("focus", style)
			botao.add_theme_stylebox_override("focus_hover", style)
			botao.focus_mode = Control.FOCUS_NONE

			botao.pressed.connect(func(nome = jogador) -> void:
				_on_voto_selecionado(nome)
			)
			container_botoes.add_child(botao)

func _on_voto_selecionado(nome):
	voto_selecionado = nome
	print("Voto selecionado:", nome)

	if botao_selecionado:
		botao_selecionado.remove_theme_color_override("font_color")
		botao_selecionado = null

	for botao in container_botoes.get_children():
		if botao.text == nome:
			botao.add_theme_color_override("font_color", Color(0, 1, 0))
			botao_selecionado = botao
			break

func configurar_pular_visivel():
	botao_pular.visible = configuracoes.get("pular_votacao", false)

func _on_ButtonPular_pressed():
	_on_voto_selecionado("PULAR")
	confirmar_voto()

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
		file.seek_end()
		file.store_string(registro)
		file.close()
		print("Voto salvo: ", registro.strip_edges()) 
	else:
		push_error("Erro ao salvar voto para o jogador: " + atual)

	
	if atual == lider_sindical_nome:
		if not lider_sindical_primeiro_voto_concluido:
			
			lider_sindical_primeiro_voto_concluido = true
			print("Líder Sindical (%s) completou o primeiro voto. Preparando para o segundo voto." % atual)
			
		else:
			
			lider_sindical_primeiro_voto_concluido = false 
			indice_jogador_atual += 1 
			print("Líder Sindical (%s) completou o segundo voto. Próximo jogador." % atual)
	else:
		
		indice_jogador_atual += 1
	
	exibir_jogador_atual()
	
func salvar_resultados_votacao():
	var votos = {}
	
	for jogador in jogadores:
		
		if jogador != lider_sindical_nome:
			votos[jogador] = 0
	
	
	if configuracoes.get("pular_votacao", false):
		votos["PULAR"] = 0

	
	var file = FileAccess.open(votacao_path, FileAccess.READ)
	if file == null:
		push_error("Erro ao abrir Votacao.txt para somar os votos.")
		return

	while not file.eof_reached():
		var line = file.get_line()
		var partes = line.split(" votou em ")
		if partes.size() == 2:
			var voto_recebido = partes[1].strip_edges()
			if votos.has(voto_recebido):
				votos[voto_recebido] += 1
	file.close()

	var mais_votados = [] 
	var max_votos = -1
	
	var esconder_numero_votos = configuracoes.get("esconder_numero_votos", false)
	
	var output_file = FileAccess.open(resultados_votacao_path, FileAccess.WRITE)
	if output_file == null:
		push_error("Erro ao criar RevelarVotacao.txt para salvar os resultados.")
		return

	var votos_ordenados = []
	for jogador_alvo in votos.keys():
		votos_ordenados.append({"nome": jogador_alvo, "votos": votos[jogador_alvo]})
	
	votos_ordenados.sort_custom(func(a, b): return a.votos > b.votos)
	
	output_file.store_string("Resultados da Votação:\n")
	output_file.store_string("------------------------\n")
	
	for item in votos_ordenados:
		var linha_resultado = item.nome
		if not esconder_numero_votos:
			linha_resultado += ": " + str(item.votos) + " votos"
		output_file.store_string(linha_resultado + "\n")
		
		if item.nome != "PULAR":
			if item.votos > max_votos:
				max_votos = item.votos
				mais_votados = [item.nome]
			elif item.votos == max_votos:
				mais_votados.append(item.nome) 
	
	output_file.store_string("------------------------\n")
	
	if mais_votados.size() == 1 and mais_votados[0] != "":
		output_file.store_string("Jogador mais votado para expulsão: " + mais_votados[0] + "\n")
	elif mais_votados.size() > 1:
		output_file.store_string("Empate na votação! Ninguém foi expulso.\n")
		output_file.store_string("Jogadores empatados: " + ", ".join(mais_votados) + "\n")
	else:
		output_file.store_string("Não houve votos válidos para expulsão ou todos pularam.\n")

	output_file.close()
	print("Resultados da votação salvos em:", resultados_votacao_path)

func _on_ButtonRevelarVotacao_pressed():
	salvar_resultados_votacao()
	get_tree().change_scene_to_file("res://scenes/RevelarVotacao.tscn")

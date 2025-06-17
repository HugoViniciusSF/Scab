extends Node2D

# --- Referências dos Nós da Cena ---
@onready var geral_label: RichTextLabel = $GeralLabel
@onready var votacao_container: VBoxContainer = $VotacaoContainer
@onready var painel_acoes: HBoxContainer = $PainelAcoes
@onready var botao_reviver: Button = $PainelAcoes/BotaoReviver
@onready var botao_beber: Button = $PainelAcoes/BotaoBeber
@onready var botao_negociar: Button = $PainelAcoes/BotaoNegociar
@onready var botao_avancar: Button = $BotaoAvancarParaNoite
@onready var painel_matematica = $PainelMatematica
@onready var label_pergunta_matematica = $PainelMatematica/LabelPergunta
@onready var input_resposta_matematica = $PainelMatematica/InputResposta
@onready var botao_confirmar_matematica = $PainelMatematica/BotaoConfirmarResposta

# --- Variáveis de Controle ---
var resposta_correta_matematica = 0

# --- INICIALIZAÇÃO ---
func _ready():
	GameManager.iniciar_logica_do_dia()
	configurar_interface_para_jogador_atual()

# --- LÓGICA PRINCIPAL DE CONFIGURAÇÃO DA INTERFACE ---
func configurar_interface_para_jogador_atual():
	# Conecta os sinais dos botões (com segurança para evitar reconexões)
	if not botao_avancar.is_connected("pressed", _on_finalizar_turno_pressed):
		botao_avancar.pressed.connect(_on_finalizar_turno_pressed)
	if not botao_reviver.is_connected("pressed", _on_botao_reviver_pressed):
		botao_reviver.pressed.connect(_on_botao_reviver_pressed)
	if not botao_beber.is_connected("pressed", _on_botao_beber_pressed):
		botao_beber.pressed.connect(_on_botao_beber_pressed)
	if not botao_negociar.is_connected("pressed", _on_botao_negociar_pressed):
		botao_negociar.pressed.connect(_on_botao_negociar_pressed)
	if not botao_confirmar_matematica.is_connected("pressed", _on_botao_confirmar_resposta_pressed):
		botao_confirmar_matematica.pressed.connect(_on_botao_confirmar_resposta_pressed)
	
	botao_avancar.text = "Finalizar Turno"
	_mostrar_resumo_e_titulo()
	_preparar_paineis_de_acao()
	_popular_lista_de_votacao()

# --- FUNÇÕES DE MONTAGEM DA UI ---

func _mostrar_resumo_e_titulo():
	geral_label.clear()
	var jogador_info = GameManager.jogadores[GameManager.jogador_atual_id]
	geral_label.append_text("[center][b]DIA - Turno de: %s (%s)[/b][/center]\n\n" % [jogador_info.nome, jogador_info.papel])
	if GameManager.eventos_da_noite.is_empty():
		geral_label.append_text("A noite foi estranhamente silenciosa.\n")
	else:
		for evento in GameManager.eventos_da_noite:
			geral_label.append_text("- " + evento + "\n")
	var id_atual = GameManager.jogador_atual_id
	if GameManager.resultados_investigacao.has(id_atual):
		var resultado_privado = GameManager.resultados_investigacao[id_atual]
		geral_label.append_text("\n[color=yellow]Mensagem para você (Fiscalizador):[/color] " + resultado_privado)

func _preparar_paineis_de_acao():
	botao_reviver.hide(); botao_beber.hide(); botao_negociar.hide()
	painel_matematica.hide()
	
	var papel_jogador = GameManager.get_papel(GameManager.jogador_atual_id)
	var tem_acao_especial = true
	match papel_jogador:
		"Doador Sindical": botao_reviver.show()
		"Cachaceiro": botao_beber.show()
		"Traficante": botao_negociar.show()
		_: tem_acao_especial = false
		
	if not tem_acao_especial:
		_gerar_problema_matematico()
		painel_matematica.show()

func _popular_lista_de_votacao():
	for child in votacao_container.get_children():
		child.queue_free()
	var jogadores_vivos = GameManager.get_jogadores_vivos(GameManager.jogador_atual_id)
	for jogador in jogadores_vivos:
		var player_card = HBoxContainer.new()
		var nome_label = Label.new()
		nome_label.text = jogador.nome
		nome_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var votar_button = Button.new()
		votar_button.name = "VoteButton"
		votar_button.text = "Votar"
		votar_button.pressed.connect(_on_voto_registrado.bind(jogador.id))
		player_card.add_child(nome_label)
		player_card.add_child(votar_button)
		votacao_container.add_child(player_card)


# --- FUNÇÕES DE CALLBACK (AÇÕES DO JOGADOR) ---

func _on_voto_registrado(id_alvo: int):
	var id_votante = GameManager.jogador_atual_id
	var papel_votante = GameManager.get_papel(id_votante)
	var peso_voto = 1
	if papel_votante == "Líder Sindical":
		peso_voto = 2
	GameManager.registrar_voto(id_votante, id_alvo, peso_voto)
	var nome_alvo = GameManager.jogadores[id_alvo].nome
	geral_label.append_text("\n[color=cyan]Você votou em %s.[/color]" % nome_alvo)
	for card in votacao_container.get_children():
		var botao = card.get_node_or_null("VoteButton")
		if botao:
			botao.disabled = true

func _on_finalizar_turno_pressed():
	botao_avancar.disabled = true
	GameManager.avancar_para_proximo_jogador_dia()


# --- CALLBACKS DAS AÇÕES ESPECIAIS ---

func _gerar_problema_matematico():
	var n1 = randi() % 10 + 1
	var n2 = randi() % 10 + 1
	resposta_correta_matematica = n1 + n2
	label_pergunta_matematica.text = "Resolva para continuar:\nQuanto é {n1} + {n2}?".format({"n1": n1, "n2": n2})
	input_resposta_matematica.clear()
	input_resposta_matematica.editable = true
	botao_confirmar_matematica.disabled = false

func _on_botao_reviver_pressed():
	if GameManager.banco_solidariedade >= 2:
		GameManager.banco_solidariedade -= 2
		geral_label.append_text("\n[color=green]Você gastou 2 fichas e reviveu um aliado![/color]")
		# Aqui você adicionaria a lógica para escolher quem reviver
		botao_reviver.disabled = true
	else:
		geral_label.append_text("\n[color=red]Banco sem fichas suficientes![/color]")

func _on_botao_beber_pressed():
	if GameManager.banco_solidariedade >= 1:
		GameManager.banco_solidariedade -= 1
		geral_label.append_text("\n[color=orange]Você bebeu e causou um evento aleatório![/color]")
		# Aqui você adicionaria a lógica para sortear o efeito
		botao_beber.disabled = true
	else:
		geral_label.append_text("\n[color=red]Banco sem fichas suficientes![/color]")
		
func _on_botao_negociar_pressed():
	geral_label.append_text("\n[color=yellow]Você iniciou uma negociação com o Diretor...[/color]")
	# Aqui você adicionaria a lógica de negociação
	botao_negociar.disabled = true

func _on_botao_confirmar_resposta_pressed():
	var resposta_do_jogador = input_resposta_matematica.text
	geral_label.append_text("\n[color=gray]Sua resposta ao problema foi registrada.[/color]")
	print("Jogador {id} respondeu '{resp}'.".format({
		"id": GameManager.jogador_atual_id,
		"resp": resposta_do_jogador
	}))
	input_resposta_matematica.editable = false
	botao_confirmar_matematica.disabled = true

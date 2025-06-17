# Dia.gd (Correção do botão de voto)
extends Node2D

# --- Referências para os Nós da Cena ---
@onready var geral_label = $GeralLabel
@onready var votacao_container = $VotacaoContainer
@onready var painel_acoes = $PainelAcoes
@onready var botao_reviver = $PainelAcoes/BotaoReviver
@onready var botao_beber = $PainelAcoes/BotaoBeber
@onready var botao_negociar = $PainelAcoes/BotaoNegociar
@onready var botao_avancar = $BotaoAvancarParaNoite
@onready var painel_matematica = $PainelMatematica
@onready var label_pergunta_matematica = $PainelMatematica/LabelPergunta
@onready var input_resposta_matematica = $PainelMatematica/InputResposta
@onready var botao_confirmar_matematica = $PainelMatematica/BotaoConfirmarResposta

# --- Variáveis de Controle ---
var votos = {}
var resposta_correta_matematica = 0

func _ready():
	_mostrar_resumo_da_noite()
	_preparar_paineis_de_acao()
	_popular_lista_de_votacao()
	botao_avancar.pressed.connect(self._on_avancar_para_noite_pressed)
	botao_confirmar_matematica.pressed.connect(self._on_botao_confirmar_resposta_pressed)


func _mostrar_resumo_da_noite():
	geral_label.clear()
	geral_label.append_text("[center][b]O dia amanhece na fábrica...[/b][/center]\n\n")
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
	botao_reviver.hide()
	botao_beber.hide()
	botao_negociar.hide()
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


func _gerar_problema_matematico():
	var n1 = randi() % 10 + 1
	var n2 = randi() % 10 + 1
	resposta_correta_matematica = n1 + n2
	label_pergunta_matematica.text = "Resolva para continuar:\nQuanto é {n1} + {n2}?".format({"n1": n1, "n2": n2})
	input_resposta_matematica.clear()
	input_resposta_matematica.editable = true
	botao_confirmar_matematica.disabled = false


# --- FUNÇÃO MODIFICADA ---
func _popular_lista_de_votacao():
	for child in votacao_container.get_children():
		child.queue_free()
	var jogadores_vivos = GameManager.get_jogadores_vivos()
	for jogador in jogadores_vivos:
		var player_card = HBoxContainer.new()
		var nome_label = Label.new()
		nome_label.text = jogador.nome + " (" + jogador.papel + ")"
		nome_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var votar_button = Button.new()
		
		# ===== CORREÇÃO 1: Dando um nome ao botão =====
		votar_button.name = "VoteButton" 
		
		votar_button.text = "Votar"
		votar_button.pressed.connect(self._on_voto_registrado.bind(jogador.id))
		player_card.add_child(nome_label)
		player_card.add_child(votar_button)
		votacao_container.add_child(player_card)


# --- FUNÇÃO MODIFICADA ---
func _on_voto_registrado(id_alvo):
	var id_votante = GameManager.jogador_atual_id
	var papel_votante = GameManager.get_papel(id_votante)
	var peso_voto = 1
	if papel_votante == "Líder Sindical":
		peso_voto = 2
	if not votos.has(id_alvo):
		votos[id_alvo] = 0
	votos[id_alvo] += peso_voto
	var nome_alvo = GameManager.jogadores[id_alvo].nome
	geral_label.append_text("\n[color=cyan]Você votou em {nome} com peso {peso}.[/color]".format({
		"nome": nome_alvo,
		"peso": peso_voto
	}))
	
	# ===== CORREÇÃO 2: Usando o nome correto para encontrar o botão =====
	for card in votacao_container.get_children():
		card.get_node("VoteButton").disabled = true


# ... (O resto do script permanece igual) ...

func _on_botao_reviver_pressed():
	if GameManager.banco_solidariedade >= 2:
		GameManager.banco_solidariedade -= 2
		geral_label.append_text("\n[color=green]Você gastou 2 fichas e reviveu um aliado![/color]")
		botao_reviver.disabled = true
	else:
		geral_label.append_text("\n[color=red]Banco sem fichas suficientes![/color]")

func _on_botao_beber_pressed():
	if GameManager.banco_solidariedade >= 1:
		GameManager.banco_solidariedade -= 1
		geral_label.append_text("\n[color=orange]Você bebeu e causou um evento aleatório![/color]")
		botao_beber.disabled = true
	else:
		geral_label.append_text("\n[color=red]Banco sem fichas suficientes![/color]")
		
func _on_botao_negociar_pressed():
	geral_label.append_text("\n[color=yellow]Você iniciou uma negociação com o Diretor...[/color]")
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

func _on_avancar_para_noite_pressed():
	var organizador = GameManager.get_jogador_por_papel("Organizador")
	if organizador and GameManager.jogador_fez_troca(organizador.id):
		GameManager.adicionar_fichas_pessoais(organizador.id, 1)
		print("Organizador ganhou +1 ficha por troca.")
	get_tree().change_scene_to_file("res://scenes/Noite.tscn")

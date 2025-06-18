extends Node2D

# --- Referências para os Nós da Cena ---
@onready var painel_aguardando = $PainelAguardando
@onready var painel_fiscalizador = $PainelFiscalizador
@onready var painel_espiao = $PainelEspiao
@onready var painel_matematica = $PainelMatematica
@onready var lista_jogadores_fiscalizador = $PainelFiscalizador/ListaJogadores
@onready var lista_jogadores_espiao = $PainelEspiao/ListaJogadores
@onready var titulo_label = $TituloLabel
@onready var botao_avancar = $BotaoAvancarParaDebate

# Referências específicas para o painel de matemática para maior segurança
@onready var label_pergunta_matematica = $PainelMatematica/LabelPergunta
@onready var input_resposta_matematica = $PainelMatematica/InputResposta

# --- Variáveis de Controle da Fase ---
var ordem_dos_turnos = []
var jogador_da_vez_idx = -1
var acoes_registradas = {"investigar": null, "roubar": null}
var resposta_correta_matematica = 0


func _ready():
	_iniciar_fase_da_noite()


func _iniciar_fase_da_noite():
	GameManager.eventos_da_noite.clear()
	GameManager.resultados_investigacao.clear()
	acoes_registradas = {"investigar": null, "roubar": null}
	
	painel_aguardando.hide()
	painel_fiscalizador.hide()
	painel_espiao.hide()
	painel_matematica.hide()
	botao_avancar.hide()
	
	var todos_vivos = GameManager.get_jogadores_vivos()
	for jogador in todos_vivos:
		ordem_dos_turnos.append(jogador.id)
	
	ordem_dos_turnos.shuffle()
	print("Ordem dos turnos da noite: ", ordem_dos_turnos)
	_proximo_jogador_ou_finalizar()


func _apresentar_acao_do_jogador():
	var id_jogador_atual = ordem_dos_turnos[jogador_da_vez_idx]
	var dados_jogador = GameManager.jogadores[id_jogador_atual]
	
	titulo_label.text = "NOITE - Vez de: {nome}".format({"nome": dados_jogador.nome})
	
	match dados_jogador.papel:
		"Fiscalizador":
			var outros_vivos = GameManager.get_jogadores_vivos(id_jogador_atual)
			lista_jogadores_fiscalizador.clear()
			for outro in outros_vivos:
				lista_jogadores_fiscalizador.add_item(outro.nome, null, true)
			painel_fiscalizador.show()
			
		"Espião":
			var outros_vivos = GameManager.get_jogadores_vivos(id_jogador_atual)
			lista_jogadores_espiao.clear()
			for outro in outros_vivos:
				lista_jogadores_espiao.add_item(outro.nome, null, true)
			painel_espiao.show()
			
		_:
			_gerar_problema_matematico()
			painel_matematica.show()


func _gerar_problema_matematico():
	var n1 = randi() % 10 + 1
	var n2 = randi() % 10 + 1
	resposta_correta_matematica = n1 + n2
	
	label_pergunta_matematica.text = "Resolva para continuar:\nQuanto é {n1} + {n2}?".format({"n1": n1, "n2": n2})
	input_resposta_matematica.clear()
	

func _proximo_jogador_ou_finalizar():
	painel_aguardando.hide()
	painel_fiscalizador.hide()
	painel_espiao.hide()
	painel_matematica.hide()

	jogador_da_vez_idx += 1
	
	if jogador_da_vez_idx < ordem_dos_turnos.size():
		_apresentar_acao_do_jogador()
	else:
		titulo_label.text = "NOITE - Ações finalizadas"
		painel_aguardando.get_node("Label").text = "Todos já realizaram suas ações.\nAguardando para avançar..."
		painel_aguardando.show()
		botao_avancar.show()


func _on_botao_investigar_pressed():
	if lista_jogadores_fiscalizador.get_selected_items().is_empty(): return
	var nome_alvo = lista_jogadores_fiscalizador.get_item_text(lista_jogadores_fiscalizador.get_selected_items()[0])
	var dados_alvo = GameManager.get_jogador_por_nome(nome_alvo)
	var id_ator = ordem_dos_turnos[jogador_da_vez_idx]
	acoes_registradas.investigar = { "ator": id_ator, "alvo": dados_alvo.id }
	print("Ação registrada: Fiscalizador ({ator}) vai investigar {alvo}".format(acoes_registradas.investigar))
	_proximo_jogador_ou_finalizar()


func _on_botao_roubar_pressed():
	if lista_jogadores_espiao.get_selected_items().is_empty(): return
	var nome_alvo = lista_jogadores_espiao.get_item_text(lista_jogadores_espiao.get_selected_items()[0])
	var dados_alvo = GameManager.get_jogador_por_nome(nome_alvo)
	var id_ator = ordem_dos_turnos[jogador_da_vez_idx]
	acoes_registradas.roubar = { "ator": id_ator, "alvo": dados_alvo.id }
	print("Ação registrada: Espião ({ator}) vai roubar de {alvo}".format(acoes_registradas.roubar))
	_proximo_jogador_ou_finalizar()


# --- FUNÇÃO MODIFICADA ---
func _on_botao_confirmar_resposta_pressed():
	var resposta_do_jogador = input_resposta_matematica.text
	
	print("Jogador {id} respondeu '{resp}' ao problema.".format({
		"id": ordem_dos_turnos[jogador_da_vez_idx],
		"resp": resposta_do_jogador
	}))
	
	if resposta_do_jogador.is_valid_int() and int(resposta_do_jogador) == resposta_correta_matematica:
		print("... e a resposta estava correta!")
	else:
		print("... e a resposta estava incorreta.")
		

	_proximo_jogador_ou_finalizar()


func _on_botao_avancar_para_debate_pressed():
	GameManager.processar_acoes_da_noite(acoes_registradas)

	get_tree().change_scene_to_file("res://scenes/Temporizador.tscn") 

func _processar_toda_a_noite():
	print("\n--- PROCESSANDO A NOITE ---")
	if acoes_registradas.investigar:
		var dados = acoes_registradas.investigar
		var alvo = GameManager.jogadores[dados.alvo]
		var e_fura_greve = (alvo.faccao == "Fura-greve" or alvo.faccao == "Diretor")
		GameManager.resultados_investigacao[dados.ator] = "O jogador {nome} é Fura-greve: {res}".format({"nome": alvo.nome, "res": e_fura_greve})
		print("Processado: Investigação de ", alvo.nome)

	if acoes_registradas.roubar:
		var dados = acoes_registradas.roubar
		var alvo = GameManager.jogadores[dados.alvo]
		if alvo.faccao == "Sindicato":
			GameManager.transferir_fichas(dados.alvo, dados.ator, 2)
			GameManager.eventos_da_noite.append("Um sindicalista foi roubado!")
			print("Processado: Roubo do alvo ", alvo.nome)
		else:
			print("Processado: Roubo falhou, alvo não era sindicalista.")

	var diretor = GameManager.get_jogador_por_papel("Diretor da Empresa")
	if diretor and not diretor.morto:
		GameManager.banco_solidariedade -= 3
		GameManager.eventos_da_noite.append("O Diretor minou a solidariedade do grupo.")
		print("Processado: Ação passiva do Diretor. Banco: ", GameManager.banco_solidariedade)

	print("--- FIM DO PROCESSAMENTO ---\n")

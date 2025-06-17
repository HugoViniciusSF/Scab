# GameManager.gd - Versão Completa com Gerenciamento de Turnos

extends Node

# --- ESTADO DO JOGO ---
var jogadores = {}
var banco_solidariedade = 10
var jogador_atual_id = -1
var eventos_da_noite = []
var resultados_investigacao = {}

# --- NOVAS VARIÁVEIS PARA CONTROLE DE TURNO ---
var fila_de_jogadores_do_dia: Array = []
var dia_ja_iniciado: bool = false
var votos_da_rodada: Dictionary = {}

# --- CONSTANTES DE CAMINHO ---
const CAMINHO_JOGADORES = "user://jogadores.txt"

# --- LÓGICA DE INICIALIZAÇÃO ---
func _ready():
	_carregar_dados_jogadores()

func _carregar_dados_jogadores():
	if not FileAccess.file_exists(CAMINHO_JOGADORES):
		print("ERRO: Arquivo de jogadores não encontrado em '", CAMINHO_JOGADORES, "'")
		return

	var file = FileAccess.open(CAMINHO_JOGADORES, FileAccess.READ)
	var regex = RegEx.new()
	# Expressão regular para capturar os dados da linha
	regex.compile("^ID (\\d+) - (.*): (.*) \\((.*)\\) \\| Morto: (true|false) \\| Senha: (.*)$")

	print("Carregando jogadores de ", CAMINHO_JOGADORES)
	while not file.eof_reached():
		var linha = file.get_line()
		# Usando RegEx para garantir que não haja erro com .strip()
		var regex_strip = RegEx.new()
		regex_strip.compile("^\\s+|\\s+$")
		var clean_line = regex_strip.sub(linha, "", true)

		if clean_line.is_empty() or clean_line.begins_with("#"):
			continue

		var resultado = regex.search(clean_line)
		if resultado:
			var id = int(resultado.get_string(1))
			var nome = resultado.get_string(2)
			var papel = resultado.get_string(3)
			var faccao = resultado.get_string(4)
			var morto = (resultado.get_string(5) == "true")
			var senha = resultado.get_string(6)
			
			jogadores[id] = {
				"id": id,
				"nome": nome,
				"papel": papel,
				"faccao": faccao,
				"morto": morto,
				"senha": senha,
				"fichas": 0
			}
		else:
			print("AVISO: Linha mal formatada em jogadores.txt foi ignorada: '", linha, "'")
	
	file.close()
	print("Jogadores carregados com sucesso: ", jogadores)
	
	# Define o jogador inicial como o primeiro vivo da lista
	var ids_ordenados = jogadores.keys()
	ids_ordenados.sort()
	var primeiro_vivo_encontrado = false
	for id in ids_ordenados:
		if not jogadores[id].morto:
			jogador_atual_id = id
			primeiro_vivo_encontrado = true
			print("Jogador atual definido como o primeiro vivo da lista: ID ", id, " (", jogadores[id].nome, ")")
			break
	
	if not primeiro_vivo_encontrado:
		print("AVISO: Nenhum jogador vivo encontrado. Fim de jogo?")
		jogador_atual_id = -1


# --- NOVAS FUNÇÕES DE CONTROLE DE TURNO E JOGO ---

func iniciar_logica_do_dia():
	if dia_ja_iniciado:
		return
	print("Iniciando a lógica do Dia pela primeira vez.")
	votos_da_rodada.clear()
	fila_de_jogadores_do_dia = get_jogadores_vivos().map(func(j): return j.id)
	print("Fila de jogadores para o dia: ", fila_de_jogadores_do_dia)
	dia_ja_iniciado = true
	_definir_proximo_jogador_na_fila()

func avancar_para_proximo_jogador_dia():
	if not fila_de_jogadores_do_dia.is_empty():
		_definir_proximo_jogador_na_fila()
		get_tree().reload_current_scene()
	else:
		print("Todos os jogadores concluíram seus turnos. O Dia está terminando.")
		_resolver_votacao_do_dia()
		dia_ja_iniciado = false
		eventos_da_noite.clear() # Limpa os eventos para o próximo dia
		get_tree().change_scene_to_file("res://scenes/Noite.tscn")

func _definir_proximo_jogador_na_fila():
	if not fila_de_jogadores_do_dia.is_empty():
		jogador_atual_id = fila_de_jogadores_do_dia.pop_front()
		print("É a vez do jogador: ID ", jogador_atual_id)
	else:
		print("Fila de jogadores do dia está vazia.")

func _resolver_votacao_do_dia():
	if votos_da_rodada.is_empty():
		eventos_da_noite.append("A votação terminou sem um resultado conclusivo.")
		return
	var contagem = {}
	for id_alvo in votos_da_rodada.values():
		if not contagem.has(id_alvo):
			contagem[id_alvo] = 0
		contagem[id_alvo] += 1
	var mais_votado_id = -1
	var max_votos = 0
	for id_alvo in contagem:
		if contagem[id_alvo] > max_votos:
			max_votos = contagem[id_alvo]
			mais_votado_id = id_alvo
	if mais_votado_id != -1:
		jogadores[mais_votado_id].morto = true
		var nome_expulso = jogadores[mais_votado_id].nome
		eventos_da_noite.append("%s foi expulso pela votação!" % nome_expulso)
		print("%s foi expulso." % nome_expulso)
	else:
		eventos_da_noite.append("A votação terminou em empate ou sem votos.")

func registrar_voto(id_votante, id_alvo, peso_voto):
	if not votos_da_rodada.has(id_alvo):
		votos_da_rodada[id_alvo] = 0
	votos_da_rodada[id_alvo] += peso_voto
	print("VOTO: Jogador %s votou em %s com peso %s" % [id_votante, id_alvo, peso_voto])


# --- FUNÇÕES GLOBAIS AUXILIARES (SEU CÓDIGO ORIGINAL) ---

func get_jogadores_vivos(id_excluido = -1):
	var vivos = []
	for id in jogadores:
		if not jogadores[id].morto and id != id_excluido:
			vivos.append(jogadores[id])
	return vivos

func get_papel(id_jogador):
	if jogadores.has(id_jogador):
		return jogadores[id_jogador].papel
	return null

func get_jogador_por_nome(nome_jogador):
	for id in jogadores:
		if jogadores[id].nome == nome_jogador:
			return jogadores[id]
	return null

func get_jogador_por_papel(nome_papel):
	for id in jogadores:
		if jogadores[id].papel == nome_papel:
			return jogadores[id]
	return null

func transferir_fichas(id_origem, id_destino, quantidade):
	var fichas_roubadas = min(jogadores[id_origem].fichas, quantidade)
	jogadores[id_origem].fichas -= fichas_roubadas
	jogadores[id_destino].fichas += fichas_roubadas
	print("{q} fichas transferidas de {origem} para {destino}".format({
		"q": fichas_roubadas,
		"origem": jogadores[id_origem].nome,
		"destino": jogadores[id_destino].nome
	}))

func adicionar_fichas_pessoais(id_jogador, quantidade):
	if jogadores.has(id_jogador):
		jogadores[id_jogador].fichas += quantidade

func ler_arquivo_votacao(caminho_arquivo):
	if not FileAccess.file_exists(caminho_arquivo):
		var erro_msg = "ERRO: Arquivo de votação não encontrado em '{path}'".format({"path": caminho_arquivo})
		print(erro_msg)
		return erro_msg
	var file = FileAccess.open(caminho_arquivo, FileAccess.READ)
	var conteudo = file.get_as_text()
	file.close()
	return conteudo

func jogador_fez_troca(id_jogador):
	print("Verificando se o jogador {id} fez troca... Sim (lógica de placeholder).".format({"id": id_jogador}))
	return true

extends Node2D

# --- ESTADO DO JOGO ---
var jogadores = {}
var banco_solidariedade = 100
var jogador_atual_id = -1
var eventos_da_noite = []
var resultados_investigacao = {}
var votos_da_rodada: Dictionary = {}
var fila_de_jogadores_do_dia: Array = []
var dia_ja_iniciado: bool = false
var log_de_eventos: Array = []

# --- CONSTANTES DE CAMINHO ---
const CAMINHO_JOGADORES = "user://jogadores.txt"
const CAMINHO_LOG = "user://log_da_partida.txt"

# --- LÓGICA DE INICIALIZAÇÃO ---
func _ready():
	log_de_eventos.clear()
	registrar_log("--- INÍCIO DE JOGO ---")
	_carregar_dados_jogadores()

func _carregar_dados_jogadores():
	if not FileAccess.file_exists(CAMINHO_JOGADORES):
		print("ERRO: Arquivo de jogadores não encontrado em '", CAMINHO_JOGADORES, "'")
		return

	var file = FileAccess.open(CAMINHO_JOGADORES, FileAccess.READ)
	var regex = RegEx.new()
	regex.compile("^ID (\\d+) - (.*): (.*) \\((.*)\\) \\| Morto: (true|false) \\| Senha: (.*)$")

	while not file.eof_reached():
		var linha = file.get_line()
		var regex_strip = RegEx.new(); regex_strip.compile("^\\s+|\\s+$")
		var clean_line = regex_strip.sub(linha, "", true)

		if clean_line.is_empty() or clean_line.begins_with("#"): continue

		var resultado = regex.search(clean_line)
		if resultado:
			var id = int(resultado.get_string(1))
			var nome = resultado.get_string(2); var papel = resultado.get_string(3)
			var faccao = resultado.get_string(4); var morto = (resultado.get_string(5) == "true")
			var senha = resultado.get_string(6)
			
			jogadores[id] = {
				"id": id, "nome": nome, "papel": papel, "faccao": faccao,
				"morto": morto, "senha": senha, "fichas": 0
			}
	file.close()
	
	var ids_ordenados = jogadores.keys(); ids_ordenados.sort()
	for id in ids_ordenados:
		if not jogadores[id].morto:
			jogador_atual_id = id; break

# --- FUNÇÕES DE LOG ---
func registrar_log(evento: String):
	print("LOG: ", evento)
	log_de_eventos.append(evento)

func salvar_log_do_jogo():
	var file = FileAccess.open(CAMINHO_LOG, FileAccess.WRITE)
	var timestamp = Time.get_datetime_string_from_system()
	var conteudo_final = "### LOG DA PARTIDA - %s ###\n\n" % timestamp
	conteudo_final += "Saldo do Banco de Solidariedade: %s fichas.\n" % banco_solidariedade
	conteudo_final += "----------------------------------------------\n\n"
	conteudo_final += "\n".join(log_de_eventos)
	file.store_string(conteudo_final)
	file.close()
	print("Log do jogo salvo com sucesso em: ", CAMINHO_LOG)

# --- FUNÇÕES DE CONTROLE DE TURNO E JOGO ---
func iniciar_logica_do_dia():
	if dia_ja_iniciado: return
	var dia_num = eventos_da_noite.size() + 1
	registrar_log("\n--- DIA %s ---" % dia_num)
	votos_da_rodada.clear()
	fila_de_jogadores_do_dia = get_jogadores_vivos().map(func(j): return j.id)
	dia_ja_iniciado = true
	_definir_proximo_jogador_na_fila()

func avancar_para_proximo_jogador_dia():
	if not fila_de_jogadores_do_dia.is_empty():
		_definir_proximo_jogador_na_fila()
		get_tree().reload_current_scene()
	else:
		salvar_log_do_jogo()
		dia_ja_iniciado = false
		get_tree().change_scene_to_file("res://scenes/Noite.tscn")

func _definir_proximo_jogador_na_fila():
	if not fila_de_jogadores_do_dia.is_empty():
		jogador_atual_id = fila_de_jogadores_do_dia.pop_front()
		registrar_log("TURNO: Começa o turno de %s." % jogadores[jogador_atual_id].nome)

func registrar_voto(id_votante, id_alvo, peso_voto):
	if not votos_da_rodada.has(id_alvo): votos_da_rodada[id_alvo] = 0
	votos_da_rodada[id_alvo] += peso_voto
	registrar_log("VOTO: %s votou em %s." % [jogadores[id_votante].nome, jogadores[id_alvo].nome])

func reviver_jogador(id_alvo: int):
	if jogadores.has(id_alvo):
		jogadores[id_alvo].morto = false
		banco_solidariedade -= 2 
		registrar_log("AÇÃO: Doador Sindical reviveu %s." % jogadores[id_alvo].nome)

func usar_habilidade_beber(id_jogador: int) -> bool:
	if banco_solidariedade >= 1:
		banco_solidariedade -= 1
		registrar_log("AÇÃO: %s (Cachaceiro) usou 1 ficha para beber." % jogadores[id_jogador].nome)
		return true
	return false

func usar_habilidade_negociar(id_jogador: int):
	registrar_log("AÇÃO: %s (Traficante) iniciou uma negociação." % jogadores[id_jogador].nome)

# --- FUNÇÕES GLOBAIS AUXILIARES ---
func get_jogadores_vivos(id_excluido = -1):
	var vivos = [];
	for id in jogadores:
		if not jogadores[id].morto and id != id_excluido: vivos.append(jogadores[id])
	return vivos

func get_sindicalistas_mortos():
	var mortos = [];
	for id in jogadores:
		if jogadores[id].morto and jogadores[id].faccao == "Sindicato": mortos.append(jogadores[id])
	return mortos

func get_papel(id_jogador):
	if jogadores.has(id_jogador): return jogadores[id_jogador].papel
	return null

func get_jogador_por_nome(nome_jogador: String):
	for id in jogadores:
		if jogadores[id].nome == nome_jogador:
			return jogadores[id]
	return null

func transferir_fichas(id_origem: int, id_destino: int, quantidade: int):
	if not jogadores.has(id_origem) or not jogadores.has(id_destino):
		print("ERRO: ID de origem ou destino inválido na transferência de fichas.")
		return

	var fichas_reais_transferidas = min(jogadores[id_origem].fichas, quantidade)
	
	if fichas_reais_transferidas > 0:
		jogadores[id_origem].fichas -= fichas_reais_transferidas
		jogadores[id_destino].fichas += fichas_reais_transferidas
		
		var log_msg = "AÇÃO: %d ficha(s) foram transferidas de %s para %s." % [
			fichas_reais_transferidas,
			jogadores[id_origem].nome,
			jogadores[id_destino].nome
		]
		registrar_log(log_msg)
	else:
		registrar_log("AÇÃO: Tentativa de transferência de %s para %s falhou (sem fichas na origem)." % [jogadores[id_origem].nome, jogadores[id_destino].nome])

func get_jogador_por_papel(nome_papel: String):
	for id in jogadores:
		if jogadores[id].papel == nome_papel:
			return jogadores[id]
	return null 

func processar_acoes_da_noite(acoes: Dictionary):
	registrar_log("\n--- NOITE ---")
	
	# Ação do Fiscalizador
	if acoes.has("investigar") and acoes.investigar != null:
		var dados = acoes.investigar
		var ator = jogadores[dados.ator]
		var alvo = jogadores[dados.alvo]
		var e_fura_greve = (alvo.faccao == "Fura-greve" or alvo.faccao == "Diretor")
		resultados_investigacao[dados.ator] = "O jogador {nome} é Fura-greve: {res}".format({"nome": alvo.nome, "res": e_fura_greve})
		registrar_log("NOITE: %s (Fiscalizador) investigou %s." % [ator.nome, alvo.nome])

	# Ação do Espião
	if acoes.has("roubar") and acoes.roubar != null:
		var dados = acoes.roubar
		var alvo = jogadores[dados.alvo]
		if alvo.faccao == "Sindicato":
			transferir_fichas(dados.alvo, dados.ator, 2)
			eventos_da_noite.append("Um sindicalista foi roubado durante a noite!")
		else:
			registrar_log("NOITE: Espião tentou roubar %s, mas o alvo não era sindicalista." % alvo.nome)
	
	var diretor = get_jogador_por_papel("Diretor da Empresa")
	if diretor and not diretor.morto:
		banco_solidariedade = max(0, banco_solidariedade - 3)
		eventos_da_noite.append("O Diretor minou a solidariedade do grupo.")
		registrar_log("NOITE: Diretor da Empresa cortou 3 fichas do banco. Saldo atual: %d" % banco_solidariedade)
		
	salvar_log_do_jogo()

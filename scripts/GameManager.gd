extends Node

# --- ESTADO DO JOGO ---
var jogadores = {}
var banco_solidariedade = 10
var jogador_atual_id = -1
var eventos_da_noite = []
var resultados_investigacao = {}

# --- CONSTANTES DE CAMINHO ---
const CAMINHO_JOGADORES = "user://jogadores.txt"

func _ready():
	_carregar_dados_jogadores()

# --- LÓGICA DE CARREGAMENTO ---
func _carregar_dados_jogadores():
	if not FileAccess.file_exists(CAMINHO_JOGADORES):
		print("ERRO: Arquivo de jogadores não encontrado em '", CAMINHO_JOGADORES, "'")
		return

	var file = FileAccess.open(CAMINHO_JOGADORES, FileAccess.READ)
	var regex = RegEx.new()
	regex.compile("^ID (\\d+) - (.*): (.*) \\((.*)\\) \\| Morto: (true|false) \\| Senha: (.*)$")

	print("Carregando jogadores de ", CAMINHO_JOGADORES)
	while not file.eof_reached():
		var linha = file.get_line().strip_edges()
		if linha.is_empty() or linha.begins_with("#"):
			continue

		var resultado = regex.search(linha)
		if resultado:
			var id = int(resultado.get_string(1))
			var nome = resultado.get_string(2).strip_edges()
			var papel = resultado.get_string(3).strip_edges()
			var faccao = resultado.get_string(4).strip_edges()
			var morto = (resultado.get_string(5) == "true")
			var senha = resultado.get_string(6).strip_edges()
			
			# Adiciona o jogador ao dicionário, AGORA INCLUINDO O ID DENTRO DELE
			jogadores[id] = {
				"id": id, # <<< A CORREÇÃO ESTÁ AQUI
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
	
	# O resto do código funciona da mesma forma
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


# --- FUNÇÕES GLOBAIS (NÃO PRECISAM DE ALTERAÇÃO) ---
# ... (todo o resto do seu script GameManager.gd continua igual) ...

# Retorna uma lista de todos os jogadores que não estão mortos.
func get_jogadores_vivos(id_excluido = -1):
	var vivos = []
	for id in jogadores:
		if not jogadores[id].morto and id != id_excluido:
			vivos.append(jogadores[id])
	return vivos

# Pega o papel de um jogador pelo seu ID.
func get_papel(id_jogador):
	if jogadores.has(id_jogador):
		return jogadores[id_jogador].papel
	return null

# Pega os dados completos de um jogador pelo seu nome de usuário.
func get_jogador_por_nome(nome_jogador):
	for id in jogadores:
		if jogadores[id].nome == nome_jogador:
			return jogadores[id]
	return null

# Pega os dados de um jogador pelo seu papel (útil para ações passivas).
func get_jogador_por_papel(nome_papel):
	for id in jogadores:
		if jogadores[id].papel == nome_papel:
			return jogadores[id]
	return null

# --- FUNÇÕES DE LÓGICA DO JOGO ---

# Transfere fichas entre jogadores.
func transferir_fichas(id_origem, id_destino, quantidade):
	var fichas_roubadas = min(jogadores[id_origem].fichas, quantidade)
	jogadores[id_origem].fichas -= fichas_roubadas
	jogadores[id_destino].fichas += fichas_roubadas
	print("{q} fichas transferidas de {origem} para {destino}".format({
		"q": fichas_roubadas, 
		"origem": jogadores[id_origem].nome, 
		"destino": jogadores[id_destino].nome
	}))

# Adiciona fichas a um jogador específico.
func adicionar_fichas_pessoais(id_jogador, quantidade):
	if jogadores.has(id_jogador):
		jogadores[id_jogador].fichas += quantidade

# Lê o conteúdo de um arquivo de texto, como o de votação.
func ler_arquivo_votacao(caminho_arquivo):
	if not FileAccess.file_exists(caminho_arquivo):
		var erro_msg = "ERRO: Arquivo de votação não encontrado em '{path}'".format({"path": caminho_arquivo})
		print(erro_msg)
		return erro_msg

	var file = FileAccess.open(caminho_arquivo, FileAccess.READ)
	var conteudo = file.get_as_text()
	file.close()
	return conteudo

# Verifica se um jogador fez uma troca (para a habilidade do Organizador).
func jogador_fez_troca(id_jogador):
	print("Verificando se o jogador {id} fez troca... Sim (lógica de placeholder).".format({"id": id_jogador}))
	return true

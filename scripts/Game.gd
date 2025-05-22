extends Node2D

var jogadores: Array = []
var max_jogadores: int = 0  # variável para guardar o limite de jogadores

@onready var voltar_botao = $VoltarBotao
@onready var input_nome = $InputNome
@onready var adicionar_jogador_botao = $AdicionarJogadorBotao
@onready var jogadores_container = $ScrollContainer/JogadoresContainer
@onready var comecar_botao = $ComecarBotao
@onready var contador_label = $ContadorLabel  # label que você adicionou

func _ready():
	max_jogadores = JogoGlobal.configuracoes_sala.get("quantidade_jogadores", 0)
	atualizar_contador()

	voltar_botao.pressed.connect(_on_botao_voltar_pressed)
	adicionar_jogador_botao.pressed.connect(_on_adicionar_jogador_pressed)
	comecar_botao.pressed.connect(_on_comecar_jogo_pressed)

func _on_botao_voltar_pressed():
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _on_adicionar_jogador_pressed():
	if jogadores.size() >= max_jogadores:
		print("Limite de jogadores atingido!")
		return

	var nome = input_nome.text.strip_edges()
	if nome == "":
		return

	# Apenas adiciona o jogador com nome, sem atribuir função ainda
	var jogador = {
		"nome": nome,
		"funcao": null  # A função será atribuída no começo do jogo
	}
	jogadores.append(jogador)

	# Mostra na UI
	var label = Label.new()
	label.text = "%s foi adicionado" % nome
	jogadores_container.add_child(label)

	input_nome.text = ""

	atualizar_contador()

func atualizar_contador():
	contador_label.text = "Jogadores: %d / %d" % [jogadores.size(), max_jogadores]

	# Desabilita botão se atingiu o limite
	adicionar_jogador_botao.disabled = jogadores.size() >= max_jogadores

func _on_comecar_jogo_pressed():
	if jogadores.size() < 4:  # mínimo de jogadores
		print("Mínimo de 4 jogadores necessário para começar o jogo.")
		return

	# Distribuir papéis conforme as regras
	distribuir_papeis()
	
	JogoGlobal.jogadores = jogadores
	salvar_jogadores_em_txt()

	get_tree().change_scene_to_file("res://scenes/RevelarFuncoes.tscn")

func distribuir_papeis():
	var total_jogadores = jogadores.size()
	
	# 1. Dividir jogadores entre Sindicato e Fura-greve
	var num_fura_greve = calcular_num_fura_greve(total_jogadores)
	var num_sindicato = total_jogadores - num_fura_greve
	
	print("Distribuição: %d Sindicalistas, %d Fura-greves" % [num_sindicato, num_fura_greve])
	
	# 2. Embaralhar jogadores para distribuição aleatória
	jogadores.shuffle()
	
	# 3. Separar jogadores em facções
	var jogadores_sindicato = jogadores.slice(0, num_sindicato)
	var jogadores_fura_greve = jogadores.slice(num_sindicato, total_jogadores)
	
	# 4. Definir papéis disponíveis com base no número de jogadores
	var papeis_sindicato = obter_papeis_sindicato(total_jogadores)
	var papeis_fura_greve = obter_papeis_fura_greve(total_jogadores)
	
	# 5. Atribuir papéis para Sindicato
	# Primeiro, garantir que haja um Líder Sindical
	var lider_sindical = encontrar_papel_por_nome(papeis_sindicato, "Líder Sindical")
	jogadores_sindicato[0]["funcao"] = lider_sindical
	
	# Depois, distribuir os demais papéis do Sindicato
	papeis_sindicato.erase(lider_sindical)
	
	for i in range(1, jogadores_sindicato.size()):
		var papel
		if papeis_sindicato.size() > 0:
			papel = papeis_sindicato[randi() % papeis_sindicato.size()]
		else:
			# Se acabarem os papéis especiais, usar Membro
			papel = {
				"faccao": "Sindicato",
				"papel": "Membro",
				"habilidades": "Sem habilidades especiais."
			}
		jogadores_sindicato[i]["funcao"] = papel
	
	# 6. Atribuir papéis para Fura-greve
	# Primeiro, garantir que haja um Diretor
	var diretor = encontrar_papel_por_nome(papeis_fura_greve, "Diretor da Empresa")
	if jogadores_fura_greve.size() > 0:
		jogadores_fura_greve[0]["funcao"] = diretor
	
	# Depois, distribuir os demais papéis dos Fura-greve
	papeis_fura_greve.erase(diretor)
	
	for i in range(1, jogadores_fura_greve.size()):
		var papel
		if papeis_fura_greve.size() > 0:
			papel = papeis_fura_greve[randi() % papeis_fura_greve.size()]
		else:
			# Se acabarem os papéis especiais, usar Membro (mas da facção Fura-greve)
			papel = {
				"faccao": "Fura-greve",
				"papel": "Membro",
				"habilidades": "Sem habilidades especiais."
			}
		jogadores_fura_greve[i]["funcao"] = papel

# Calcula quantos jogadores serão Fura-greve com base no total
func calcular_num_fura_greve(total):
	if total <= 4:
		return 1  # 4 jogadores: 1 Fura-greve (Diretor)
	elif total <= 6:
		return 2  # 5-6 jogadores: 2 Fura-greve
	else:
		return 3  # 7+ jogadores: 3 Fura-greve

# Retorna os papéis disponíveis para o Sindicato com base no número de jogadores
func obter_papeis_sindicato(total_jogadores):
	var papeis = []
	
	# Líder Sindical sempre disponível
	papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Líder Sindical"))
	
	# Membro sempre disponível
	papeis.append({
		"faccao": "Sindicato",
		"papel": "Membro",
		"habilidades": "Sem habilidades especiais."
	})
	
	# Adicionar outros papéis conforme o número de jogadores
	if total_jogadores >= 5:
		papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Organizador"))
	
	if total_jogadores >= 6:
		papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Fiscalizador"))
		papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Doador Sindical"))
		papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Cachaceiro"))
	
	return papeis

# Retorna os papéis disponíveis para os Fura-greve com base no número de jogadores
func obter_papeis_fura_greve(total_jogadores):
	var papeis = []
	
	# Diretor sempre disponível
	papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Diretor da Empresa"))
	
	# Adicionar outros papéis conforme o número de jogadores
	if total_jogadores >= 5:
		papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Espião"))
	
	if total_jogadores >= 7:
		papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Traficante"))
	
	return papeis

# Função auxiliar para encontrar um papel pelo nome
func encontrar_papel_por_nome(lista_papeis, nome_papel):
	for papel in lista_papeis:
		if papel["papel"] == nome_papel:
			# Retorna uma cópia para evitar modificar o original
			return papel.duplicate()
	
	# Se não encontrar, retorna um papel genérico
	return {
		"faccao": "Desconhecido",
		"papel": nome_papel,
		"habilidades": "Papel não encontrado."
	}

func salvar_jogadores_em_txt():
	var caminho = "user://jogadores.txt"
	var file = FileAccess.open(caminho, FileAccess.WRITE)
	
	if file:
		file.store_line("=== Configurações da Sala ===")
		for chave in JogoGlobal.configuracoes_sala:
			var valor = JogoGlobal.configuracoes_sala[chave]
			file.store_line("%s: %s" % [chave, str(valor)])
		
		file.store_line("") # linha em branco para separar

		file.store_line("=== Jogadores ===")
		for jogador in jogadores:
			var nome = jogador["nome"]
			var funcao = jogador["funcao"]
			var papel = funcao.get("papel", "Desconhecido")
			var faccao = funcao.get("faccao", "Desconhecida")
			file.store_line("%s: %s (%s)" % [nome, papel, faccao])

		file.close()
		print("Dados salvos em:", caminho)
	else:
		print("Erro ao salvar jogadores.txt")

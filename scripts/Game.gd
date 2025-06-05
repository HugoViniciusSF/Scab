extends Node2D

var jogadores: Array = []
var max_jogadores: int = 0

@onready var voltar_botao = $VoltarBotao
@onready var input_nome = $InputNome
@onready var adicionar_jogador_botao = $AdicionarJogadorBotao
@onready var jogadores_container = $ScrollContainer/JogadoresContainer
@onready var comecar_botao = $ComecarBotao
@onready var contador_label = $ContadorLabel  
@onready var input_senha = $InputSenha

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
	var senha = input_senha.text.strip_edges()
	if nome == "" or senha == "":
		return

	var jogador = {
		"nome": nome,
		"senha": senha,
		"funcao": null
	}
	jogadores.append(jogador)

	var label = Label.new()
	label.text = "%s foi adicionado" % nome
	jogadores_container.add_child(label)

	input_nome.text = ""
	input_senha.text = ""

	atualizar_contador()

func atualizar_contador():
	contador_label.text = "Jogadores: %d / %d" % [jogadores.size(), max_jogadores]

	adicionar_jogador_botao.disabled = jogadores.size() >= max_jogadores

func _on_comecar_jogo_pressed():
	if jogadores.size() < 4:
		print("Mínimo de 4 jogadores necessário para começar o jogo.")
		return

	distribuir_papeis()
	
	JogoGlobal.jogadores = jogadores
	
	salvar_configuracoes_sala()
	salvar_jogadores_em_txt()

	get_tree().change_scene_to_file("res://scenes/RevelarFuncoes.tscn")

func distribuir_papeis():
	var total_jogadores = jogadores.size()
	
	var num_fura_greve = calcular_num_fura_greve(total_jogadores)
	var num_sindicato = total_jogadores - num_fura_greve
	
	print("Distribuição: %d Sindicalistas, %d Fura-greves" % [num_sindicato, num_fura_greve])
	
	jogadores.shuffle()
	
	var jogadores_sindicato = jogadores.slice(0, num_sindicato)
	var jogadores_fura_greve = jogadores.slice(num_sindicato, total_jogadores)
	
	var papeis_sindicato = obter_papeis_sindicato(total_jogadores)
	var papeis_fura_greve = obter_papeis_fura_greve(total_jogadores)
	
	var lider_sindical = encontrar_papel_por_nome(papeis_sindicato, "Líder Sindical")
	jogadores_sindicato[0]["funcao"] = lider_sindical
	
	papeis_sindicato.erase(lider_sindical)
	
	for i in range(1, jogadores_sindicato.size()):
		var papel
		if papeis_sindicato.size() > 0:
			papel = papeis_sindicato[randi() % papeis_sindicato.size()]
		else:
			papel = {
				"faccao": "Sindicato",
				"papel": "Membro",
				"habilidades": "Sem habilidades especiais."
			}
		jogadores_sindicato[i]["funcao"] = papel
	
	var diretor = encontrar_papel_por_nome(papeis_fura_greve, "Diretor da Empresa")
	if jogadores_fura_greve.size() > 0:
		jogadores_fura_greve[0]["funcao"] = diretor
	
	papeis_fura_greve.erase(diretor)
	
	for i in range(1, jogadores_fura_greve.size()):
		var papel
		if papeis_fura_greve.size() > 0:
			papel = papeis_fura_greve[randi() % papeis_fura_greve.size()]
		else:
			papel = {
				"faccao": "Fura-greve",
				"papel": "Membro",
				"habilidades": "Sem habilidades especiais."
			}
		jogadores_fura_greve[i]["funcao"] = papel

func calcular_num_fura_greve(total):
	if total <= 4:
		return 1 
	elif total <= 6:
		return 2 
	else:
		return 3 

func obter_papeis_sindicato(total_jogadores):
	var papeis = []
	
	papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Líder Sindical"))
	
	papeis.append({
		"faccao": "Sindicato",
		"papel": "Membro",
		"habilidades": "Sem habilidades especiais."
	})
	
	if total_jogadores >= 5:
		papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Organizador"))
	
	if total_jogadores >= 6:
		papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Fiscalizador"))
		papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Doador Sindical"))
		papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Cachaceiro"))
	
	return papeis

func obter_papeis_fura_greve(total_jogadores):
	var papeis = []
	
	papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Diretor da Empresa"))
	
	if total_jogadores >= 5:
		papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Espião"))
	
	if total_jogadores >= 7:
		papeis.append(encontrar_papel_por_nome(JogoGlobal.classes_disponiveis, "Traficante"))
	
	return papeis

func encontrar_papel_por_nome(lista_papeis, nome_papel):
	for papel in lista_papeis:
		if papel["papel"] == nome_papel:
			return papel.duplicate()
	
	return {
		"faccao": "Desconhecido",
		"papel": nome_papel,
		"habilidades": "Papel não encontrado."
	}

func salvar_jogadores_em_txt():
	var caminho = "user://jogadores.txt"
	var file = FileAccess.open(caminho, FileAccess.WRITE)
	
	if file:
		var id = 1
		for jogador in jogadores:
			var nome = jogador["nome"]
			var senha = jogador["senha"]
			var funcao = jogador["funcao"]
			var papel = funcao.get("papel", "Desconhecido")
			var faccao = funcao.get("faccao", "Desconhecida")
			
			jogador["id"] = id
			jogador["morto"] = false

			file.store_line("ID %d - %s: %s (%s) | Morto: %s | Senha: %s" % [id, nome, papel, faccao, str(jogador["morto"]), senha])
			id += 1

		file.close()
		print("Jogadores salvos em:", caminho)
	else:
		print("Erro ao salvar jogadores.txt")


func salvar_configuracoes_sala():
	var caminho = "user://configuracoes_sala.txt"
	var file = FileAccess.open(caminho, FileAccess.WRITE)
	
	if file:
		for chave in JogoGlobal.configuracoes_sala:
			var valor = JogoGlobal.configuracoes_sala[chave]
			file.store_line("%s: %s" % [chave, str(valor)])
		
		file.close()
		print("Configurações da sala salvas em:", caminho)
	else:
		print("Erro ao salvar configuracoes_sala.txt")


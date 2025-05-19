extends Node2D

var jogadores: Array = []
var funcoes_disponiveis: Array = JogoGlobal.classes_disponiveis.duplicate()

@onready var voltar_botao = $VoltarBotao
@onready var input_nome = $InputNome
@onready var adicionar_jogador_botao = $AdicionarJogadorBotao
@onready var jogadores_container = $ScrollContainer/JogadoresContainer
@onready var comecar_botao = $ComecarBotao

func _ready():
	voltar_botao.pressed.connect(_on_botao_voltar_pressed)
	adicionar_jogador_botao.pressed.connect(_on_adicionar_jogador_pressed)
	comecar_botao.pressed.connect(_on_comecar_jogo_pressed)

func _on_botao_voltar_pressed():
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _on_adicionar_jogador_pressed():
	var nome = input_nome.text.strip_edges()
	if nome == "":
		return

	# Atribui função imediatamente
	var funcao = null
	if funcoes_disponiveis.size() > 0:
		funcao = funcoes_disponiveis.pop_front()
	else:
		funcao = {
			"faccao": "Sindicato",
			"papel": "Membro",
			"habilidades": "Sem habilidades especiais."
		}

	var jogador = {
		"nome": nome,
		"funcao": funcao
	}
	jogadores.append(jogador)

	# Mostra na UI com papel e facção
	var label = Label.new()
	#label.text = "%s foi adicionado como %s (%s)" % [nome, funcao["papel"], funcao["faccao"]]
	#jogadores_container.add_child(label)
	label.text = "%s foi adicionado" % nome
	jogadores_container.add_child(label)

	input_nome.text = ""

func _on_comecar_jogo_pressed():
	if jogadores.size() < 4: #Aqui vamos colocar a quantidade de jogades que foi selecionado na tela de criação da tela !!!!!
		print("Mínimo de 4 jogadores necessário para começar o jogo.") #ver quantos sao no documento coloquei 4 por enquanto
		return

	# Jogadores já têm função, apenas salva no singleton
	JogoGlobal.jogadores = jogadores

	# Salva os dados em um .txt para conferência
	salvar_jogadores_em_txt()

	get_tree().change_scene_to_file("res://scenes/RevelarFuncoes.tscn")

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


extends Node2D

var jogadores: Array = []
var funcoes_disponiveis: Array = JogoGlobal.classes_disponiveis.duplicate()
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
	label.text = "%s foi adicionado" % nome
	jogadores_container.add_child(label)

	input_nome.text = ""

	atualizar_contador()

func atualizar_contador():
	contador_label.text = "Jogadores: %d / %d" % [jogadores.size(), max_jogadores]

	# Desabilita botão se atingiu o limite
	adicionar_jogador_botao.disabled = jogadores.size() >= max_jogadores

func _on_comecar_jogo_pressed():
	if jogadores.size() < 4:  # aqui você pode adaptar para usar max_jogadores se quiser
		print("Mínimo de 4 jogadores necessário para começar o jogo.")
		return

	JogoGlobal.jogadores = jogadores
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

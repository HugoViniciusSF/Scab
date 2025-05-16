extends Node2D

# Lista de jogadores (cada jogador é um dicionário com nome e função)
var jogadores: Array = []

# Lista de funções possíveis MUDAR PRA O QUE TEMOS NO DOCUMENTO
var funcoes_disponiveis = ["Lobisomem", "Detetive", "Vidente", "Cidadão"]

# Referências para os nós da cena
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
		return  # Não adiciona nomes vazios

	# Cria um jogador e adiciona à lista
	var jogador = {
		"nome": nome,
		"funcao": null  # Função será atribuída depois
	}
	jogadores.append(jogador)

	# Mostra o jogador na UI
	var novo_label = Label.new()
	novo_label.text = "%s foi adicionado" % nome
	jogadores_container.add_child(novo_label)

	input_nome.text = ""  # Limpa o campo de entrada

func _on_comecar_jogo_pressed():
	if jogadores.size() < 3:
		print("Mínimo de 3 jogadores necessário para começar o jogo.")
		return

	atribuir_funcoes()

	# Armazena os jogadores no autoload (singleton)
	JogoGlobal.jogadores = jogadores

	# Vai para a próxima cena
	get_tree().change_scene_to_file("res://scenes/RevelarFuncoes.tscn")

func atribuir_funcoes():
	var funcoes = funcoes_disponiveis.duplicate()
	funcoes.shuffle()

	for jogador in jogadores:
		if funcoes.size() > 0:
			jogador["funcao"] = funcoes.pop_front()
		else:
			jogador["funcao"] = "Cidadão"  # Papel padrão se acabarem

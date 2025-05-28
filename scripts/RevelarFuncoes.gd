extends Node2D

@onready var scroll_container = $ScrollContainer

var jogadores = []
var container : GridContainer

func _ready():
	configurar_layout()
	carregar_jogadores()
	criar_botoes_jogadores()

func configurar_layout():
	var center_container = CenterContainer.new()
	center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(center_container)

	container = GridContainer.new()
	container.columns = 3
	
	# Ajustei o tamanho mínimo do container para 380px de largura (quase o total da largura 400)
	container.custom_minimum_size = Vector2(380, 0)
	
	# Centralizar horizontalmente
	container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	center_container.add_child(container)

func carregar_jogadores():
	var file = FileAccess.open("user://jogadores.txt", FileAccess.READ)
	if file == null:
		push_error("Erro ao abrir jogadores.txt")
		return

	jogadores.clear()
	while not file.eof_reached():
		var line = file.get_line()
		if line.begins_with("ID "):
			var id = line.get_slice(" ", 1).strip_edges()
			var nome = line.get_slice(" - ", 1).get_slice(":", 0).strip_edges()
			var papel = line.get_slice(":", 1).get_slice("|", 0).strip_edges()
			var senha = line.get_slice("Senha:", 1).strip_edges()
			jogadores.append({
				"id": id,
				"nome": nome,
				"papel": papel,
				"senha": senha
			})
	file.close()

	# 🔠 Ordenar os jogadores por nome (alfabeticamente)
	jogadores.sort_custom(func(a, b): return a["nome"].to_lower() < b["nome"].to_lower())

func criar_botoes_jogadores():
	for jogador in jogadores:
		var botao = Button.new()
		botao.text = jogador["nome"]
		
		botao.custom_minimum_size = Vector2(120, 120)
		botao.flat = true

		botao.pressed.connect(func():
			solicitar_senha_e_revelar(jogador)
		)

		container.add_child(botao)

func solicitar_senha_e_revelar(jogador):
	var senha_dialog = AcceptDialog.new()
	senha_dialog.set_min_size(Vector2(300, 150))

	var entrada = LineEdit.new()
	entrada.placeholder_text = "Digite a senha"
	entrada.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	senha_dialog.dialog_text = "Senha para " + jogador["nome"] + ":"
	senha_dialog.add_child(entrada)
	senha_dialog.get_ok_button().text = "Revelar"
	senha_dialog.title = ""

	add_child(senha_dialog)
	
	senha_dialog.confirmed.connect(func():
		var senha_digitada = entrada.text.strip_edges()
		if senha_digitada == jogador["senha"]:
			mostrar_papel(jogador)
		else:
			mostrar_erro()
	)

	senha_dialog.popup_centered()

func mostrar_papel(jogador):
	var aviso = AcceptDialog.new()
	aviso.set_min_size(Vector2(300, 150))
	aviso.dialog_text = "Função de %s:\n%s" % [jogador["nome"], jogador["papel"]]
	aviso.get_ok_button().text = "Fechar"
	aviso.title = ""
	add_child(aviso)
	aviso.popup_centered()

func mostrar_erro():
	var erro = AcceptDialog.new()
	erro.dialog_text = "Senha incorreta!"
	erro.get_ok_button().text = "OK"
	add_child(erro)
	erro.popup_centered()

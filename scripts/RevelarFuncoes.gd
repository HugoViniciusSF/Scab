extends Node2D

@onready var container = $VBoxContainer

var jogadores = []

func _ready():
	carregar_jogadores()
	criar_botoes_jogadores()

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

func criar_botoes_jogadores():
	for jogador in jogadores:
		var botao = Button.new()
		botao.text = jogador["nome"]
		botao.pressed.connect(func():
			solicitar_senha_e_revelar(jogador)
		)
		container.add_child(botao)

func solicitar_senha_e_revelar(jogador):
	var senha_dialog = AcceptDialog.new()
	senha_dialog.set_min_size(Vector2(400, 150)) # Aumenta o tamanho do popup

	var entrada = LineEdit.new()
	entrada.placeholder_text = "Digite a senha"
	entrada.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	senha_dialog.dialog_text = "Senha para " + jogador["nome"] + ":"
	senha_dialog.add_child(entrada)
	senha_dialog.get_ok_button().text = "Revelar"
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
	aviso.dialog_text = "Função de %s:\n%s" % [jogador["nome"], jogador["papel"]]
	aviso.get_ok_button().text = "OK"
	add_child(aviso)
	aviso.popup_centered()

func mostrar_erro():
	var erro = AcceptDialog.new()
	erro.dialog_text = "Senha incorreta!"
	erro.get_ok_button().text = "OK"
	add_child(erro)
	erro.popup_centered()

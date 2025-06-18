extends Node2D

@onready var scroll_container = $ScrollContainer
@onready var seguir_botao = $SeguirBotao

var jogadores = []
var container : GridContainer

func _ready():
	configurar_layout()
	carregar_jogadores()
	criar_botoes_jogadores()
	seguir_botao.pressed.connect(_on_botao_seguir_pressed)

# --- FUNÇÃO MODIFICADA ---
func _on_botao_seguir_pressed():
	# 1. Manda o GameManager recarregar os dados do arquivo 'jogadores.txt'
	print("Atualizando GameManager com os dados dos jogadores...")
	GameManager._carregar_dados_jogadores()
	
	# 2. Depois de garantir que o GameManager está atualizado, avança para a próxima cena
	get_tree().change_scene_to_file("res://scenes/Introducao.tscn")

func configurar_layout():
	var center_container = CenterContainer.new()
	center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(center_container)

	container = GridContainer.new()
	container.columns = 3
	
	container.custom_minimum_size = Vector2(380, 0)
	
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
			var id_str = line.get_slice(" ", 1).strip_edges()
			var nome = line.get_slice(" - ", 1).get_slice(":", 0).strip_edges()
			# Adiciona uma checagem para garantir que a linha contém os separadores esperados
			if line.find(":") > -1 and line.find("Senha:") > -1:
				var papel = line.get_slice(":", 1).get_slice("|", 0).strip_edges()
				var senha = line.get_slice("Senha:", 1).strip_edges()
				jogadores.append({
					"id": id_str,
					"nome": nome,
					"papel": papel,
					"senha": senha
				})
			else:
				print("AVISO: Linha mal formatada em jogadores.txt e foi ignorada: ", line)

	file.close()

	jogadores.sort_custom(func(a, b): return a["nome"].to_lower() < b["nome"].to_lower())

func criar_botoes_jogadores():
	for jogador in jogadores:
		var botao = Button.new()
		botao.text = jogador["nome"]
		botao.custom_minimum_size = Vector2(120, 120)
		botao.flat = true
		botao.focus_mode = Control.FOCUS_NONE

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.set_border_width_all(0)
		style.corner_radius_top_left = 60
		style.corner_radius_top_right = 60
		style.corner_radius_bottom_left = 60
		style.corner_radius_bottom_right = 60

		botao.add_theme_stylebox_override("normal", style)
		botao.add_theme_stylebox_override("hover", style)
		botao.add_theme_stylebox_override("pressed", style)
		botao.add_theme_stylebox_override("disabled", style)
		botao.add_theme_stylebox_override("focus", style)

		botao.pressed.connect(func():
			solicitar_senha_e_revelar(jogador)
		)

		container.add_child(botao)

func solicitar_senha_e_revelar(jogador):
	var senha_dialog = ConfirmationDialog.new()
	senha_dialog.set_min_size(Vector2(300, 150))

	var entrada = LineEdit.new()
	entrada.placeholder_text = "Digite a senha"
	entrada.secret = true # Esconde a senha
	entrada.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vbox = VBoxContainer.new()
	vbox.add_child(entrada)
	
	senha_dialog.title = "Senha para " + jogador["nome"]
	senha_dialog.add_child(vbox)
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
	aviso.set_min_size(Vector2(300, 150))
	aviso.dialog_text = "Função de %s:\n\n%s" % [jogador["nome"], jogador["papel"]]
	aviso.get_ok_button().text = "Fechar"
	aviso.title = "Papel Revelado"
	add_child(aviso)
	aviso.popup_centered()

func mostrar_erro():
	var erro = AcceptDialog.new()
	erro.dialog_text = "Senha incorreta!"
	erro.get_ok_button().text = "OK"
	erro.title = "Erro"
	add_child(erro)
	erro.popup_centered()

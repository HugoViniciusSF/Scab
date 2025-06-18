extends Node2D

@onready var seguir_botao = $SeguirBotao
@onready var voltar_botao = $VoltarBotao
@onready var contexto_label = $ContextoContainer/ContextoLabel


var velocidade_rolagem = 20.0

func _ready():
	seguir_botao.pressed.connect(_on_botao_seguir_pressed)
	voltar_botao.pressed.connect(_on_botao_voltar_pressed)
	
	exibir_contexto_aleatorio()

func exibir_contexto_aleatorio():
	var file = FileAccess.open("user://contexto_greve.txt", FileAccess.READ)
	if file:
		var contextos = []
		while not file.eof_reached():
			var linha = file.get_line()
			if not linha.is_empty():
				contextos.append(linha)
		
		file.close()
		
		if not contextos.is_empty():
			var linha_aleatoria = contextos.pick_random()
			var partes = linha_aleatoria.split(";", false, 1)
			if partes.size() == 2:
				contexto_label.text = partes[1].strip_edges()
				
				await get_tree().process_frame
				
				contexto_label.position.y = $ContextoContainer.size.y

		else:
			contexto_label.text = "A tensão paira no ar da fábrica. Por semanas, o sindicato tentou negociar melhores condições, mas a diretoria permaneceu inflexível. Hoje, o som das máquinas finalmente silenciou. A greve foi declarada, e a luta por dignidade definirá o futuro de todos nós."
	else:
		contexto_label.text = "As negociações com a diretoria fracassaram. Cansados de promessas vazias e salários injustos, os operários cruzaram os braços. A greve é o nosso último recurso. Agora, a união do sindicato será testada contra a ganância da empresa e a traição interna."

func _process(delta):
	contexto_label.position.y -= velocidade_rolagem * delta
	
	var altura_total_rolagem = contexto_label.size.y + $ContextoContainer.size.y
	if contexto_label.position.y < -altura_total_rolagem:
		contexto_label.position.y = $ContextoContainer.size.y


func _on_botao_voltar_pressed():
	get_tree().change_scene_to_file("res://scenes/RevelarFuncoes.tscn")

func _on_botao_seguir_pressed():
	get_tree().change_scene_to_file("res://scenes/Dia.tscn")

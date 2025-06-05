extends Node2D

@onready var label_resultados = $ResultadosLabel 
func _ready():
	var file = FileAccess.open("user://RevelarVotacao.txt", FileAccess.READ)
	if file == null:
		label_resultados.text = "Erro ao carregar resultados da votação."
		push_error("Erro ao carregar RevelarVotacao.txt")
		return

	var conteudo = file.get_as_text()
	file.close()
	
	label_resultados.text = conteudo
	print("Conteúdo de RevelarVotacao.txt carregado:\n", conteudo)

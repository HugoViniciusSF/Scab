extends Node2D

@onready var label_resultados = $ResultadosLabel
@onready var seguir_botao = $SeguirBotao

func _ready():
	var revelar_file_path = "user://RevelarVotacao.txt"
	var revelar_file = FileAccess.open(revelar_file_path, FileAccess.READ)
	seguir_botao.pressed.connect(_on_botao_seguir_pressed)

	if revelar_file == null:
		label_resultados.text = "Erro ao carregar resultados da votação."
		push_error("Erro ao carregar RevelarVotacao.txt")
		return

	var revelar_content = revelar_file.get_as_text()
	revelar_file.close()
	
	label_resultados.text = revelar_content
	print("Conteúdo de RevelarVotacao.txt carregado.")

	var players_to_mark_as_killed = _get_players_to_kill(revelar_content)
	
	if players_to_mark_as_killed.is_empty():
		print("Nenhum jogador a ser marcado como morto desta vez.")
	else:
		print("Jogadores a serem marcados como mortos: ", players_to_mark_as_killed)
		_update_jogadores_txt(players_to_mark_as_killed)

func _on_botao_seguir_pressed():
	get_tree().change_scene_to_file("res://scenes/Dia.tscn")

func _get_players_to_kill(revelar_votacao_content: String) -> Array[String]:
	var lines = revelar_votacao_content.split("\n")
	var vote_counts: Dictionary = {}

	for line in lines:
		var regex = RegEx.new()
		regex.compile("^\\s*(.+?)\\s*:\\s*(\\d+)\\s*voto(s)?\\s*$")
		var match_result = regex.search(line)
		if match_result:
			var entity_name = match_result.get_string(1).strip_edges()
			var count = match_result.get_string(2).to_int()
			vote_counts[entity_name] = count

	if vote_counts.is_empty():
		printerr("Não foram encontrados contagens de votos em RevelarVotacao.txt. Não é possível determinar quem morreu.")
		return []

	var max_votes = 0
	for entity_name in vote_counts:
		if vote_counts[entity_name] > max_votes:
			max_votes = vote_counts[entity_name]
	
	if max_votes == 0:
		return []

	var most_voted_entities: Array[String] = []
	for entity_name in vote_counts:
		if vote_counts[entity_name] == max_votes:
			most_voted_entities.append(entity_name)

	var players_to_kill: Array[String] = []
	
	if most_voted_entities.size() == 1 and most_voted_entities[0] == "PULAR":
		print("PULAR foi o mais votado. Ninguém morre.")
		return []

	var pular_is_among_most_voted = false
	for entity in most_voted_entities:
		if entity == "PULAR":
			pular_is_among_most_voted = true
			break
			
	if not pular_is_among_most_voted and most_voted_entities.size() > 1:
		print("Empate entre jogadores. Ninguém morre.")
		return []

	for entity_name in most_voted_entities:
		if entity_name != "PULAR":
			players_to_kill.append(entity_name)
			
	return players_to_kill

func _update_jogadores_txt(player_names_to_kill: Array[String]):
	var jogadores_file_path = "user://jogadores.txt"
	var file_read = FileAccess.open(jogadores_file_path, FileAccess.READ)
	
	if not file_read:
		push_error("Erro ao abrir jogadores.txt para leitura ao tentar atualizar status de mortos.")
		return

	var updated_lines: Array[String] = []
	while not file_read.eof_reached():
		var line = file_read.get_line()
		var original_line = line 
		
		if line.strip_edges() == "":
			updated_lines.append(line)
			continue

		var current_player_name = ""
		if line.begins_with("ID "):
			var line_parts = line.split(" - ", false, 2) 
			if line_parts.size() >= 2:
				var info_part = line_parts[1] 
				var name_role_faction_part = info_part.split("|", false, 1)[0].strip_edges()
				if name_role_faction_part.contains(":"):
					current_player_name = name_role_faction_part.split(":", false, 1)[0].strip_edges()
		
		if current_player_name == "":
			push_warning("Não foi possível extrair nome do jogador da linha em jogadores.txt: " + original_line)
			updated_lines.append(original_line)
			continue

		var is_killed = player_names_to_kill.has(current_player_name)
		var new_morto_status_as_string = "true" if is_killed else "false"
		
		var modified_line = original_line
		
		var morto_tag_prefix = " | Morto: "
		var morto_tag_suffix_marker = " | Senha:"

		var start_of_morto_tag = original_line.find(morto_tag_prefix)

		if start_of_morto_tag != -1:
			var start_of_boolean_value = start_of_morto_tag + morto_tag_prefix.length()
			
			var end_of_boolean_value_at = original_line.find(morto_tag_suffix_marker, start_of_boolean_value)
			
			if end_of_boolean_value_at != -1:
				
				var part1 = original_line.substr(0, start_of_boolean_value)
				var part3 = original_line.substr(end_of_boolean_value_at)   
				
				modified_line = part1 + new_morto_status_as_string + part3
			else:
				push_warning("Formato inesperado: Marcador '" + morto_tag_suffix_marker + "' não encontrado após o valor de 'Morto' para o jogador: " + current_player_name + ". Linha: " + original_line)
		else:
			push_warning("Formato inesperado: Tag '" + morto_tag_prefix + "' não encontrada para o jogador: " + current_player_name + ". Linha: " + original_line)
			
		updated_lines.append(modified_line)
			
	file_read.close()

	var file_write = FileAccess.open(jogadores_file_path, FileAccess.WRITE)
	if not file_write:
		push_error("Erro ao abrir jogadores.txt para escrita.")
		return

	for updated_line in updated_lines:
		file_write.store_line(updated_line)
	file_write.close()
	print("jogadores.txt foi atualizado com o status dos jogadores (lógica de substituição aprimorada).")

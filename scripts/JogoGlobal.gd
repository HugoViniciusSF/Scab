extends Node

# Jogadores adicionados
var jogadores: Array = []

# Configurações da sala (exemplo: tempo de rodada, número mínimo, etc.)
var configuracoes_sala: Dictionary = {
	# Geral
	"revelar_funcoes": false,
	"sem_mortes_noite": false,
	"habilitar_acoes": false,

	# Votação
	"pular_votacao": false,
	"esconder_votos": false,

	# Jogadores
	"quantidade_jogadores": 0
}

# Lista de classes disponíveis no jogo
var classes_disponiveis: Array = [
	{
		"faccao": "Sindicato",
		"papel": "Líder Sindical",
		"habilidades": "Vota duas vezes na votação de expulsão. Papel revelado no início e não pode ser votado."
	},
	{
		"faccao": "Sindicato",
		"papel": "Organizador",
		"habilidades": "Ganha +1 ficha de Solidariedade por troca no Mercado. (limite 2 ou 3 por Dia)"
	},
	{
		"faccao": "Sindicato",
		"papel": "Fiscalizador",
		"habilidades": "À Noite, pode vigiar 1 jogador e saber se ele é Fura-greve."
	},
	{
		"faccao": "Sindicato",
		"papel": "Doador Sindical",
		"habilidades": "Durante o Dia, pode reviver o primeiro sindicalista eliminado na Noite anterior."
	},
	{
		"faccao": "Sindicato",
		"papel": "Cachaceiro",
		"habilidades": "Pode beber (efeito aleatório: moral +/-, evento especial)."
	},
	{
		"faccao": "Fura-greve",
		"papel": "Espião",
		"habilidades": "À Noite, transfere até 2 fichas de um sindicalista para si."
	},
	{
		"faccao": "Fura-greve",
		"papel": "Traficante",
		"habilidades": "Durante o Dia, pode trocar fichas por uma pista com o Diretor."
	},
	{
		"faccao": "Diretor",
		"papel": "Diretor da Empresa",
		"habilidades": "A cada Noite, remove 3 fichas do Banco de Solidariedade."
	}
]

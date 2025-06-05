extends Node

var jogadores: Array = []

var configuracoes_sala: Dictionary = {
	"revelar_funcoes": false,
	"sem_mortes_noite": false,
	"habilitar_acoes": false,

	"pular_votacao": false,
	"esconder_votos": false,

	"quantidade_jogadores": 0
}

var classes_disponiveis: Array = [
	{
		"faccao": "Sindicato",
		"papel": "Líder Sindical",
		"habilidades": "Vota duas vezes na votação de expulsão (contam como votos separados). Este papel é revelado no início do jogo e não pode ser votado para expulsão."
	},
	{
		"faccao": "Sindicato",
		"papel": "Membro",
		"habilidades": "O Membro é um sindicalista sem habilidades especiais, mas sua presença é crucial para manter a maioria do Sindicato. Eles participam das negociações, debates e votações, ajudando a identificar e expulsar os Fura-greves."
	},
	{
		"faccao": "Sindicato",
		"papel": "Organizador",
		"habilidades": "Ganha +1 ficha de Solidariedade pessoal ao final do Dia se fechar ao menos 1 troca no Mercado de Negociações. (Sugestão: +1 ficha por troca, limitado a 2 ou 3 por Dia)."
	},
	{
		"faccao": "Sindicato",
		"papel": "Fiscalizador",
		"habilidades": "À Noite, pode “vigiar” 1 jogador: o aplicativo informa secretamente se o alvo é Fura-greve (sim/não), mas não revela o papel específico."
	},
	{
		"faccao": "Sindicato",
		"papel": "Doador Sindical",
		"habilidades": "Ao Dia, pode gastar 2 fichas do Banco de Solidariedade (via aplicativo) para \"reviver\" o primeiro sindicalista eliminado na Fase de Noite anterior."
	},
	{
		"faccao": "Sindicato",
		"papel": "Cachaceiro",
		"habilidades": "Ao Dia, pode gastar 1 ficha do Banco de Solidariedade (via aplicativo) para \"beber\". O aplicativo sorteia um efeito: pode aumentar ou diminuir a Moral, ou causar outro evento aleatório (ver sugestões na seção de Mecânicas)."
	},
	{
		"faccao": "Fura-greve",
		"papel": "Espião",
		"habilidades": "À Noite, escolhe um jogador Sindicalista alvo. O aplicativo transfere até 2 fichas de Solidariedade pessoais do alvo para o Espião."
	},
	{
		"faccao": "Fura-greve",
		"papel": "Traficante",
		"habilidades": "Ao Dia, pode oferecer fichas de Solidariedade pessoais ao Diretor (via negociação física e registro no app) para receber uma pista (o aplicativo mostra uma Carta de Informante ao Traficante)."
	},
	{
		"faccao": "Diretor",
		"papel": "Diretor da Empresa",
		"habilidades": "A cada Noite, o aplicativo descarta 3 fichas do Banco de Solidariedade em \"corte de verba\" (sem roubar fichas para si)."
	}
];


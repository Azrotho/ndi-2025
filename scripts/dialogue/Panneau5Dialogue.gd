extends Node
class_name Panneau5Dialogue


static var liste_dialogues = [
	{
		"type": "message",
		"text": "Welcome to Neotown !\nWhere technology primes !"
	},
	{
		"type": "message",
		"text": "Learn here the laws of gravity\nand inertia"
	}
]

var nameDiag = "panneau5"

func getDialogue():
	return liste_dialogues

func getName():
	return nameDiag

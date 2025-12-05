extends Node
class_name Panneau6Dialogue


static var liste_dialogues = [
	{
		"type": "message",
		"text": "Time to show your physics skills !\nDon't forget inertia's laws"
	},
]

var nameDiag = "panneau6"

func getDialogue():
	return liste_dialogues

func getName():
	return nameDiag

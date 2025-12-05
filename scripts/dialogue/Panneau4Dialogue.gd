extends Node
class_name Panneau4Dialogue


static var liste_dialogues = [
	{
		"type": "message",
		"text": "Trust and Jump."
	},
	{
		"type": "message",
		"text": "Go on, you're halfway through !"
	}
]

var nameDiag = "panneau4"

func getDialogue():
	return liste_dialogues

func getName():
	return nameDiag

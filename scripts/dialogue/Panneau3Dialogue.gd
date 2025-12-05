extends Node
class_name Panneau3Dialogue


static var liste_dialogues = [
	{
		"type": "message",
		"text": "Human Shelter's Entrance"
	}
]

var nameDiag = "panneau3"

func getDialogue():
	return liste_dialogues

func getName():
	return nameDiag

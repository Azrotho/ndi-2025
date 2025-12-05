extends Dialogue
class_name Panneau1Dialogue

static var liste_dialogues = [
	{
		"type": "message",
		"text": "hey i'm a sign!"
	}
]

var nameDiag = "test"

func getDialogue():
	return liste_dialogues

func getName():
	return nameDiag
extends Dialogue
class_name DialogueTest

static var liste_dialogues = [
	{
		"type": "message",
		"text": "Salut je suis Azrotho!"
	},
	{
		"type": "message",
		"text": "Je suis gentil"
	},
	{
		"type": "message",
		"text": "et je sens bon!"
	}
]

var nameDiag = "test"

func getDialogue():
	return liste_dialogues

func getName():
	return nameDiag

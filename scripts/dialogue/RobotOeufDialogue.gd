extends Dialogue
class_name RobotOeufDialogue

static var liste_dialogues = [
	{
		"type": "message",
		"text": "Hey ! \nThat's my head !"
	},
	{
		"type": "message",
		"text": "I ? I am a Robot, I fell and lost \nmyself on my way back to the top."
	},
	{
		"type": "message",
		"text": "You are ?\n John Fish Carpe ?"
	},
	{
		"type": "message",
		"text": "That's nice i like this name !"
	},
	{
		"type": "message",
		"text": "Follow the damaged wood, \nmy friend."
	},
	{
		"type": "message",
		"text": "Do it for m... .nd those who failed..."
	}
]

var nameDiag = "robotOeuf"

func getDialogue():
	return liste_dialogues

func getName():
	return nameDiag

extends Dialogue
class_name RobotCasseDialogue

static var liste_dialogues = [
	{
		"type": "message",
		"text": "Hey kiddo! \n It's dangerous to go alone !"
	},
	{
		"type": "message",
		"text": "This tower is very high, \n be careful !"
	},
	{
		"type": "message",
		"text": "And this acid ocean made me \n unable to climb it back."
	},
	{
		"type": "message",
		"text": "Good luck tiny fish..."
	}
]

var nameDiag = "robotCasse"

func getDialogue():
	return liste_dialogues

func getName():
	return nameDiag

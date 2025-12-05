extends Node
class_name Panneau7Dialogue


static var liste_dialogues = [
	{
		"type": "message",
		"text": "Prepare yourself for there is no\nturning back !"
	},
	{
		"type": "message",
		"text": "Enter the portal to Mars and join\n the rest of Humanity !"
	},
	{
		"type": "message",
		"text": "Be sure not to leave anything\nbehind you."
	},
{
		"type": "message",
		"text": "If you're ready, step into the\nportal."
	},
]

var nameDiag = "panneau6"

func getDialogue():
	return liste_dialogues

func getName():
	return nameDiag

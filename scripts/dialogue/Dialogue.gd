extends Node
class_name Dialogue

@onready var list_dialogues = {
	"test": DialogueTest.new(),
	"robotcasse": RobotCasseDialogue.new()
}


func getDialogue():
	pass

func getName():
	pass

func getDialogues():
	pass

func getMessages(dialogueName : String):
	return list_dialogues[dialogueName].getDialogue()

func getMessage(dialogueName : String, messageIndex : int):
	var dialogue : Dialogue = list_dialogues[dialogueName]
	var dialogue_dict : Dictionary = dialogue.getDialogue()[messageIndex]
	return dialogue_dict

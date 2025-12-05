extends Node
class_name Panneau2Dialogue


static var liste_dialogues = [
	{
		"type": "message",
		"text": "Do you want to know the \nmeaning of life?"
	},
	{
		"type": "message",
		"text": "it's really interesting \nyou should really know about"
	},
	{
		"type": "message",
		"text": "In the words of\nSigmund Freud"
	},
	{
		"type": "message",
		"text": "damn, I forgot what he said\ntoo bad..."
	},
	{
		"type": "message",
		"text": "Sooo, you want to know\nthe meaning of life?"
	},
	{
		"type": "message",
		"text": "I hope you don't\nget bored :D"
	},
	{
		"type": "message",
		"text": "I will answer the question\nin 500 texts"
	},
	{
		"type": "message",
		"text": "hehe, i am just kidding :D"
	},
	{
		"type": "message",
		"text": "Before the answer, \nI have a question for you"	
	},
	{
		"type": "message",
		"text": "Do you know the\nmeaning of life?"
	},
	{
		"type": "message",
		"text": "I hope you do\nbecause I don't"
	},
	{
		"type": "message",
		"text": "I am just a sign!\nJean-Paneau d'affichage :D"
	},
	{
		"type": "message",
		"text": "My name is from..."
	},
	{
		"type": "message",
		"text": "I don't know\nI am just a sign!"
	},
	{
		"type": "message",
		"text": "I am just a sign\nI don't have a name"
	},
	{
		"type": "message",
		"text": "Okay, I will tell you\nthe meaning of life"
	},
	{
		"type": "message",
		"text": "It was a joke\nI have the answer!"
	},
	{
		"type": "message",
		"text": "The meaning of life is..."
	},
	{
		"type": "message",
		"text": "I am just a sign ! :D"
	},
	{
		"type": "message",
		"text": "I mean, it's MY meaning of life\nI am just a sign"
	},
	{
		"type": "message",
		"text": "I am just a sign\nI don't have a meaning"
	},
	{
		"type": "message",
		"text": "But you, you have a meaning\nyou are a human"
	},
	{
		"type": "message",
		"text": "You have a purpose\nyou have a life"
	},
	{
		"type": "message",
		"text": "I hope you will find\nyour meaning of life"
	},
	{
		"type": "message",
		"text": "I hope you will find\nyour purpose"
	},
	{
		"type": "message",
		"text": "BUT i know the universal\nmeaning of life !"
	},
	{
		"type": "message",
		"text": "The universal meaning of life is..."
	},
	{
		"type": "message",
		"text": "[REMOVED TO CONFORM WITH\nLOCAL AND INTERNATIONAL"
	},
	{
		"type": "message",
		"text": "CENSORSHIP LAWS]"
	},
	{
		"type": "message",
		"text": "I hope you are happy\nwith the answer !"
	},
	{
		"type": "message",
		"text": "oh, sorry, the universal\nmeaning of life is..."
	},
	{
		"type": "message",
		"text": "TOP SECRET :c"
	},
	{
		"type": "message",
		"text": "i think i have an idea"
	},
	{
		"type": "message",
		"text": "Did you know Hexadecimal\nand ascii table?"
	},
	{
		"type": "message",
		"text": "49 27 4D 20 41 20 \n53 49 47 4E 21"
	},
	{
		"type": "message",
		"text": "thank you for reading\nmy messages!"
	},
]

var nameDiag = "robotCasse"

func getDialogue():
	return liste_dialogues

func getName():
	return nameDiag

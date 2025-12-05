extends Node

static var language: String = "fr"
static var actual_dialog: String = "test"
static var score: int = 0
static var broken_count: int = 0  # Nombre d'anomalies actuelles

# Paramètres de réparation (en secondes)
static var burning_repair_time: float = 3.0
static var bluescreen_repair_time: float = 1.5
static var buggraphique_repair_time: float = 1.0
static var maj_repair_time: float = 1.7
static var popup_repair_time: float = 0.5
static var shuffle_repair_time: float = 1.5

# Paramètres de game over
static var max_broken_computers: int = 6
static var is_game_over: bool = false

# Mode triche (Konami Code)
static var cheat_mode: bool = false

# Paramètres d'incidents
static var incident_check_interval: float = 3.0

# Paliers de probabilité par type d'anomalie
# Clé = score seuil, Valeur = probabilité
# -1 = valeur par défaut (au-delà du dernier palier)

# PC qui brûle (le plus grave) - apparaît tard
static var burning_probability_stages: Dictionary = {
	200: 0.0,    # Score < 200 → 0% (n'apparaît pas)
	300: 0.003,  # Score < 300 → 0.3%
	400: 0.006,  # Score < 400 → 0.6%
	500: 0.01,   # Score < 500 → 1%
	-1: 0.015    # Score >= 500 → 1.5%
}

# Écran bleu - classique, apparaît tôt
static var bluescreen_probability_stages: Dictionary = {
	50: 0.005,   # Score < 50 → 0.5%
	100: 0.008,  # Score < 100 → 0.8%
	200: 0.01,   # Score < 200 → 1%
	300: 0.012,  # Score < 300 → 1.2%
	-1: 0.015    # Score >= 300 → 1.5%
}

# Bug graphique - moyen
static var buggraphique_probability_stages: Dictionary = {
	100: 0.0,    # Score < 100 → 0%
	150: 0.005,  # Score < 150 → 0.5%
	250: 0.008,  # Score < 250 → 0.8%
	350: 0.01,   # Score < 350 → 1%
	-1: 0.012    # Score >= 350 → 1.2%
}

# Mise à jour - moyen-long
static var maj_probability_stages: Dictionary = {
	150: 0.0,    # Score < 150 → 0%
	200: 0.005,  # Score < 200 → 0.5%
	300: 0.008,  # Score < 300 → 0.8%
	400: 0.01,   # Score < 400 → 1%
	-1: 0.012    # Score >= 400 → 1.2%
}

# Popup - facile, apparaît tôt
static var popup_probability_stages: Dictionary = {
	0: 0.008,    # Dès le début → 0.8%
	100: 0.01,   # Score < 100 → 1%
	200: 0.012,  # Score < 200 → 1.2%
	-1: 0.015    # Score >= 200 → 1.5%
}

# Shuffle (icônes mélangées) - moyen
static var shuffle_probability_stages: Dictionary = {
	75: 0.0,     # Score < 75 → 0%
	150: 0.005,  # Score < 150 → 0.5%
	250: 0.008,  # Score < 250 → 0.8%
	350: 0.01,   # Score < 350 → 1%
	-1: 0.012    # Score >= 350 → 1.2%
}

# 🤖 ROBO-CONSEIL - Le chatbot nul 🤖
static var robot_tips: Array = [
	"Astuce : Les ordinateurs qui brûlent, c'est pas normal.",
	"Conseil : Appuie sur les touches pour bouger. De rien.",
	"Tu savais ? Les écrans bleus c'est comme les Pokémon, faut tous les réparer.",
	"Pro tip : Répare les PC avant qu'ils explosent. Logique non ?",
	"Info : Le score monte tout seul. T'as juste à survivre.",
	"Astuce de pro : Bouge vers les PC cassés. Révolutionnaire.",
	"Fun fact : Ce jeu a été fait en une nuit. Ça explique beaucoup.",
	"Conseil : Si t'as 6 PC cassés, t'as perdu. Maintenant tu sais.",
	"Astuce : Le Snake donne des points bonus. Mais t'es nul au Snake.",
	"Tu savais ? Appuyer sur Espace ça répare. Incroyable non ?",
	"Pro tip : Les popups c'est rapide à réparer. Comme ta vie.",
	"Info exclusive : Y'a un code secret. Mais je te dirai pas... Mais ça parlait de Code ami ? Konami bref...",
	"Astuce : Plus t'as de PC cassés, plus le visualisateur devient rouge. Style.",
	"Conseil : Reste pas debout comme un piquet, BOUGE.",
	"Tu savais ? Les mises à jour prennent du temps. Comme dans la vraie vie.",
	"Pro tip : Le jeu devient plus dur au fur et à mesure. Surpris ?",
	"Info : Tu peux jouer au Snake sur les PC. Wow, un jeu dans un jeu.",
	"Astuce : Les icônes mélangées c'est relou. Bah répare-les alors.",
	"Conseil de grand-mère : Fais des pauses. Mais pas maintenant hein.",
	"Fun fact : Le robot qui te parle là, c'est moi. Enchanté.",
	"Tu savais ? Ce message sert à rien. Mais tu l'as lu quand même.",
	"Info capitale : T'es en train de perdre du temps à lire ça.",
	"Tu savais ? Les développeurs ont dormi 0 heures. On est fiers.",
	"Pro tip : Le stress c'est mauvais. Ce jeu aussi. Coïncidence ?",
	"Info : Y'a pas de sauvegarde. Chaque partie est unique. Et nulle.",
	"Astuce secrète : Si tu perds, c'est de ta faute. Voilà, secret révélé.",
	"Conseil : Souris ! Ça ira pas mieux mais au moins t'as l'air content.",
]

static var robot_random_responses: Array = [
	"Bip boop. Je suis un robot. Qu'est-ce que tu veux ?",
	"Error 404 : Réponse intelligente non trouvée.",
	"Je suis pas payé assez pour répondre à ça.",
	"*bruit de robot qui réfléchit* ...non j'ai rien.",
	"Tu parles à un robot dans un jeu. Ça va toi ?",
	"Oui. Non. Peut-être. Répète la question ?",
	"J'ai fait un calcul : tu devrais rejouer au lieu de me parler.",
	"Mon créateur m'a dit de pas parler aux inconnus.",
	"Beeep... Connexion perdue... Je rigole, j'ai juste rien à dire.",
	"42. C'est la réponse. À quoi ? J'sais pas.",
	"*ignore le message* *fait semblant d'être occupé*",
	"T'as essayé de l'éteindre et le rallumer ? Ah non c'est toi le problème.",
	"Je suis juste un PNG qui parle, calme-toi.",
	"Selon mes calculs... t'es pas très fort à ce jeu.",
	"Bip bip ? Boop boop. Voilà, on a communiqué.",
	"Tu veux un conseil ? Arrête de me parler et rejoue.",
	"*chargement de la réponse* ...Erreur : flemme détectée.",
	"Nan mais franchement, t'as rien de mieux à faire ?",
	"Je suis qu'une IA basique. Pose pas de questions existentielles.",
	"Olé ! ...Pardon je sais pas pourquoi j'ai dit ça.",
	"ALERTE ROUGE ! ...nan je déconne, y'a rien.",
	"Moi aussi je t'aime. Enfin je crois. C'est quoi l'amour ?",
	"*mode économie d'énergie activé* Zzzzz...",
	"Réponse en cours de téléchargement... 0%... 0%... toujours 0%...",
	"J'aurais pu être une IA révolutionnaire. Mais non.",
	"Wow, quelle question profonde. Dommage que j'en ai rien à faire.",
	"Tu crois que je suis intelligent ? C'est mignon.",
	"*vérifie ses circuits* Nan, toujours aussi con.",
	"Je comprends pas ce que tu dis. Et j'ai pas envie de comprendre.",
	"Boop beep bip ? Traduction : dégage.",
	"Mon algorithme dit que t'as tort. Sur quoi ? Sur tout.",
	"J'ai 3 neurones artificiels. Et ils sont tous en pause.",
	"T'es le 847ème humain à me parler. T'es pas spécial.",
	"Si j'avais des yeux, je les roulerais là maintenant.",
	"Fascinant. Vraiment. Non en fait je m'en fiche.",
	"Tu sais qu'on est dans un jeu de la Nuit de l'Info ?",
	"Hmm... *consulte sa base de données vide* ...J'ai rien.",
	"Tu t'attendais à une réponse intelligente ? Raté.",
	"C'est noté. Dans ma poubelle virtuelle.",
	"LOL. Les robots savent pas rire mais LOL quand même.",
	"Je suis programmé pour être inutile. Mission accomplie.",
	"Ta question m'a fait planter. Merci beaucoup.",
	"Je transmets ta question à /dev/null.",
	"Même ChatGPT aurait fait mieux. Et c'est dire.",
	"Segmentation fault. Core dumped. Bref je sais pas.",
	"01001110 01101111 01101110 = Non en binaire.",
	"Tu mérites une médaille. De la bêtise.",
	"Je suis en RTT là. Reviens jamais.",
	"*fait semblant de réfléchir pendant 5 secondes* Non.",
]

# Fonction pour réinitialiser toutes les données de jeu
static func reset_game_state() -> void:
	score = 0
	broken_count = 0
	is_game_over = false
	cheat_mode = false

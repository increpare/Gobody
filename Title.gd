extends Control



onready var selectionitems:Array = [
	$Control/VBoxContainer/Player1,
	$Control/VBoxContainer/Player2,
	$Control/VBoxContainer/Handicap,
	$Control/VBoxContainer/Start,
	$Control/VBoxContainer/Help,
	$Control/VBoxContainer/Credits,
	$Control/VBoxContainer/QUIT
]

var handicapboards:Array = [
	preload("res://handicaps/hc0.png"),
	preload("res://handicaps/hc2.png"),
	preload("res://handicaps/hc3.png"),
	preload("res://handicaps/hc4.png"),
	preload("res://handicaps/hc5.png"),
]

onready var bgrects:Array = [
	$Control/VBoxContainer/Player1/ColorRect,
	$Control/VBoxContainer/Player2/ColorRect,
	$Control/VBoxContainer/Handicap/ColorRect,
	$Control/VBoxContainer/Start/ColorRect,
	$Control/VBoxContainer/Help/ColorRect,
	$Control/VBoxContainer/Credits/ColorRect,
	$Control/VBoxContainer/QUIT/ColorRect,	
]
func wrap(s):
	return s# "["+s+"]"

func updateDisplay():
		
	var p1text = "black:"
	if Global.player1:
		p1text = p1text + "HUMAN"
	else:
		p1text = p1text + "CPU"
		
		
	var p2text = "white:"
	if Global.player2:
		p2text = p2text + "HUMAN"
	else:
		p2text = p2text + "CPU"
		
	
	var handicaptext = "handicap:"
	if Global.handicap==0:
		handicaptext = handicaptext + "NONE"
	else:
		handicaptext = handicaptext + "BLACK+" + str(Global.handicap+1)

	$Control/VBoxContainer/Handicap/Hc4.texture = handicapboards[Global.handicap]
	
	var starttext = "START"		
	var helptext = "HELP"
	var creditstext = "CREDITS"
	var quittext = "QUIT"
	
	for i in bgrects.size():
		var rect : ColorRect = bgrects[i]
		rect.visible = i==Global.menuselect
		
	match Global.menuselect:
		0:
			p1text = wrap(p1text)
		1:
			p2text = wrap(p2text)
		2:
			handicaptext = wrap(handicaptext)
		3: 
			starttext = wrap(starttext);
		4:
			creditstext = wrap(creditstext)
		5:
			helptext = wrap(helptext)
		6:
			quittext = wrap(quittext)
			
	$Control/VBoxContainer/Player1.text = p1text
	$Control/VBoxContainer/Player2.text = p2text
	$Control/VBoxContainer/Handicap.text = handicaptext
	$Control/VBoxContainer/Start.text = starttext
	$Control/VBoxContainer/Help.text = helptext
	$Control/VBoxContainer/Credits.text = creditstext
	$Control/VBoxContainer/QUIT.text = quittext
	
# Called when the node enters the scene tree for the first time.
var web:bool=false

func _ready():
	web =  OS.get_name()=="HTML5"
	
	if web:
		$Control/VBoxContainer/QUIT.visible=false
		
	updateDisplay()
	
	
	# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("cursor_up"):
		if Global.menuselect>0:
			Global.menuselect = Global.menuselect - 1
			updateDisplay()
	if Input.is_action_just_pressed("cursor_down"):
		if Global.menuselect<6:		
			Global.menuselect = Global.menuselect + 1
			if web and Global.menuselect==6:
				Global.menuselect=5
			updateDisplay()

	match Global.menuselect:
		0:
			if Input.is_action_just_pressed("cursor_left") or Input.is_action_just_pressed("cursor_right") or Input.is_action_just_pressed("ui_accept"):
				Global.player1 = not Global.player1
				updateDisplay()
		1:
			if Input.is_action_just_pressed("cursor_left") or Input.is_action_just_pressed("cursor_right") or Input.is_action_just_pressed("ui_accept"):
				Global.player2 = not Global.player2
				updateDisplay()
		2:
			if Input.is_action_just_pressed("cursor_left") :
				if Global.handicap>0:
					Global.handicap = Global.handicap - 1
					updateDisplay()
			if Input.is_action_just_pressed("cursor_right") :
				if Global.handicap<4:
					Global.handicap = Global.handicap + 1
					updateDisplay()
		3:
			if Input.is_action_just_pressed("ui_accept"):
				get_tree().change_scene("res://Pachingo.tscn")
		4:
			if Input.is_action_just_pressed("ui_accept"):
				get_tree().change_scene("res://help.tscn")
		5:
			if Input.is_action_just_pressed("ui_accept"):
				get_tree().change_scene("res://credits.tscn")
		6:
			if Input.is_action_just_pressed("ui_accept"):
				get_tree().quit()


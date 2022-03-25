extends Node

onready var player1 :bool= true
onready var player2 :bool= false
onready var handicap  :int= 0
onready var menuselect:int=3

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	
	if Input.is_key_pressed(KEY_ESCAPE):	
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

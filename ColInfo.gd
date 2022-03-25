extends Area

export var col:int=0

var row:int=-1
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	row = get_parent().row



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

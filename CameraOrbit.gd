class_name OrbitCamera
extends Spatial

# Control variables
export var max_pitch: float = 0
export var min_pitch: float = -20

#export var max_yaw: float = 45
#export var min_yaw: float = -45

export var max_zoom: float = 20
export var min_zoom: float = 4
export var zoom_step: float = 2
export var zoom_y_step: float = 0.15
export var vertical_sensitivity: float = 0.002
export var horizontal_sensitivity: float = 0.002
export var cam_y_offset: float = 4.0
export var cam_lerp_speed: float = 16.0

export var sensitivity_key:float=5

export (NodePath) var target

var zoomgesturestep:float =0.01

# Private variables
var _cam_target: Spatial = null
var _cam: Camera
var _cur_zoom: float = 0.0


func _ready() -> void:
	# Setup node references
	_cam_target = get_node(target)
	_cam = $Camera

	# Setup camera position in rig
	_cam.translate(Vector3(0, cam_y_offset, max_zoom))
	_cur_zoom = max_zoom


func _input(event) -> void:		
	#print (event.as_text())
	if event is InputEventMouseMotion:
		# Rotate the rig around the target
		rotation.x = clamp(
			rotation.x - event.relative.y * horizontal_sensitivity,
			deg2rad(min_pitch),
			deg2rad(max_pitch)
		)
		orthonormalize()

		rotation.y = rotation.y - event.relative.x * vertical_sensitivity
#		clamp(
#			rotation.y - event.relative.x * vertical_sensitivity,
#			deg2rad(min_yaw),
#			deg2rad(max_yaw)
#		)
		orthonormalize()
	if event is InputEventMouseButton:
		# Change zoom level on mouse wheel rotation
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP and _cur_zoom > min_zoom:
				_cur_zoom -= zoom_step
				cam_y_offset -= zoom_y_step
			if event.button_index == BUTTON_WHEEL_DOWN and _cur_zoom < max_zoom:
				_cur_zoom += zoom_step
				cam_y_offset += zoom_y_step
	if event is InputEventMagnifyGesture:
		if event.factor>1 and _cur_zoom > min_zoom:
			_cur_zoom -= zoom_step*zoomgesturestep*5
			cam_y_offset -= zoom_y_step*zoomgesturestep*5
		elif event.factor<1 and _cur_zoom < max_zoom:
			_cur_zoom += zoom_step*zoomgesturestep*5
			cam_y_offset += zoom_y_step*zoomgesturestep*5
	if event is InputEventPanGesture:
		if event.delta.y<-0.1 and _cur_zoom > min_zoom:
			_cur_zoom -= zoom_step*zoomgesturestep*5
			cam_y_offset -= zoom_y_step*zoomgesturestep*5
		elif event.delta.y>0.1 and _cur_zoom < max_zoom:
			_cur_zoom += zoom_step*zoomgesturestep*5
			cam_y_offset += zoom_y_step*zoomgesturestep*5
			


func _process(delta) -> void:
	var rot_1:float=0
	var rot_2:float=0
	
	if Input.is_action_pressed("cursor_down"):
		rot_1 = rot_1 - sensitivity_key*delta	
	if Input.is_action_pressed("cursor_up"):
		rot_1 = rot_1 + sensitivity_key*delta	
	if Input.is_action_pressed("cursor_left"):
		rot_2 = rot_2 + sensitivity_key*delta	
	if Input.is_action_pressed("cursor_right"):
		rot_2 = rot_2 - sensitivity_key*delta


	if Input.is_action_pressed("ui_page_up") and _cur_zoom > min_zoom:
		_cur_zoom -= zoom_step*delta*5
		cam_y_offset -= zoom_y_step*delta*5
	if Input.is_action_pressed("ui_page_down") and _cur_zoom < max_zoom:
		_cur_zoom += zoom_step*delta*5
		cam_y_offset += zoom_y_step*delta*5


	rotation.y = rotation.y - rot_2
#	clamp(
#		rotation.y - rot_2,
#		deg2rad(min_yaw),
#		deg2rad(max_yaw)
#	)
	rotation.x = clamp(
		rotation.x - rot_1,
		deg2rad(min_pitch),
		deg2rad(max_pitch)
	)
	
	orthonormalize()
	
	# zoom the camera accordingly
	_cam.set_translation(
		_cam.translation.linear_interpolate(
			Vector3(0, cam_y_offset, _cur_zoom), delta * cam_lerp_speed
		)
	)
	# set the position of the rig to follow the target
	set_translation(_cam_target.global_transform.origin)


func set_target(new_target: Spatial):
	_cam_target = new_target

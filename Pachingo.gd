extends Spatial

var stones = [preload("res://Whitestone.tscn"),preload("res://Blackstone.tscn")]

var sfx_turnstart = [ preload("res://audio/Audiospur.wav"), preload("res://audio/Audiospur.wav") ]
var sfx_wingame = [ preload("res://audio/player1win.mp3"), preload("res://audio/player2win.mp3") ]


export var movement_speed:float=8

export var cursor_min_x:float=-5
export var cursor_max_x:float=-5
export var cursor_min_z:float=-5
export var cursor_max_z:float=-5

const stone_info_script = preload("res://StoneInfo.gd")

var boardstate:Array=[]
var unplacedstones:Array=[]

var rod_overlapmaterial = preload("res://materials/woodenrods_althighlight.material")
var rod_nooverlapmaterial = preload("res://materials/woodenrods.material")

var edgehighlight_black_material = preload("res://materials/edgehighlight_black.tres")
var edgehighlight_white_material = preload("res://materials/edgehighlight_white.tres")

var sfx_hit = preload("res://audio/Audiospur-2.wav")
var sfx_destroy = preload("res://audio/Audiospur-4.wav")
var sfx_place = preload("res://audio/placepiece.wav")

export(Array,Color) var cursorCols : Array = [  Color.white,Color.black ]
export(Array,Color) var cursorCols_Map : Array = [  Color.white,Color.black ]

var rods:Array=[]

var borderhighlights:Array=[]

#0,1,2 for draw
var winner:int=-1

var turn:int=1

func resetCursor():
	var t = $Placement.translation
	t.x=0
	t.z=0
	$Placement.translation=t

func stonehit(body: Node,stone:RigidBody):
	$Board/AudioStreamPlayer3D.stop()
	$Board/AudioStreamPlayer3D.global_transform.origin = stone.global_transform.origin
	$Board/AudioStreamPlayer3D.stream=sfx_hit
	$Board/AudioStreamPlayer3D.play()

	
var onestonespawned:bool =false
var gameover:bool = false

func spawnStoneAt(v:Vector3,col:int):
	var stone = stones[col]
	var newStone : RigidBody = stone.instance()
	unplacedstones.append(newStone)
	
	newStone.contact_monitor=true
	newStone.contacts_reported=1
	newStone.connect("body_entered",self,"stonehit",[newStone])
	#$Placement.add_child(newStone)
	
	#$Placement.get_parent().remove_child(newStone)
	$Stones.add_child(newStone)
	newStone.global_translate( v )	
	
	$Board/AudioStreamPlayer3D.stop()
	$Board/AudioStreamPlayer3D.global_transform.origin = v
	$Board/AudioStreamPlayer3D.stream=sfx_place
	$Board/AudioStreamPlayer3D.play()
	

	
func spawnStone(force:bool=false):
	if (gameover or onestonespawned) and not force:
		return 
		
	spawnStoneAt($Placement.global_transform.origin,turn%2)
	
	if not force:
		onestonespawned= true
		yield(get_tree().create_timer(3), "timeout")
		turn = turn+1
		setNewTurn()
	

var ai_x:float=0.5;
var ai_z:float=0.5;
var ai_wait:float=-1;
func setNewTurn():	
	if gameover:
		return
		
	ai_wait=0.5
	if turn%2==0:
		$Placement.scale = Vector3(0.890,1.0,0.890)
	else:
		$Placement.scale = Vector3(0.905,1.0,0.905)
	onestonespawned=false
	var cursorcol = cursorCols[turn%2]
	var mat : SpatialMaterial = $Placement/PlacementCylinder.get_surface_material(0);
	mat.albedo_color = cursorcol
	var cursorcol_map = cursorCols_Map[turn%2]
	var mat_map : SpatialMaterial = $Placement/PlacementCylinder/Map_Cylinder.get_surface_material(0)
	mat_map.albedo_color = cursorcol_map
	
	randomize()
	
	var enemypositions:Array = []
	for i in 9:
		for j in 9:
			var piece = boardstate[i][j]
			if is_instance_valid(piece)==false:
				boardstate[i][j]=null
				piece=null
			if piece==null:
				continue
			if piece.type!=turn%2:
				enemypositions.append([i,j])
			
	var unit_x = (cursor_max_x-cursor_min_x)/10.0
	var unit_z = (cursor_max_z-cursor_min_z)/10.0
	
	if enemypositions.size()==0 or randf()<0.1:
		ai_x = cursor_min_x + (cursor_max_x-cursor_min_x)*randf()
		ai_z = cursor_min_z + (cursor_max_z-cursor_min_z)*randf()
	else:
		var target = enemypositions[randi()%enemypositions.size()]
		var i = target[0]
		var j = target[1]
		var physical_location:Area=$Areas.get_child(i).get_child(j)
		ai_x=physical_location.global_transform.origin.x
		ai_z=physical_location.global_transform.origin.z
		ai_x = ai_x + unit_x*2*(2*randf()-1)
		ai_z = ai_z + unit_z*2*(2*randf()-1)
		ai_x = clamp(ai_x,cursor_min_x,cursor_max_x)
		ai_z = clamp(ai_z,cursor_min_z,cursor_max_z)
		
	#keep ai away from the corners with high probability
	if randf()>0.1:
		var xedge = (abs(cursor_min_x-ai_x)<unit_x*1.5) or (abs(cursor_max_x-ai_x)<unit_x*1.5)
		var zedge = (abs(cursor_min_z-ai_z)<unit_z*1.5) or (abs(cursor_max_z-ai_z)<unit_z*1.5)
		if xedge and zedge:
			print("keeping away from edge")
			ai_x = ai_x*0.8
			ai_z = ai_z*0.8
	$World/AudioStreamPlayer.stop()
	$World/AudioStreamPlayer.pitch_scale=1.0
	$World/AudioStreamPlayer.volume_db=-15
	$World/AudioStreamPlayer.stream = sfx_turnstart[turn%2]
	$World/AudioStreamPlayer.play()
	
	var turnlabel:Label
	var otherlabel:Label
	if turn%2==0:
		turnlabel=$CanvasLayer/Control2/WhitesTurn
		otherlabel=$CanvasLayer/Control2/BlacksTurn
	else:
		otherlabel=$CanvasLayer/Control2/WhitesTurn
		turnlabel=$CanvasLayer/Control2/BlacksTurn
	
	otherlabel.visible=false
	turnlabel.visible=true
	turnlabel.percent_visible=0
	targettext = turnlabel
	targettext_chars_visible_old=0
	var tween:Tween = $CanvasLayer/Control2/Tween	
	tween.interpolate_property(turnlabel, "percent_visible",0,1, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.interpolate_property(turnlabel, "percent_visible",1,0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN,1)
	tween.start()


func cursor_area_entered(body:Node):
	if body.name=="StaticBody":
		var parent:MeshInstance = body.get_parent()
		parent.material_override = rod_overlapmaterial
	
func cursor_area_exited(body:Node):
	if body.name=="StaticBody":
		var parent:MeshInstance = body.get_parent()
		parent.material_override = null

#null no capture, [side,area] capture
func detect_capture(i,j):
	if i<0 or j<0 or i>=9 or j>=9:
		return null
	#flood fill out from i,j - each time check if any neighbour is blank. if so: not captured
	var piece = boardstate[i][j]
	if not is_instance_valid(piece):
		boardstate[i][j]=null
		return null
		
	if piece==null:
		return null
	var type = piece.type
	#print("checking", [i,j],type)
	var visited= [ ]
	var unvisited = [ [i,j] ]
	var fillarea=[]
	while unvisited.size()>0:
		var l = unvisited.pop_front()
		var li=l[0]
		var lj=l[1]
		
		#print("popping visited", [li,lj]," from ",unvisited)
		var l_id = li+9*lj
		if li<0 or lj<0 or li>=9 or lj >= 9:
			#print("oob")
			continue
		if visited.find(l_id)>=0:
			#print("already visited")
			continue
		visited.append(l_id)
		
		var l_type = -1
		var l_piece = boardstate[li][lj]
		if l_piece!=null && is_instance_valid(l_piece):
			l_type=l_piece.type
		#print("type",l_type)
		if l_type==-1:
			return null #no capture		
		elif l_type!=type: #wrong color
			continue
		
		fillarea.append([li,lj])
		#print("continuing search")
		unvisited.append([li+1,lj])
		unvisited.append([li-1,lj])
		unvisited.append([li,lj+1])
		unvisited.append([li,lj-1])
	
	print(str(type) + " captured!")
	print([i,j])
	return [type,fillarea]
	
func markWinEdges(player,area):
	var fillmat : Material
	if player==0:
		fillmat = edgehighlight_white_material
	else:
		fillmat = edgehighlight_black_material
		
	for i in area.size():
		var coord=area[i]
		var edgehighlight:MeshInstance=borderhighlights[coord[0]][coord[1]]
		edgehighlight.material_override=fillmat
		edgehighlight.visible=true
		
	
func board_cell_entered(node:Node,ar1,ar2):
	if not (node is stone_info_script):
		return
	if not is_instance_valid(node):
		return

	for i in unplacedstones.size():
		if unplacedstones[i]==node:
			unplacedstones.remove(i)
			break
			
	for i in 9:
		for j in 8:
			if boardstate[i][j]==node:
				print("DUPE FOUND AT",i,j)
				boardstate[i][j]=null
						
	if boardstate[ar1][ar2]!=null && !is_instance_valid(boardstate[ar1][ar2]):
		boardstate[ar1][ar2]=null
		
	#print(ar1,ar2)
	if boardstate[ar1][ar2]==null:
		#remove node from all cells first
		boardstate[ar1][ar2]=node		
		var captured = [
			detect_capture(ar1+1,ar2),
			detect_capture(ar1-1,ar2),
			detect_capture(ar1,ar2+1),
			detect_capture(ar1,ar2-1),
			detect_capture(ar1,ar2)]
		var black_captured=false
		var white_captured=false
		for n in captured.size():
			var result = captured[n]
			if result==null:
				continue
			if result[0]==0:
				white_captured=true
			else:
				black_captured=true
			markWinEdges(result[0],result[1])
		
		if black_captured and white_captured:
			$CanvasLayer/Control2/WinsMessage.text="DRAW GAME"
		elif black_captured:
			$CanvasLayer/Control2/WinsMessage.text="WHITE WINS"
		elif white_captured:
			$CanvasLayer/Control2/WinsMessage.text="BLACK WINS"
						

		
		if black_captured or white_captured:
			$CanvasLayer/Control2/WinsMessage.visible=true
			gameover=true
			
			for i in 9:
				for j in 9:
					var piece:RigidBody = boardstate[i][j]
					if piece==null or not is_instance_valid(piece):
						continue
					piece.mode=RigidBody.MODE_STATIC
						
					
			var old_t : Vector3 = $Placement.translation
			var t : Vector3 = $Placement.translation
			t.x=0
			t.z=0
			var jingle = sfx_wingame[turn%2]
					
			$World/AudioStreamPlayer.stop()
			$World/AudioStreamPlayer.pitch_scale=1.0
			$World/AudioStreamPlayer.volume_db=-10
			$World/AudioStreamPlayer.stream = jingle
			$World/AudioStreamPlayer.play()
				
			var tween:Tween = $CanvasLayer/Control2/Tween	
			tween.remove_all()
			$CanvasLayer/Control2/BlacksTurn.visible=false
			$CanvasLayer/Control2/WhitesTurn.visible=false
			tween.interpolate_property($CanvasLayer/Control2/WinsMessage, "percent_visible",0,1, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.interpolate_property($Placement, "translation",old_t,t, 3, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.start()
			#$Placement.translation = t 
			$Placement/PlacementCylinder.visible=false
			$Placement/PlacementCylinder/Map_Cylinder.visible=false
			
			for si in unplacedstones.size():
				var stone = unplacedstones[si]
						
				var particles:Particles
				if stone.type==0:
					particles = $DestroyParticles_White
				else:
					particles = $DestroyParticles_Black		
				particles.translation=stone.global_transform.origin
				particles.emitting=true
						
				$Board/AudioStreamPlayer3D_StoneRemove.stop()
				$Board/AudioStreamPlayer3D_StoneRemove.stream=sfx_destroy
				$Board/AudioStreamPlayer3D_StoneRemove.global_transform.origin = particles.translation
				$Board/AudioStreamPlayer3D_StoneRemove.play()
				
				stone.queue_free()
					
			unplacedstones=[]
		
	else:
		var particles:Particles
		if node.type==0:
			particles = $DestroyParticles_White
		else:
			particles = $DestroyParticles_Black		
		particles.translation=node.global_transform.origin
		particles.emitting=true
		node.queue_free()
			
		$Board/AudioStreamPlayer3D_StoneRemove.stop()
		$Board/AudioStreamPlayer3D_StoneRemove.stream=sfx_destroy
		$Board/AudioStreamPlayer3D_StoneRemove.global_transform.origin = particles.translation
		$Board/AudioStreamPlayer3D_StoneRemove.play()
	
func isPlayerTurn():
	if turn%2==1:
		return Global.player1
	else:
		return Global.player2
		
# Called when the node enters the scene tree for the first time.
func _ready():
	turn=1
	if Global.handicap>0:
		turn=0
		
	#instantiate gamestate
	boardstate=[]
	for i in 9:
		var col=[]
		for j in 9:
			col.append(null)
		boardstate.append(col)		
		
	unplacedstones=[]
			
	var rodcount:int = $Board/Rods.get_child_count()
	for i in rodcount:
		var rod:MeshInstance = $Board/Rods.get_child(i)
		rods.append(rod)
	
	var cursor_overlap_area:Area = $Placement/PlacementCylinder/Area
	cursor_overlap_area.connect("body_entered",self,"cursor_area_entered")
	cursor_overlap_area.connect("body_exited",self,"cursor_area_exited")
	
	var area_container:Spatial = $Areas
	var area_rows = area_container.get_children()
	for ri in area_rows.size():
		var row:Spatial=area_rows[ri]
		var pieces = row.get_children()
		for pi in pieces.size():
			var piece:Area = pieces[pi]
			var collisionshape:CollisionShape = piece.get_child(0)
			var bs:BoxShape = collisionshape.shape
			bs.extents.x=0.3
			bs.extents.y=0.3
			piece.connect("body_entered",self,"board_cell_entered",[ri,pi])
			
	borderhighlights=[]
	var border_highlights_container:Spatial = $WinPatternHighlights
	area_rows = border_highlights_container.get_children()
	for ri in area_rows.size():
		var row:Spatial=area_rows[ri]
		var borderhighlightsrow=[]
		var pieces = row.get_children()
		for pi in pieces.size():
			var piece:MeshInstance = pieces[pi]
			piece.visible=false
			borderhighlightsrow.append(piece)
		borderhighlights.append(borderhighlightsrow)
		
	if Global.handicap>0:
		for i in Global.handicap+1:
			var hcs:Spatial = $Handicap.get_child(i)
			var spawnpos = hcs.global_transform.origin
			spawnStoneAt(spawnpos,1)
			
	setNewTurn()

var targettext:Label=null
var targettext_chars_visible_old:int=0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if isPlayerTurn():
		if Input.is_action_just_pressed("jump"):
			if not gameover:
				spawnStone()
			else:
				get_tree().change_scene("res://Title.tscn")
	else:
		if gameover and Input.is_action_just_pressed("jump"):
			get_tree().change_scene("res://Title.tscn")
				

	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene("res://Title.tscn")

	if OS.is_debug_build():
		if Input.is_key_pressed(KEY_SHIFT):
			if not gameover:
				spawnStone(true)
			
	var aim = $CameraArm/Camera.get_global_transform().basis
	var forward = -aim.z
	#var backward = aim.z
	#var left = -aim.x
	var right = aim.x

	forward.y=0
	forward = forward.normalized()
	right.y=0
	right = right.normalized()
	
	var v2d_a = Vector2(right.x,right.z)
	var angle : float = - v2d_a.angle_to(Vector2.RIGHT)
	$CanvasLayer/Control/Sprite.rotation = -angle
	
	var dx:float=0
	var dz:float=0
	
	if gameover:
		return
		
	if isPlayerTurn():					
		if Input.is_action_pressed("wasd_right"):
			dx = dx + movement_speed*delta 
		if Input.is_action_pressed("wasd_left"):
			dx = dx - movement_speed*delta 	
		
		if Input.is_action_pressed("wasd_up"):
			dz = dz + movement_speed*delta 
		if Input.is_action_pressed("wasd_down"):
			dz = dz - movement_speed*delta 
	else:#AI turn
		if ai_wait>0:
			ai_wait = ai_wait - delta
		else:
			var cur:Vector3 = $Placement.translation
			cur.y=0
			var target:Vector3 = Vector3(ai_x,0,ai_z)
			var diff:Vector3 = target-cur
			var dist = diff.length()
			if dist<0.1:
				spawnStone()
			else:
				var normalized:Vector3 = diff.normalized()
				right = Vector3.RIGHT
				forward = Vector3.BACK
				dx = normalized.x*delta*movement_speed
				dz = normalized.z*delta*movement_speed
			
	if onestonespawned:
		return
		
	var t:Vector3 = $Placement.translation
	t = t + dx*right+dz*forward
	
	t.x = clamp(t.x,cursor_min_x,cursor_max_x)
	t.z = clamp(t.z,cursor_min_z,cursor_max_z)
	$Placement.translation = t
	
	if targettext != null:
		var newcharsvisible:int = targettext.visible_characters
		if newcharsvisible!=targettext_chars_visible_old:
			targettext_chars_visible_old = newcharsvisible
			$World/AudioStreamPlayer.stop()
			$World/AudioStreamPlayer.pitch_scale=0.5			
			$World/AudioStreamPlayer.volume_db=-20
			$World/AudioStreamPlayer.stream = sfx_hit
			$World/AudioStreamPlayer.play()
			
		


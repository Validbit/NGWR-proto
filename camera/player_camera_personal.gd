extends Camera

# Explanation ---------------------
# 0 = current/default/disabled
# 1 = changing (of modes, cameras, etc.)
# 2 = closeup (default)
# 3 = perspective/birds-eye-view
# 4 = cinematic (auto) (switch to manual (defined by world or dataset) by changing Camera export 

export var spd_cinematic = 2.8
# Camera's timer variables
export var t_short = 2.2
export var t_long = 3.7
export var is_cam_cinema_data_external = false #are the cinematic's paths/points taken from the map's data (to showcase bigger picture) or the player's (to showcase player/item)
export var is_cam_cinema_target_external = false #is the cinematic centering the player or a different object
#var is_cam_cinema_data_multiparent = false

var is_processing_movement = true

#Pre-aligned spatials
onready var pos_default = get_node("../DEFAULT")
onready var pos_far = get_node("../FAR")
onready var pos_close = get_node("../CLOSE")
onready var pos_bev = get_node("../BEV") #Bird's Eye View
onready var setup = get_node("..")

var xT: Vector3
var yT: Vector3
var zT: Vector3
var rT: Vector3
var weight = 0

onready var pub = get_node("/root/PublicVariables")
onready var util = get_node("/root/Utility")
onready var ui_hud = $"../../HUDsys/ocHUD_L" as Spatial
var ui_hud_ctl: HBoxContainer

onready var cam = get_parent() # ~Needs to be absolute (ex. /root/Player/Camerasetup/Camera)~
onready var cam_cinema = get_parent().get_node("CINEMA")
var cam_cinema_i_prev # "What cinematic view (curve used) was the previous one"
var cam_cinema_i = 0 # "What cinematic view (curve used) was the last one (used latest)"
var cam_cinema_target = null
var is_cam_cinema_static = false
var parent # is meant as a cam_cinema_pathfollow (in case of curve) or a cam_cinema_point (in case of static Spatial/point/empty)
var timer: Timer
var dataset_q = [] # When init_cam is given custom dataset of multiple sets (nodes) of CINEMATIC points/curves it creates a memory of these nodes for them to reparent-to once last children point/curve is reached.



func _enter_tree():
	set_process(false)

func _process(delta):
	# On 0 and 3 the camera doesn't change apart from present physics (relative to parent's behaviour)
	if pub.player_w_camera_mode[0] == 1: #is Transitioning
		pass
	if pub.player_w_camera_mode[0] == 2: #is Closeup
		#self.transform = lerp(pos_close.transform, pos_far.transform, delta*pub.player_rpm[0])
		weight = delta*pub.player_spd[0]
		#TODO align UI
		#TODO: just replace with smootstep and speed (instead of rpm) and test
		xT = lerp(pos_far.transform.basis.x,pos_close.transform.basis.x,weight)
		yT = lerp(pos_far.transform.basis.y,pos_close.transform.basis.y,weight)
		zT = lerp(pos_far.transform.basis.z,pos_close.transform.basis.z,weight)
		rT = lerp(pos_far.transform.origin, pos_close.transform.origin,weight)
		self.transform.basis.x = xT
		self.transform.basis.y = yT
		self.transform.basis.z = zT
		self.transform.origin = rT
		#util.clog_t("EVAL","NEW Camera.transform: ["+str(xT)+", "+str(yT)+", "+str(zT)+"] with "+str(rT)+"rotation")
		
	if pub.player_w_camera_mode[0] == 4:
#		parent = get_parent()
		if is_processing_movement:
			if parent.unit_offset == 1: 
				# pathfoolow end and reparent
				(get_node("CameraTimer") as Timer).start()
				set_process_movement(false)
				return
				
#			if point-only
#				(get_node("CameraTimer") as Timer).start()
#				return (skip the rest)
			if true: #NOT point-only
				parent.set_offset(parent.get_offset()+ spd_cinematic * delta)#Get PathFollow of the curve the cinematic camera inherits transformation from
		look_at(pub.player[0].pivot.transform.origin,Vector3(0,1,0))
#		if !is_cam_cinema_target_external:
		
func _ready():
	ui_hud_ctl = ui_hud.get_child(0).get_child(0).get_child(0) #UI node for managind layout of a specific HUD
	init_cam()
	set_process(true)
	pass

func init_cam(cam_mode = 0, reset_queued = false, dataset = null):
	# For 1, 2 the position is being actively updated (_process)
	if cam_mode != 4 && pub.player_w_camera_mode[0] == 4:
		Utility.reparent(self,setup)
		self.transform = Transform.IDENTITY
	
	if cam_mode == 0:
		xT = pos_default.transform.basis.x
		yT = pos_default.transform.basis.y
		zT = pos_default.transform.basis.z
		rT = pos_default.transform.origin
#		#self.transform = pos_default.transform
#		xT = self.transform.basis.x
#		yT = self.transform.basis.y
#		zT = self.transform.basis.z
#		rT = self.transform.origin
	
	elif cam_mode == 2:
#		ui_hud.rotation_degrees.x = -15
#		ui_hud.translation = Vector3(-0.06,0,0.1)
#		ui_hud.scale = Vector3(1,1,1)
		ui_hud.rotation_degrees.x = -15
		ui_hud_ctl.margin_left = 540
		ui_hud_ctl.margin_right =-580
#		ui_hud.translation = Vector3(0,0,0)
		ui_hud.scale = Vector3(1,1,1)
		
	elif cam_mode == 3:
		xT = pos_bev.transform.basis.x
		yT = pos_bev.transform.basis.y
		zT = pos_bev.transform.basis.z
		rT = pos_bev.transform.origin
		
#		ui_hud.translation = Vector3(+0.14,0,0)
#		ui_hud.rotation_degrees.x = -90
#		ui_hud.scale = Vector3(3.6,3.6,1)
		ui_hud.rotation_degrees.x = -90
		ui_hud_ctl.margin_left = 540
		ui_hud_ctl.margin_right =-470
#		ui_hud.translation = Vector3(+0.2,0,0)
		ui_hud.scale = Vector3(3.6,3.6,1)
	
	elif cam_mode == 4:
#		is_cam_cinema_data_multiparent = false
		if true: #!is_cam_cinema_data_external
			if dataset != null:
				if dataset.size() != 1:
#					is_cam_cinema_data_multiparent = true
					if reset_queued: #dataset_q == null || 
						dataset = []
					dataset_q += dataset
#				parent = dataset[0]
			if !dataset_q.empty():
				dataset_q[0]
			else:
				parent = cam_cinema
		else:
			parent = get_node("/root/World/PointersLocal/Cinematic")
			
		parent = parent.get_child(cam_cinema_i)
		is_cam_cinema_static = true
		if parent.get_class() == "Path":
			parent = parent.get_child(0)
			is_cam_cinema_static = false
		
		Utility.reparent(self,parent)
		
		timer = get_node("CameraTimer") 
		timer.wait_time = t_long
		if is_cam_cinema_static:
			timer.wait_time = t_short
		
		xT = parent.transform.basis.x
		yT = parent.transform.basis.y
		zT = parent.transform.basis.z
		rT = parent.transform.origin
		
		ui_hud.rotation_degrees.x = -15
		ui_hud_ctl.margin_left = 540
		ui_hud_ctl.margin_right =-580
#		ui_hud.translation = Vector3(0,0,0)
		ui_hud.scale = Vector3(1,1,1)

	
	#DO maybe add validation (if requested index exist) without complications (change_cam())
	self.transform.basis.x = xT
	self.transform.basis.y = yT
	self.transform.basis.z = zT
	self.transform.origin = rT

func change_cam(cam_mode = 2, init_params = null):
	set_process(false)
	if init_params == null:
		init_cam(cam_mode)
	else:
		init_cam(cam_mode,init_params[0],init_params[1])
	pub.player_w_camera_mode[0] = cam_mode
	set_process(true)

func set_process_movement(val):
	is_processing_movement = val


func _on_CameraTimer_timeout():
	parent.set_offset(0)
	cam_cinema_i_prev = cam_cinema_i
	if (cam_cinema_i) == cam_cinema.get_child_count():
		cam_cinema_i += 1
	else:
		cam_cinema_i = 0
		dataset_q.pop_front() #empty check not needed
	
	init_cam(4)
		
	set_process_movement(true)
	#unfreeze process

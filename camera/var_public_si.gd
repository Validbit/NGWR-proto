extends Node

onready var player = [$"/root/World/Player" as Spatial] # Access its body by .vb
#onready var playerbody = [$"/root/World/Player/UIWrapper/dodger" as VehicleBody] 

var player_rpm = [0] #4 players => p1 = 0. index
var player_spd = [0]
var player_boost_capacity = [100]
var player_jump_capacity_timer = [Timer.new()]
var player_w_chk = [0] #WorldData>Checkpoints
var player_w_status = []
var player_w_camera_mode = [2] #Determines behaviour of active camera
var player_linear_velocity_ground = [Vector3.ZERO]
var player_pos_chunk = [Vector2(0,0),Vector2.ZERO,Vector2.ZERO,Vector2.ZERO]
var player_pos_chunk_prev = [Vector2(0,0),Vector2.ZERO,Vector2.ZERO,Vector2.ZERO]
onready var u = $"/root/Utility"
onready var w = $"/root/WorldSession"
onready var wp = $"/root/WorldSession/Pointers"
#func get_data(target,index) #Not needed

# Chunks & Terrain Generation
const QUAD_SIZE := 1
const CHUNK_QUAD_COUNT := 20
const CHUNK_SIZE = QUAD_SIZE*CHUNK_QUAD_COUNT #int(QUAD_SIZE * CHUNK_QUAD_COUNT)

func _init():
	for t in player_jump_capacity_timer:
		t.wait_time = 0.3
		t.one_shot = true
		add_child(t)

func get_data_f(target,index): # ex. "player", 1
	if target=="player_rpm":
		return str("%3d" % abs(floor(player_rpm[index-1]))) #%03d for filling with zeroes
	if target=="player_spd":
		return str("%3d" % abs(floor(player_spd[index-1])))
	else:
		u.clog("ERR","Invalid data request target")

func set_checkpoint(player_iid, checkpoint_index):
	if checkpoint_index == -1:
		checkpoint_index = wp.get_child_count()-1
	player_w_chk[player_iid] = checkpoint_index

func ach_checkpoint(player_iid, checkpoint_index): #Achieve Checkpoint
	if !(player_w_chk[player_iid] >= checkpoint_index):
		player_w_chk[player_iid] = checkpoint_index
		print("I | You "+str(player_iid)+" have reached a new checkpoint ("+str(checkpoint_index)+")")
	

func ach_stat(player_iid,stat_name,stat_param=-1): #Achieve (register) Stat (Statistic achievement)
	pass
	
func ach_achievement(player_iid,ach_name,ach_category,ach_param=-1): #Achieve an Achievement (Statistic recognizable by game environment's system (like Steam Achievements)
	pass

func _ready():
	pass

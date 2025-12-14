extends Node3D

# =============================
# CONFIG
# =============================
@export var cell_size: float = 1.0
@export var wall_1x1: PackedScene
@export var wall_height: float = 1.0
var timer: Timer
var time_left = 5
# --- WIND CONFIG ---
@export var base_wind_strength := 2.0
@export var max_wind_strength := 15.0
@export var wind_change_speed := 0.2
@export var wind_force_clamp := 60.0

# =============================
# NODES
# =============================
@onready var camera: Camera3D = $Camera3D
@onready var wall_container: Node3D = $WallContainer
@onready var wind_sources: Node3D = $WindSources
@onready var buildableArea: StaticBody3D = $buildableArea
@onready var place_sound: AudioStreamPlayer3D = $AudioStreamPlayer3D


# =============================
# STATE
# =============================
var occupied_cells := {}
var itemToPlace = null
# --- WIND STATE ---
var wind_direction: Vector3 = Vector3.FORWARD
var wind_strength: float = 0.0
var time_elapsed := 0.0

# --- CAMERA FOLLOW ---
@export var camera_height_offset: float = 6.0
@export var camera_follow_speed: float = 3.0

var max_tower_height: float = 0.0

# =============================
# SCENES
# =============================
var creamPoofScene = preload("res://Scenes/creamPoof.tscn")
var gumDropScene = preload("res://Scenes/gumDrop.tscn")
var hersheyKissScene = preload("res://Scenes/hersheyKiss.tscn")
var marshMallowScene = preload("res://Scenes/marshMallow.tscn")
var peanutCupScene = preload("res://Scenes/peanutCup.tscn")
var pretzelSquareScene = preload("res://Scenes/pretzelSquare.tscn")

# Gingerbread walls - list all possible walls

var rectWalls: Array[PackedScene] = [
	preload("res://Scenes/Gingerbread/rectWall1.tscn"),
	preload("res://Scenes/Gingerbread/rectWall2.tscn")
]

var thinWalls: Array[PackedScene] = [
	preload("res://Scenes/Gingerbread/thinWall3.tscn"),
	preload("res://Scenes/Gingerbread/thinWall4.tscn")
]

var fatWalls: Array[PackedScene] = [
	preload("res://Scenes/Gingerbread/fatWall5.tscn"),
	preload("res://Scenes/Gingerbread/fatWall6.tscn"),
	preload("res://Scenes/Gingerbread/fatWall7.tscn"),
	preload("res://Scenes/Gingerbread/fatWall8.tscn")
]
# =============================
# INPUT
# =============================
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		itemToPlace = null
		var focused_node = get_viewport().gui_get_focus_owner()
		if focused_node:
			focused_node.release_focus()
		return

	if itemToPlace == null:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if itemToPlace == wall_1x1:
			placeAtMouse() 
		elif itemToPlace == creamPoofScene:
			placeOnFace()
		elif itemToPlace == gumDropScene:
			placeOnFace()
		elif itemToPlace == hersheyKissScene:
			placeOnFace()
		elif itemToPlace == marshMallowScene:
			placeOnFace()
		elif itemToPlace == peanutCupScene:
			placeOnFace()
		elif itemToPlace == pretzelSquareScene:
			placeOnFace()
		else:
			placeAtMouse()
		"""
		elif thinWalls.has(itemToPlace):
			# placeGWall()
			placeOnFace()
		elif fatWalls.has(itemToPlace):
			# placeGWall()
			placeOnFace()
		elif rectWalls.has(itemToPlace):
			# placeGWall()
			placeOnFace()
		"""

func _ready():
	StartTimer()

	
# =============================
# WIND UPDATE
# =============================
func _physics_process(delta: float) -> void:
	time_elapsed += delta
	_update_wind()
	_apply_wind_to_bodies()

func _update_wind() -> void:
	# Slow wandering wind direction
	var angle := sin(time_elapsed * wind_change_speed)
	wind_direction = Vector3(angle, 0, cos(angle)).normalized()

	# Smooth ramp over entire run
	var t: float = clamp(time_elapsed / 60.0, 0.0, 1.0)
	wind_strength = lerp(base_wind_strength, max_wind_strength, t)


func _apply_wind_to_bodies() -> void:
	for child in get_children():
		if child is RigidBody3D and not child.freeze:
			var height_factor: float = max(child.global_position.y, 0.5)
			var force: Vector3 = wind_direction * wind_strength * height_factor

			if force.length() > wind_force_clamp:
				force = force.normalized() * wind_force_clamp

			child.apply_central_force(force)

# =============================
# VISUAL WIND DEBUG (OPTIONAL)
# =============================
func _process(delta: float) -> void:
	# Wind debug
	if wind_sources:
		wind_sources.look_at(
			wind_sources.global_position + wind_direction,
			Vector3.UP
		)

	# Camera follow
	_update_camera_height(delta)

# =============================
# TOOL SELECTION
# =============================

# Item can be placed on walls
func placeCream() -> void:
	itemToPlace = creamPoofScene

# Item can be placed on walls
func placeGum() -> void:
	itemToPlace = gumDropScene

# Item can be placed on walls
func placeKiss() -> void:
	itemToPlace = hersheyKissScene
	
# Item can be placed on walls
func placeMallow() -> void:
	itemToPlace = marshMallowScene
	
# Item can be placed on walls
func placeCup() -> void:
	itemToPlace = peanutCupScene
	
func placePretzel()-> void:
	itemToPlace = pretzelSquareScene

func placeWall() -> void:
	itemToPlace = wall_1x1
	
# for gingerbread walls
func placeFatWall() -> void:
	# itemToPlace = randWall(fatWalls)
	itemToPlace = fatWalls[0]

func placeThinWall() -> void:
	itemToPlace = thinWalls[0]
	# itemToPlace = randWall(thinWalls)
	
func placeRectWall() -> void:
	itemToPlace = rectWalls[0]
	# itemToPlace = randWall(rectWalls)

func restartGame():
	get_tree().reload_current_scene()

func endGame():
	get_tree().quit()

# =============================
# Handling Gingerbread Walls
# =============================

# Function to select random gingerbread wall for placement
# upon clicking the Wall button on the UI bar
func randWall(wall_list: Array[PackedScene]):
	if wall_list.is_empty():
		print("Warning: Provided wall list is empty. Using default wall.")
		itemToPlace = wall_1x1 # Use magenta cube for backup
	else:
		itemToPlace = wall_list.pick_random()
	return itemToPlace

# =============================
# RAYCASTING
# =============================
func getMouseCoords():
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)
	return result.position if result else null

func objectClicked() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)
	if result and result.has("collider"):
		return {
			"node": result["collider"],
			"normal": result["normal"],
			"position": result["position"]
		}
	return {}

# =============================
# PLACEMENT
# =============================
func placeAtMouse() -> void:
	var world_position = getMouseCoords()
	if world_position == null:
		return

	var new_object = itemToPlace.instantiate()
	add_child(new_object)
	new_object.global_position = world_position
	
	play_place_sound(new_object.global_position)

	if not is_inside_buildable_area(new_object) and not intersects_anything(new_object):
		new_object.queue_free()

func get_snapped_normal(n: Vector3) -> Vector3:
	if abs(n.y) > abs(n.x) and abs(n.y) > abs(n.z):
		return Vector3(0, sign(n.y), 0)
	elif abs(n.x) > abs(n.z):
		return Vector3(sign(n.x), 0, 0)
	else:
		return Vector3(0, 0, sign(n.z))

func placeOnFace() -> void:
	print("Using placeOnFace...")
	var hit = objectClicked()
	if hit.is_empty():
		placeAtMouse()
		return

	var clicked_node = hit["node"]
	# everything that is not a wall can be placed on face?
	if not clicked_node.is_in_group("walls"):
		placeAtMouse()
		return

	var new_object = itemToPlace.instantiate()
	add_child(new_object)
	new_object.global_position = hit["position"]

	var face_normal = get_snapped_normal(hit["normal"])
	if face_normal != Vector3.UP:
		new_object.look_at(new_object.global_position + face_normal, Vector3.UP)
		new_object.rotate_object_local(Vector3.RIGHT, -PI / 2)

	if new_object is RigidBody3D:
		new_object.freeze = true
		new_object.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC

	if not is_inside_buildable_area(new_object) and not intersects_anything(new_object):
		new_object.queue_free()

# Gingerbread walls are "sticky" and should use a modified version of place on face

func placeGWall()-> void:
	pass
	
# =============================
# COLLISION HELPERS
# =============================
func is_inside_buildable_area(object: Node3D) -> bool:
	var mesh_child = null
	for child in buildableArea.get_children():
		if child is MeshInstance3D:
			mesh_child = child
			break
	if not mesh_child:
		return true
	var area_aabb = mesh_child.get_aabb()
	var local_pos = mesh_child.to_local(object.global_position)
	return area_aabb.has_point(local_pos)

func check_intersection(a: Node3D, b: Node3D) -> bool:
	return _get_global_aabb(a).intersects(_get_global_aabb(b))

func intersects_anything(target: Node3D) -> bool:
	for child in get_children():
		if child == target:
			continue
		if child is Node3D and check_intersection(target, child):
			return true
	return false

func _get_global_aabb(node: Node3D) -> AABB:
	if node is MeshInstance3D:
		return node.global_transform * node.get_aabb()
	for child in node.get_children():
		if child is MeshInstance3D:
			return child.global_transform * child.get_aabb()
	return AABB(node.global_position, Vector3(0.1, 0.1, 0.1))

# =============================
# TIMER / SCORE
# =============================
func StartTimer():
	if timer: 
		timer.queue_free()
		
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.one_shot = false # Must be false to repeat every second
	timer.timeout.connect(_on_timer_tick)
	timer.start()
	
	# Update the UI immediately
	_update_timer_ui()

func _on_timer_tick() -> void:
	# global
	time_left -= 1
	
	if time_left <= 0:
		time_left = 0
		_update_timer_ui() # Show 0:00
		timer.stop()       # Stop the timer
		_on_timer_timeout() # End game
		return
	
	_update_timer_ui()

func _update_timer_ui() -> void:
	# Format to MM:SS
	var minutes = int(time_left / 60)
	var seconds = int(time_left) % 60
	var time_string = "%d:%02d" % [minutes, seconds]
	
	# Safely try to get the label node
	var ui_label = $CanvasLayer/UI/TimeLabel
	if ui_label:
		ui_label.text = time_string
	else:
		# Fallback debug so you know if the path is wrong
		print("Timer Tick: ", time_string, " (UI Node not found!)")
		
func CheckHeight(): 
	var FinalHeight = 0.0 
	while not intersects_anything($HeightChecker): 
		$HeightChecker.position.y -= 1 
		FinalHeight = $HeightChecker.position.y 
	
	return FinalHeight
	
func _on_timer_timeout():
	$CanvasLayer/UI/decorativePlacement.hide()
	$CanvasLayer/UI/endGame.show()
	
	var score = "" 
	score = str(snapped(CheckHeight(), 0.01)) 
	
	$CanvasLayer/UI/endGame/ScoreLabel/Score.text = score 
	
	itemToPlace = null
	
func get_current_tower_height() -> float:
	var highest: float = 0.0

	for child in get_children():
		if child is RigidBody3D:
			highest = max(highest, child.global_position.y)

	return highest

func _update_camera_height(delta: float) -> void:
	var current_height: float = get_current_tower_height()

	# Only move camera UP, never down
	max_tower_height = max(max_tower_height, current_height)

	var target_y: float = max_tower_height + camera_height_offset

	var cam_pos := camera.global_position
	cam_pos.y = lerp(cam_pos.y, target_y, delta * camera_follow_speed)

	camera.global_position = cam_pos

func play_place_sound(pos: Vector3):
	if place_sound:
		place_sound.global_position = pos
		place_sound.pitch_scale = randf_range(0.9, 1.1)
		place_sound.play()

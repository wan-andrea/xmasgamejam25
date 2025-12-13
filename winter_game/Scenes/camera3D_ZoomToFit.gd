extends Camera3D

# Get the worldFloor
@onready var world_floor = $"../worldFloor"

# runs when game starts
func _ready():
	# force ortho camera
	projection = PROJECTION_ORTHOGONAL
	# true ortho degree rotations for iso
	rotation_degrees = Vector3(-35.264, 45, 0)
	# get bounding box 
	var bbox = get_world_floor_bbox(world_floor)
	print(bbox)
	orthoZoomToFit(bbox)
	
# Function to get the bounding box of the worldFloor tscn
func get_world_floor_bbox(root_node: Node3D) -> AABB:
	var final_box = AABB()
	var first = true
	var meshes = root_node.find_children("*", "MeshInstance3D", true, false)
	
	for mesh in meshes:
		var world_box = mesh.global_transform * mesh.get_aabb()
		if first:
			final_box = world_box
			first = false
		else:
			final_box = final_box.merge(world_box)
	return final_box

# Function to zoom to fit
func orthoZoomToFit(bbox, margin: float = 1.2):
	print("running orthoZoomToFit...")
	# centerpoint of the bounding box
	var target_center = bbox.get_center()
	# move camera away from the center
	var back_direction = self.global_transform.basis.z.normalized()
	# calculate safe distance
	var radius = bbox.size.length() * 0.5
	var safe_distance = radius + self.near + 0.1
	# place object at the center of the bounding box then move it backwards
	self.global_position = target_center + (back_direction * safe_distance)
	# point camera at bbox point
	self.look_at(target_center)
	# game window in pixels
	var viewport_rect = get_viewport().get_visible_rect()
	# calculate aspect ratio
	var aspect = viewport_rect.size.x / viewport_rect.size.y
	var max_w = 0.0
	var max_h = 0.0
	# get camera bounds
	for i in 8:
		var world_corner = bbox.get_endpoint(i)
		var camera_local_corner = self.to_local(world_corner)
		max_w = max(max_w, abs(camera_local_corner.x)) # center to right
		max_h = max(max_h, abs(camera_local_corner.y)) # center to top
	var required_height = max_h * 2.0
	var required_width_as_height = (max_w * 2.0) / aspect
	# choose limiting dim and add margin
	self.size = max(required_height, required_width_as_height) * margin

extends Node3D

@export var wall_scene: PackedScene
@export var min_segment_distance: float = 0.5
@export var ray_length: float = 1000.0

@onready var camera: Camera3D = $Camera3D
@onready var wall_container: Node3D = $WallContainer

var drawing: bool = false
var points: Array[Vector3] = []

# --------------------------------------------------
# INPUT
# --------------------------------------------------

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drawing()
			else:
				_finish_drawing()

# --------------------------------------------------
# DRAW LOOP
# --------------------------------------------------

func _process(_delta):
	if not drawing:
		return

	var world_pos := Vector3.ZERO
	if not _get_mouse_world_position(world_pos):
		return

	if world_pos.distance_to(points[-1]) >= min_segment_distance:
		var last_point := points[-1]
		points.append(world_pos)
		_spawn_wall_segment(last_point, world_pos)

# --------------------------------------------------
# DRAW STATE
# --------------------------------------------------

func _start_drawing():
	var world_pos := Vector3.ZERO
	if not _get_mouse_world_position(world_pos):
		return

	drawing = true
	points.clear()
	points.append(world_pos)

func _finish_drawing():
	drawing = false
	points.clear()

# --------------------------------------------------
# WALL SPAWNING
# --------------------------------------------------

func _spawn_wall_segment(from: Vector3, to: Vector3):
	if wall_scene == null:
		push_error("Wall scene not assigned!")
		return

	var segment: Node3D = wall_scene.instantiate()
	wall_container.add_child(segment)

	var direction := to - from
	var length := direction.length()
	var midpoint := from + direction * 0.5

	segment.global_position = midpoint

	# Rotate so the wall follows the line
	segment.look_at(midpoint + direction.normalized(), Vector3.UP)

	# If your mesh faces Z instead of X, uncomment this:
	# segment.rotate_y(deg_to_rad(90))

	# Scale along X to match length
	segment.scale.x = length

# --------------------------------------------------
# RAYCAST
# --------------------------------------------------

func _get_mouse_world_position(out_pos: Vector3) -> bool:
	var mouse_pos := get_viewport().get_mouse_position()

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_direction := camera.project_ray_normal(mouse_pos)

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_direction * ray_length
	)

	var result := space_state.intersect_ray(query)
	if result:
		out_pos = result.position
		return true

	return false

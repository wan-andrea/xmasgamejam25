extends RigidBody3D
var anchor_node: Node3D = null
func _ready():
	# Listen for collisions
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Ignore the thing it's attached to don't turn on gravity
	if body == anchor_node:
		return
	# If something hits me, and I am currently frozen (stuck to wall)
	if freeze:
		# Wake up!
		# otherwise gravity will take over and should fall
		freeze = false
		sleeping = false
	

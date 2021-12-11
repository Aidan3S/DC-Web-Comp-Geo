extends Area

var won = false

signal win

# Called when the node enters the scene tree for the first time.
func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	transform.origin = Vector3(
		rng.randf_range(3.0, 13.0),
		rng.randf_range(3.0, 13.0),
		rng.randf_range(3.0, 13.0)
	)


func _on_MeshInstance_chunk_update(octree: Octree):
	if not won:
		# Check the octree at the rock's current location.  If it's solid
		# (> 0.99) then the player won.
		var chunk_pos = (transform.origin) / 0.5
		chunk_pos = Vector3(round(chunk_pos.x), round(chunk_pos.y), round(chunk_pos.z))
		if octree.get_weight_at(chunk_pos) > 0.99:
			won = true
			emit_signal("win")


func _on_FreeCamera_view_changed(draw_mode):
	$rock.visible = draw_mode == 0

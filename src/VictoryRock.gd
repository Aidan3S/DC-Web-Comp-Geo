extends Area

# Called when the node enters the scene tree for the first time.
func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	transform.origin = Vector3(
		rng.randf_range(3.0, 13.0),
		rng.randf_range(3.0, 13.0),
		rng.randf_range(3.0, 13.0)
	)

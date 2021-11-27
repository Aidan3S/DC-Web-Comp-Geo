class_name SphereGeneratorNegative
extends WorldGenerator

var size
var position

func _init(brush_size, pos):
	size = brush_size
	position = pos

func sample(x: float, y: float, z: float) -> float:
	var loc = Vector3(x, y, z) - position
	return (loc.distance_to(Vector3.ZERO) - size) * -1

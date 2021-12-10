class_name CubeGenerator
extends WorldGenerator

var size
var position

func _init(brush_size, pos):
	size = brush_size
	position = pos

func sample(x: float, y: float, z: float) -> float:
	var pos = Vector3(
		abs(x - position.x) - size,
		abs(y - position.y) - size,
		abs(z - position.z) - size
	)
	return max(max(pos.x, pos.y), pos.z)

func sample_normals(x: float, y: float, z: float) -> Vector3:
	var max_axis = Vector3(x, y, z).max_axis()
	if max_axis == Vector3.AXIS_X:
		return Vector3.RIGHT if x > 0 else Vector3.LEFT
	elif max_axis == Vector3.AXIS_Y:
		return Vector3.UP if y > 0 else Vector3.DOWN
	elif max_axis == Vector3.AXIS_Z:
		return Vector3.BACK if z > 0 else Vector3.FORWARD
	else:
		print("No max found")
		return Vector3.ZERO

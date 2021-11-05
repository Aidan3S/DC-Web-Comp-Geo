class_name WorldGenerator

var noise = OpenSimplexNoise.new()
const AMPLITUDE = 10.0
const OFFSET = 0.001


func _init():
	noise.seed = 1
	noise.octaves = 1
	noise.period = 5
	noise.persistence = 0.8


func sample_2p(x: float, y: float, z: float) -> float:
	var height = noise.get_noise_2d(x, z) * AMPLITUDE
	return min(max(y - height - 10, -10.0), 10.0)


func sample_circle(x: float, y: float, z: float) -> float:
	var loc = Vector3(x, y, z) - Vector3(16.1, 16, 16)
	return loc.distance_to(Vector3.ZERO) - 15


func sample_flat(x: float, y: float, z: float) -> float:
	var height = 5.0
	var ret_val = min(max(height - 10.0, -10.0), 10.0)
	return ret_val

func sample(x: float, y: float, z: float) -> float:
	var height = noise.get_noise_3d(x, y, z)
	return height

func sample_cube(x: float, y: float, z: float) -> float:
	var center = 16
	var pos = Vector3(
		abs(x - 16) - 10.5,
		abs(y - 16) - 10.5,
		abs(z - 16) - 10.5
	)
	return max(max(pos.x, pos.y), pos.z)

func sample_normal(x: float, y: float, z: float) -> Vector3:
	var base_density = sample(x, y, z)
	var a = sample(x, 10.0, z)
	var b = sample(x, 20.0, z)
	var c = sample(x, 10.001, z)
	var normal = Vector3(
		base_density - sample(x - OFFSET, y, z),
		base_density - sample(x, y - OFFSET, z),
		base_density - sample(x, y, z - OFFSET)
	)
	return normal.normalized()


func generate(start_x: int, start_y: int, start_z: int, size: int):
	var result = []
	result.resize(size)
	for x in range(size):
		var new_sub_array = []
		new_sub_array.resize(size)
		result[x] = new_sub_array
		for y in range(size):
			# NOTE: using PoolRealArray limits floats to 32 bits
			var new_array = PoolRealArray()
			new_array.resize(size)
			result[x][y] = new_array
			for z in range(size):
				result[x][y][z] = sample(x + start_x, y + start_y, z + start_z)
				
	return result

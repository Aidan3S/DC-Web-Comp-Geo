class_name WorldGenerator

var noise = OpenSimplexNoise.new()
const AMPLITUDE = 10.0
const OFFSET = 0.001


func _init():
	noise.seed = 1
	noise.octaves = 1
	noise.period = 20
	noise.persistence = 0.8


func sample(x: float, y: float, z: float) -> float:
	var height = noise.get_noise_2d(x, z) * AMPLITUDE
	return min(max(y - height - 10, -10.0), 10.0)


func sample_flat(x: float, y: float, z: float) -> float:
	var height = 5.0
	var ret_val = min(max(y - height - 10.0, -10.0), 10.0)
	return ret_val


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

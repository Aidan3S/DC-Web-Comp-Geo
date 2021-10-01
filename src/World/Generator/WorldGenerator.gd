class_name WorldGenerator

var noise = OpenSimplexNoise.new()
const AMPLITUDE = 10.0


func _init():
	noise.seed = 1
	noise.octaves = 1
	noise.period = 20
	noise.persistence = 0.8


func sample(x: int, y: int, z: int) -> float:
	var height = noise.get_noise_2d(x, z) * AMPLITUDE
	return min(max(y - height - 10, -10.0), 10.0)


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

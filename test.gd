extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	print("READY")
	for i in range(3, -1, -1):
		print(i)
		
	var test_mat = Matrix.new([
		[1, 3, 5],
		[1.5, 1, 1],
		[0, 0.5, 0]
	])
	var test_mat2 = Matrix.new([
		[1, 3, 1],
		[1, 0, 1],
		[3, 3, 3]
	])
	var test_mat3 = Matrix.new(test_mat.subtract(test_mat2))
	test_mat3.debug_print()

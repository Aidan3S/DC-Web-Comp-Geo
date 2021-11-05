extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	print("READY")
	for i in range(3, -1, -1):
		print(i)
		
	var test_mat = ([
		[1, 3, 5],
		[1.5, 1, 1],
		[0, 0.5, 1]
	])
	var eigs = LinAlg.eigs_powerit(test_mat)
	print("EIGS")
	for i in range(len(eigs[1])):
		var print_str = "| "
		for j in range(len(eigs[1][0])):
			print_str += str(eigs[1][i][j]) + "\t"
		print(print_str)
		
	for p in eigs[0]:
		print(p)

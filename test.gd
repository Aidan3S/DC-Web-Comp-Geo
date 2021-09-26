extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	print("READY")
	for i in range(3, -1, -1):
		print(i)

extends OctreeNode
class_name BranchNode

var children = []

func _init():
	children.resize(8)

func _is_homogenous():
	for child in children:
		if child is HomoLeafNode:
			return false
	return true

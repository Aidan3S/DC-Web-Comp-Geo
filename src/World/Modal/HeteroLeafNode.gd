extends OctreeNode
class_name HeteroLeafNode

var corners: int = 0
var points = PoolRealArray()
var vertex: int = -1
var dirty: bool = false

func _init():
	points.resize(8)

extends OctreeNode
class_name HeteroLeafNode

var corners: int = 0
var points = PoolRealArray()
var vertex: int = -1
var dirty: bool = false
var edge_points = []
var edge_normals = []

func _init():
	points.resize(8)
	edge_points.resize(12)
	edge_normals.resize(12)

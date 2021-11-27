extends OctreeNode
class_name HeteroLeafNode

var corners: int = 0
var points = PoolRealArray()
var vertex: int = -1
var solve_point: Vector3 = Vector3.ZERO
var avg_norm: Vector3 = Vector3.ZERO
var dirty: bool = false
var edge_points = []
var edge_normals = []
var point_materials = PoolIntArray()
var edge_dirty = []

func _init():
	points.resize(8)
	point_materials.resize(8)
	edge_points.resize(12)
	edge_normals.resize(12)
	edge_dirty.resize(12)
	for i in range(12):
		edge_dirty[i] = true

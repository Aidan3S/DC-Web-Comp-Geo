class_name Octree

# Determines which corners are stored in what index of the child array in a 
# branch node.
const VERTEX_MAP = [
	PoolIntArray([0, 0, 0]),
	PoolIntArray([0, 0, 1]),
	PoolIntArray([0, 1, 0]),
	PoolIntArray([0, 1, 1]),
	PoolIntArray([1, 0, 0]),
	PoolIntArray([1, 0, 1]),
	PoolIntArray([1, 1, 0]),
	PoolIntArray([1, 1, 1])
]

var root


# Initializes octree from a static 3d array of values. Size of data must be size
# 2^x + 1 and equal length in all dimensions.
func from_array(data):
	root = _from_array(data, 0, 0, 0, len(data) - 1)
	

func _from_array(data, min_x: int, min_y: int, min_z: int, size: int) -> OctreeNode:
	if size <= 1:
		# Base case, generate smallest leaf node
		# Check for homogeneous node
		var homo = true
		var weight_sign = data[min_x][min_y][min_z] > 0.0
		for mod_x in [0, 1]:
			for mod_y in [0, 1]:
				for mod_z in [0, 1]:
					var matches = (data[min_x + mod_x][min_y + mod_y][min_z + mod_z] > 0.0) == weight_sign
					homo = homo && matches
					
		# Check if homogenous node
		if homo:
			# Homogenous node found, return
			var node = HomoLeafNode.new()
			node.size = size
			node.has_mass = !weight_sign
			return node
			
		# Return hetrogenous node otherwise
		var node = HeteroLeafNode.new()
		# Copy weights
		for i in range(len(VERTEX_MAP)):
			# TODO: ADD CORNERS
			var offset = VERTEX_MAP[i]
			node.points[i] = data[min_x + offset[0]][min_y + offset[1]][min_z + offset[2]]
		node.size = size
		return node
		
	# Otherwise, this could be a branch node
	var children = []
	children.resize(8)
	# Try to construct children
	var homo = true
	var child_size = size / 2
	for i in range(len(VERTEX_MAP)):
		var offset = VERTEX_MAP[i]
		var child_x = offset[0] * child_size + min_x
		var child_y = offset[1] * child_size + min_y
		var child_z = offset[2] * child_size + min_z
		children[i] = _from_array(data, child_x, child_y, child_z, child_size)
		homo = homo && children[i] is HomoLeafNode
	# If all children are homo, parent is homo
	if homo:
		var node = HomoLeafNode.new()
		node.has_mass = children[0].has_mass
		node.size = size
		return node
	else:
		# This is a branch node
		var node = BranchNode.new()
		node.size = size
		node.children = children
		return node

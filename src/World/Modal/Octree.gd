class_name Octree

## CONSTANTS
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

# Maps an edge number to two corners, the third number is the direction.
const EDGE_TO_CORNER = [
	PoolIntArray([0,4,0]), PoolIntArray([1,5,0]), PoolIntArray([2,6,0]), PoolIntArray([3,7,0]),
	PoolIntArray([0,2,1]), PoolIntArray([4,6,1]), PoolIntArray([1,3,1]), PoolIntArray([5,7,1]),
	PoolIntArray([0,1,2]), PoolIntArray([2,3,2]), PoolIntArray([4,5,2]), PoolIntArray([6,7,2])
]

const CELL_PROC_EDGE_MASK = [
	PoolIntArray([0,1,2,3,0]), PoolIntArray([4,5,6,7,0]),
	PoolIntArray([0,4,1,5,1]), PoolIntArray([2,6,3,7,1]),
	PoolIntArray([0,2,4,6,2]), PoolIntArray([1,3,5,7,2])
]

const FACE_PROC_FACE_MASK = [
	[ PoolIntArray([4,0,0]), PoolIntArray([5,1,0]), PoolIntArray([6,2,0]), PoolIntArray([7,3,0]) ],
	[ PoolIntArray([2,0,1]), PoolIntArray([6,4,1]), PoolIntArray([3,1,1]), PoolIntArray([7,5,1]) ],
	[ PoolIntArray([1,0,2]), PoolIntArray([3,2,2]), PoolIntArray([5,4,2]), PoolIntArray([7,6,2]) ]
]

const FACE_PROC_EDGE_MASK = [
	[ PoolIntArray([1,4,0,5,1,1]), PoolIntArray([1,6,2,7,3,1]), PoolIntArray([0,4,6,0,2,2]), PoolIntArray([0,5,7,1,3,2]) ],
	[ PoolIntArray([0,2,3,0,1,0]), PoolIntArray([0,6,7,4,5,0]), PoolIntArray([1,2,0,6,4,2]), PoolIntArray([1,3,1,7,5,2]) ],
	[ PoolIntArray([1,1,0,3,2,0]), PoolIntArray([1,5,4,7,6,0]), PoolIntArray([0,1,5,0,4,1]), PoolIntArray([0,3,7,2,6,1]) ]
]

const FACE_PROC_ORDER = [
	PoolIntArray([0,0,1,1]), PoolIntArray([0,1,0,1])
]

const EDGE_PROC_EDGE_MASK = [
	[ PoolIntArray([3,2,1,0,0]), PoolIntArray([7,6,5,4,0]) ],
	[ PoolIntArray([5,1,4,0,1]), PoolIntArray([7,3,6,2,1]) ],
	[ PoolIntArray([6,4,2,0,2]), PoolIntArray([7,5,3,1,2]) ]
]

# Relates direction and node order to edge id
const PROCESS_EDGE_MAP = [
	PoolIntArray([3,2,1,0]), PoolIntArray([7,5,6,4]), PoolIntArray([11,10,9,8])
]

var root
var chunk_size


# Initializes octree from a static 3d array of values. Size of data must be size
# 2^x + 1 in all dimensions.
func from_array(data):
	chunk_size = len(data) - 1
	root = _from_array(data, 0, 0, 0, chunk_size)
	

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
			var offset = VERTEX_MAP[i]
			node.points[i] = data[min_x + offset[0]][min_y + offset[1]][min_z + offset[2]]
		node.size = size
		node.dirty = true
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


func generate_verticies(meshTool: MeshTool, generator: WorldGenerator):
	_generate_verticies(root, meshTool, 0, 0, 0, chunk_size, generator)


func _generate_verticies(node: OctreeNode, meshTool: MeshTool, min_x: int, min_y: int, min_z: int, size: int, generator: WorldGenerator):
	# Recurse on branch nodes
	if node is BranchNode:
		var child_size = size / 2
		for i in range(len(node.children)):
			var child_x = VERTEX_MAP[i][0] * child_size + min_x
			var child_y = VERTEX_MAP[i][1] * child_size + min_y
			var child_z = VERTEX_MAP[i][2] * child_size + min_z
			_generate_verticies(node.children[i], meshTool, child_x, child_y, child_z, child_size, generator)

	# Filter out only hetero nodes
	if !(node is HeteroLeafNode):
		return

	# Don't update this node if it's not dirty
	if !node.dirty:
		return
		
	# Calculate corners variable
	node.corners = 0
	for i in range(len(VERTEX_MAP) - 1, -1, -1):
		node.corners <<= 1
		var point_weight = node.points[i]
		node.corners |= (1 if point_weight > 0 else 0)

	var AtA = Matrix.new([
		[0, 0, 0],
		[0, 0, 0],
		[0, 0, 0]
	])
	# Generate edge crossing locations and normals
	for edge_index in range(len(EDGE_TO_CORNER)):
		var index1 = EDGE_TO_CORNER[edge_index][0]
		var index2 = EDGE_TO_CORNER[edge_index][1]
		# Skip edge if not a crossing
		if ((node.corners >> index1) & 1) == ((node.corners >> index2) & 1):
			continue
		
		# Estimate position of crossing
		var n2Dist = -1 * node.points[index2]
		var percentDist = n2Dist / (n2Dist + node.points[index1])
		var invPercentDist = 1 - percentDist
		var crossing = Vector3(
			VERTEX_MAP[index1][0] * percentDist + VERTEX_MAP[index2][0] * invPercentDist,
			VERTEX_MAP[index1][1] * percentDist + VERTEX_MAP[index2][1] * invPercentDist,
			VERTEX_MAP[index1][2] * percentDist + VERTEX_MAP[index2][2] * invPercentDist
		)
		node.edge_points[edge_index] = crossing
		
		# Calculate normal
		var norm = generator.sample_normal(crossing.x, crossing.y, crossing.z)
		node.edge_normals[edge_index] = norm
		
		# Add to AtA matrix
		
	# TODO: do vertex calculation here
	var vertex = Vector3(min_x + 0.5, min_y + 0.5, min_z + 0.5)

	# Add vertex to mesh and node
	node.vertex = meshTool.add_vertex(vertex, Vector3.ZERO, node)


func build_mesh(mesh_tool: MeshTool):
	_cell_proc(root, mesh_tool)


func _cell_proc(node: OctreeNode, mesh_tool: MeshTool):
	# Only run on branch nodes
	if (node == null) or not (node is BranchNode):
		return
	
	# Propagate cell_proc to all children
	for child in node.children:
		_cell_proc(child, mesh_tool)
	
	# Propagate face_proc for all 12 internal faces
	for i in range(12):
		var face_nodes = [
			node.children[EDGE_TO_CORNER[i][0]],
			node.children[EDGE_TO_CORNER[i][1]]
		]
		_face_proc(face_nodes, EDGE_TO_CORNER[i][2], mesh_tool)
	
	# Propagate edge_proc for all 6 internal edges
	for i in range(6):
		var edge_nodes = [
			node.children[CELL_PROC_EDGE_MASK[i][0]],
			node.children[CELL_PROC_EDGE_MASK[i][1]],
			node.children[CELL_PROC_EDGE_MASK[i][2]],
			node.children[CELL_PROC_EDGE_MASK[i][3]]
		]
		_edge_proc(edge_nodes, CELL_PROC_EDGE_MASK[i][4], mesh_tool)
	
	
func _face_proc(nodes: Array, direction: int, mesh_tool: MeshTool):
	# Only run if there are no null nodes and not all nodes are not leaves.
	var all_leaves = true
	for node in nodes:
		if node == null:
			return
		elif node is BranchNode:
			all_leaves = false
	if all_leaves:
		return
	
	# Propagate calls to face_proc
	for i in range(4):
		var face_nodes = [ nodes[0], nodes[1] ]
		for j in range(2):
			if not face_nodes[j] is BranchNode:
				continue
			face_nodes[j] = face_nodes[j].children[FACE_PROC_FACE_MASK[direction][i][j]]
		_face_proc(face_nodes, FACE_PROC_FACE_MASK[direction][i][2], mesh_tool)
	
	# Propagate calls to face_proc
	for i in range(4):
		var edge_nodes = []
		edge_nodes.resize(4)
		var order = FACE_PROC_ORDER[FACE_PROC_EDGE_MASK[direction][i][0]]
		for j in range(4):
			var select_node = nodes[order[j]]
			if select_node is BranchNode:
				edge_nodes[j] = select_node.children[FACE_PROC_EDGE_MASK[direction][i][j + 1]]
			else:
				edge_nodes[j] = select_node
		_edge_proc(edge_nodes, FACE_PROC_EDGE_MASK[direction][i][5], mesh_tool)
	
	
func _edge_proc(nodes: Array, direction: int, mesh_tool: MeshTool):
	# If any node is a homogenous node, we don't want this edge
	# Keep track if all nodes are Hetrogenous nodes
	var all_hetero_nodes = true
	for node in nodes:
		if node is HomoLeafNode:
			return
		if not node is HeteroLeafNode:
			all_hetero_nodes = false
	
	# If all hetero nodes, we want to process this edge as it contains a quad on
	# the mesh
	if all_hetero_nodes:
		_process_edge(nodes, direction, mesh_tool)
		return

	# One of the nodes is a branch node, break it down
	for i in range(2):
		var edge_nodes = []
		edge_nodes.resize(4)
		for j in range(4):
			if nodes[j] is BranchNode:
				edge_nodes[j] = nodes[j].children[EDGE_PROC_EDGE_MASK[direction][i][j]]
			else:
				edge_nodes[j] = nodes[j]
		_edge_proc(edge_nodes, EDGE_PROC_EDGE_MASK[direction][i][4], mesh_tool)


func _process_edge(nodes: Array, direction: int, mesh_tool: MeshTool):
	# Find smallest node along edge and accumulate all verticies
	var min_size = nodes[0].size
	var deepest_node_index = 0
	var verticies = []
	verticies.resize(4)
	for i in range(4):
		var node = nodes[i]
		verticies[i] = node.vertex
		if node.size <= min_size:
			min_size = node.size
			deepest_node_index = i
			
	# Check smallest node to see if quad needs flipped
	var deepest_node = nodes[deepest_node_index]
	var edge = PROCESS_EDGE_MAP[direction][deepest_node_index]
	var corner1 = EDGE_TO_CORNER[edge][0]
	var sign1 = (deepest_node.corners >> corner1) & 1
	var corner2 = EDGE_TO_CORNER[edge][1]
	var sign2 = (deepest_node.corners >> corner2) & 1
	# Skip this edge if it's not a crossing
	if sign1 == sign2:
		return
	# This edge has a crossing - create a quad around it
	# Flip quad direction first if sign is 0
	if sign1 == 1:
		var temp = verticies[2]
		verticies[2] = verticies[1]
		verticies[1] = temp
	mesh_tool.add_quad(verticies)

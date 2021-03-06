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

const CORNER_TO_EDGE = [
	PoolIntArray([0, 4, 8]),
	PoolIntArray([1, 6, 8]),
	PoolIntArray([2, 8, 9]),
	PoolIntArray([3, 6, 9]),
	PoolIntArray([0, 5, 10]),
	PoolIntArray([1, 7, 10]),
	PoolIntArray([2, 5, 11]),
	PoolIntArray([3, 6, 11])
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

const EIGEN_THRESHOLD = 0.01

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
			# Temp: generate materials
			if !node.has_mass:
				node.material = 0
			elif min_y < 16:
				node.material = 2
			else:
				node.material = 1
			return node
			
		# Return hetrogenous node otherwise
		var node = HeteroLeafNode.new()
		# Copy weights
		for i in range(len(VERTEX_MAP)):
			var offset = VERTEX_MAP[i]
			node.points[i] = data[min_x + offset[0]][min_y + offset[1]][min_z + offset[2]]
			# Temp: generate materials
			if data[min_x + offset[0]][min_y + offset[1]][min_z + offset[2]] > 0:
				node.point_materials[i] = 0
			elif min_y + offset[1] < 16:
				node.point_materials[i] = 2
			else:
				node.point_materials[i] = 1
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
		# Temp: generate materials
		if !node.has_mass:
			node.material = 0
		elif min_y < 16:
			node.material = 2
		else:
			node.material = 1
		return node
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

func _calc_point(node: HeteroLeafNode, meshTool: MeshTool, min_x: int, min_y: int, min_z: int, size: int, generator: WorldGenerator):
	# Calculate average normal and point
	var avg_norm = Vector3.ZERO
	var avg_point = Vector3.ZERO
	var num_norm = 0
	
	# Generate edge crossing locations and normals
	for edge_index in range(len(EDGE_TO_CORNER)):
		# Skip edge if it's not dirty
		if !node.edge_dirty[edge_index]:
			continue
		var index1 = EDGE_TO_CORNER[edge_index][0]
		var index2 = EDGE_TO_CORNER[edge_index][1]
		# Skip edge if not a crossing
		if ((node.corners >> index1) & 1) == ((node.corners >> index2) & 1):
			node.edge_points[edge_index] = null
			node.edge_normals[edge_index] = null
			node.edge_dirty[edge_index] = false
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
		var norm = generator.sample_normal(crossing.x + min_x, crossing.y + min_y, crossing.z + min_z)
		node.edge_normals[edge_index] = norm

		node.edge_points[edge_index] = crossing
		node.edge_normals[edge_index] = norm
		
		node.edge_dirty[edge_index] = false
	
	# Forward to C# for processing
	var normals = []
	var crossings = []
	for i in range(len(node.edge_points)):
		if node.edge_points[i] != null:
			normals.append(node.edge_normals[i])
			crossings.append(node.edge_points[i])
	node.solve_point = QEFSolver.solve(normals, crossings) + Vector3(min_x, min_y, min_z)

	# Calculate average normal
	var num_normals = 0
	var sum_normals = Vector3.ZERO
	for normal in node.edge_normals:
		if normal != null:
			sum_normals += normal
			num_normals += 1
	node.avg_norm = sum_normals / num_normals
	
	# Add vertex to mesh
	node.vertex = meshTool.add_vertex(node.solve_point, node.avg_norm, node)

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

	# Update edges, normals, and calculate vertex location
	_calc_point(node, meshTool, min_x, min_y, min_z, size, generator)


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
	# Also set the material
	var material
	if sign1 == 1:
		var temp = verticies[2]
		verticies[2] = verticies[1]
		verticies[1] = temp
		material = deepest_node.point_materials[corner2]
	else:
		material = deepest_node.point_materials[corner1]
	mesh_tool.add_quad(verticies, material)


func apply_func(generator: WorldGenerator, subtract: bool, meshTool: MeshTool, brush_min_pos: Vector3, brush_size: int):
	var new_root =_apply_func(root, generator, subtract, Vector3.ZERO, chunk_size, meshTool, brush_min_pos, brush_size)
	if new_root != null:
		root = new_root
	build_mesh(meshTool)


func _apply_func(n: OctreeNode, generator: WorldGenerator, subtract: bool, min_pos: Vector3, size: int, meshTool: MeshTool, brush_min_pos: Vector3, brush_size: int):
	var child_size = size / 2
	# Due to silly restrictions in gdscript, we have to handle this in octree,
	# not in the nodes themselves. BranchNodes can't instatiate more branches.
	if n is BranchNode:
		# Make call on all children
		for i in range(8):
			var child_pos = Vector3(
				VERTEX_MAP[i][0] * child_size + min_pos.x,
				VERTEX_MAP[i][1] * child_size + min_pos.y,
				VERTEX_MAP[i][2] * child_size + min_pos.z
			)
			var replacement = _apply_func(n.children[i], generator, subtract, child_pos, child_size, meshTool, brush_min_pos, brush_size)
			if replacement != null:
				n.children[i] = replacement
		# Check for collapse
		for child in n.children:
			if not child is HomoLeafNode:
				return null
		# All are homogenous, collapse this node
		n.children[0].size = size
		return n.children[0]
	
	elif n is HeteroLeafNode:
		var dirty = false
		
		# Update all corners
		for i in range(len(VERTEX_MAP)):
			var offset = VERTEX_MAP[i]
			var value = generator.sample(min_pos.x + offset[0], min_pos.y + offset[1], min_pos.z + offset[2])
			var had_mass = n.points[i] <= 0
			# Check if we should replace
			if (subtract and value > n.points[i]) or (!subtract and value < n.points[i]):
				# Replace value
				n.points[i] = value
				dirty = true
				# Check if sign changed
				if had_mass != (n.points[i] <= 0):
					# Replace material
					n.point_materials[i] = 3 if n.points[i] <= 0 else 0
					# Adjust corner bits
					if n.points[i] <= 0:
						n.corners &= ~(1 << i)
					else:
						n.corners |= 1 << i
					# Mark edges dirty
					for edge_index in range(3):
						n.edge_dirty[CORNER_TO_EDGE[i][0]] = true
						n.edge_dirty[CORNER_TO_EDGE[i][1]] = true
						n.edge_dirty[CORNER_TO_EDGE[i][2]] = true

		# Update changed edges
		if dirty:
			# Collapse if no longer a crossing
			if n.corners == 0 or n.corners == 255:
				var new_node = HomoLeafNode.new()
				new_node.has_mass = n.points[0] <= 0
				new_node.material = n.point_materials[0]
				new_node.size = 1
				return new_node
			_calc_point(n, meshTool, min_pos.x, min_pos.y, min_pos.z, size, generator)
		else:
			n.vertex = meshTool.add_vertex(n.solve_point, n.avg_norm, n)
	
	elif n is HomoLeafNode:
		# Check area for changed signs
		for x in range(max(min_pos.x, brush_min_pos.x), min(min_pos.x + size, brush_min_pos.x + brush_size) + 1):
			for y in range(max(min_pos.y, brush_min_pos.y), min(min_pos.y + size, brush_min_pos.y + brush_size) + 1):
				for z in range(max(min_pos.z, brush_min_pos.z), min(min_pos.z + size, brush_min_pos.z + brush_size) + 1):
					# Check if different sign
					var sample = generator.sample(x, y, z)
					if (subtract and (sample > 0) and n.has_mass) or (!subtract and (sample <= 0) and !n.has_mass):
						# Break this node down
						if size == 1:
							# Break into heterogenous node
							var val = -1 if n.has_mass else 1
							var new_node = HeteroLeafNode.new()
							new_node.corners = 0 if n.has_mass else 255
							new_node.size = size
							for i in range(len(new_node.points)):
								new_node.points[i] = val
								new_node.point_materials[i] = n.material
							_apply_func(new_node, generator, subtract, min_pos, size, meshTool, brush_min_pos, brush_size)
							return new_node
						else:
							# Break into branch
							var new_node = BranchNode.new()
							new_node.size = size
							for i in range(len(new_node.children)):
								var new_child = HomoLeafNode.new()
								new_child.size = child_size
								new_child.has_mass = n.has_mass
								new_child.material = n.material
								new_node.children[i] = new_child
							_apply_func(new_node, generator, subtract, min_pos, size, meshTool, brush_min_pos, brush_size)
							return new_node
	return null


func get_weight_at(search_pos: Vector3):
	return _get_weight_at(search_pos, Vector3.ZERO, 32, root)


func _get_weight_at(search_pos: Vector3, min_pos: Vector3, size: int, node: OctreeNode):
	# Base case: every child is the same weight
	if node is HomoLeafNode:
		return -1 if node.has_mass else 1
		
	var child_size = size / 2
	var local_pos = search_pos - min_pos
	
	# Get corner index
	var corner_index = 4 if local_pos.x > child_size else 0
	corner_index |= 2 if local_pos.y > child_size else 0
	corner_index |= 1 if local_pos.z > child_size else 0
	
	# Return appropriate corner weight if a hetero node
	if node is HeteroLeafNode:
		return node.points[corner_index]
		
	# Continue down path if branch node
	var child_pos = Vector3(
		VERTEX_MAP[corner_index][0] * child_size + min_pos.x,
		VERTEX_MAP[corner_index][1] * child_size + min_pos.y,
		VERTEX_MAP[corner_index][2] * child_size + min_pos.z
	)
	return _get_weight_at(search_pos, child_pos, child_size, node.children[corner_index])

func _count_verts(node: OctreeNode):
	if node is HeteroLeafNode:
		return 0
	elif node is HomoLeafNode:
		return 1 if node.has_mass else 0
	else:
		var sum = 0
		for c in node.children:
			sum += _count_verts(c)
		return sum

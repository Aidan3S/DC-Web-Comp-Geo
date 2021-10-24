extends MeshInstance
class_name Chunk

const CHUNK_SIZE = 32

export var block_x: int
export var block_y: int
export var block_z: int

var octree

# Called when the node enters the scene tree for the first time.
func _ready():
	# Generate samples in a grid
	var generator = WorldGenerator.new()
	var sample_data = generator.generate(block_x, block_y, block_z, CHUNK_SIZE + 1)
	
	# Create octree
	octree = Octree.new()
	octree.from_array(sample_data)
	
	# Generate verticies (place using QEF minimization)
	var mesh_tool = MeshTool.new()
	octree.generate_verticies(mesh_tool, generator)
	
	# Create mesh from octree
	octree.build_mesh(mesh_tool)

	# Apply mesh
	mesh = mesh_tool.to_mesh()
	create_trimesh_collision()
	print("loaded")

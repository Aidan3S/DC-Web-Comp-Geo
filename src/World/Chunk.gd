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

func break_block(world_pos: Vector3):
	var local_pos = (world_pos - transform.origin) / scale
	local_pos = Vector3(floor(local_pos.x), floor(local_pos.y), floor(local_pos.z))
	var generator = SphereGeneratorNegative.new(2, local_pos)
	var mesh_tool = MeshTool.new()
	octree.apply_func(generator, true, mesh_tool)
	
	# Apply mesh
	mesh = mesh_tool.to_mesh()
	remove_child(get_child(0))
	create_trimesh_collision()
	print("loaded")

extends MeshInstance
class_name Chunk

const CHUNK_SIZE = 32

export var block_x: int
export var block_y: int
export var block_z: int

var octree

signal chunk_update(new_octree)


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
	local_pos = Vector3(round(local_pos.x), round(local_pos.y), round(local_pos.z))
	var generator = SphereGeneratorNegative.new(2, local_pos)
	_modify(local_pos - Vector3(2, 2, 2), generator, 4, true)
	emit_signal("chunk_update", octree)

func place_block(world_pos: Vector3):
	var local_pos = (world_pos - transform.origin) / scale
	local_pos = Vector3(round(local_pos.x), round(local_pos.y), round(local_pos.z))
	var generator = SphereGenerator.new(2, local_pos)
	if Input.is_action_pressed("sprint"):
		generator = CubeGenerator.new(1.4, local_pos)
	_modify(local_pos - Vector3(2, 2, 2), generator, 4, false)
	emit_signal("chunk_update", octree)
	
func _modify(local_pos, generator, size, erase):
	var mesh_tool = MeshTool.new()
	octree.apply_func(generator, erase, mesh_tool, local_pos, size)
	
	# Apply mesh
	mesh = mesh_tool.to_mesh()
	remove_child(get_child(0))
	create_trimesh_collision()

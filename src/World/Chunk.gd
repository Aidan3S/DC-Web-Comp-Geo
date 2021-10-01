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
	
	# Create mesh from octree
	var mesh_tool = MeshTool.new()
	mesh_tool.add_vertex(Vector3(0, 0, 0), Vector3(0,0,0), self)
	mesh_tool.add_vertex(Vector3(1, 0, 0), Vector3(0,0,0), self)
	mesh_tool.add_vertex(Vector3(0, 1, 0), Vector3(0,0,0), self)
	mesh_tool.add_vertex(Vector3(1, 1, 0), Vector3(0,0,0), self)
	mesh_tool.add_quad(0,2,1,3)
	mesh = mesh_tool.to_mesh()
	create_trimesh_collision()
	print("loaded")

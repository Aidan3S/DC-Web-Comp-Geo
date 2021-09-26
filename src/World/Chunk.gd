extends MeshInstance
class_name Chunk

# Called when the node enters the scene tree for the first time.
func _ready():
	var mesh_tool = MeshTool.new()
	mesh_tool.add_vertex(Vector3(0, 0, 0), Vector3(0,0,0), self)
	mesh_tool.add_vertex(Vector3(1, 0, 0), Vector3(0,0,0), self)
	mesh_tool.add_vertex(Vector3(0, 1, 0), Vector3(0,0,0), self)
	mesh_tool.add_vertex(Vector3(1, 1, 0), Vector3(0,0,0), self)
	mesh_tool.add_quad(0,2,1,3)
	mesh = mesh_tool.to_mesh()
	create_trimesh_collision()
	print("loaded")

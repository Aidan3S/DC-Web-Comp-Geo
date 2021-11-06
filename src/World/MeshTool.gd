class_name MeshTool

var x = 0
var verticies = []
var polygons = []
var materials = {
	"0": preload("res://src/Materials/M_Test.tres"),
	"1": preload("res://src/Materials/M_Grass.tres"),
	"2": preload("res://src/Materials/M_Dirt.tres"),
}


func add_vertex(vertex: Vector3, normal: Vector3, parent: OctreeNode) -> int:
	var ret_value = len(verticies)
	verticies.append({
		"vertex": vertex,
		"normal": normal,
		"parent": parent,
		"polygons": []
	})
	return ret_value


func add_quad(vert_list: Array, material: int = 1) -> int:
	var ret_value = len(polygons)
	polygons.append({
		"verts": vert_list,
		"material": material
	})
	for vert_id in vert_list:
		verticies[vert_id]["polygons"].append(ret_value)
	return ret_value


func remove_polygon(poly_id: int):
	# Remove polygon from each connected vertex
	for vertex_id in polygons[poly_id]["verts"]:
		verticies[vertex_id]["polygons"].erase(poly_id)
		
	# If there are polygons left, copy the last one and update its verts
	if poly_id != len(polygons) - 1:
		polygons[poly_id] = polygons[-1]
		for vertex_id in polygons[poly_id]["verts"]:
			var replace_index = verticies[vertex_id]["polygons"].find(len(polygons) - 1)
			verticies[vertex_id]["polygons"][replace_index] = poly_id
			
	# Remove last polygon (it's now duplicated)
	polygons.remove(-1)


func remove_vertex(vert_id: int):
	# Remove vertex from each connected polygon
	var num_polys = len(polygons)
	for i in range(num_polys - 1, -1, -1):
		remove_polygon(verticies[vert_id]["polygons"][i])
	
	# Update associated polygons
	if vert_id != len(verticies) - 1:
		verticies[vert_id] = verticies[-1]
		for poly_id in verticies[vert_id]["polygons"]:
			var replace_index = polygons[poly_id]["verts"].find(len(verticies) - 1)
			polygons[poly_id]["verts"][replace_index] = vert_id
			
	# Remove last vertex (it's now duplicated)
	verticies.remove(-1)
	

func to_mesh() -> Mesh:
	var vert_map = {}
	
	for poly in polygons:
		# Get this material's set of vertex/poly/normals
		# Make a set of arrays if this is the first time the material is found
		var mat_key = str(poly["material"])
		var arrays
		if not mat_key in vert_map:
			arrays = [
				[],
				[],
				[],
				{}   # This maps the vertex index in this tool to the surface
			]
			vert_map[mat_key] = arrays
		else:
			arrays = vert_map[mat_key]
			
		# Change this quad's verts to use the per-surface index
		var mapped_verts = []
		mapped_verts.resize(4)
		for i in range(4):
			var vert_index = poly["verts"][i]
			var vert_key = str(vert_index)
			if vert_index in arrays[3]:
				mapped_verts[i] = arrays[3][vert_key]
			else:
				# This vert isn't in arrays yet, add it
				var pos = len(arrays[0])
				arrays[0].push_back(verticies[vert_index]["vertex"])
				arrays[1].push_back(verticies[vert_index]["normal"])
				arrays[3][vert_key] = vert_index
				mapped_verts[i] = pos
				
		# Add mapped vertex indicies
		arrays[2].push_back(mapped_verts[0])
		arrays[2].push_back(mapped_verts[1])
		arrays[2].push_back(mapped_verts[3])
		
		arrays[2].push_back(mapped_verts[0])
		arrays[2].push_back(mapped_verts[3])
		arrays[2].push_back(mapped_verts[2])
	
	# Put data into ArrayMesh
	var array_mesh = ArrayMesh.new()
	for surface_key in vert_map.keys():
		var surface_array = vert_map[surface_key]
		var composite_array = []
		composite_array.resize(ArrayMesh.ARRAY_MAX)
		composite_array[ArrayMesh.ARRAY_VERTEX] = PoolVector3Array(surface_array[0])
		composite_array[ArrayMesh.ARRAY_INDEX] = PoolIntArray(surface_array[2])
		composite_array[ArrayMesh.ARRAY_NORMAL] = PoolVector3Array(surface_array[1])
		var surf_idx = array_mesh.get_surface_count()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, composite_array)
		array_mesh.surface_set_material(surf_idx, materials[surface_key])
	return array_mesh

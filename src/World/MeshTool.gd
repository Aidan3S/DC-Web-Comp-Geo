class_name MeshTool

var x = 0
var verticies = []
var polygons = []


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
		"marterial": material
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
	# Compile vertex data
	var comp_verts = PoolVector3Array()
	var comp_norms = PoolVector3Array()
	for vert_info in verticies:
		comp_verts.push_back(vert_info["vertex"])
		comp_norms.push_back(vert_info["normal"])
		
	# Compile face data
	var comp_polys = PoolIntArray()
	for poly in polygons:
		var verts = poly["verts"]
		comp_polys.push_back(verts[0])
		comp_polys.push_back(verts[1])
		comp_polys.push_back(verts[3])
		
		comp_polys.push_back(verts[0])
		comp_polys.push_back(verts[3])
		comp_polys.push_back(verts[2])
	
	# Put data into ArrayMesh
	var array_mesh = ArrayMesh.new()
	var composite_array = []
	composite_array.resize(ArrayMesh.ARRAY_MAX)
	composite_array[ArrayMesh.ARRAY_VERTEX] = comp_verts
	composite_array[ArrayMesh.ARRAY_INDEX] = comp_polys
	composite_array[ArrayMesh.ARRAY_NORMAL] = comp_norms
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, composite_array)
	return array_mesh

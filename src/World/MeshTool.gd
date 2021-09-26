class_name MeshTool

var x = 0
var verticies = []
var polygons = []


func add_vertex(vertex: Vector3, normal: Vector3, parent: Node) -> int:
	var ret_value = len(verticies)
	verticies.append({
		"vertex": vertex,
		"normal": normal,
		"parent": parent,
		"polygons": []
	})
	return ret_value


func add_quad(v1: int, v2: int, v3: int, v4: int) -> int:
	var ret_value = len(polygons)
	var vert_list = [v1, v2, v3, v4]
	polygons.append(vert_list)
	for vert_id in vert_list:
		verticies[vert_id]["polygons"].append(ret_value)
	return ret_value

	
func remove_polygon(poly_id: int):
	# Remove polygon from each connected vertex
	var update_verts = polygons[-1]
	for vertex_id in polygons[poly_id]:
		verticies[vertex_id]["polygons"].erase(poly_id)
		
	# If there are polygons left, copy the last one and update its verts
	if poly_id != len(polygons) - 1:
		polygons[poly_id] = polygons[-1]
		for vertex_id in polygons[poly_id]:
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
			var replace_index = polygons[poly_id].find(len(verticies) - 1)
			polygons[poly_id][replace_index] = vert_id
			
	# Remove last vertex (it's now duplicated)
	polygons.remove(-1)
	

func to_mesh() -> Mesh:
	# Compile vertex data
	var comp_verts = PoolVector3Array()
	for vert_info in verticies:
		comp_verts.push_back(vert_info["vertex"])
		
	# Compile face data
	var comp_polys = PoolIntArray()
	for poly in polygons:
		comp_polys.push_back(poly[0])
		comp_polys.push_back(poly[1])
		comp_polys.push_back(poly[3])
		
		comp_polys.push_back(poly[0])
		comp_polys.push_back(poly[3])
		comp_polys.push_back(poly[2])
	
	# Put data into ArrayMesh
	var array_mesh = ArrayMesh.new()
	var composite_array = []
	composite_array.resize(ArrayMesh.ARRAY_MAX)
	composite_array[ArrayMesh.ARRAY_VERTEX] = comp_verts
	composite_array[ArrayMesh.ARRAY_INDEX] = comp_polys
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, composite_array)
	return array_mesh

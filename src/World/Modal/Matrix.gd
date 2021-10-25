class_name Matrix
# Matrix operations return data array because GDScript does not yet support
# instantiating a class within itself.

var data
var rows
var cols

func _init(input_data):
	if input_data != null:
		data = input_data
		rows = len(input_data)
		cols = len(input_data[0])


func shape(rows, cols):
	self.rows = rows
	self.cols = cols
	data = _make_shape(rows, cols)


func _make_shape(new_rows, new_cols):
	var new_data = []
	new_data.resize(new_rows)
	for r in range(new_rows):
		var new_arr = []
		new_arr.resize(new_cols)
		new_data[r] = new_arr
		for c in range(new_cols):
			new_data[r][c] = 0.0
	return new_data


func multiply(mat: Matrix):
	var data2 = mat.data
	var result = _make_shape(rows, mat.cols)
	for i in range(rows):
		for j in range(mat.cols):
			var total = 0
			for k in range(cols):
				total += data[i][k] * data2[k][j]
			result[i][j] = total
			
	return result


func add(mat: Matrix):
	var data2 = mat.data
	var result = _make_shape(rows, cols)
	for i in range(rows):
		for j in range(cols):
			result[i][j] = data[i][j] + data2[i][j]
			
	return result


func subtract(mat: Matrix):
	var data2 = mat.data
	var result = _make_shape(rows, cols)
	for i in range(rows):
		for j in range(cols):
			result[i][j] = data[i][j] - data2[i][j]
			
	return result


func transpose():
	var result = _make_shape(cols, rows)
	for i in range(rows):
		for j in range(cols):
			result[j][i] = data[i][j]
			
	return result
	
	
func append_AtBt(normal: Vector3, position: Vector3):
	var vec_to_add = normal * normal.dot(position)
	data[0][0] += vec_to_add.x
	data[0][1] += vec_to_add.y
	data[0][2] += vec_to_add.z
	


func debug_print():
	print("Matrix: " + str(rows) + "x" + str(cols))
	for i in range(rows):
		var print_str = "| "
		for j in range(cols):
			print_str += str(data[i][j]) + "\t"
		print(print_str)

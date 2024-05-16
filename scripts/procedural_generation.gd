extends Node2D

@export var root_3d : Node3D
@export var camera : Camera3D

var original_polygon : CustomPolygon2D
var polygons : Array
var center : Vector2 = Vector2(1280.0, 720.0) / 2.0
var zoom : float = 1.0
var offset : Vector2 = Vector2.ZERO


func _ready():
	# 7, 17
	original_polygon = generate_city_outline(Vector2.ZERO, 7, 17, 180.0)
	polygons = [original_polygon]
	
	
	for i in 10:
		var line = find_split_line(original_polygon)
		var new_polygons = []
		for polygon in polygons:
			var split_polygon : Array = polygon.split(line)
			if split_polygon.size() == 2.0:
				var area1 = split_polygon[0].get_area()
				var area2 = split_polygon[1].get_area()
				if area1 < 1000.0 or area2 < 1000.0:
					split_polygon = [polygon]
					
			new_polygons.append_array(split_polygon)
			
		polygons = new_polygons
	
	var final_polygons = []
	
	for polygon in polygons:
		final_polygons.append_array(split_polygon_into_grid(polygon, Vector2(30, 15)))
	
	var final_final_polygons = []
	
	for polygon in final_polygons:
		polygon = polygon.simplify(2.0)
		final_final_polygons.append(polygon.shrink(1.0))
	
	for polygon in final_final_polygons:
		polygon_to_mesh(polygon)
	
	polygons = final_final_polygons
	polygons.append(original_polygon.shrink(-1.0))


func _process(delta):
	zoom += Input.get_axis("face_button_left", "face_button_bottom") * delta
	zoom = clamp(zoom, 0.1, 100.0)
	var input_vector = Input.get_vector("left_stick_left", "left_stick_right", "left_stick_up", "left_stick_down")
	offset -= input_vector * 5.0 / zoom
	queue_redraw()
	
	camera.global_position += Vector3(input_vector.x, Input.get_axis("face_button_left", "face_button_bottom"), input_vector.y)

func generate_city_outline(city_center : Vector2, min_sides : int, max_sides : int, radius : float) -> CustomPolygon2D:
	var polygon : CustomPolygon2D = CustomPolygon2D.new_regular_polygon(city_center, randi_range(min_sides, max_sides), radius)
	polygon.scale_from_point(polygon.get_mean_point(), Vector2(randf() + 1.0, randf() + 1.0))
	polygon.skew(32.0)
	return polygon

func find_split_line(polygon : CustomPolygon2D) -> FiniteLine2D:
	
	var line : FiniteLine2D
	var bounding_box_center = polygon.get_bounding_box_center()
	var bounding_half_width = abs(polygon.bounding_box.x - polygon.bounding_box.z) / 2.0
	var bounding_half_height = abs(polygon.bounding_box.y - polygon.bounding_box.w) / 2.0
	var max_radius = sqrt((bounding_half_width *  bounding_half_width) + (bounding_half_height * bounding_half_height))
	
	while true:
		var start_point : Vector2 = bounding_box_center + (Vector2.UP.rotated(randf() * 2.0 * PI) * max_radius)
		var end_point : Vector2 = bounding_box_center + (Vector2.UP.rotated(randf() * 2.0 * PI) * max_radius)
		line = FiniteLine2D.new(start_point, end_point)
		var intersections = polygon.is_line_intersecting(line)
			
		if intersections.size() == 2:
			break
				
	return line

func split_polygon_into_grid(polygon : CustomPolygon2D, grid_size : Vector2) -> Array:
	
	var longest_edge_index : int = polygon.get_longest_line_index()
	var angle = polygon.edges[longest_edge_index].angle()
	var bounding_box_center : Vector2 = polygon.get_bounding_box_center()
	var rotated_polygon : CustomPolygon2D = polygon.rotate_around_point(bounding_box_center, -angle)
	var rotated_bounding_box : Vector4 = rotated_polygon.bounding_box
	var final_polygons = [polygon]
	
	var blocks_y = ceil(abs(rotated_bounding_box.x - rotated_bounding_box.z) / grid_size.x)
		
	for i in range(1, blocks_y):
			
		var line = FiniteLine2D.new(
			Vector2(rotated_bounding_box.x + (i * grid_size.x), rotated_bounding_box.y - 100.0), 
			Vector2(rotated_bounding_box.x + (i * grid_size.x), rotated_bounding_box.w + 100.0), 
		).rotate_around(bounding_box_center, angle)
				

		var new_polygons = []
		for grid_polygon in final_polygons:
				
			var split_polygon : Array = grid_polygon.split(line)
			if split_polygon.size() != 2.0:
				split_polygon = [grid_polygon]
			else:
				var area1 = split_polygon[0].get_area()
				var area2 = split_polygon[1].get_area()
				if area1 < 100.0 or area2 < 100.0:
					split_polygon = [grid_polygon]
					
			new_polygons.append_array(split_polygon)
			
		final_polygons = new_polygons
		
	var blocks_x = ceil(abs(rotated_bounding_box.y - rotated_bounding_box.w) / grid_size.y)

	for i in range(1, blocks_x):
		var line = FiniteLine2D.new(
			Vector2(rotated_bounding_box.x - 100.0, rotated_bounding_box.y + (i * grid_size.y)), 
			Vector2(rotated_bounding_box.z + 100.0, rotated_bounding_box.y + (i * grid_size.y)), 
		).rotate_around(bounding_box_center, angle)
		
		var new_polygons = []
		
		for grid_polygon in final_polygons:
			
			var split_polygon : Array = grid_polygon.split(line)
			if split_polygon.size() != 2.0:
				split_polygon = [grid_polygon]
			else:
				var area1 = split_polygon[0].get_area()
				var area2 = split_polygon[1].get_area()
				if area1 < 100.0 or area2 < 100.0:
					split_polygon = [grid_polygon]
					
			new_polygons.append_array(split_polygon)
			
		final_polygons = new_polygons
				
	return final_polygons

func _draw():
	for polygon in polygons:
		for edge in polygon.edges:
			draw_line(edge.start + center, edge.end + center, Color.WHITE, -1.0, true)

func get_cross_product(a : Vector2, b: Vector2) -> float:
	return (a.x * b.y) - (a.y * b.x)

func is_ear(polygon : CustomPolygon2D, previous_index, current_index) -> bool:
	
	var cross_product : float = get_cross_product(
		polygon.edges[current_index].end - polygon.edges[current_index].start, 
		polygon.edges[previous_index].start - polygon.edges[previous_index].end
	)
	
	if cross_product < 0:
		return false
	
	for i in polygon.edges.size():
		if i == current_index or i == previous_index:
			if CustomPolygon2D.new([
				polygon.edges[previous_index],
				polygon.edges[current_index],
				FiniteLine2D.new(polygon.edges[current_index].end, polygon.edges[previous_index].start),
			]).is_point_inside(polygon.edges[i].start):
				return false
	
	return true

func triangluate_polygon(polygon : CustomPolygon2D, current_vertices : Array = []) -> Array:
	
	var edges = polygon.duplicate().edges
	
	if edges.size() > 3:
		for i in edges.size():
		
			var previous_index : int = i - 1
			
			if i == 0:
				previous_index = edges.size() - 1
			
			if is_ear(polygon, previous_index, i):
				current_vertices.append_array([
					Vector3(edges[previous_index].start.x, 0.0, edges[previous_index].start.y),
					Vector3(edges[i].start.x, 0.0, edges[i].start.y), 
					Vector3(edges[i].end.x, 0.0, edges[i].end.y)
				])
				var new_polygon : CustomPolygon2D = polygon.remove_ear(previous_index, i)
				return triangluate_polygon(new_polygon, current_vertices)
	else:
		for edge in edges:
			current_vertices.append(Vector3(edge.start.x, 0.0, edge.start.y))
			
	return current_vertices

func create_flat_surface_array(polygon : CustomPolygon2D, normal : Vector3) -> Array:
	
	var surface_array : Array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	vertices.append_array(triangluate_polygon(polygon))
	
	# generate uvs
	var uvs = PackedVector2Array()
	for vertex in vertices:
		uvs.append(Vector2(vertex.x, vertex.z))
	
	var normals = PackedVector3Array()
	for vertex in vertices:
		normals.append(normal)
		
	var indices = PackedInt32Array()
	for i in vertices.size():
		indices.append(i)
	
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	return surface_array

func polygon_to_mesh(polygon : CustomPolygon2D):
	
	var mesh : ArrayMesh = ArrayMesh.new()
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, create_flat_surface_array(polygon, Vector3.UP))
	
	var mesh_instance : MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	add_child(mesh_instance)

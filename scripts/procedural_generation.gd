extends Node

var original_polygon : CustomPolygon2D
var polygons : Array
var center : Vector2 = Vector2(1280.0, 720.0) / 2.0
var zoom : float = 1.0
var offset : Vector2 = Vector2.ZERO

var random_materials : Array = []

func generate_random_materials(amount : int) -> void:

	var material : StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color("#e4b58c")
	random_materials.append(material)
	
	material = StandardMaterial3D.new()
	material.albedo_color = Color("#928b80")
	random_materials.append(material)
	
	material = StandardMaterial3D.new()
	material.albedo_color = Color("#fef5ec")
	random_materials.append(material)
	
	material = StandardMaterial3D.new()
	material.albedo_color = Color("#8f786b")
	random_materials.append(material)
	
	material = StandardMaterial3D.new()
	material.albedo_color = Color("#542324")
	random_materials.append(material)
	
	#for i in amount:
		#var random_float = (randf() * 0.5) + 0.5
		#
		#var material : StandardMaterial3D = StandardMaterial3D.new()
		#material.albedo_color = Color(random_float, random_float, random_float)
		#random_materials.append(material)

func vector2_on_xy_to_vector3_xz(vector2 : Vector2, y : float):
	return Vector3(vector2.x, y, vector2.y)

func generate_prism_mesh_from_polygon(polygon : CustomPolygon2D, height : float) -> Array:
	
	var surface_array : Array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# generate ring
	for i in polygon.edges.size():
		vertices.append_array([
			vector2_on_xy_to_vector3_xz(polygon.edges[i].start, height),
			vector2_on_xy_to_vector3_xz(polygon.edges[i].end, height),
			vector2_on_xy_to_vector3_xz(polygon.edges[i].start, 0.0),
			vector2_on_xy_to_vector3_xz(polygon.edges[i].end, 0.0),
		])
		
		# todo: add uvs
		uvs.append_array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
		
		# todo: add normals
		var normal = Vector3.FORWARD.rotated(Vector3.UP, polygon.edges[i].get_angle())
		
		normals.append_array([normal, normal, normal, normal])
		
		var index = i * 4
		
		indices.append_array([
			index + 2, index + 1, index, 
			index + 2, index + 3, index + 1
		])
	
	var top_vertices = triangluate_polygon(polygon, height)
	vertices.append_array(top_vertices)

	for vertex in top_vertices:
		uvs.append(Vector2.ZERO)
	
	for vertex in top_vertices:
		normals.append(Vector3.UP)
	
	var indices_start = polygon.edges.size() * 4
	
	for i in top_vertices.size():
		indices.append(indices_start + i)
	
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	return surface_array

func _ready():
	
	generate_random_materials(20)
	
	original_polygon = generate_city_outline(Vector2.ZERO, 7, 17, 2000.0)
	polygons = [original_polygon]
	
	for i in 20:
		var line = find_split_line(original_polygon)
		var new_polygons = []
		for polygon in polygons:
			var split_polygon : Array = polygon.split(line)
			if split_polygon.size() == 2.0:
				var area1 = split_polygon[0].get_area()
				var area2 = split_polygon[1].get_area()
				if area1 < 10000.0 or area2 < 10000.0:
					split_polygon = [polygon]
					
			new_polygons.append_array(split_polygon)
			
		polygons = new_polygons
	
	var final_polygons = []
	
	for polygon in polygons:
		final_polygons.append_array(split_polygon_into_grid(polygon, Vector2(100, 200)))
	
	var final_final_polygons = []
	
	for polygon in final_polygons:
		polygon = polygon.simplify(20.0)
		final_final_polygons.append(polygon.shrink(10.0))

	
	for polygon in final_final_polygons:
		var x : float = pow(randf(), 10.0)
		polygon_to_mesh(polygon, (x * 450.0) + 15.0, random_materials.pick_random())
	
	polygons = final_final_polygons
	
	var material : StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color("#2b2d25")
	polygon_to_mesh(original_polygon.shrink(-5.0), 5.0, material)

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
	var angle = polygon.edges[longest_edge_index].get_angle()
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
				if area1 < 10000.0 or area2 < 10000.0:
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
				if area1 < 10000.0 or area2 < 10000.0:
					split_polygon = [grid_polygon]
					
			new_polygons.append_array(split_polygon)
			
		final_polygons = new_polygons
				
	return final_polygons

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

func triangluate_polygon(polygon : CustomPolygon2D, height : float, current_vertices : Array = []) -> Array:
	
	var edges = polygon.duplicate().edges
	
	if edges.size() > 3:
		for i in edges.size():
		
			var previous_index : int = i - 1
			
			if i == 0:
				previous_index = edges.size() - 1
			
			if is_ear(polygon, previous_index, i):
				current_vertices.append_array([
					Vector3(edges[previous_index].start.x, height, edges[previous_index].start.y),
					Vector3(edges[i].start.x, height, edges[i].start.y), 
					Vector3(edges[i].end.x, height, edges[i].end.y)
				])
				var new_polygon : CustomPolygon2D = polygon.remove_ear(previous_index, i)
				return triangluate_polygon(new_polygon, height, current_vertices)
	else:
		for edge in edges:
			current_vertices.append(Vector3(edge.start.x, height, edge.start.y))
			
	return current_vertices

func polygon_to_mesh(polygon : CustomPolygon2D, height : float, material : StandardMaterial3D):
	
	var mesh : ArrayMesh = ArrayMesh.new()
	
	var prism = generate_prism_mesh_from_polygon(polygon, height)
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, prism)
	
	var mesh_instance : MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	mesh_instance.set_surface_override_material(0, material)
	
	var static_body : StaticBody3D = StaticBody3D.new()
	
	
	var convex_polygon_shape : ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	convex_polygon_shape.points = prism[Mesh.ARRAY_VERTEX]
	
	var collision_shape : CollisionShape3D = CollisionShape3D.new()
	collision_shape.shape = convex_polygon_shape;
	
	static_body.add_child(collision_shape)
	static_body.add_child(mesh_instance)
	
	add_child(static_body)

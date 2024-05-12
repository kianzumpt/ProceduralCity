class_name FiniteLine2D

var start : Vector2 = Vector2.ZERO
var end : Vector2 = Vector2.ZERO

func _init(new_start : Vector2, new_end : Vector2):
	start = new_start
	end = new_end

# returns slope of the line. 0 is a flat horizontal line. 1 is a line at 45 degress. null is a vertical line
func get_slope() -> Variant:
	
	if start.x - end.x == 0.0:
		return null
	
	return (start.y - end.y) / (start.x - end.x)

# return the x coordinate where the line intersects the x-axis
func get_x_intercept() -> Variant:
	
	# get the slope of the line
	var slope = get_slope()
	
	# no x intercept if the line is parallel to the x-axis
	if slope == 0.0:
		return null
	
	# the intercept is at either x value as the line is vertical
	if slope == null:
		return start.x
	
	# otherwise solve y = mx + c where y = 0
	var c = start.y - (slope * start.x)
	var x = -c / slope
	
	return x
	
func get_finite_x_intercept(width : float) -> Variant:
	
	# get the x intercept given the lines are infinte
	var x = get_x_intercept()
	
	# no intersection if the horizontal line has no width
	if width == 0.0:
		return null
		
	# check if 0 if inbetween the y coordinates of the line (two checks to account for if the line runs top to bottom or bottom to top)
	var within_y_range : bool = (0.0 <= start.y and 0.0 >= end.y) or (0.0 >= start.y and 0.0 <= end.y)
	
	# if not with this range return null
	if not within_y_range:
		return null
	
	# check if the x intercept lies between 0 and the point (width, 0)
	var within_x_range : bool = x >= 0.0 and x <= width
	
	# if not with this range return null
	if not within_x_range:
		return null
	
	# otherwise return this as a valid intercept
	return x
	
func is_intersecting(other_line : FiniteLine2D) -> Variant:
	
	# calculate we each point would be if start was at the origin (0, 0)
	var relative_end = end - start
	var other_line_relative_start = other_line.start - start
	var other_line_relative_end = other_line.end - start
	
	# get the angle of this line
	var angle = relative_end.angle()
	
	# rotate the end point so that this line rests on the x-axis
	var rotated_end = relative_end.rotated(-angle)
	
	
	# rotate the other line the same way
	var other_line_rotated = FiniteLine2D.new(
		other_line_relative_start.rotated(-angle),
		other_line_relative_end.rotated(-angle)
	)
	
	# get the finite x intercept of the other line after the rotation, as the current line is not on the x-axis going from (0, 0) to (rotated_end.x, 0)
	var x = other_line_rotated.get_finite_x_intercept(rotated_end.x)
	
	# return null if there is not x intercept
	if x == null:
		return null
	
	# get the intersect point, reverse the rotation, and reverse the relative move by adding start back
	var intersection_point = start + Vector2(x, 0.0).rotated(angle)
	
	# return the interstion point
	return intersection_point
	
func get_center() -> Vector2:
	return (start + end) / 2.0

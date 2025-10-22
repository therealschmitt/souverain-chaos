extends Resource
class_name MapScale

## MapScale Resource
## Defines the scale and dimensions of the game world map.
## This allows for different map sizes while maintaining consistent coordinate systems.

## === MAP DIMENSIONS ===
## Physical dimensions of the map in pixels
@export var map_width_pixels: float = 2000.0
@export var map_height_pixels: float = 1200.0

## Real-world dimensions of the map in kilometers
@export var map_width_km: float = 20000.0
@export var map_height_km: float = 12000.0

## === CALCULATED SCALE (computed on load) ===
var km_per_pixel_x: float
var km_per_pixel_y: float
var pixels_per_km_x: float
var pixels_per_km_y: float

## Average scale (for isotropic calculations)
var km_per_pixel: float
var pixels_per_km: float

## === WORLD COORDINATE BOUNDS ===
## World coordinates use a Cartesian system with origin at top-left
## X: 0 to map_width_km (left to right)
## Y: 0 to map_height_km (top to bottom)
var world_min_x: float = 0.0
var world_max_x: float
var world_min_y: float = 0.0
var world_max_y: float

func _init() -> void:
	_calculate_scale()

func _calculate_scale() -> void:
	"""Calculates scale factors based on map dimensions."""
	# Pixel to km ratios
	km_per_pixel_x = map_width_km / map_width_pixels
	km_per_pixel_y = map_height_km / map_height_pixels

	# km to pixel ratios
	pixels_per_km_x = map_width_pixels / map_width_km
	pixels_per_km_y = map_height_pixels / map_height_km

	# Average scale (assumes roughly square pixels in world space)
	km_per_pixel = (km_per_pixel_x + km_per_pixel_y) / 2.0
	pixels_per_km = (pixels_per_km_x + pixels_per_km_y) / 2.0

	# World bounds
	world_max_x = map_width_km
	world_max_y = map_height_km

## === COORDINATE CONVERSION ===

func pixel_to_world(pixel_pos: Vector2) -> Vector2:
	"""Converts pixel coordinates to world coordinates (km)."""
	return Vector2(
		pixel_pos.x * km_per_pixel_x,
		pixel_pos.y * km_per_pixel_y
	)

func world_to_pixel(world_pos: Vector2) -> Vector2:
	"""Converts world coordinates (km) to pixel coordinates."""
	return Vector2(
		world_pos.x * pixels_per_km_x,
		world_pos.y * pixels_per_km_y
	)

func pixel_array_to_world(pixel_array: PackedVector2Array) -> PackedVector2Array:
	"""Converts array of pixel coordinates to world coordinates."""
	var world_array: PackedVector2Array = []
	for pixel in pixel_array:
		world_array.append(pixel_to_world(pixel))
	return world_array

func world_array_to_pixel(world_array: PackedVector2Array) -> PackedVector2Array:
	"""Converts array of world coordinates to pixel coordinates."""
	var pixel_array: PackedVector2Array = []
	for world_pos in world_array:
		pixel_array.append(world_to_pixel(world_pos))
	return pixel_array

## === DISTANCE CALCULATIONS ===

func calculate_distance_km(world_pos1: Vector2, world_pos2: Vector2) -> float:
	"""Calculates Euclidean distance between two world coordinates in km."""
	return world_pos1.distance_to(world_pos2)

func calculate_distance_km_from_pixels(pixel_pos1: Vector2, pixel_pos2: Vector2) -> float:
	"""Calculates distance in km from pixel coordinates."""
	var world1 = pixel_to_world(pixel_pos1)
	var world2 = pixel_to_world(pixel_pos2)
	return calculate_distance_km(world1, world2)

## === AREA CALCULATIONS ===

func calculate_polygon_area_km2(world_polygon: PackedVector2Array) -> float:
	"""
	Calculates area of a polygon in km² using the Shoelace formula.
	Expects polygon vertices in world coordinates (km).
	"""
	if world_polygon.size() < 3:
		return 0.0

	var area: float = 0.0
	var n = world_polygon.size()

	for i in range(n):
		var j = (i + 1) % n
		area += world_polygon[i].x * world_polygon[j].y
		area -= world_polygon[j].x * world_polygon[i].y

	return abs(area) / 2.0

func calculate_polygon_area_km2_from_pixels(pixel_polygon: PackedVector2Array) -> float:
	"""Calculates area in km² from a polygon in pixel coordinates."""
	var world_polygon = pixel_array_to_world(pixel_polygon)
	return calculate_polygon_area_km2(world_polygon)

## === VALIDATION ===

func is_valid_world_position(world_pos: Vector2) -> bool:
	"""Checks if world coordinates are within map bounds."""
	return (world_pos.x >= world_min_x and world_pos.x <= world_max_x and
			world_pos.y >= world_min_y and world_pos.y <= world_max_y)

func is_valid_pixel_position(pixel_pos: Vector2) -> bool:
	"""Checks if pixel coordinates are within map bounds."""
	return (pixel_pos.x >= 0 and pixel_pos.x <= map_width_pixels and
			pixel_pos.y >= 0 and pixel_pos.y <= map_height_pixels)

func clamp_world_position(world_pos: Vector2) -> Vector2:
	"""Clamps world coordinates to map bounds."""
	return Vector2(
		clamp(world_pos.x, world_min_x, world_max_x),
		clamp(world_pos.y, world_min_y, world_max_y)
	)

func clamp_pixel_position(pixel_pos: Vector2) -> Vector2:
	"""Clamps pixel coordinates to map bounds."""
	return Vector2(
		clamp(pixel_pos.x, 0, map_width_pixels),
		clamp(pixel_pos.y, 0, map_height_pixels)
	)

## === DEBUG ===

func get_info_string() -> String:
	"""Returns formatted string with map scale information."""
	return """MapScale Information:
	Pixel Dimensions: %.0fx%.0f px
	World Dimensions: %.0fx%.0f km
	Scale: %.2f km/px (X: %.2f, Y: %.2f)
	World Bounds: X[%.0f, %.0f], Y[%.0f, %.0f]""" % [
		map_width_pixels, map_height_pixels,
		map_width_km, map_height_km,
		km_per_pixel, km_per_pixel_x, km_per_pixel_y,
		world_min_x, world_max_x, world_min_y, world_max_y
	]

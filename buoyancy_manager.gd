# Adapted from https://github.com/Lucactus22/GodotOceanWaves_bouyancy/tree/main
extends Node

# Configuration
@export var displacement_updates_per_second := 10
@export var water = MeshInstance3D
var num_cascades: int = 3
var map_scales: Array = [Vector4(0.0078125,0.0078125, 1, 1), Vector4(0.0175, 0.0175, 0.1, 1), Vector4(0.063, 0.063, 0, 0.25)] 

var _accumulator = 0.0;
var _displacement_update_rate: float;
var _img: Image = null;
var _img_height: int;
var _img_width: int;

func _ready() -> void:
	_img = water.get_displacement_maps(0, _img)
	_img_height = _img.get_height()
	_img_width = _img.get_width()
	_displacement_update_rate = (1 / displacement_updates_per_second)
	
func _process(delta: float) -> void:
	# Resample
	_accumulator += delta;
	if _accumulator >= _displacement_update_rate:
		_accumulator -= _displacement_update_rate
		_img = water.get_displacement_maps(0, _img)

func get_wave_height(global_position: Vector3) -> float:
	var uv: Vector2 = Vector2(global_position.x, global_position.z)
	var displacement: Vector3 = Vector3.ZERO
	
	var i = 0;
	#for i in num_cascades:
	var scales: Vector4 = map_scales[i]
	var sample_uv: Vector2 = uv * Vector2(scales.x, scales.y)
	displacement += _sample_cached_displacement(i, sample_uv) * scales.z
	
	return displacement.y

func _sample_cached_displacement(cascade: int, uv: Vector2) -> Vector3:
	# Wrap UVs
	uv.x = wrapf(uv.x, 0.0, 1.0)
	uv.y = wrapf(uv.y, 0.0, 1.0)
	
	# Calculate coordinates
	var x: float = uv.x * (_img_width - 1)
	var y: float = uv.y * (_img_width - 1)
	
	var x0 := int(floor(x))
	var y0 := int(floor(y))
	var x1 = min(x0 + 1, _img_width - 1)
	var y1 = min(y0 + 1, _img_width - 1)
	
	var fx := x - x0
	var fy := y - y0
	
	# Get cached pixel data
	var c00: Color = _img.get_pixel(x0, y0) # _cached_displacements[y0 * img_width + x0]
	var c10: Color = _img.get_pixel(x1, y0) # _cached_displacements[y0 * img_width + x1]
	var c01: Color = _img.get_pixel(x0, y1) #_cached_displacements[y1 * img_width + x0]
	var c11: Color = _img.get_pixel(x1, y1) #_cached_displacements[y1 * img_width + x1]
	
	# Bilinear interpolation
	var col_x0 := c00.lerp(c10, fx)
	var col_x1 := c01.lerp(c11, fx)
	var col := col_x0.lerp(col_x1, fy)
	
	return Vector3(col.r, col.g, col.b)

extends CollisionShape3D

@export var water : Node
@export var parent : RigidBody3D
@export var cell_density_kg_per_m3: float = 500; # 500 is about right for solid wood, though 300-900 are acceptable ranges
@export var fluid_density_kg_per_m3: float = 1000; # Thanks, science
@export var calc_f_gravity: bool = false; # True if this should simulate gravity on this cell. 0 if gravity is calculated on the whole rigidbody

func _physics_process(delta: float) -> void:
	apply_force_on_cell()

# Divides the cell 1 time, into 8 cells.
# Then, simulates buoyant force acting on each cell. Returns an array where
# each 2 consecutive elements represent the center point of the subdivided cell
# and the vector of the force acting on it, respectively.
# 
# Eg. with only one cell [(-.5, 2, 0.3), (0, 10, 0)]: the first Vector3 is the
# global position of the point, and the second Vector3 is a +10N buoyant force
# acting in the global Y direction
#func force_on_octets(global_position: Vector3, size: Vector3, cell_density_kg_per_m3: float = 100) -> PackedVector3Array:
	#var elements = PackedVector3Array()
	#elements.resize(8 * 2) # Cells * 2 Vector3s per cell
	#for x in range(2):
		#for y in range(2):
			#for z in range(2):
				 ##Need to rotate size to match
				##var center = Vector3(global_position - x)
				##var offset = Vector3(x - 0.5, y - 0.5, z - 0.5) + (0.5 * size);
				##force_on_cell(global_position = global_position - : size / 2)
	#return elements

# This approach uses a box shape to model the main 'void' area of a ship or
# some subsection of it. It divides the box into octets and samples the depth
# at the center of the octets. It then approximates a buoyant force based on the
# volume enclosed by that octet.
# This is generally a 'good enough' approximation as you can add more boxes. To
# expand it, you could also define a weight for each box shape to simulate material
# (or flooding, if weight is assigned dynamically) and use this to apply gravity
# rather than the global gravity. Done this way, complex objects (eg. ships) will
# feel their weight correctly. Uneven weights will distribute correctly and you
# could even simulate sinking as some boxes gain weight equal to or greater than
# the volume of water they displace
func apply_force_on_cell() -> void:
	var size = shape.size;
	var volume: float = size.x * size.y * size.z
	var global_position = to_global(position)
	var depth: float = water.get_wave_height(global_position) - global_position.y
	
	# To tell how much of the box is submerged, we reimagine the volume as containing
	# to a cube, then assume that the depth of the center as a fraction of the
	# cube height is equivalent the fraction of the volume that is submerged.
	
	# TODO: account for effects of only being partially submerged
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity_vector") * ProjectSettings.get_setting("physics/3d/default_gravity")
	var cube_side_length = pow(volume, 1.0/3.0)
	var submerged_fraction = clampf((depth + 0.5 * cube_side_length) / cube_side_length, 0, 1)
	#print(submerged_fraction)
	
	var displaced_mass = fluid_density_kg_per_m3 * volume * submerged_fraction
	var f_buoyancy: Vector3 = displaced_mass * -gravity
	var f_gravity = Vector3.ZERO
	if calc_f_gravity:
		f_gravity = cell_density_kg_per_m3 * volume * gravity;
	print("------")
	print("Gravity: " + str(f_gravity))
	print("Buoyancy: " + str(f_buoyancy))
	print("Depth at center: " + str(depth))
	print("Submerged fraction: " + str(submerged_fraction))
	print("Position: " + str(position))
	
	parent.apply_force(f_buoyancy + f_gravity, position)
	
	
	#return f_gravity #+ f_buoyancy
	#var f_resistance: 
	#var point_velocity = linear_velocity + angular_velocity.cross(mesh_inst.to_local(point) - center_of_mass);
		
	#var f_drag = Vector3.ZERO
	#if depth < 0:
		#hydrodynamic_drag = - fluid_density_kg_per_m3 * point_velocity * point_velocity * point_velocity
	
	
	
	pass

extends MeshInstance3D

@export var water : Node
@export var parent : RigidBody3D

@export var active: bool = true; # If false, does nothing
@export var debug_log: bool = false; # True if this should simulate gravity on this cell. 0 if gravity is calculated on the whole rigidbody
@export var calc_f_gravity: bool = false; # True if this should simulate gravity on this cell. 0 if gravity is calculated on the whole rigidbody

@export var cell_density_kg_per_m3: float = 500; # 500 is about right for solid wood, though 300-900 are acceptable ranges
@export var engine_force: float = 0; # If not 0 provides thrust of the amount given at this cell in the local X direction

var fluid_density_kg_per_m3: float = 1000; # Thanks, science

#var indicator: MeshInstance3D;
#var indicator_mesh: BoxMesh;

func _physics_process(delta: float) -> void:
	if !active:
		return

	# TODO: Acting strangely
	apply_force_on_octets()
	#apply_force_on_cell(global_position, mesh.size)

	if engine_force > 0:
		apply_engine_force_on_cell()
	
func apply_engine_force_on_cell() -> void:
	parent.apply_force(to_global(Vector3(engine_force, 0, 0)), global_position - parent.global_position)


# Divides the cell 1 time, into 8 cells.
# Then, simulates buoyant force acting on each cell. Returns an array where
# each 2 consecutive elements represent the center point of the subdivided cell
# and the vector of the force acting on it, respectively.
# 
# Eg. with only one cell [(-.5, 2, 0.3), (0, 10, 0)]: the first Vector3 is the
# global position of the point, and the second Vector3 is a +10N buoyant force
# acting in the global Y direction
func apply_force_on_octets() -> void:
	#var elements = PackedVector3Array()
	#elements.resize(8 * 2) # Cells * 2 Vector3s per cell
	var size = mesh.size

	for x in range(2):
		for y in range(2):
			for z in range(2):
				# Will run once for each coord as -0.5 and once as 0.5
				var x_offset = (x - 0.5) * size.x
				var y_offset = (y - 0.5) * size.y
				var z_offset = (z - 0.5) * size.z
				var local_offset = Vector3(x_offset, y_offset, z_offset)
				var cell_global_center = to_global(local_offset)
				var cell_size = 0.5 * Vector3(size.x, size.y, size.z)
				
				apply_force_on_cell(cell_global_center, cell_size)

func volume(size: Vector3 = mesh.size) -> float:
	return size.x * size.y * size.z

func mass(volume: float = volume()) -> float:
	return cell_density_kg_per_m3 * volume

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
func apply_force_on_cell(global_center: Vector3, size: Vector3) -> void:
	var depth: float = water.get_wave_height(global_center) - global_center.y
	var volume = volume(size)
	var mass = mass(volume)
	
	var gravity = ( # Load gravity settings from file in case it's unusual
		ProjectSettings.get_setting("physics/3d/default_gravity_vector") *
		ProjectSettings.get_setting("physics/3d/default_gravity")
	)
	
	var submerged_fraction = clampf((depth + 0.5 * size.y) / size.y, 0, 1)
	var displaced_mass = fluid_density_kg_per_m3 * volume * submerged_fraction
	var f_buoyancy: Vector3 = displaced_mass * -gravity
	var f_gravity = Vector3.ZERO
	if calc_f_gravity:
		f_gravity = mass * gravity;
		
		
	var net_force = f_buoyancy + f_gravity
	# Global axis, 
	var force_location = global_center - parent.global_position
		
	if debug_log:
		print("------ Buoyancy Cell: " + name + " ------")
		print("Cell Height: " + str(size.y))
		print("Gravity: " + str(f_gravity))
		print("Buoyancy: " + str(f_buoyancy))
		print("Net Force: " + str(net_force))
		print("Global Net Force: " + str(to_global(net_force)))
		print("Depth at center: " + str(depth))
		print("Submerged fraction: " + str(submerged_fraction))
		print("Local Position: " + str(position))
		print("Global Cell Position: " + str(global_center))
		print("Parent Global Pos: " + str(parent.global_position))
		print("Vector to Force: " + str(force_location))
		print("Global Vector to Force: " + str(to_global(force_location)))
		
	# NOTES:
	# var global_velocity: Vector3
	# var local_velocity = global_basis.inverse() * global_velocity
	# var local_velocity: Vector3
	# var global_velocity = global_basis * local_velocity
	if active:
		# force is on the GLOBAL axis. Good for gravity & buoyancy, hard for engines
		# position IS on the GLOBAL axis from the center, but magnitudes are local distances
		# to the center of mass. Why? Who tf knows
		# Force should be framerate independent, but it doesn't appear to be
		parent.apply_force(net_force, force_location)
	
	
	#return f_gravity #+ f_buoyancy
	#var f_resistance: 
	#var point_velocity = linear_velocity + angular_velocity.cross(mesh_inst.to_local(point) - center_of_mass);
		
	#var f_drag = Vector3.ZERO
	#if depth < 0:
		#hydrodynamic_drag = - fluid_density_kg_per_m3 * point_velocity * point_velocity * point_velocity

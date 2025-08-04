extends MeshInstance3D

@export var water : Node
@export var parent : RigidBody3D
@export var cell_density_kg_per_m3: float = 500; # 500 is about right for solid wood, though 300-900 are acceptable ranges
@export var calc_f_gravity: bool = false; # True if this should simulate gravity on this cell. 0 if gravity is calculated on the whole rigidbody
@export var engine_force: float = 0; # If not 0 provides thrust of the amount given at this cell in the local X direction
@export var debug: bool = false; # True if this should simulate gravity on this cell. 0 if gravity is calculated on the whole rigidbody
@export var active: bool = true; # If false, does nothing

# TODO: Move to global config
const DEBUG_FORCE_SCALE: float = 0.000015;

var fluid_density_kg_per_m3: float = 1000; # Thanks, science

#var indicator: MeshInstance3D;
#var indicator_mesh: BoxMesh;

func _physics_process(delta: float) -> void:
	if !active:
		return

	apply_force_on_cell(delta)

	if engine_force > 0:
		apply_engine_force_on_cell(delta)
	
func apply_engine_force_on_cell(delta: float) -> void:
	#print("firing engine")
	var engine_force_vec = to_global( Vector3(-engine_force, 0, 0))
	parent.apply_force(engine_force_vec, parent.transform.basis * position)

	if debug:
		DebugDraw3D.draw_arrow(global_position, global_position+(engine_force_vec * DEBUG_FORCE_SCALE), Color(1, 0, 0))
	

# Divides the cell 1 time, into 8 cells.
# Then, simulates buoyant force acting on each cell. Returns an array where
# each 2 consecutive elements represent the center point of the subdivided cell
# and the vector of the force acting on it, respectively.
# 
# Eg. with only one cell [(-.5, 2, 0.3), (0, 10, 0)]: the first Vector3 is the
# global position of the point, and the second Vector3 is a +10N buoyant force
# acting in the global Y direction
func apply_force_on_octets(size: Vector3, cell_density_kg_per_m3: float = 100) -> void:
	var elements = PackedVector3Array()
	elements.resize(8 * 2) # Cells * 2 Vector3s per cell
	pass
	#for x in range(2):
		#for y in range(2):
			#for z in range(2):
				# Need to rotate size to match
				#var center = Vector3(global_position - x)
				#var offset = Vector3(x - 0.5, y - 0.5, z - 0.5) + (0.5 * size);
				#force_on_cell(global_position = global_position - : size / 2)
	
func mass() -> float:
	var size = mesh.size
	var volume: float = size.x * size.y * size.z
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
func apply_force_on_cell(delta: float) -> void:
	var size = mesh.size
	var volume: float = size.x * size.y * size.z
	var depth: float = water.get_wave_height(global_position) - global_position.y
	
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity_vector") * ProjectSettings.get_setting("physics/3d/default_gravity")
	#var cube_side_length = pow(volume, 1.0/3.0)
	#draw_gizmo(Vector3(cube_side_length, cube_side_length, cube_side_length))
	
	var submerged_fraction = clampf((depth + 0.5 * size.y) / size.y, 0, 1)
	#print(submerged_fraction)
	
	var displaced_mass = fluid_density_kg_per_m3 * volume * submerged_fraction
	var f_buoyancy: Vector3 = displaced_mass * -gravity
	var f_gravity = Vector3.ZERO
	if calc_f_gravity:
		f_gravity = mass() * gravity;
		
		
	var net_force = f_buoyancy + f_gravity
	
	# According to the docs "position is the offset from the body origin in global coordinates."
	# BUT what they mean is "positino is the RELATIVE OFFSET from the body origin in global coordinates.
	var force_location = parent.transform.basis * position;
	
	#if active && debug:
		#print("------ Buoyancy Cell: " + name + " ------")
		#print("Cell Height: " + str(size.y))
		#print("Gravity: " + str(f_gravity))
		#print("Buoyancy: " + str(f_buoyancy))
		#print("Net Force: " + str(net_force))
		#print("Global Net Force: " + str(to_global(net_force)))
		#print("Depth at center: " + str(depth))
		#print("Submerged fraction: " + str(submerged_fraction))
		#print("Local Position: " + str(position))
		#print("Global Position: " + str(global_position))
		#print("Parent Global Pos: " + str(parent.global_position))
		#print("Vector to Force: " + str(force_location))
		#print("Global Vector to Force: " + str(to_global(force_location)))
		#print("Mass: " + str(parent.mass))
		#print("Inertia: " + str(parent.inertia))
		
	# NOTES:
	# var global_velocity: Vector3
	# var local_velocity = global_basis.inverse() * global_velocity
	# var local_velocity: Vector3
	# var global_velocity = global_basis * local_velocity
	if active:
		# force is on the GLOBAL axis. Good for gravity & buoyancy, hard for engines
		# position IS on the GLOBAL axis from the center, but magnitudes are local distances
		# to the center of mass. Why? Who tf knows
	
		if debug:
			# The draw location in global coordinates, so we need to put it at the cell position
			var draw_location = global_position;
			DebugDraw3D.draw_arrow(draw_location, draw_location+(f_buoyancy * DEBUG_FORCE_SCALE), Color(0, 1, 1))
			DebugDraw3D.draw_arrow(draw_location, draw_location+(f_gravity * DEBUG_FORCE_SCALE), Color(1, 1, 0))
		parent.apply_force(net_force, force_location)
		#parent.apply_force(Vector3(0, -10000000, 0), Vector3(0, 0, -10))
	
	
	#return f_gravity #+ f_buoyancy
	#var f_resistance: 
	#var point_velocity = linear_velocity + angular_velocity.cross(mesh_inst.to_local(point) - center_of_mass);
		
	#var f_drag = Vector3.ZERO
	#if depth < 0:
		#hydrodynamic_drag = - fluid_density_kg_per_m3 * point_velocity * point_velocity * point_velocity
	
	
	
#func draw_gizmo(size: Vector3):
	#if indicator == null:
		#indicator = MeshInstance3D.new()
		#add_child(indicator)
		#indicator.name = "(EditorOnly) Visual indicator"
		#indicator_mesh = BoxMesh.new()
	#indicator_mesh.size = size
		

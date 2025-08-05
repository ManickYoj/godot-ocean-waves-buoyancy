extends RigidBody3D

@export var debug: bool = false
@export var buoyant_cells: Array[MeshInstance3D]
@export var drag_coef_axial: float = 0.15;
@export var drag_coef_lateral: float = 1;
@export var drag_coef_vertical: float = 1;
@export var drag_coef_yaw: float = 100;
@export var drag_coef_pitch: float = 100;
@export var drag_coef_roll: float = 100;
@export var mesh: MeshInstance3D;

# TODO: Move to global config
const DEBUG_FORCE_SCALE: float = 0.000015;

const WATER_MASS_DENSITY := 1000; # kg / m^3
const DRAG_SCALE: float = 1;

func _ready() -> void:
	var prospective_mass = 0 # Error if 0
	var bounds = Vector3.ZERO
	for cell in buoyant_cells:
		bounds = bounds.max(abs(cell.position) + abs(0.5 * cell.mesh.size))
		prospective_mass += cell.mass()

	mass = prospective_mass
	inertia = Vector3(pow(bounds.y * bounds.z * 0.15, 2), pow(bounds.x * bounds.z * 0.15, 2), pow(bounds.x * bounds.y * 0.15, 2)) * mass

	if debug:
		print("---- " + name + " -----")
		print("Calculated Bounds: " + str(bounds) + " Calculated Mass: "+ str(mass) + " Calculated Inertia: " + str(inertia))

func _physics_process(delta: float) -> void:
	apply_drag();

func apply_drag() -> void:
	# TODO: Different drag for parts in air vs water
	# TODO: Angular drag
	# TODO: velocity calc should be relative to the fluid, not relative to global velocity
	apply_drag_axial();
	apply_drag_lateral();
	apply_drag_vertical();
	
	apply_yaw_drag();
	apply_pitch_drag();
	apply_roll_drag();
	
func apply_yaw_drag() -> void:
	var length = mesh.mesh.size.x; # Looks like a mistake, but the long axis resisting yaw is the x, though the technically the y has some contribution
	var area = mesh.mesh.size.y * mesh.mesh.size.x;
	var local_angular_velocity = angular_velocity.dot(global_transform.basis.y)
	var torque_magnitude = calculate_drag_torque(area, length, local_angular_velocity, drag_coef_yaw)
	var torque = torque_magnitude * basis.y
	apply_torque(torque)
	
	if debug:
		var offset = Vector3(length / 4, 0 ,0)
		var force_vector = Vector3(0, 0, torque_magnitude)
		
		#print(offset)
		DebugDraw3D.draw_sphere(to_global(offset), 1, Color(0.4, 0.3, 0.7));
		DebugDraw3D.draw_sphere(to_global(-offset), 1, Color(0.4, 0.3, 0.7));
		DebugDraw3D.draw_arrow(to_global(offset), to_global(offset) + (to_global(-force_vector) * DEBUG_FORCE_SCALE), Color(.4, 0.3, 0.7));
		DebugDraw3D.draw_arrow(to_global(-offset), to_global(-offset) + (to_global(force_vector) * DEBUG_FORCE_SCALE), Color(0.4, 0.3, 0.7));

func apply_roll_drag() -> void:
	var length = mesh.mesh.size.z;
	var area = mesh.mesh.size.z * mesh.mesh.size.x;
	var local_angular_velocity = angular_velocity.dot(global_transform.basis.x)
	var torque_magnitude = calculate_drag_torque(area, length, local_angular_velocity, drag_coef_roll)
	var torque = torque_magnitude * basis.x
	apply_torque(torque)
	
	if debug:
		var offset = Vector3(0, 0, length / 4)
		var force_vector = Vector3(0, torque_magnitude, 0)
		
		#print(offset)
		DebugDraw3D.draw_sphere(to_global(offset), 1, Color(0.4, 0.3, 0.7));
		DebugDraw3D.draw_sphere(to_global(-offset), 1, Color(0.4, 0.3, 0.7));
		DebugDraw3D.draw_arrow(to_global(offset), to_global(offset) + (to_global(-force_vector) * DEBUG_FORCE_SCALE), Color(.4, 0.3, 0.7));
		DebugDraw3D.draw_arrow(to_global(-offset), to_global(-offset) + (to_global(force_vector) * DEBUG_FORCE_SCALE), Color(0.4, 0.3, 0.7));
	
func apply_pitch_drag() -> void:
	var length = mesh.mesh.size.x; # Looks like a mistake, but the long axis resisting pitch is the x, though the technically the y has some contribution
	var area = mesh.mesh.size.x * mesh.mesh.size.z;
	var local_angular_velocity = angular_velocity.dot(global_transform.basis.z)
	var torque_magnitude = calculate_drag_torque(area, length, local_angular_velocity, drag_coef_pitch)
	var torque = torque_magnitude * basis.z
	apply_torque(torque)
	
	if debug:
		var offset = Vector3(length / 4, 0 ,0)
		var force_vector = Vector3(0, torque_magnitude, 0)
		
		#print(offset)
		DebugDraw3D.draw_sphere(to_global(offset), 1, Color(0.4, 0.3, 0.7));
		DebugDraw3D.draw_sphere(to_global(-offset), 1, Color(0.4, 0.3, 0.7));
		DebugDraw3D.draw_arrow(to_global(offset), to_global(offset) + (to_global(force_vector) * DEBUG_FORCE_SCALE), Color(.4, 0.3, 0.7));
		DebugDraw3D.draw_arrow(to_global(-offset), to_global(-offset) + (to_global(-force_vector) * DEBUG_FORCE_SCALE), Color(0.4, 0.3, 0.7));

func apply_drag_axial() -> void:
	var area = mesh.mesh.size.y * mesh.mesh.size.z;
	var local_velocity = linear_velocity.dot(global_transform.basis.x)
	var axial_drag = calculate_drag(area, local_velocity, drag_coef_axial)  * basis.x * DRAG_SCALE;
	apply_central_force(axial_drag);
	
	if debug:
		DebugDraw3D.draw_arrow(global_position, global_position+(axial_drag * DEBUG_FORCE_SCALE), Color(0, 1, 0));
	
func apply_drag_lateral() -> void:
	var area = mesh.mesh.size.y * mesh.mesh.size.x;
	#var local_velocity = basis.inverse() * linear_velocity
	var local_velocity = linear_velocity.dot(global_transform.basis.z)
	var lateral_drag = calculate_drag(area, local_velocity, drag_coef_lateral) * basis.z * DRAG_SCALE;
	apply_central_force(lateral_drag);

	if debug:
		DebugDraw3D.draw_arrow(global_position, global_position+(lateral_drag * DEBUG_FORCE_SCALE), Color(0, 1, 0));
	
func apply_drag_vertical() -> void:
	var area = mesh.mesh.size.x * mesh.mesh.size.z;
	var local_velocity = linear_velocity.dot(global_transform.basis.y)
	var vertical_drag = calculate_drag(area, local_velocity, drag_coef_vertical) * basis.y * DRAG_SCALE;
	apply_central_force(vertical_drag);

	if debug:
		DebugDraw3D.draw_arrow(global_position, global_position+(vertical_drag * DEBUG_FORCE_SCALE), Color(0, 1, 0));

func calculate_drag_torque(area, length, angular_velocity, drag_coef) -> float:
	# .25 because average moment arm is half the length of the half of the ship
	var torque_magnitude = (0.5 * WATER_MASS_DENSITY * angular_velocity * angular_velocity * area * drag_coef * length * 0.25)
	if angular_velocity > 0:
		return - torque_magnitude
	else:
		return torque_magnitude

func calculate_drag(area, velocity, drag_coef) -> float:
	var drag_magnitude = (0.5 * WATER_MASS_DENSITY * velocity * velocity * area * drag_coef)
	if velocity > 0:
		return - drag_magnitude
	else:
		return drag_magnitude
	
	

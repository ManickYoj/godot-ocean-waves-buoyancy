extends RigidBody3D

@export var debug: bool = false
@export var buoyant_cells: Array[MeshInstance3D]
@export var drag_coef_axial: float = 0.15;
@export var drag_coef_lateral: float = 1;
@export var drag_coef_vertical: float = 0.8;
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

func apply_drag_axial() -> void:
	var area = mesh.mesh.size.y * mesh.mesh.size.z;
	var local_velocity = global_transform.basis.inverse() * linear_velocity
	var axial_drag = calculate_drag(area, local_velocity.x, drag_coef_axial)  * global_transform.basis.x * DRAG_SCALE;
	apply_central_force(axial_drag);
	
	if debug:
		DebugDraw3D.draw_arrow(global_position, global_position+(axial_drag * DEBUG_FORCE_SCALE), Color(0, 1, 0));
	
func apply_drag_lateral() -> void:
	var area = mesh.mesh.size.y * mesh.mesh.size.x;
	var local_velocity = global_transform.basis.inverse() * linear_velocity
	var lateral_drag = calculate_drag(area, local_velocity.z, drag_coef_lateral) * global_transform.basis.z * DRAG_SCALE;
	apply_central_force(lateral_drag);

	if debug:
		DebugDraw3D.draw_arrow(global_position, global_position+(lateral_drag * DEBUG_FORCE_SCALE), Color(0, 1, 0));
	
func apply_drag_vertical() -> void:
	var area = mesh.mesh.size.x * mesh.mesh.size.z;
	var local_velocity = global_transform.basis.inverse() * linear_velocity
	var vertical_drag = calculate_drag(area, local_velocity.y, drag_coef_vertical) * global_transform.basis.y * DRAG_SCALE;
	apply_central_force(vertical_drag);

	if debug:
		DebugDraw3D.draw_arrow(global_position, global_position+(vertical_drag * DEBUG_FORCE_SCALE), Color(0, 1, 0));
	
func calculate_drag(area, velocity, drag_coef) -> float:
	return -0.5 * WATER_MASS_DENSITY * velocity * area * drag_coef;
	

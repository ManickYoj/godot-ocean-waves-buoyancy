extends RigidBody3D

@export var debug: bool = false
@export var buoyant_cells: Array[MeshInstance3D]

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

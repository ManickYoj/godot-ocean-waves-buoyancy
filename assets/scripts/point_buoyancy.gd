extends RigidBody3D

@export var water : Node
@export var buoyancy_spring: float = 500  # Reduced spring force for stability
@export var buoyancy_damping: float = 100  # Increased damping to reduce oscillation
@export var buoyancy_max_force: float = 500  # Max limit to prevent excessive force
#@export var buoyancy_marker: Array[Marker3D]
#@export var collider: CollisionShape3D
@export var mesh_inst: MeshInstance3D
#@export var density: float = 1
#@export var cells: Array[CollisionShape3D]

#func _physics_process(delta: float) -> void:
	#float_by_mesh_verts(delta) # Used temporarily to apply hydro drag
	#for cell in cells:
		#print(cell.position)
		#apply_force(cell.position, cell.force_on_cell())
		
	
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
func float_by_box_cells(delta: float, center: Vector3, size: Vector3, cell_weight: float = 0) -> void:
	var volume = size.x * size.y * size.z
	
	pass

# Measures the depth of each unique vert in mesh. If a vert is below water,
# applies a buoyant force proportional to the depth and a drag force proportional
# to the velocity at that vert. The overall force felt is normalized by the number
# of verts, so more verts don't make an object more buoyent, they just sample depth
# at more points. The overall 'spring force' paramter would be felt only if every
# vert is submerged:
# This is a very limited approach. It does not account for volume at all, so the
# spring force felt by the object must be precisely tuned to its mass and volume
# to feel like it floats correctly.
# This was my first approach to buoyancy and it's pretty limited. Would not
# recommend
func float_by_mesh_verts(delta: float) -> void:
	var faces = mesh_inst.get_mesh().get_faces()
	#var size = mesh_inst.mesh.get_size()
	var points_dict = {} # Used as a set for deduplication
	# Note that a face is a Vector3 object rather than a list of Vector3s as
	# the docs seem to indicate
	for face in faces:
		var vert_0 = mesh_inst.to_global(face)
		points_dict[vert_0] = null
		
	for point in points_dict.keys():
		# Calculate the depth at the vertex. But don't apply buoyancy if above the water
		var depth = clampf(point.y - water.get_wave_height(point), -1000000, 0)
		
		# Calculate spring force (proportional to depth)
		# Depth is negative.
		# Buoyancy is only linearly proportional to depth, but for each unit one
		# corner sinks, it's submerging 
		var spring_force = Vector3(0, buoyancy_spring * - depth, 0)
		
		# Calculate damping force (proportional to vertical velocity) to account for having
		# to push water out of the way or pull it in
		# Not sure that this is correct
		# should damp all velocity AT POINT (ie. angular * moment arm = velocity at point)
		var point_velocity = linear_velocity + angular_velocity.cross(mesh_inst.to_local(point) - center_of_mass);
		
		var hydrodynamic_drag = Vector3.ZERO
		if depth < 0:
			hydrodynamic_drag = - buoyancy_damping * point_velocity * point_velocity * point_velocity
		#print("point " + str(point) + ", depth: " + str(depth))
		#print("drag " + str(hydrodynamic_drag))
		#print("spring" + str(spring_force))
		#print("point" + str(point))		
		
		# Combine forces and clamp to avoid excessive force
		var raw_force = (spring_force + hydrodynamic_drag) / points_dict.size()
		var scaled_force = raw_force * delta
		 
		# The Godot docs for the position are incorrect: the point should be in 
		# local coordinates to the body
		apply_impulse(scaled_force, mesh_inst.to_local(point))
		

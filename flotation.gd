extends RigidBody3D

@export var buoyancy_manager : Node
@export var buoyancy_spring: float = 500  # Reduced spring force for stability
@export var buoyancy_damping: float = 100  # Increased damping to reduce oscillation
@export var buoyancy_max_force: float = 500  # Max limit to prevent excessive force
#@export var buoyancy_marker: Array[Marker3D]
#@export var collider: CollisionShape3D
@export var mesh_inst: MeshInstance3D
#@export var density: float = 1

func _physics_process(delta: float) -> void:
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
		var depth = clampf(point.y - buoyancy_manager.get_wave_height(point), -1000000, 0)
		
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
		

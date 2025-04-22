extends MeshInstance3D

@export var target: Node3D;

func _process(delta):
	mesh.material.set_shader_parameter(&"focal_point", target.global_position)

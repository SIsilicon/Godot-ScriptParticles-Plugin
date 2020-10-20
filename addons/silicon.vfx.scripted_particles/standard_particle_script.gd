tool
class_name StandardParticleScript, "particle_script.svg"
extends ParticleScript

enum {
	EMISSION_SHAPE_POINT,
	EMISSION_SHAPE_SPHERE,
	EMISSION_SHAPE_BOX,
	EMISSION_SHAPE_POINTS,
	EMISSION_SHAPE_DIRECTED_POINTS
}

var emission_shape := 0
var emission_sphere_radius := 1.0
var emission_box_extents := Vector3.ONE
var emission_points := PoolVector3Array()
var emission_normals := PoolVector3Array()
var emission_colors := PoolColorArray()

var flag_align_y := false
var flag_rotate_y := false
var flag_disable_z := false

var direction := Vector3(0, 0, 1)
var spread := 0.0
var flatness := 0.0

var gravity := Vector3(0, -9.8, 0)

var initial_velocity := 0.0
var initial_velocity_random := 0.0

var angular_velocity := 0.0
var angular_velocity_random := 0.0
var angular_velocity_curve: Curve

var orbit_velocity := 0.0
var orbit_velocity_random := 0.0

var linear_accel := 0.0
var linear_accel_random := 0.0
var linear_accel_curve: Curve

var radial_accel := 0.0
var radial_accel_random := 0.0
var radial_accel_curve: Curve

var tangential_accel := 0.0
var tangential_accel_random := 0.0
var tangential_accel_curve: Curve

var damping := 0.0
var damping_random := 0.0
var damping_curve: Curve

var angle := 0.0
var angle_random := 0.0
var angle_curve: Curve

var scale := 1.0
var scale_random := 0.0
var scale_curve: Curve

var color := Color.white
var color_ramp: Gradient

var hue_variation := 0.0
var hue_variation_random := 0.0
var hue_variation_curve: Curve

var anim_speed := 1.0
var anim_speed_random := 0.0
var anim_speed_curve: Curve
var anim_offset := 0.0
var anim_offset_random := 0.0
var anim_offset_curve: Curve

var collision_bounce := 0.5
var collision_friction := 0.0


func _get_property_list() -> Array:
	var properties := [
		{name="StandardParticleScript", type=TYPE_NIL, usage=PROPERTY_USAGE_CATEGORY},
		
		{name="Emission Shape", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP, hint_string="emission_"},
		{name="emission_shape", type=TYPE_INT, hint=PROPERTY_HINT_ENUM, hint_string="Point,Sphere,Box,Points,Directed Points"},
		{name="emission_sphere_radius", type=TYPE_REAL, hint=PROPERTY_HINT_EXP_RANGE, hint_string="0.01,128,0.01,or_greater"},
		{name="emission_box_extents", type=TYPE_VECTOR3},
		{name="emission_points", type=TYPE_VECTOR3_ARRAY},
		{name="emission_normals", type=TYPE_VECTOR3_ARRAY},
		{name="emission_colors", type=TYPE_COLOR_ARRAY},

		{name="Flags", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP, hint_string="flag_"},
		{name="flag_align_y", type=TYPE_BOOL},
		{name="flag_rotate_y", type=TYPE_BOOL},
		{name="flag_disable_z", type=TYPE_BOOL},
		
		{name="Direction", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP},
		{name="direction", type=TYPE_VECTOR3},
		{name="spread", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,180,0.01"},
		{name="flatness", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		
		{name="Gravity", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP},
		{name="gravity", type=TYPE_VECTOR3},
		
		{name="Initial Velocity", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP, hint_string="initial_"},
		{name="initial_velocity", type=TYPE_REAL, hint=PROPERTY_HINT_EXP_RANGE, hint_string="0,1000,0.01,or_greater"},
		{name="initial_velocity_random", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		
		{name="Angular Velocity", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP, hint_string="angular_"},
		{name="angular_velocity", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="-720,720,0.01,or_lesser,or_greater"},
		{name="angular_velocity_random", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="angular_velocity_curve", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Curve"},
		
		{name="Orbit Velocity", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP, hint_string="orbit_"},
		{name="orbit_velocity", type=TYPE_REAL, hint=PROPERTY_HINT_EXP_RANGE, hint_string="-1000,1000,0.01,or_lesser,or_greater"},
		{name="orbit_velocity_random", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		
		{name="Linear Accel", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP, hint_string="linear_"},
		{name="linear_accel", type=TYPE_REAL, hint=PROPERTY_HINT_EXP_RANGE, hint_string="-100,100,0.01,or_lesser,or_greater"},
		{name="linear_accel_random", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="linear_accel_curve", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Curve"},
		
		{name="Radial Accel", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP, hint_string="radial_"},
		{name="radial_accel", type=TYPE_REAL, hint=PROPERTY_HINT_EXP_RANGE, hint_string="-100,100,0.01,or_lesser,or_greater"},
		{name="radial_accel_random", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="radial_accel_curve", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Curve"},
		
		{name="Tangential Accel", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP, hint_string="tangential_"},
		{name="tangential_accel", type=TYPE_REAL, hint=PROPERTY_HINT_EXP_RANGE, hint_string="-100,100,0.01,or_lesser,or_greater"},
		{name="tangential_accel_random", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="tangential_accel_curve", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Curve"},
		
		{name="Damping", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP},
		{name="damping", type=TYPE_REAL, hint=PROPERTY_HINT_EXP_RANGE, hint_string="0,100,0.01,or_greater"},
		{name="damping_random", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="damping_curve", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Curve"},
		
		{name="Angle", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP},
		{name="angle", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="-720,720,0.01,or_lesser,or_greater"},
		{name="angle_random", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="angle_curve", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Curve"},
		
		{name="Scale", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP},
		{name="scale", type=TYPE_REAL, hint=PROPERTY_HINT_EXP_RANGE, hint_string="0,1000,0.01,or_greater"},
		{name="scale_random", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="scale_curve", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Curve"},
		
		{name="Color", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP},
		{name="color", type=TYPE_COLOR},
		{name="color_ramp", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Gradient"},
		
		{name="Hue Variation", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP, hint_string="hue_"},
		{name="hue_variation", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="-1,1,0.01,or_lesser,or_greater"},
		{name="hue_variation_random", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="hue_variation_curve", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Curve"},

		{name="Animation", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP, hint_string="anim_"},
		{name="anim_speed", type=TYPE_REAL, hint=PROPERTY_HINT_EXP_RANGE, hint_string="0,128,0.01,or_greater"},
		{name="anim_speed_random", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="anim_speed_curve", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Curve"},
		{name="anim_offset", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="anim_offset_random", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="anim_offset_curve", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Curve"},
		
		{name="Collision", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP, hint_string="collision_"},
		{name="collision_bounce", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="collision_friction", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
	]
	return properties


func get_curve(curve: Curve, pos: float, default := 0.0) -> float:
	return default if not curve else curve.interpolate_baked(pos)


func vec3_to_2d(vector: Vector3, is_2d: bool):
	return Vector2(vector.x, vector.y) if is_2d else vector


func _particle_birth(particle: Particle) -> void:
	var is_2d := particle is Particle2D

	var angle1_rad := atan2(direction.x, direction.z) + (randf() * 2.0 - 1.0) * PI * spread / 180.0
	var angle2_rad := atan2(direction.y, abs(direction.z)) + (randf() * 2.0 - 1.0) * (1.0 - flatness) * PI * spread / 180.0
	
	var direction_xz := Vector3(sin(angle1_rad), 0, cos(angle1_rad))
	var direction_yz := Vector3(0, sin(angle2_rad), cos(angle2_rad))
	direction_yz.z = direction_yz.z / max(0.0001, sqrt(abs(direction_yz.z)))
	var p_direction := Vector3(direction_xz.x * direction_yz.z, direction_yz.y, direction_xz.z * direction_yz.z)
	p_direction = p_direction.normalized()
	particle.velocity = vec3_to_2d(p_direction * initial_velocity * lerp(1.0, float(randf()), initial_velocity_random), is_2d)
	
	particle.custom["base_color"] = Color.white
	particle.custom["rand_angle"] = randf()
	particle.custom["rand_anim_offset"] = randf()
	particle.custom["rand_hue_rot"] = randf()
	particle.custom["rand_scale"] = randf()
	
	var tex_angle := get_curve(angle_curve, 0.0, 0.0)
	var tex_anim_offset := get_curve(anim_offset_curve, 0.0, 0.0)
	particle.custom[0] = deg2rad((angle + tex_angle) * lerp(1.0, particle.custom["rand_angle"], angle_random))
	particle.custom[2] = deg2rad((anim_offset + tex_anim_offset) * lerp(1.0, particle.custom["rand_anim_offset"], anim_offset_random))
	
	match emission_shape:
		EMISSION_SHAPE_POINT:
			pass
		EMISSION_SHAPE_SPHERE:
			var s := 2.0 * randf() - 1.0
			var t := 2.0 * PI * randf()
			var radius := emission_sphere_radius * sqrt(1.0 - s * s)
			particle.transform.origin = vec3_to_2d(Vector3(radius * cos(t), radius * sin(t), emission_sphere_radius * s), is_2d)
		EMISSION_SHAPE_BOX:
			particle.transform.origin = vec3_to_2d(Vector3(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0, randf() * 2.0 - 1.0) * emission_box_extents, is_2d)
		EMISSION_SHAPE_POINTS:
			continue
		EMISSION_SHAPE_DIRECTED_POINTS:
			var pc := emission_points.size()
			if pc == 0:
				continue
			var random_idx := randi() % pc
			particle.transform.origin = emission_points[random_idx]
			
			if emission_shape == EMISSION_SHAPE_DIRECTED_POINTS && emission_normals.size() == pc:
				if flag_disable_z or is_2d:
					var normal := emission_normals[random_idx]
					var normal_2d := Vector2(normal.x, normal.y)
					var m2 := Transform2D()
					m2[0] = normal_2d
					m2[1] = normal_2d.tangent()
					var velocity_2d := Vector2(particle.velocity.x, particle.velocity.y)
					velocity_2d = m2.basis_xform(velocity_2d)
					particle.velocity.x = velocity_2d.x
					particle.velocity.y = velocity_2d.y
				else:
					var normal := emission_normals[random_idx]
					var v0 := Vector3(0.0, 0.0, 1.0) if abs(normal.z) < 0.999 else Vector3(0, 1.0, 0.0)
					var tangent := v0.cross(normal).normalized()
					var bitangent := tangent.cross(normal).normalized()
					var m3 := Basis(tangent, bitangent, normal)
					particle.velocity = m3.xform(particle.velocity)
				
			if emission_colors.size() == pc:
				particle.base_color = emission_colors[random_idx]
	
	var p_scale := get_curve(scale_curve, particle.custom[1], 1.0)
	p_scale *= lerp(scale, 1.0, particle.custom["rand_scale"] * scale_random)
	p_scale = max(p_scale, 0.001)
	if is_2d:
		particle.transform = particle.transform.scaled(Vector2.ONE * p_scale / particle.transform.get_scale())
	else:
		particle.transform.basis = particle.transform.basis.scaled(Vector3.ONE * p_scale / particle.transform.basis.get_scale())

	if flag_disable_z and not is_2d:
		particle.velocity.z = 0.0
		particle.transform.origin.z = 0.0


func _particle_update(particle: Particle, delta: float) -> void:
	var is_2d := particle is Particle2D
	
	var position = particle.transform.origin
	if flag_disable_z and not is_2d:
		position.z = 0.0
	
	var force := gravity
	var org = particle.emitter.transform.origin
	var diff = position - org
	
	# Linear Acceleration
	var tex_linear_accel := get_curve(linear_accel_curve, particle.custom[1], 0.0)
	force += particle.velocity.normalized() * (linear_accel + tex_linear_accel) * lerp(1.0, randf(), linear_accel_random) if particle.velocity.length() > 0.0 else Vector3()
	
	# Radial Acceleraion
	var tex_radial_accel := get_curve(radial_accel_curve, particle.custom[1], 0.0)
	force += diff.normalized() * (radial_accel + tex_radial_accel) * lerp(1.0, randf(), radial_accel_random) if diff.length() > 0.0 else Vector3()
	
	# Tangential Acceleration
	var tex_tangential_accel := get_curve(tangential_accel_curve, particle.custom[1], 0.0)
	if flag_disable_z or is_2d:
		var yx := Vector2(diff.y, diff.x)
		var yx2 := (yx * Vector2(-1.0, 1.0)).normalized()
		force += Vector3(yx2.x, yx2.y, 0.0) * (tangential_accel + tex_tangential_accel) * lerp(1.0, randf(), tangential_accel_random) if yx.length() > 0.0 else Vector3()
	else:
		var crossDiff = diff.normalized().cross(gravity.normalized())
		force += crossDiff.normalized() * ((tangential_accel + tex_tangential_accel) * lerp(1.0, randf(), tangential_accel_random)) if crossDiff.length() > 0.0 else Vector3()
	
	particle.velocity += vec3_to_2d(force * delta, is_2d)
	
	# Damping
	var v: float = particle.velocity.length()
	var tex_damping := get_curve(damping_curve, particle.custom[1], 0.0)
	if tex_damping + damping > 0.0:
		var damp: float = (damping + tex_damping) * lerp(1.0, randf(), damping_random)
		v -= damp * delta
		if v < 0.0:
			particle.velocity = vec3_to_2d(Vector3(), is_2d)
		else:
			particle.velocity = vec3_to_2d(particle.velocity.normalized() * v, is_2d)
	
	# Orbit Velocity
	if flag_disable_z or is_2d:
		var orbit_amount: float = orbit_velocity * lerp(1.0, randf(), orbit_velocity_random)
		if orbit_amount != 0.0:
			var ang := orbit_amount * delta * PI * 2.0
			var rot := Transform2D(-ang, Vector2())
			var rotv := rot.basis_xform(Vector2(diff.x, diff.y))
			particle.transform.origin -= vec3_to_2d(Vector3(diff.x, diff.y, 0), is_2d)
			particle.transform.origin += vec3_to_2d(Vector3(rotv.x, rotv.y, 0), is_2d)
	
	# Angular Velocity and Animation
	var tex_angle := get_curve(angle_curve, particle.custom[1], 0.0)
	var tex_angular_velocity := get_curve(angular_velocity_curve, particle.custom[1], 0.0)
	var tex_anim_offset := get_curve(anim_offset_curve, particle.custom[1], 0.0)
	var tex_anim_speed := get_curve(anim_speed_curve, particle.custom[1], 0.0)
	var base_angle: float = (angle + tex_angle) * lerp(1.0, particle.custom["rand_angle"], angle_random)
	base_angle += particle.custom[1] * particle.emitter.lifetime * (angular_velocity + tex_angular_velocity) * lerp(1.0, randf() * 2.0 - 1.0, angular_velocity_random)
	particle.custom[0] = deg2rad(base_angle)
	particle.custom[2] = (anim_offset + tex_anim_offset) * lerp(1.0, particle.custom["rand_anim_offset"], anim_offset_random) + particle.custom[1] * (anim_speed + tex_anim_speed) * lerp(1.0, randf(), anim_speed_random)
	
	# Hue and Color
	var tex_hue_variation := get_curve(hue_variation_curve, particle.custom[1], 0.0)
	var hue_rot_angle: float = (hue_variation + tex_hue_variation) * PI * 2.0 * lerp(1.0, particle.custom["rand_hue_rot"] * 2.0 - 1.0, hue_variation_random)
	var hue_rot_c := cos(hue_rot_angle)
	var hue_rot_s := sin(hue_rot_angle)

	var hue_rot_mat := Basis()
	var mat1 := Basis(Vector3(0.299, 0.587, 0.114), Vector3(0.299, 0.587, 0.114), Vector3(0.299, 0.587, 0.114))
	var mat2 := Basis(Vector3(0.701, -0.587, -0.114), Vector3(-0.299, 0.413, -0.114), Vector3(-0.300, -0.588, 0.886))
	var mat3 := Basis(Vector3(0.168, 0.330, -0.497), Vector3(-0.328, 0.035, 0.292), Vector3(1.250, -1.050, -0.203))
	for j in 3:
		hue_rot_mat[j] = mat1[j] + mat2[j] * hue_rot_c + mat3[j] * hue_rot_s
	
	particle.color = color if not color_ramp else color_ramp.interpolate(particle.custom[1]) * color
	
	var color_rgb := hue_rot_mat.xform_inv(Vector3(particle.color.r, particle.color.g, particle.color.b))
	particle.color.r = color_rgb.x
	particle.color.g = color_rgb.y
	particle.color.b = color_rgb.z

	particle.color *= particle.custom["base_color"]

	if flag_disable_z or is_2d:
		if is_2d:
			if flag_align_y:
				if particle.velocity.length() > 0.0:
					particle.transform[1] = particle.velocity.normalized()
				else:
					particle.transform[1] = particle.transform[1]
				particle.transform[0] = particle.transform[1].tangent()
			else:
				particle.transform[0] = Vector3(cos(particle.custom[0]), -sin(particle.custom[0]), 0.0)
				particle.transform[1] = Vector3(sin(particle.custom[0]), cos(particle.custom[0]), 0.0)
		else:
			if flag_align_y:
				if particle.velocity.length() > 0.0:
					particle.transform.basis[1] = particle.velocity.normalized()
				else:
					particle.transform.basis[1] = particle.transform.basis[1]
				particle.transform.basis[0] = particle.transform.basis[1].cross(particle.transform.basis[2]).normalized()
				particle.transform.basis[2] = Vector3(0, 0, 1)
			else:
				particle.transform.basis[0] = Vector3(cos(particle.custom[0]), -sin(particle.custom[0]), 0.0)
				particle.transform.basis[1] = Vector3(sin(particle.custom[0]), cos(particle.custom[0]), 0.0)
				particle.transform.basis[2] = Vector3(0, 0, 1)
	else:
		# orient particle Y towards velocity
		if flag_align_y:
			if particle.velocity.length() > 0.0:
				particle.transform.basis[1] = particle.velocity.normalized()
			else:
				particle.transform.basis[1] = particle.transform.basis[1].normalized()
			if particle.transform.basis[1] == particle.transform.basis[0]:
				particle.transform.basis[0] = particle.transform.basis[1].cross(particle.transform.basis[2]).normalized()
				particle.transform.basis[2] = particle.transform.basis[0].cross(particle.transform.basis[1]).normalized()
			else:
				particle.transform.basis[2] = particle.transform.basis[0].cross(particle.transform.basis[1]).normalized()
				particle.transform.basis[0] = particle.transform.basis[1].cross(particle.transform.basis[2]).normalized()
		else:
			particle.transform.basis = particle.transform.basis.orthonormalized()

		# turn particle by rotation in Y
		if flag_rotate_y:
			var rot_y := Basis().rotated(Vector3(0, 1, 0), particle.custom[0])
			particle.transform.basis = particle.transform.basis * rot_y
	
	# Scale
	var p_scale := get_curve(scale_curve, particle.custom[1], 1.0)
	p_scale *= lerp(scale, 1.0, particle.custom["rand_scale"] * scale_random)
	p_scale = max(p_scale, 0.001)
	if is_2d:
		particle.transform = particle.transform.scaled(Vector2.ONE * p_scale / particle.transform.get_scale())
	else:
		particle.transform.basis = particle.transform.basis.scaled(Vector3.ONE * p_scale / particle.transform.basis.get_scale())
	
	if flag_disable_z and not is_2d:
		particle.transform.origin.z = 0.0
		particle.velocity.z = 0.0


func _particle_collision_3d(particle: Particle3D, normal: Vector3, collider_velocity: Vector3) -> void:
	var velocity := particle.velocity
	particle.velocity = velocity.slide(normal).linear_interpolate(velocity.bounce(normal), collision_bounce)
	particle.velocity -= velocity.slide(normal) * collision_friction
	
	if flag_disable_z:
		particle.transform.origin.z = 0.0
		particle.velocity.z = 0.0


func _particle_collision_2d(particle: Particle2D, normal: Vector2, collider_velocity: Vector2) -> void:
	var velocity := particle.velocity
	particle.velocity = velocity.slide(normal).linear_interpolate(velocity.bounce(normal), collision_bounce)
	particle.velocity -= velocity.slide(normal) * collision_friction

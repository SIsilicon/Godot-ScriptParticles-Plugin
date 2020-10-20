# Script based 3D particle emitter.
# This particle emitter simulates particles based on a specified script.
# It's slower than [CPUParticles], but much more versatile.
tool
class_name ScriptParticles, "script_particles.svg"
extends Spatial

enum DrawOrder {
	DRAW_ORDER_INDEX,
	DRAW_ORDER_LIFETIME,
	DRAW_ORDER_VIEW_DEPTH,
	DRAW_ORDER_CUSTOM
}

# If true, the emitter starts creating particles.
var emitting := false
# Amount of particles to emit.
var amount := 8
# If true, [amount] particles are only emitted once.
var one_shot := false
# How long each particle lasts.
var lifetime := 1.0
# How random the lifetime of each particle is.
var lifetime_randomness := 0.0
# How randomly a new particle is spawned.
var randomness := 0.0

# How spontaneous the particles are spawned.
# 1 means that all particles are spawned at the same _time.
var explosiveness := 0.0 setget set_explosiveness
# How fast the particles are simulated.
var speed_scale := 1.0
# The frame rate at which particles are simulated.
# 0 makes the particles act as if it was just simulated using `_process`.
# Otherwise it's like `_physics_process`.
var fixed_fps := 0

# If true, particles are simulated relative to the emitter.
var use_local_coords := true setget set_local_coords
# The order in which the particles are drawn in.
var draw_order := 0
# What the particles display as.
var mesh: Mesh setget set_mesh

# Determines how the particles behave.
var process_script: ParticleScript

# If true, the particles may react to collision bodies in the scene.
var collision_enabled := false setget set_collision_enabled
# The layers that the particles may collide with.
var collision_mask := 1
# The radius of the particles' collision spheres.
var collision_radius := 0.25 

# Geometry Instance variables

# See [GeometryInstance.material_override].
var material_override: Material setget set_material_override
# See [GeometryInstance.cast_shadow].
var cast_shadow := 1 setget set_cast_shadow
# See [GeometryInstance.extra_cull_margin].
var extra_cull_margin := 0.0 setget set_extra_cull_margin
# See [GeometryInstance.use_in_baked_light]. Does nothing.
var use_in_baked_light := false

# Visual Instance variable

# See [VisualInstance.layers]
var layers := 1 setget set_layers

var _time_to_next_emission := 0.0
var _mesh_inst: RID
var _multimesh: RID

var _multimesh_thread := Thread.new()
var _thread_mutex := Mutex.new()

var _time := 0.0
var _particles_in_cycle := 0
var _cycle := 0
var _frame_remainder := 0.0
var _particles := []
var _current_world: World
var _collision_shape: SphereShape


func _get_property_list() -> Array:
	var properties := [
		{name="ScriptParticles", type=TYPE_NIL, usage=PROPERTY_USAGE_CATEGORY},
		{name="emitting", type=TYPE_BOOL},
		{name="amount", type=TYPE_INT},
		
		{name="Time", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP},
		{name="lifetime", type=TYPE_REAL, hint=PROPERTY_HINT_EXP_RANGE, hint_string="0.01,600,0.01,or_greater"},
		{name="one_shot", type=TYPE_BOOL},
		{name="preprocess", type=TYPE_REAL, hint=PROPERTY_HINT_EXP_RANGE, hint_string="0,600,0.01,or_greater"},
		{name="speed_scale", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,64,0.01,or_greater"},
		{name="explosiveness", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="randomness", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="lifetime_randomness", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="fixed_fps", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0,64,0.01,or_greater"},
		
		{name="Drawing", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP},
		{name="use_local_coords", type=TYPE_BOOL},
		{name="draw_order", type=TYPE_INT, hint=PROPERTY_HINT_ENUM, hint_string="Index,Lifetime,View Depth,Custom"},
		{name="mesh", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Mesh"},
		
		{name="Process Script", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP},
		{name="process_script", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="ParticleScript"},
		
		{name="Collision", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP, hint_string="collision_"},
		{name="collision_enabled", type=TYPE_BOOL},
		{name="collision_mask", type=TYPE_INT, hint=PROPERTY_HINT_LAYERS_3D_PHYSICS},
		{name="collision_radius", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0.01,20,0.01,or_greater"},
		
		{name="GeometryInstance", type=TYPE_NIL, usage=PROPERTY_USAGE_CATEGORY},
		{name="Geometry", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP},
		{name="material_override", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Material"},
		{name="cast_shadow", type=TYPE_INT, hint=PROPERTY_HINT_ENUM, hint_string="Off,On,Double-Sided,Shadows Only"},
		{name="extra_cull_margin", type=TYPE_REAL, hint=PROPERTY_HINT_EXP_RANGE, hint_string="0,16384,0.001"},
		{name="used_in_baked_light", type=TYPE_BOOL},
		{name="VisualInstance", type=TYPE_NIL, usage=PROPERTY_USAGE_CATEGORY},
		{name="layers", type=TYPE_INT, hint=PROPERTY_HINT_LAYERS_3D_RENDER},
	]
	return properties


func _init() -> void:
	set_process_internal(true)
	set_notify_transform(true)
	_multimesh = VisualServer.multimesh_create()
	_mesh_inst = VisualServer.instance_create()
	VisualServer.instance_set_base(_mesh_inst, _multimesh)
	
	set_mesh(mesh)
	set_cast_shadow(cast_shadow)
	set_extra_cull_margin(extra_cull_margin)
	set_material_override(material_override)
	set_layers(layers)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_WORLD:
			_current_world = get_viewport().find_world()
			VisualServer.instance_set_scenario(_mesh_inst, _current_world.scenario)
		NOTIFICATION_EXIT_WORLD:
			_current_world = null
			VisualServer.instance_set_scenario(_mesh_inst, RID())
		NOTIFICATION_INTERNAL_PROCESS:
			VisualServer.instance_set_visible(_mesh_inst, is_visible_in_tree())
			_thread_mutex.lock()
			if process_script and (emitting or not _particles.empty()):
				if fixed_fps:
					var frame_time := 1.0 / fixed_fps
					var decr := frame_time
					
					var ldelta := get_process_delta_time()
					if ldelta > 0.1:
						ldelta = 0.1
					elif ldelta <= 0.0:
						ldelta = 0.001
					var todo := _frame_remainder + ldelta
					while todo >= frame_time:
						_update_particles(frame_time)
						todo -= decr
					_frame_remainder = todo
				else:
					_update_particles(get_process_delta_time())
					_frame_remainder = 0
			_thread_mutex.unlock()
			
			if _multimesh_thread.is_active():
				_multimesh_thread.wait_to_finish()
			_update_multimesh()
			# _multimesh_thread.start(self, "_update_multimesh")
		NOTIFICATION_TRANSFORM_CHANGED:
			if use_local_coords:
				VisualServer.instance_set_transform(_mesh_inst, global_transform)
		NOTIFICATION_PREDELETE:
			if _multimesh_thread.is_active():
				_multimesh_thread.wait_to_finish()
			
			_particles = []
			for particle in _particles:
				particle.die()
				process_script._particle_death(particle)
			VisualServer.free_rid(_multimesh)
			VisualServer.free_rid(_mesh_inst)


func set_explosiveness(value: float) -> void:
	explosiveness = value
	restart()


func set_local_coords(value: bool) -> void:
	var update_coords := false
	if use_local_coords != value:
		update_coords = true
	
	use_local_coords = value

	if update_coords:
		_thread_mutex.lock()
		if use_local_coords:
			for particle in _particles:
				particle.transform = global_transform.affine_inverse() * particle.transform
				particle.velocity = global_transform.affine_inverse().basis * particle.velocity
				VisualServer.instance_set_transform(_mesh_inst, global_transform)
		else:
			for particle in _particles:
				particle.transform = global_transform * particle.transform
				particle.velocity = global_transform.basis * particle.velocity
				VisualServer.instance_set_transform(_mesh_inst, Transform())
		_thread_mutex.unlock()
		

func set_mesh(value: Mesh) -> void:
	mesh = value
	if _multimesh:
		VisualServer.multimesh_set_mesh(_multimesh, mesh.get_rid() if mesh else RID())


func set_collision_enabled(value: bool) -> void:
	collision_enabled = value
	if value:
		_collision_shape = SphereShape.new()
		_collision_shape.margin = 0.5
	else:
		_collision_shape = null


func set_material_override(value: Material) -> void:
	material_override = value
	if _mesh_inst:
		VisualServer.instance_geometry_set_material_override(_mesh_inst, material_override.get_rid() if material_override else RID())


func set_cast_shadow(value: int) -> void:
	cast_shadow = value
	if _mesh_inst:
		VisualServer.instance_geometry_set_cast_shadows_setting(_mesh_inst, cast_shadow)


func set_extra_cull_margin(value: float) -> void:
	extra_cull_margin = value
	if _mesh_inst:
		VisualServer.instance_set_extra_visibility_margin(_mesh_inst, extra_cull_margin)


func set_layers(value: int) -> void:
	layers = value
	if _mesh_inst:
		VisualServer.instance_set_layer_mask(_mesh_inst, layers)


func restart() -> void:
	_thread_mutex.lock()

	_time = 0.0
	_cycle = 0
	_frame_remainder = 0.0
	_particles_in_cycle = 0
	_particles = []
	for particle in _particles:
		particle.die()
		process_script._particle_death(particle)
	
	_thread_mutex.unlock()


func _update_particles(delta: float) -> void:
	delta *= speed_scale
	
	var prev_time := _time
	_time += delta
	if _time > lifetime:
		_time = fmod(_time, lifetime)
		_particles_in_cycle = 0
		_cycle += 1
		if one_shot and _cycle > 0:
			self.emitting = false
			property_list_changed_notify()
	
	_time_to_next_emission -= delta
	while _time_to_next_emission < 0.0 and emitting and _particles.size() < amount and _particles_in_cycle < amount:
		var increment := lifetime / amount
		increment += rand_range(-increment, increment) * randomness
		_time_to_next_emission += increment * (1.0 - explosiveness)
		
		randomize()
		var particle: Particle3D = Particle3D.new(Transform(), Vector3.ZERO, lifetime, self)
		particle.emitter = self
		particle.lifetime *= lerp(1.0, randf(), lifetime_randomness)
		seed(particle.rand)
		process_script._particle_birth(particle)

		if not use_local_coords:
			particle.transform = global_transform * particle.transform
			particle.velocity = global_transform.basis * particle.velocity
		
		_particles.append(particle)
		_particles_in_cycle += 1
	_time_to_next_emission = max(_time_to_next_emission, 0)
	
	# Preparing the physics query and such outside the loop might improve performance
	var query := PhysicsShapeQueryParameters.new()
	var state := PhysicsServer.space_get_direct_state(_current_world.get_space())
	if _collision_shape:
		query.set_shape(_collision_shape)
	query.collision_mask = collision_mask
	var to_local_dir := global_transform.affine_inverse().basis if use_local_coords else Basis.IDENTITY
	var to_local_pos := global_transform.affine_inverse() if use_local_coords else Transform.IDENTITY
	var to_global_pos := global_transform if use_local_coords else Transform.IDENTITY
	
	for i in range(_particles.size() - 1, -1, -1):
		var particle: Particle3D = _particles[i]
		seed(particle.rand)
		process_script._particle_update(particle, delta)
		particle.update(delta)
		
		if collision_enabled and particle.alive:
			var particle_radius := collision_radius * particle.transform.basis.get_scale().x

			_collision_shape.radius = particle_radius
			query.transform = to_global_pos * particle.transform.orthonormalized()

			var collision := state.get_rest_info(query)
			if not collision.empty():
				var position := to_global_pos * particle.transform.origin
				var penetration = position - collision.point
				particle.transform.origin += to_local_dir * penetration.normalized() * (particle_radius - penetration.length())
				
				process_script._particle_collision_3d(particle, to_local_dir * collision.normal, to_local_dir * collision.linear_velocity)
		
		if not particle.alive:
			process_script._particle_death(particle)
			_particles.erase(particle)
	randomize()


func _update_multimesh(__=null) -> void:
	var pc := _particles.size()
	var order: Array
	var ptr := PoolRealArray([0.0])
	ptr.resize(pc * (12 + 4 + 4))

	if pc == 0:
		return
	
	if draw_order != DrawOrder.DRAW_ORDER_INDEX:
		order = []
		order.resize(pc)
		
		for i in pc:
			order[i] = i
		
		if draw_order == DrawOrder.DRAW_ORDER_LIFETIME:
			order.sort_custom(self, "_sort_particles_lifetime")
		elif draw_order == DrawOrder.DRAW_ORDER_VIEW_DEPTH:
			var cam := get_viewport().get_camera()
			if cam:
				var dir := cam.get_global_transform().basis.z
				if use_local_coords:
					# will look different from Particles in editor as this is based on the camera in the scenetree
					# and not the editor camera
					dir = global_transform.basis.xform(dir).normalized()
				else:
					dir = dir.normalized()
				_axis_sort = dir
				order.sort_custom(self, "_sort_particles_axis")
	
	for i in pc:
		var offset: int = i*20
		var idx: int = i if not order else order[i]
		var t: Transform = _particles[idx].transform
		if _particles[idx].alive:
			ptr[0+offset] = t.basis[0][0]
			ptr[1+offset] = t.basis[1][0]
			ptr[2+offset] = t.basis[2][0]
			ptr[3+offset] = t.origin[0]
			ptr[4+offset] = t.basis[0][1]
			ptr[5+offset] = t.basis[1][1]
			ptr[6+offset] = t.basis[2][1]
			ptr[7+offset] = t.origin[1]
			ptr[8+offset] = t.basis[0][2]
			ptr[9+offset] = t.basis[1][2]
			ptr[10+offset] = t.basis[2][2]
			ptr[11+offset] = t.origin[2]
		else:
			offset += 12
		
		var color: Color = _particles[idx].color
		var custom: Dictionary = _particles[idx].custom
		ptr[12+offset] = color.r
		ptr[13+offset] = color.g
		ptr[14+offset] = color.b
		ptr[15+offset] = color.a
		ptr[16+offset] = custom[0]
		ptr[17+offset] = custom[1]
		ptr[18+offset] = custom[2]
		ptr[19+offset] = custom[3]
	
	if VisualServer.multimesh_get_instance_count(_multimesh) != _particles.size():
		VisualServer.multimesh_allocate(_multimesh, _particles.size(), VisualServer.MULTIMESH_TRANSFORM_3D, VisualServer.MULTIMESH_COLOR_FLOAT, VisualServer.MULTIMESH_CUSTOM_DATA_FLOAT)
	VisualServer.multimesh_set_as_bulk_array(_multimesh, ptr)


func _sort_particles_lifetime(a: int, b: int) -> bool:
	return _particles[a].age > _particles[b].age


var _axis_sort := Vector3.FORWARD
func _sort_particles_axis(a: int, b: int) -> bool:
	return _axis_sort.dot(_particles[a].transform.origin) < _axis_sort.dot(_particles[b].transform.origin)

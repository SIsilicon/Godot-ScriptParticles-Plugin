tool
extends MenuButton

const CUSTOM_TEMPLATE := """tool
extends ParticleScript

## Called whenever a new particle is made by the emitter
func _particle_birth(particle: Particle) -> void:
	pass

## Called whenever a particle is being updated
func _particle_update(particle: Particle, delta: float) -> void:
	pass

## Called whenever a particle collides with a 3D body.
func _particle_collision_3d(particle: Particle3D, normal: Vector3, collider_velocity: Vector3) -> void:
	pass

## Called whenever a particle collides with a 2D body.
func _particle_collision_2d(particle: Particle2D, normal: Vector2, collider_velocity: Vector2) -> void:
	pass

## Called whenever a particle is about to be deleted.
func _particle_death(particle: Particle) -> void:
	pass
"""

var emitter: ScriptParticles
var _custom_script: Script


func _ready() -> void:
	_custom_script = GDScript.new()
	_custom_script.source_code = CUSTOM_TEMPLATE
	
	if not get_popup().is_connected("id_pressed", self, "_on_id_pressed"):
		get_popup().connect("id_pressed", self, "_on_id_pressed")


func _create_custom_script() -> void:
	var script := ParticleScript.new()
	script.set_script(_custom_script.duplicate())
	emitter.property_list_changed_notify()
	emitter.process_script = script


func _on_id_pressed(id: int) -> void:
	match id:
		0:
			_create_custom_script()
		1:
			emitter.restart()




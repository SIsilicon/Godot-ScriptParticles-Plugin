tool
class_name ParticleScript, "particle_script.svg"
extends Resource

# If you see this comment when giving your ScriptParticle a process_script,
# THIS SCRIPT SHOULD NOT BE EDITED!
# Either get a standard script, or a custom/extended one.

const Particle = preload("particle.gd")


func _get_property_list() -> Array:
	var properties := [
		{name="ParticleScript", type=TYPE_NIL, usage=PROPERTY_USAGE_CATEGORY},
		{name="script", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Script"}
	]
	return properties

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


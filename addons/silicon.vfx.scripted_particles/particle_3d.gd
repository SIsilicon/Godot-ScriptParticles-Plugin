tool
class_name Particle3D
extends "particle.gd"

var transform: Transform
var velocity: Vector3

# warning-ignore:shadowed_variable
# warning-ignore:shadowed_variable
func _init(transform: Transform, velocity: Vector3, lifetime: float, emitter: Spatial).(lifetime, emitter) -> void:
	self.transform = transform
	self.velocity = velocity


func update(delta: float) -> void:
	.update(delta)
	transform.origin += velocity * delta


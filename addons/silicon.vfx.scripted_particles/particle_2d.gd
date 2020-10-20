tool
class_name Particle2D
extends "particle.gd"

var transform: Transform2D
var velocity: Vector2

# warning-ignore:shadowed_variable
# warning-ignore:shadowed_variable
func _init(transform: Transform2D, velocity: Vector2, lifetime: float, emitter: Node2D).(lifetime, emitter) -> void:
	self.transform = transform
	self.velocity = velocity


func update(delta: float) -> void:
	.update(delta)
	transform.origin += velocity * delta


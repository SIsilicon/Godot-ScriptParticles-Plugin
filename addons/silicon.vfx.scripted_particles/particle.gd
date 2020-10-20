tool
extends Reference

var age := 0.0
var lifetime := 1.0
var color := Color.white
var custom := {0: 0, 1: 0, 2: 0, 3: 0}
var alive := true
var emitter: Node
var rand: int

# warning-ignore:shadowed_variable
# warning-ignore:shadowed_variable
func _init(lifetime: float, emitter: Node) -> void:
	self.lifetime = lifetime
	self.emitter = emitter
	rand = randi()


func update(delta: float) -> void:
	age += delta
	if age >= lifetime:
		die()
	custom[1] = age / lifetime


func die() -> void:
	alive = false


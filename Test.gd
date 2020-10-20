extends Spatial


func _ready() -> void:
	yield(get_tree().create_timer(2.0), "timeout")
#	$ScriptParticles.queue_free()

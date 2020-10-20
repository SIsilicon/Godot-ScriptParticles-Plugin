tool
extends EditorPlugin

var _button: Button
var _edited_node: Object


func _enter_tree() -> void:
	_button = preload("script_particles_editor_button.tscn").instance()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _button)


func _exit_tree() -> void:
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _button)
	_button.queue_free()


func handles(object : Object) -> bool:
	var handle = object is ScriptParticles
	if not handle:
		_button.hide()
	return handle


func edit(object: Object) -> void:
	_edited_node = object
	if _edited_node is ScriptParticles:
		_button.show()
		_button.emitter = _edited_node
	else:
		_button.hide()

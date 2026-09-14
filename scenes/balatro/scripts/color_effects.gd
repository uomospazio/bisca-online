@tool
extends WorldEnvironment

@export var effects_enabled: bool = false:
	set(value):
		effects_enabled = value
		_apply_effects()

@export var saved_environment: Environment:
	set(value):
		saved_environment = value
		_apply_effects()

func _ready() -> void:
	_apply_effects()

func _apply_effects() -> void:
	environment = saved_environment if effects_enabled else null

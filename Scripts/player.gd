class_name Player extends StaticBody2D

@export var move_force := 10.0

# Local References
@onready var _collision_shape_2d: CollisionShape2D = %CollisionShape2D

var viewport_size: Vector2 
var width: float

const OFFSET := 8

signal shoot_ball

# shoots ball
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		shoot_ball.emit()
		# call_deferred makes sure that action "shoot" is called only once
		call_deferred("set_process_unhandled_input", false)

func _ready() -> void:
	viewport_size = get_viewport_rect().size
	width = _collision_shape_2d.shape.get_rect().size.x + OFFSET

func _process(delta: float) -> void:
	# Steering Behaviour algorithm; Player movement controlled by mouse
	var desired_velocity := get_global_mouse_position().x - global_position.x
	global_position.x += desired_velocity * delta * move_force
	
	# clamp player within horizontal viewport boundaries
	global_position.x = clampf(global_position.x, width/2.0, viewport_size.x - (width/2.0))

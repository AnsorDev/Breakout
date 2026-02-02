class_name Brick extends StaticBody2D

# Local References
@onready var _audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var _collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var _animation_player: AnimationPlayer = %AnimationPlayer

func destroy() -> void:
	# Audio
	_audio_stream_player.pitch_scale = randf_range(0.95, 1.05)
	_audio_stream_player.play()
	
	_collision_shape_2d.set_deferred("disabled", true)	# disables collision 
	_animation_player.play("disappear")	 # sets seld modulation:a to 0

	await _audio_stream_player.finished
	queue_free()

class_name Ball extends RigidBody2D

# Local References
@onready var _audio_collision: AudioStreamPlayer = %CollisionAudioStreamPlayer
@onready var _audio_hurt: AudioStreamPlayer = %HurtAudioStreamPlayer
@onready var _reposition_stream_player: AudioStreamPlayer = %RepositionStreamPlayer

# External References (game.tscn)
@onready var _player: Player = %Player
@onready var _lose_area_2d: Area2D = %LoseArea2D

var speed := GameManager.ball_speed
var wall_collision_amount := 0

func _ready() -> void:
	if OS.get_name() == "Web":
		# Lower the master bus audio when in Web
		var master_bus_index = AudioServer.get_bus_index("Master")
		AudioServer.set_bus_volume_db(master_bus_index, -10.0)
		
	wall_collision_amount = 0
	
	print("speed: ", speed)
	# Handles shooting ball from the player at the start of each game
	_player.shoot_ball.connect(func() -> void:
		# Ball linear velocity at start of game
		linear_velocity = (
			Vector2.UP.rotated(randf_range(deg_to_rad(-45), deg_to_rad(45))) * speed
		)
		call_deferred("set_process", false)	 #disables process, thus ball can move up
	)
	
	# Handles losing a live, thus repositioning the ball back at player
	_lose_area_2d.area_exited.connect(func(_area: Area2D) -> void:
		_audio_hurt.pitch_scale = randf_range(0.95, 1.05)
		_audio_hurt.play()
		
		GameManager.subtract_live(1)
		wall_collision_amount = 0
		reposition_ball_to_player()
	)
	
	# Handles collision with other bodies
	body_entered.connect(func(body: Node2D) -> void:
		# Ball bounce sounds
		_audio_collision.pitch_scale = randf_range(0.95, 1.05)
		_audio_collision.play()
		
		if body is Player or body is Brick:
			wall_collision_amount = 0
			
			# change ball direction after collision if player racket
			if body is Player:
				change_ball_direction()
				
			elif body is Brick:	 # score update if collision with brick
				GameManager.add_score(100)	# update score
				body.destroy()	# destroy brick
				# increase ball speed, multiply new speed by linear_velocity direction
				speed += 10.0	
				linear_velocity = linear_velocity.normalized() * speed
			
		else: # resets the ball position if wall_collision amount exceeds a certain value
			wall_collision_amount += 1
			if wall_collision_amount == 4:
				reposition_ball_to_player()
				_reposition_stream_player.play()
				wall_collision_amount = 0
	)

func _process(_delta: float) -> void:
	# Set ball horizontal position same as player
	global_position = Vector2(_player.global_position.x, 550)

# Sets ball linear velocity direction based on collided position with the player racket
func change_ball_direction() -> void:
	#offset will be a value between [-1.0, 1.0]
	var offset: float = (
		(global_position.x - _player.global_position.x) / (_player.width / 2.0)
	)
	var angle := offset * deg_to_rad(35)
	linear_velocity = (
		Vector2.UP.rotated(angle + randf_range(deg_to_rad(-10), deg_to_rad(10))) * speed
	)

func reposition_ball_to_player() -> void:
	linear_velocity = Vector2.ZERO	# stops ball from moving
	call_deferred("set_process", true)	# resets the ball near player racker position
	# enables for the player to press shoot again
	_player.call_deferred("set_process_unhandled_input", true)

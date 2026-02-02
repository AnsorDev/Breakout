extends Node	# Autoload

# the variable value changes persist even when reloading the scene bc autoload script is global
var score := 0
var highscore := 0
var lives := 3
var ball_speed := 400.0
var is_game_over := false

# If this MAX_SCORE reached by score, player won
const MAX_SCORE := 6000

# Here will save highscore so that it doesn't reset after we close the game
const _SAVE_PATH := "res://highscore.txt"

# sent to the UI label nodes
signal score_updated(new_score: int)
signal lives_updated(new_lives: int)
signal game_over
signal win

# Autoload's _ready function is only called once when the game starts, reloading current scene no effect
func _ready() -> void:
	# Set highscore variable with the actual current highscore
	_load_highscore()
	if OS.get_name() == "Web":
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	#Input.set_default_cursor_shape(Input.CURSOR_CROSS)8

func add_score(points: int) -> void:
	score += points
	score_updated.emit(score)
	
	# Win State
	if score % MAX_SCORE == 0:
		# wait for 0.2 for the last brick to fully disappear before pausing
		await get_tree().create_timer(0.2).timeout
		restart_game()

func subtract_live(subtract_amount: int) -> void:
	lives -= subtract_amount
	lives_updated.emit(lives)
	
	# Game Over State
	if lives <= 0:
		var start_game_over := true
		restart_game(start_game_over)

# assigning default value to parameter makes them optional
func restart_game(start_game_over: bool = false) -> void:
	if score > highscore:
		highscore = score
		_save_highscore()
		print("highscore: ", highscore)
	
	# Restarts Score in Case of Game Over State
	if start_game_over == true:
		game_over.emit()
		is_game_over = true
		
		# reset the global variables to the original value
		score = 0
		lives = 3
		ball_speed = 400.0
	else:
		win.emit()
		is_game_over = false
		
		# make ball faster after each win state
		ball_speed += 100.0
		
	get_tree().paused = true
	await get_tree().create_timer(5).timeout
	get_tree().reload_current_scene()

func _save_highscore() -> void:
	var file := FileAccess.open(_SAVE_PATH, FileAccess.WRITE)
	file.store_line(str(highscore))
	file.close()

func _load_highscore() -> void:
	var file := FileAccess.open(_SAVE_PATH, FileAccess.READ)
	highscore = int(file.get_line())
	file.close()

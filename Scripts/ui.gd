extends Control

# Local References
@onready var _score_label: Label = %ScoreLabel
@onready var _highscore_label: Label = %HighscoreLabel
@onready var _score_lose_summary_label: Label = %ScoreLoseSummaryLabel
@onready var _highscore_lose_summary_label: Label = %HighscoreLoseSummaryLabel
@onready var _score_win_summary_label: Label = %ScoreWinSummaryLabel
@onready var _highscore_win_summary_label: Label = %HighscoreWinSummaryLabel
@onready var _game_over_label: RichTextLabel = %GameOverLabel
@onready var _winner_label: RichTextLabel = %WinnerLabel
@onready var _health_bar_container: HBoxContainer = %HealthBarContainer
@onready var _quit_button: Button = %QuitButton
@onready var _start_button: Button = %StartButton
@onready var _menu: Panel = %Menu

@onready var _game_over_sound: AudioStreamPlayer = %GameOverAudioStreamPlayer
@onready var _start_sound: AudioStreamPlayer = %StartAudioStreamPlayer
@onready var _main_theme_audio: AudioStreamPlayer = %MenuAudioStreamPlayer

var audio_menu_array: Array[AudioStreamMP3] = [
	preload("res://Assets/Audio/Grey Sector v0_85.mp3"),
	preload("res://Assets/Audio/Retro Samurai v0_4.mp3"),
]
var heart_texture_array: Array[TextureRect]

const ANIM_DURATION := 1.0
const MAX_SCORE := GameManager.MAX_SCORE
const SILENT_VOLUME := -50.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Setting Up Properties
	_highscore_label.text += str(GameManager.highscore)
	_game_over_label.visible = false
	_winner_label.visible = false
	_start_button.button_pressed = true
	
	_score_label.text = str(GameManager.score)
	_game_over_label.scale = Vector2(0.1, 0.1)
	_winner_label.scale = Vector2(0.1, 0.1)
	
	# Audio
	_main_theme_audio.stream = audio_menu_array.pick_random()
	_main_theme_audio.volume_db = SILENT_VOLUME
	_main_theme_audio.play(randf_range(0.0, (_main_theme_audio.stream.get_length() / 2.0)))
	
	# Differentiates between Menu State on or off, here is on when first start or game over
	if get_tree().paused == false or GameManager.is_game_over == true:
		_menu.visible = true
		get_tree().paused = true
		
		# Animation (for Audio)
		var tween := create_tween()
		tween.tween_property(_main_theme_audio, "volume_db", -5, ANIM_DURATION)
	# and here is the off state when winning
	elif get_tree().paused == true:
		_menu.visible = false
		get_tree().paused = false
		
		var tween5 = create_tween()
		tween5.tween_property(_main_theme_audio, "volume_db", -20, ANIM_DURATION)
	
	# Stores Heart Textures within Array
	for heart_texture in _health_bar_container.get_children():
		heart_texture_array.append(heart_texture)
	
	# Diplays the right amount of hearts in next game after win state
	update_heart_display(GameManager.lives)
	
	# Updates Score UI
	GameManager.score_updated.connect(func(new_score: int) -> void:
		_score_label.text = str(new_score)
	)
	
	# Updates Lives UI
	GameManager.lives_updated.connect(func(new_lives: int) -> void:
		update_heart_display(new_lives)
	)
	
	# Pops Up the Win Label
	GameManager.win.connect(func() -> void:
		_winner_label.visible = true
		_score_win_summary_label.text += str(GameManager.score)
		_highscore_win_summary_label.text += str(GameManager.highscore)
		
		var tween2 = create_tween().parallel()
		tween2.tween_property(_winner_label, "scale", Vector2.ONE, 0.3)
		tween2.tween_property(_main_theme_audio, "volume_db", SILENT_VOLUME, ANIM_DURATION)
	)
	
	# Pops Up Game Over Label
	GameManager.game_over.connect(func() -> void:
		_game_over_sound.pitch_scale = randf_range(0.97, 1.03)
		_game_over_sound.play()
		_game_over_label.visible = true
		_score_lose_summary_label.text += str(GameManager.score)
		_highscore_lose_summary_label.text += str(GameManager.highscore)
		
		var tween3 = create_tween().parallel()
		tween3.tween_property(_game_over_label, "scale", Vector2.ONE, 0.3)
		tween3.tween_property(_main_theme_audio, "volume_db", SILENT_VOLUME, ANIM_DURATION)
	)
	
	# Handles Start Game state
	_start_button.pressed.connect(func() -> void:
		_start_sound.play()
		_start_button.disabled = true
		
		var tween4 = create_tween().parallel()
		tween4.tween_property(_menu, "modulate:a", 0.0, ANIM_DURATION)
		tween4.tween_property(_main_theme_audio, "volume_db", -20, ANIM_DURATION)
		
		await get_tree().create_timer(1.0).timeout
		get_tree().paused = false
		_menu.visible = false
	)
	
	# Handles the Quit Game State
	_quit_button.pressed.connect(func() -> void:
		# Web
		if OS.get_name() == "Web":
			GameManager.score = 0
			GameManager.lives = 3
			GameManager.ball_speed = 400.0
			get_tree().reload_current_scene()
		# Desktop
		else:
			get_tree().quit()
	)

# Changes Amount of Heart Textures Displayed Depending on the Lives Value
func update_heart_display(life: int) -> void:
	var is_heart_lost: bool
	for i in heart_texture_array.size():
		is_heart_lost = i < life
		
		if is_heart_lost == false:
			heart_texture_array[i].modulate.a = 0.3

extends Node2D

const INITIAL_BALL_SPEED = 120 # px/s
const PAD_SPEED = 200 # px/s
const SCREEN_WIDTH = 640
const SCREEN_HEIGHT = 400

var PlayModule = load("res://scripts/play.gd")

enum PLAYER_MOVEMENTS {
	UP,
	DOWN,
	NONE,
}

const PLAYER_MOVEMENTS_MAP = {
	PLAYER_MOVEMENTS.UP: 1,
	PLAYER_MOVEMENTS.DOWN: 2,
	PLAYER_MOVEMENTS.NONE: 0,
}

enum AI_DIFFICULTY {
	EASY,
	MEDIUM,
	HARD,
	IMPOSSIBLE,
}

const AI_DIFFICULTY_MAP = {
	AI_DIFFICULTY.IMPOSSIBLE: 0.0,
	AI_DIFFICULTY.HARD: 0.25,
	AI_DIFFICULTY.MEDIUM: 0.5,
	AI_DIFFICULTY.EASY: 0.70,
}

# Whether AI should play against itself
const SKYNET = false

# Declare member variables here. Examples:
var screen_size
var pad_size
var direction = Vector2(1.0, 0.0)
var ball_speed = INITIAL_BALL_SPEED
var previous_ball_pos = Vector2(1, 1)
var left_score
var right_score
var left_score_label
var right_score_label
var rnd
var moved_in_round
var ai_difficulty
var current_play

# Called when the node enters the scene tree for the first time.
func _ready():
	print(OS.get_user_data_dir())
	screen_size = Vector2(SCREEN_WIDTH, SCREEN_HEIGHT)
	pad_size = get_node("left").get_texture().get_size()
	set_process(true)
	left_score = 0
	right_score = 0
	left_score_label = get_node("leftscore")
	right_score_label = get_node("rightscore")
	rnd = RandomNumberGenerator.new()
	rnd.randomize()
	ai_difficulty = AI_DIFFICULTY.EASY
	ai_takeover()
	current_play = PlayModule.Play.new()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var ball_pos = get_node("ball").position
	var left_rect = Rect2(get_node("left").position - pad_size*0.5, pad_size)
	var right_rect = Rect2(get_node("right").position - pad_size*0.5, pad_size)

	# Record previous ball position
	previous_ball_pos = ball_pos

	# Integrate new ball position
	ball_pos += direction * ball_speed * delta

	# Flip when touching roof or floor
	if ((ball_pos.y < 0 and direction.y < 0) or (ball_pos.y > screen_size.y and direction.y > 0)):
		direction.y = -direction.y

	# Flip, change direction and increase speed when touching pads
	if ((left_rect.has_point(ball_pos) and direction.x < 0) or (right_rect.has_point(ball_pos) and direction.x > 0)):
		direction.x = -direction.x
		direction.y = randf()*2.0 - 1
		direction = direction.normalized()
		ball_speed *= 1.1

	# Check gameover
	if (ball_pos.x < 0 or ball_pos.x > screen_size.x):
		# Serve ball to loser
		if (ball_pos.x < 0):
			right_score += 1
			right_score_label.text = str(right_score)
			direction = Vector2(-1, 0)
			current_play.label = str(0)
		else:
			left_score += 1
			left_score_label.text = str(left_score)
			direction = Vector2(1, 0)
			current_play.label = str(1)

		ball_pos = screen_size*0.5
		ball_speed = INITIAL_BALL_SPEED
		ai_takeover()
		current_play.export()
		current_play.reset()

	# Set new position to ball.
	get_node("ball").position = ball_pos

	# Move left pad - Human (or AI if inactive)
	var left_pos = get_node("left").position

	var player_movement = player_movement()

	var left_movement
	if player_movement == PLAYER_MOVEMENTS.NONE and !moved_in_round:
		left_movement = player_ai(ball_pos, previous_ball_pos, get_node("left").position, ai_difficulty)
	else:
		left_movement = player_movement

	if (left_pos.y > left_rect.size.y / 2 and left_movement == PLAYER_MOVEMENTS.UP):
		left_pos.y += -PAD_SPEED * delta
	if (left_pos.y < screen_size.y - left_rect.size.y / 2 and left_movement == PLAYER_MOVEMENTS.DOWN):
		left_pos.y += PAD_SPEED * delta

	get_node("left").position = left_pos

	# Update phantom AI paddle.
	var phantom_ai_movement = player_ai(ball_pos, previous_ball_pos, get_node("phantom").position, AI_DIFFICULTY.IMPOSSIBLE)
	var phantom_pos = get_node("phantom").position
	if (phantom_pos.y > left_rect.size.y / 2 and phantom_ai_movement == PLAYER_MOVEMENTS.UP):
		phantom_pos.y += -PAD_SPEED * delta
	if (phantom_pos.y < screen_size.y - left_rect.size.y / 2 and phantom_ai_movement == PLAYER_MOVEMENTS.DOWN):
		phantom_pos.y += PAD_SPEED * delta

	get_node("phantom").position = phantom_pos

	# Move right pad - AI
	var right_pos = get_node("right").position

	var right_ai_movement = player_ai(ball_pos, previous_ball_pos, get_node("right").position, ai_difficulty)
	if (right_pos.y > right_rect.size.y / 2 and right_ai_movement == PLAYER_MOVEMENTS.UP):
		right_pos.y += -PAD_SPEED * delta
	if (right_pos.y < screen_size.y - right_rect.size.y / 2 and right_ai_movement == PLAYER_MOVEMENTS.DOWN):
		right_pos.y += PAD_SPEED * delta

	get_node("right").position = right_pos

	# Record frame
	current_play.add_frame(
		ball_pos.x,
		ball_pos.y,
		ball_speed,
		direction.x,
		direction.y,
		left_pos.y,
		right_pos.y,
		PLAYER_MOVEMENTS_MAP[left_movement],
		PLAYER_MOVEMENTS_MAP[right_ai_movement]
	)

func player_movement():
	if Input.is_action_pressed("down"):
		player_takeover()
		return PLAYER_MOVEMENTS.DOWN
	elif Input.is_action_pressed("up"):
		player_takeover()
		return PLAYER_MOVEMENTS.UP
	else:
		return PLAYER_MOVEMENTS.NONE

func player_ai(ball_pos, prev_ball_pos, paddle_pos, difficulty):
	# If ball is going away, we try to center our paddle, otherwise we predict
	# where the ball will go and go there.
	var y_dest
	if abs(paddle_pos.x - ball_pos.x) < abs(paddle_pos.x - prev_ball_pos.x):
		# Let's add a chance that we won't do anything.
		if (rnd.randf() <= AI_DIFFICULTY_MAP[difficulty]):
			return PLAYER_MOVEMENTS.NONE

		y_dest = predict(ball_pos, prev_ball_pos, paddle_pos.x)
	else:
		y_dest = screen_size.y / 2

	var paddle_lower_limit = int(paddle_pos.y - pad_size.y / 4)
	var paddle_upper_limit = int(paddle_pos.y + pad_size.y / 4)
	if y_dest > paddle_upper_limit:
		return PLAYER_MOVEMENTS.DOWN
	elif y_dest < paddle_lower_limit:
		return PLAYER_MOVEMENTS.UP
	else:
		return PLAYER_MOVEMENTS.NONE

func predict(curr_pos, prev_pos, x_intersect):
	var y_2 = curr_pos.y
	var y_1 = prev_pos.y

	var x_2 = curr_pos.x
	var x_1 = prev_pos.x

	if (x_2 == x_1):
		x_1 += 1

	var y = (((y_2 - y_1) / (x_2 - x_1)) * (x_intersect - x_1)) + y_1
	var reflected_y = int(abs(y))

	var vertical_size = int(abs(screen_size.y))
	if (reflected_y > vertical_size):
		reflected_y = vertical_size - (reflected_y % vertical_size)

	return reflected_y

func ai_takeover():
	ai_difficulty = AI_DIFFICULTY.IMPOSSIBLE
	moved_in_round = false
	get_node("playercontrol").text = str("AI (diff: " + str(ai_difficulty) + ")")
	get_node("phantom").visible = false

func player_takeover():
	ai_difficulty = AI_DIFFICULTY.MEDIUM
	moved_in_round = true
	get_node("playercontrol").text = str("HUMAN")
	get_node("phantom").visible = true

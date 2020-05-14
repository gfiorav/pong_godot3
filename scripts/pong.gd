extends Node2D

const INITIAL_BALL_SPEED = 80 # px/s
const PAD_SPEED = 150 # px/s

enum PLAYER_MOVEMENTS {
	UP,
	DOWN,
}

# Declare member variables here. Examples:
var screen_size
var pad_size
var direction = Vector2(1.0, 1.0)
var ball_speed = INITIAL_BALL_SPEED
var previous_ball_pos = Vector2(1, 1)

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport().size
	pad_size = get_node("left").get_texture().get_size()
	set_process(true)

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
			direction = Vector2(-1, 0)
		else:
			direction = Vector2(1, 0)

		ball_pos = screen_size*0.5
		ball_speed = INITIAL_BALL_SPEED

	# Set new position to ball.
	get_node("ball").position = ball_pos

	# Move left pad - AI
	var left_pos = get_node("left").position

	var left_ai_movement = player_ai(ball_pos, previous_ball_pos, get_node("left").position)
	if (left_pos.y > left_rect.size.y / 2 and left_ai_movement == PLAYER_MOVEMENTS.DOWN):
		left_pos.y += -PAD_SPEED * delta
	if (left_pos.y < screen_size.y - left_rect.size.y / 2 and left_ai_movement == PLAYER_MOVEMENTS.UP):
		left_pos.y += PAD_SPEED * delta

	get_node("left").position = left_pos

	# Move right pad - AI too
	var right_pos = get_node("right").position

	var right_ai_movement = player_ai(ball_pos, previous_ball_pos, get_node("right").position)
	if (right_pos.y > right_rect.size.y / 2 and right_ai_movement == PLAYER_MOVEMENTS.DOWN):
		right_pos.y += -PAD_SPEED * delta
	if (right_pos.y < screen_size.y - right_rect.size.y / 2 and right_ai_movement == PLAYER_MOVEMENTS.UP):
		right_pos.y += PAD_SPEED * delta

	get_node("right").position = right_pos


func player_ai(ball_pos, prev_ball_pos, paddle_pos):
	var ball_y_prediction = predict(ball_pos, prev_ball_pos, paddle_pos.x)
	if (ball_y_prediction > paddle_pos.y):
		return PLAYER_MOVEMENTS.UP
	else:
		return PLAYER_MOVEMENTS.DOWN

func predict(curr_pos, prev_pos, x_intersect):
	var y_2 = curr_pos.y
	var y_1 = prev_pos.y

	var x_2 = curr_pos.x
	var x_1 = prev_pos.x

	if (x_2 == x_1):
		x_1 += 1

	var y = (((y_2 - y_1) / (x_2 - x_1)) * (x_intersect - x_1)) + y_1
	var reflected_y = int(abs(y))

	var vertical_size = int(abs(get_viewport().size.y))
	if (reflected_y > vertical_size):
		reflected_y = vertical_size - (reflected_y % vertical_size)

	return reflected_y

extends Node2D

const INITIAL_BALL_SPEED = 80 # px/s
const PAD_SPEED = 150 # px/s

# Declare member variables here. Examples:
var screen_size
var pad_size
var direction = Vector2(1.0, 0.0)
var ball_speed = INITIAL_BALL_SPEED

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

	# Move left pad
	var left_pos = get_node("left").position

	if (left_pos.y > left_rect.size.y / 2 and Input.is_action_pressed("left_move_up")):
		left_pos.y += -PAD_SPEED * delta
	if (left_pos.y < screen_size.y - left_rect.size.y / 2 and Input.is_action_pressed("left_move_down")):
		left_pos.y += PAD_SPEED * delta

	get_node("left").position = left_pos

	# Move right pad
	var right_pos = get_node("right").position

	if (right_pos.y > right_rect.size.y / 2 and Input.is_action_pressed("right_move_up")):
		right_pos.y += -PAD_SPEED * delta
	if (right_pos.y < screen_size.y - right_rect.size.y / 2 and Input.is_action_pressed("right_move_down")):
		right_pos.y += PAD_SPEED * delta

	get_node("right").position = right_pos

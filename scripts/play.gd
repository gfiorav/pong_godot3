class Frame:
	var ball_pos_x: String
	var ball_pos_y: String
	var ball_speed: String
	var ball_dir_x: String
	var ball_dir_y: String
	var left_paddle_pos_y: String
	var right_paddle_pos_y: String
	var left_paddle_move: String
	var right_paddle_move: String

class Play:
	var header = [
		"label",
		"ball_pos_x",
		"ball_pos_y",
		"ball_speed",
		"ball_dir_x",
		"ball_dir_y",
		"left_paddle_pos_y",
		"right_paddle_pos_y",
		"left_paddle_move",
		"right_paddle_move"
	]

	var frames: Array
	var label: String

	func add_frame(
		ball_pos_x,
		ball_pos_y,
		ball_speed,
		ball_dir_x,
		ball_dir_y,
		left_paddle_pos_y,
		right_paddle_pos_y,
		left_paddle_move,
		right_paddle_move
	):
		var frame = Frame.new()

		frame.ball_pos_x = str(ball_pos_x)
		frame.ball_pos_y = str(ball_pos_y)
		frame.ball_speed = str(ball_speed)
		frame.ball_dir_x = str(ball_dir_x)
		frame.ball_dir_y = str(ball_dir_y)
		frame.left_paddle_pos_y = str(left_paddle_pos_y)
		frame.right_paddle_pos_y = str(right_paddle_pos_y)
		frame.left_paddle_move = str(left_paddle_move)
		frame.right_paddle_move = str(right_paddle_move)

		self.frames.append(frame)

	func reset():
		self.frames = []
		self.label = ""

	func export():
		# Open csv file with unique name for time.
		var output_csv = File.new()
		output_csv.open(
			"user://play_" + str(OS.get_unix_time()) + ".csv",
			File.WRITE
		)

		# Write header.
		output_csv.store_line(PoolStringArray(self.header).join(","))

		# Write body.
		for frame in self.frames:
			var line = [
				self.label,
				frame.ball_pos_x,
				frame.ball_pos_y,
				frame.ball_speed,
				frame.ball_dir_x,
				frame.ball_dir_y,
				frame.left_paddle_pos_y,
				frame.right_paddle_pos_y,
				frame.left_paddle_move,
				frame.right_paddle_move
			]

			output_csv.store_line(PoolStringArray(line).join(","))

		# Close file.
		output_csv.close()


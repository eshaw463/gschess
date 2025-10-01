#############################
# Game by RandomCrow
# Initial template: https://github.com/Godot-With-Me/Chess

# Idea: expand upon chess with UI, placing pieces, and crazy things down the line


#############################

extends Sprite2D

const BOARD_SIZE = 8
const CELL_WIDTH = 18

const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")

const BLACK_BISHOP = preload("res://Assets/black_bishop.png")
const BLACK_KING = preload("res://Assets/black_king.png")
const BLACK_KNIGHT = preload("res://Assets/black_knight.png")
const BLACK_PAWN = preload("res://Assets/black_pawn.png")
const BLACK_QUEEN = preload("res://Assets/black_queen.png")
const BLACK_ROOK = preload("res://Assets/black_rook.png")
const WHITE_BISHOP = preload("res://Assets/white_bishop.png")
const WHITE_KING = preload("res://Assets/white_king.png")
const WHITE_KNIGHT = preload("res://Assets/white_knight.png")
const WHITE_PAWN = preload("res://Assets/white_pawn.png")
const WHITE_QUEEN = preload("res://Assets/white_queen.png")
const WHITE_ROOK = preload("res://Assets/white_rook.png")

const TURN_WHITE = preload("res://Assets/turn-white.png")
const TURN_BLACK = preload("res://Assets/turn-black.png")

const PIECE_MOVE = preload("res://Assets/Piece_move.png")

@onready var pieces = $Pieces
@onready var dots = $Dots
@onready var turn = $Turn
@onready var white_pieces = $"../CanvasLayer/white_pieces"
@onready var black_pieces = $"../CanvasLayer/black_pieces"
@onready var opt = $"../CanvasLayer/UI/OptionButton"
@onready var turn_lab: Label = $"../CanvasLayer/UI/turnLab"

@onready var infotab: RichTextLabel = $"../CanvasLayer/UI/INFOTAB"
@onready var infobacker: Sprite2D = $"../CanvasLayer/UI/infobacker"


#extra var
var currentTurn : int = 0
var b_manpower : int = 0
var w_manpower : int = 0
var w_name = "Player1"
var b_name = "Player2"

var w_up : int = 0
var b_up : int = 0
var w_list = []
var b_list = []

var infoOn = false


#Variables
# -6 = black king
# -5 = black queen
# -4 = black rook
# -3 = black bishop
# -2 = black knight
# -1 = black pawn
# 0 = empty
# 6 = white king
# 5 = white queen
# 4 = white rook
# 3 = white bishop
# 2 = white knight
# 1 = white pawn

var board : Array
var white : bool = true
var state : bool = false
var moves = []
var selected_piece : Vector2

var promotion_square = null

var white_king = false
var black_king = false
var white_rook_left = false
var white_rook_right = false
var black_rook_left = false
var black_rook_right = false

var en_passant = null

var fifty_move_rule = 0

var unique_board_moves : Array = []
var amount_of_same : Array = []

func _ready():
	infotab.set_visible(false)
	infobacker.set_visible(false)
	
	board.append([0, 0, 6, 6, 6, 6, 0, 0])
	board.append([0, 0, 1, 1, 1, 1, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, -1, -1, -1, -1, 0, 0])
	board.append([0, 0, -6, -6, -6, -6, 0, 0])
	
	display_board()
	
	var white_buttons = get_tree().get_nodes_in_group("white_pieces")
	var black_buttons = get_tree().get_nodes_in_group("black_pieces")
	
	for button in white_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))
		
	for button in black_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))
	
func _input(event):
	if event is InputEventMouseButton && event.pressed && promotion_square == null:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_out(): return
			var var1 = snapped(get_global_mouse_position().x, 0) / CELL_WIDTH
			var var2 = abs(snapped(get_global_mouse_position().y, 0)) / CELL_WIDTH
			if !state && (white && board[var2][var1] > 0 || !white && board[var2][var1] < 0):
				selected_piece = Vector2(var2, var1)
				show_options()
				state = true
			elif state: set_move(var2, var1)
			
func is_mouse_out():
	if get_rect().has_point(to_local(get_global_mouse_position())): return false
	return true

func display_board():
	for child in pieces.get_children():
		child.queue_free()
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = TEXTURE_HOLDER.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2), -i * CELL_WIDTH - (CELL_WIDTH / 2))
			
			match board[i][j]:
				-6: holder.texture = BLACK_KING
				-5: holder.texture = BLACK_QUEEN
				-4: holder.texture = BLACK_ROOK
				-3: holder.texture = BLACK_BISHOP
				-2: holder.texture = BLACK_KNIGHT
				-1: holder.texture = BLACK_PAWN
				0: holder.texture = null
				6: holder.texture = WHITE_KING
				5: holder.texture = WHITE_QUEEN
				4: holder.texture = WHITE_ROOK
				3: holder.texture = WHITE_BISHOP
				2: holder.texture = WHITE_KNIGHT
				1: holder.texture = WHITE_PAWN
				
				
				
				
#WIN?
	var w_loss = true
	var b_loss = true
	for n in range (8):
		for m in range (8):
			if board[n][m] > 0: 
				w_loss = false
			if board[n][m] < 0: 
				b_loss = false
	if (w_loss):   #DISPLAY WIN SCREENS HERE
		OS.alert("Black Wins! Reopen game to reset","Black Wins")
	if (b_loss):
		OS.alert("White Wins! Reopen game to reset","White Wins")


#CHANGE TURN
	if white: 
		var infotxt: Label = $"../CanvasLayer/UI/infotxt"
		infotxt.text = "ⓘ"
		infotab.set_visible(false)
		infobacker.set_visible(false)
		infoOn = false
		turn.texture = TURN_WHITE
		currentTurn+=1
		w_display_upgrades()
		w_manpower += 1 #set back to 1
		if (w_list.has(6) && currentTurn%3==0): w_manpower += 1
		var text = $"../CanvasLayer/UI/DeployNumber"
		text.text = "power: " + str(w_manpower)
		var enemyNum = $"../CanvasLayer/UI/enemyNum"
		enemyNum.text = "enemy power: " + str(b_manpower+1)
		
		var nameLabel = $"../CanvasLayer/UI/PlayerName"
		nameLabel.text = w_name
		turn_lab.text = "Turn: " + str(currentTurn)
		
	else: 
		b_display_upgrades()
		var infotxt: Label = $"../CanvasLayer/UI/infotxt"
		infotxt.text = "ⓘ"
		infotab.set_visible(false)
		infobacker.set_visible(false)
		infoOn = false
		turn.texture = TURN_BLACK
		b_manpower += 1
		if (b_list.has(6) && currentTurn%3==0): b_manpower += 1
		var text = $"../CanvasLayer/UI/DeployNumber"
		text.text = "power: " + str(b_manpower)
		var enemyNum = $"../CanvasLayer/UI/enemyNum"
		enemyNum.text = "enemy power: " + str(w_manpower+1)

		var nameLabel = $"../CanvasLayer/UI/PlayerName"
		nameLabel.text = b_name
		turn_lab.text = "Turn: " + str(currentTurn)

func show_options():
	moves = get_moves(selected_piece)
	if moves == []:
		state = false
		return
	show_dots()
	
func show_dots():
	for i in moves:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.global_position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH / 2), -i.x * CELL_WIDTH - (CELL_WIDTH / 2))

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(var2, var1):
	var just_now = false
	for i in moves:
		if i.x == var2 && i.y == var1:
			fifty_move_rule += 1
			if is_enemy(Vector2(var2, var1)): fifty_move_rule = 0
			match board[selected_piece.x][selected_piece.y]:
				1:
					fifty_move_rule = 0
					if i.x == 7: promote(i)
					if i.x == 3 && selected_piece.x == 1:
						en_passant = i
						just_now = true
					elif en_passant != null:
						if en_passant.y == i.y && selected_piece.y != i.y && en_passant.x == selected_piece.x:
							board[en_passant.x][en_passant.y] = 0
				-1:
					fifty_move_rule = 0
					if i.x == 0: promote(i)
					if i.x == 4 && selected_piece.x == 6:
						en_passant = i
						just_now = true
					elif en_passant != null:
						if en_passant.y == i.y && selected_piece.y != i.y && en_passant.x == selected_piece.x:
							board[en_passant.x][en_passant.y] = 0
				4:
					if selected_piece.x == 0 && selected_piece.y == 0: white_rook_left = true
					elif selected_piece.x == 0 && selected_piece.y == 7: white_rook_right = true
				-4:
					if selected_piece.x == 7 && selected_piece.y == 0: black_rook_left = true
					elif selected_piece.x == 7 && selected_piece.y == 7: black_rook_right = true
				6:
					if selected_piece.x == 0 && selected_piece.y == 4:
						white_king = true
						if i.y == 2:
							white_rook_left = true
							white_rook_right = true
							board[0][0] = 0
							board[0][3] = 4
						elif i.y == 6:
							white_rook_left = true
							white_rook_right = true
							board[0][7] = 0
							board[0][5] = 4
				-6:
					if selected_piece.x == 7 && selected_piece.y == 4:
						black_king = true
						if i.y == 2:
							black_rook_left = true
							black_rook_right = true
							board[7][0] = 0
							board[7][3] = -4
						elif i.y == 6:
							black_rook_left = true
							black_rook_right = true
							board[7][7] = 0
							board[7][5] = -4
			if !just_now: en_passant = null
			board[var2][var1] = board[selected_piece.x][selected_piece.y]
			
			# extra weapon stuffs
			# revolver
			if white && w_list.has(0) && (currentTurn%6 == 0):
				if (var2 < 7):
					if (board[var2+1][var1] < 0): board[var2+1][var1] = 0
					if (board[var2+1][var1+1] < 0): board[var2+1][var1+1] = 0
					if (board[var2+1][var1-1] < 0): board[var2+1][var1-1] = 0
					
			elif !white && b_list.has(0) && (currentTurn%6 == 0):
				if (var2 > 0):
					if (board[var2-1][var1] > 0): board[var2-1][var1] = 0
					if (board[var2-1][var1+1] > 0): board[var2-1][var1+1] = 0
					if (board[var2-1][var1-1] > 0): board[var2-1][var1-1] = 0
			# sword
			if white && w_list.has(3) && (currentTurn%3 == 1): # ==1 to offset with revolver
				if (var2 < 7):
					if (board[var2+1][var1] < 0): board[var2+1][var1] = 0
					
			elif !white && b_list.has(3) && (currentTurn%3 == 1):
				if (var2 > 0):
					if (board[var2-1][var1] > 0): board[var2-1][var1] = 0
			# artillery
			if white && w_list.has(8) && (currentTurn%12 == 2): # ==2 to offset with revolver
				if (var2+1 < 8):
					if (board[var2+1][var1] < 0): board[var2+1][var1] = 0
				if (var2+2 < 8):
					if (board[var2+2][var1] < 0): board[var2+2][var1] = 0
				if (var2+3 < 8):
					if (board[var2+3][var1] < 0): board[var2+3][var1] = 0
				if (var2+4 < 8):
					if (board[var2+4][var1] < 0): board[var2+4][var1] = 0
				if (var2+5 < 8):
					if (board[var2+5][var1] < 0): board[var2+5][var1] = 0
					
			elif !white && b_list.has(8) && (currentTurn%12 == 2):
				if (var2-1 > -1):
					if (board[var2-1][var1] > 0): board[var2-1][var1] = 0
				if (var2-2 > -1):
					if (board[var2-2][var1] > 0): board[var2-2][var1] = 0
				if (var2-3 > -1):
					if (board[var2-3][var1] > 0): board[var2-3][var1] = 0
				if (var2-4 > -1):
					if (board[var2-4][var1] > 0): board[var2-4][var1] = 0
				if (var2-5 > -1):
					if (board[var2-5][var1] > 0): board[var2-5][var1] = 0
			
			# end
			
			board[selected_piece.x][selected_piece.y] = 0
			white = !white
			display_board()
			break
	delete_dots()
	state = false
	
	if (selected_piece.x != var2 || selected_piece.y != var1) && (white && board[var2][var1] > 0 || !white && board[var2][var1] < 0):
		selected_piece = Vector2(var2, var1)
		show_options()
		state = true
	
func get_moves(selected : Vector2):
	var _moves = []
	match abs(board[selected.x][selected.y]):
		1: _moves = get_pawn_moves(selected)
		2: _moves = get_knight_moves(selected)
		3: _moves = get_bishop_moves(selected)
		4: _moves = get_rook_moves(selected)
		5: _moves = get_queen_moves(selected)
		6: _moves = get_king_moves(selected)
		
	return _moves

func get_rook_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]
	
	for i in directions:
		var pos = piece_position
		pos += i
		while is_valid_position(pos):
			if is_empty(pos): 
				board[pos.x][pos.y] = 4 if white else -4
				board[piece_position.x][piece_position.y] = 0
				_moves.append(pos)
				board[pos.x][pos.y] = 0
				board[piece_position.x][piece_position.y] = 4 if white else -4
			elif is_enemy(pos):
				var t = board[pos.x][pos.y]
				board[pos.x][pos.y] = 4 if white else -4
				board[piece_position.x][piece_position.y] = 0
				_moves.append(pos)
				board[pos.x][pos.y] = t
				board[piece_position.x][piece_position.y] = 4 if white else -4
				break
			else: break
			
			pos += i
	
	return _moves
	
func get_bishop_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	for i in directions:
		var pos = piece_position
		pos += i
		while is_valid_position(pos):
			if is_empty(pos):
				board[pos.x][pos.y] = 3 if white else -3
				board[piece_position.x][piece_position.y] = 0
				_moves.append(pos)
				board[pos.x][pos.y] = 0
				board[piece_position.x][piece_position.y] = 3 if white else -3
			elif is_enemy(pos):
				var t = board[pos.x][pos.y]
				board[pos.x][pos.y] = 3 if white else -3
				board[piece_position.x][piece_position.y] = 0
				_moves.append(pos)
				board[pos.x][pos.y] = t
				board[piece_position.x][piece_position.y] = 3 if white else -3
				break
			else: break
			
			pos += i
	
	return _moves
	
func get_queen_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	for i in directions:
		var pos = piece_position
		pos += i
		while is_valid_position(pos):
			if is_empty(pos):
				board[pos.x][pos.y] = 5 if white else -5
				board[piece_position.x][piece_position.y] = 0
				_moves.append(pos)
				board[pos.x][pos.y] = 0
				board[piece_position.x][piece_position.y] = 5 if white else -5
			elif is_enemy(pos):
				var t = board[pos.x][pos.y]
				board[pos.x][pos.y] = 5 if white else -5
				board[piece_position.x][piece_position.y] = 0
				_moves.append(pos)
				board[pos.x][pos.y] = t
				board[piece_position.x][piece_position.y] = 5 if white else -5
				break
			else: break
			
			pos += i
	
	return _moves
	
func get_king_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	
	for i in directions:
		var pos = piece_position + i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
				
			
	
	return _moves
	
func get_knight_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(2, 1), Vector2(2, -1), Vector2(1, 2), Vector2(1, -2),
	Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)]
	
	for i in directions:
		var pos = piece_position + i
		if is_valid_position(pos):
			if is_empty(pos):
				board[pos.x][pos.y] = 2 if white else -2
				board[piece_position.x][piece_position.y] = 0
				_moves.append(pos)
				board[pos.x][pos.y] = 0
				board[piece_position.x][piece_position.y] = 2 if white else -2
			elif is_enemy(pos):
				var t = board[pos.x][pos.y]
				board[pos.x][pos.y] = 2 if white else -2
				board[piece_position.x][piece_position.y] = 0
				_moves.append(pos)
				board[pos.x][pos.y] = t
				board[piece_position.x][piece_position.y] = 2 if white else -2
	
	return _moves

func get_pawn_moves(piece_position : Vector2):
	var _moves = []
	var direction
	var is_first_move = false
	
	if white: direction = Vector2(1, 0)
	else: direction = Vector2(-1, 0)
	
	if white && piece_position.x == 1 || !white && piece_position.x == 6: is_first_move = true
	
	if en_passant != null && (white && piece_position.x == 4 || !white && piece_position.x == 3) && abs(en_passant.y - piece_position.y) == 1:
		var pos = en_passant + direction
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		board[en_passant.x][en_passant.y] = 0
		_moves.append(pos)
		board[pos.x][pos.y] = 0
		board[piece_position.x][piece_position.y] = 1 if white else -1
		board[en_passant.x][en_passant.y] = -1 if white else 1
	
	var pos = piece_position + direction
	if is_empty(pos):
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		_moves.append(pos)
		board[pos.x][pos.y] = 0
		board[piece_position.x][piece_position.y] = 1 if white else -1
	
	pos = piece_position + Vector2(direction.x, 1)
	if is_valid_position(pos):
		if is_enemy(pos):
			var t = board[pos.x][pos.y]
			board[pos.x][pos.y] = 1 if white else -1
			board[piece_position.x][piece_position.y] = 0
			_moves.append(pos)
			board[pos.x][pos.y] = t
			board[piece_position.x][piece_position.y] = 1 if white else -1
	pos = piece_position + Vector2(direction.x, -1)
	if is_valid_position(pos):
		if is_enemy(pos):
			var t = board[pos.x][pos.y]
			board[pos.x][pos.y] = 1 if white else -1
			board[piece_position.x][piece_position.y] = 0
			_moves.append(pos)
			board[pos.x][pos.y] = t
			board[piece_position.x][piece_position.y] = 1 if white else -1
		
	pos = piece_position + direction * 2
	if is_first_move && is_empty(pos) && is_empty(piece_position + direction):
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		_moves.append(pos)
		board[pos.x][pos.y] = 0
		board[piece_position.x][piece_position.y] = 1 if white else -1
	
	return _moves

func is_valid_position(pos : Vector2):
	if pos.x >= 0 && pos.x < BOARD_SIZE && pos.y >= 0 && pos.y < BOARD_SIZE: return true
	return false
	
func is_empty(pos : Vector2):
	if board[pos.x][pos.y] == 0: return true
	return false
	
func is_enemy(pos : Vector2):
	if white && board[pos.x][pos.y] < 0 || !white && board[pos.x][pos.y] > 0: return true
	return false
	
func promote(_var : Vector2):
	promotion_square = _var
	white_pieces.visible = white
	black_pieces.visible = !white

func _on_button_pressed(button):
	var num_char = int(button.name.substr(0, 1))
	board[promotion_square.x][promotion_square.y] = -num_char if white else num_char
	white_pieces.visible = false
	black_pieces.visible = false
	promotion_square = null
	display_board()


func _on_deploy_l_pressed() -> void:
	
	if white && board[0][1] == 0:
		if (opt.get_selected_id() == 0 && w_manpower > 0):
			board[0][1] = 1 #pawn
			w_manpower -= 2
			white = false
			display_board() # has to be after every option to avoid manpower gain on invalid button press
		elif (opt.get_selected_id() == 1 && w_manpower > 1):
			board[0][1] = 2 # knight
			w_manpower -= 3
			white = false
			display_board()
		elif (opt.get_selected_id() == 2 && w_manpower > 1):
			board[0][1] = 6 # king
			w_manpower -= 3
			white = false
			display_board()
		elif (opt.get_selected_id() == 3 && w_manpower > 2):
			board[0][1] = 4 # rook
			w_manpower -= 4
			white = false
			display_board()
		elif (opt.get_selected_id() == 4 && w_manpower > 2):
			board[0][1] = 3 # bishop
			w_manpower -= 4
			white = false
			display_board()
		elif (opt.get_selected_id() == 5 && w_manpower > 4):
			board[0][1] = 5 # queen
			w_manpower -= 6
			white = false
			display_board()
	elif !white && board[7][1] == 0: 
		if (opt.get_selected_id() == 0 && b_manpower > 0):
			board[7][1] = -1 #pawn
			b_manpower -= 2
			white = true
			display_board() # has to be after every option to avoid manpower gain on invalid button press
		elif (opt.get_selected_id() == 1 && b_manpower > 1):
			board[7][1] = -2 # knight
			b_manpower -= 3
			white = true
			display_board()
		elif (opt.get_selected_id() == 2 && b_manpower > 1):
			board[7][1] = -6 # king
			b_manpower -= 3
			white = true
			display_board()
		elif (opt.get_selected_id() == 3 && b_manpower > 2):
			board[7][1] = -4 # rook
			b_manpower -= 4
			white = true
			display_board()
		elif (opt.get_selected_id() == 4 && b_manpower > 2):
			board[7][1] = -3 # bishop
			b_manpower -= 4
			white = true
			display_board()
		elif (opt.get_selected_id() == 5 && b_manpower > 4):
			board[7][1] = -5 # queen
			b_manpower -= 6
			white = true
			display_board()
	


func _on_deploy_r_pressed() -> void:
	
	if white && board[0][6] == 0:
		if (opt.get_selected_id() == 0 && w_manpower > 0):
			board[0][6] = 1 #pawn
			w_manpower -= 2
			white = false
			display_board() # has to be after every option to avoid manpower gain on invalid button press
		elif (opt.get_selected_id() == 1 && w_manpower > 1):
			board[0][6] = 2 # knight
			w_manpower -= 3
			white = false
			display_board()
		elif (opt.get_selected_id() == 2 && w_manpower > 1):
			board[0][6] = 6 # king
			w_manpower -= 3
			white = false
			display_board()
		elif (opt.get_selected_id() == 3 && w_manpower > 2):
			board[0][6] = 4 # rook
			w_manpower -= 4
			white = false
			display_board()
		elif (opt.get_selected_id() == 4 && w_manpower > 2):
			board[0][6] = 3 # bishop
			w_manpower -= 4
			white = false
			display_board()
		elif (opt.get_selected_id() == 5 && w_manpower > 4):
			board[0][6] = 5 # queen
			w_manpower -= 6
			white = false
			display_board()
	elif !white && board[7][6] == 0: 
		if (opt.get_selected_id() == 0):
			board[7][6] = -1 #pawn
			b_manpower -= 2
			white = true
			display_board() # has to be after every option to avoid manpower gain on invalid button press
		elif (opt.get_selected_id() == 1 && b_manpower > 1):
			board[7][6] = -2 # knight
			b_manpower -= 3
			white = true
			display_board()
		elif (opt.get_selected_id() == 2 && b_manpower > 1):
			board[7][6] = -6 # king
			b_manpower -= 3
			white = true
			display_board()
		elif (opt.get_selected_id() == 3 && b_manpower > 2):
			board[7][6] = -4 # rook
			b_manpower -= 4
			white = true
			display_board()
		elif (opt.get_selected_id() == 4 && b_manpower > 2):
			board[7][6] = -3 # bishop
			b_manpower -= 4
			white = true
			display_board()
		elif (opt.get_selected_id() == 5 && b_manpower > 4):
			board[7][6] = -5 # queen
			b_manpower -= 6
			white = true
			display_board()


func _on_submit_pressed() -> void:
	var nameIn = $"../CanvasLayer/UI/nameInput"
	var nameLabel = $"../CanvasLayer/UI/PlayerName"
	
	if white: 
		w_name = nameIn.text
		nameLabel.text = w_name
	else: 
		b_name = nameIn.text
		nameLabel.text = b_name
	
	# revolver - every 6 turns the piece you move will kill the 3 in front of it   DONE
	# guillotine - kills all enemy queens                                          DONE
	# crown - turns all of your pawns into kings                                   DONE
	# sword - every 3 turns the piece you move will kill the one in front of it    DONE
	# tower - turns all kings into rooks                                           DONE
	# shield - fills row 2 with pawns                                              DONE
	# factory - gain points more quickly                                           DONE
	# colony - gain 24 points                                                      DONE
	# artillery - every 12 turns destroy 5 pieces in a line in front of you        DONE



func _on_buy_pressed() -> void: 
	# subtracting manpower & redisplay not done
	# plus pixel art & implementation for each ability
	var upShop = $"../CanvasLayer/UI/Upgrades"
	var ID = upShop.get_selected_id()
	if white && w_up < 3:
		if ID == 0 && w_manpower > 9:
			w_list.append(ID) 
			w_up += 1
			w_manpower -= 11
			white = false
			display_board()
		if ID == 1 && w_manpower > 9:
			w_list.append(ID) 
			w_up += 1
			w_manpower -= 11
			
			# kill all enemy queens
			for n in range (8):
				for m in range (8):
					if board[n][m] == -5: 
						board[n][m] = 0
			
			white = false
			display_board()
		if ID == 2 && w_manpower > 9:
			w_list.append(ID)
			w_up += 1 
			w_manpower -= 11
			
			# pawns to kings
			for n in range (8):
				for m in range (8):
					if board[n][m] == 1: 
						board[n][m] = 6
			
			white = false
			display_board()
		if ID == 3 && w_manpower > 7:
			w_list.append(ID)
			w_up += 1 
			w_manpower -= 9
			white = false
			display_board()
		if ID == 4 && w_manpower > 7:
			w_list.append(ID)
			w_up += 1 
			w_manpower -= 9
			
			# kings to rooks
			for n in range (8):
				for m in range (8):
					if board[n][m] == 6: 
						board[n][m] = 4
			
			white = false
			display_board()
		if ID == 5 && w_manpower > 7:
			w_list.append(ID)
			w_up += 1 
			w_manpower -= 9
			
			if (board[1][0] == 0): board[1][0] = 1
			if (board[1][1] == 0): board[1][1] = 1
			if (board[1][2] == 0): board[1][2] = 1
			if (board[1][3] == 0): board[1][3] = 1
			if (board[1][4] == 0): board[1][4] = 1
			if (board[1][5] == 0): board[1][5] = 1
			if (board[1][6] == 0): board[1][6] = 1
			if (board[1][7] == 0): board[1][7] = 1
			
			white = false
			display_board()
		if ID == 6 && w_manpower > 11:
			w_list.append(ID)
			w_up += 1 
			w_manpower -= 13
			white = false
			display_board()
		if ID == 7 && w_manpower > 11:
			w_list.append(ID)
			w_up += 1 
			w_manpower += 12
			white = false
			display_board()
		if ID == 8 && w_manpower > 15:
			w_list.append(ID)
			w_up += 1 
			w_manpower -= 17
			white = false
			display_board()
	elif !white && b_up < 3:
		if ID == 0 && b_manpower > 9:
			b_list.append(ID)
			b_up += 1 
			b_manpower -= 11
			white = true
			display_board()
		if ID == 1 && b_manpower > 9:
			b_list.append(ID)
			b_up += 1  
			b_manpower -= 11
			
			# kill all enemy queens
			for n in range (8):
				for m in range (8):
					if board[n][m] == 5: 
						board[n][m] = 0
			
			white = true
			display_board()
		if ID == 2 && b_manpower > 9:
			b_list.append(ID)
			b_up += 1  
			b_manpower -= 11
			
			# pawns to kings
			for n in range (8):
				for m in range (8):
					if board[n][m] == -1: 
						board[n][m] = -6
			
			white = true
			display_board()
		if ID == 3 && b_manpower > 7:
			b_list.append(ID)
			b_up += 1  
			b_manpower -= 9
			white = true
			display_board()
		if ID == 4 && b_manpower > 7:
			b_list.append(ID)
			b_up += 1  
			b_manpower -= 9
			
			# kings to rooks
			for n in range (8):
				for m in range (8):
					if board[n][m] == -6: 
						board[n][m] = -4
			
			white = true
			display_board()
		if ID == 5 && b_manpower > 7:
			b_list.append(ID)
			b_up += 1  
			b_manpower -= 9
			
			if (board[6][0] == 0): board[6][0] = -1
			if (board[6][1] == 0): board[6][1] = -1
			if (board[6][2] == 0): board[6][2] = -1
			if (board[6][3] == 0): board[6][3] = -1
			if (board[6][4] == 0): board[6][4] = -1
			if (board[6][5] == 0): board[6][5] = -1
			if (board[6][6] == 0): board[6][6] = -1
			if (board[6][7] == 0): board[6][7] = -1
			
			white = true
			display_board()
		if ID == 6 && b_manpower > 11:
			b_list.append(ID)
			b_up += 1  
			b_manpower -= 13
			white = true
			display_board()
		if ID == 7 && b_manpower > 11:
			b_list.append(ID)
			b_up += 1  
			b_manpower += 12
			white = true
			display_board()
		if ID == 8 && b_manpower > 15:
			b_list.append(ID)
			b_up += 1  
			b_manpower -= 17
			white = true
			display_board()


func _on_info_pressed() -> void:
	if (!infoOn):
		var infotxt: Label = $"../CanvasLayer/UI/infotxt"
		infotxt.text = "X"
		infotab.set_visible(true)
		infobacker.set_visible(true)
		infoOn = true
	else:
		var infotxt: Label = $"../CanvasLayer/UI/infotxt"
		infotxt.text = "ⓘ"
		infotab.set_visible(false)
		infobacker.set_visible(false)
		infoOn = false

func w_display_upgrades() -> void:
	
	var UP1 = $"../CanvasLayer/UI/UP1"
	var UP2 = $"../CanvasLayer/UI/UP2"
	var UP3 = $"../CanvasLayer/UI/UP3"
	
	for x in range (3):
		var curUP
		if (x == 0): curUP = UP1
		elif (x == 1): curUP = UP2
		elif (x == 2): curUP = UP3
		if len(w_list) >= x+1:
			if w_list[x] == 0: #REV
				if currentTurn%6 == 0:
					curUP.texture=load("res://Assets/rev6.png")
				elif currentTurn%6 == 1:
					curUP.texture=load("res://Assets/rev1.png")
				elif currentTurn%6 == 2:
					curUP.texture=load("res://Assets/rev2.png")
				elif currentTurn%6 == 3:
					curUP.texture=load("res://Assets/rev3.png")
				elif currentTurn%6 == 4:
					curUP.texture=load("res://Assets/rev4.png")
				elif currentTurn%6 == 5:
					curUP.texture=load("res://Assets/rev5.png")
			elif w_list[x] == 1:
				curUP.texture=load("res://Assets/guillotine.png")
			elif w_list[x] == 2:
				curUP.texture=load("res://Assets/crown.png")
			elif w_list[x] == 3: #SWORD
				if currentTurn%3 == 0:
					curUP.texture=load("res://Assets/sword2.png")
				elif currentTurn%3 == 1:
					curUP.texture=load("res://Assets/sword3.png")
				elif currentTurn%3 == 2:
					curUP.texture=load("res://Assets/sword1.png")
			elif w_list[x] == 4:
				curUP.texture=load("res://Assets/tower.png")
			elif w_list[x] == 5:
				curUP.texture=load("res://Assets/shield.png")
			elif w_list[x] == 6:
				curUP.texture=load("res://Assets/factory.png")
			elif w_list[x] == 7:
				curUP.texture=load("res://Assets/ship.png")
			elif w_list[x] == 8: #ARTY
				if currentTurn%12 == 0:
					curUP.texture=load("res://Assets/arty10.png")
				elif currentTurn%12 == 1:
					curUP.texture=load("res://Assets/arty11.png")
				elif currentTurn%12 == 2:
					curUP.texture=load("res://Assets/arty12.png")
				elif currentTurn%12 == 3:
					curUP.texture=load("res://Assets/arty1.png")
				elif currentTurn%12 == 4:
					curUP.texture=load("res://Assets/arty2.png")
				elif currentTurn%12 == 5:
					curUP.texture=load("res://Assets/arty3.png")
				elif currentTurn%12 == 6:
					curUP.texture=load("res://Assets/arty4.png")
				elif currentTurn%12 == 7:
					curUP.texture=load("res://Assets/arty5.png")
				elif currentTurn%12 == 8:
					curUP.texture=load("res://Assets/arty6.png")
				elif currentTurn%12 == 9:
					curUP.texture=load("res://Assets/arty7.png")
				elif currentTurn%12 == 10:
					curUP.texture=load("res://Assets/arty8.png")
				elif currentTurn%12 == 11:
					curUP.texture=load("res://Assets/arty9.png")
		else:
			curUP.texture=load("res://Assets/blankUpgrade.png") #display nothing/// will need to switch to a blank texture!!!
	
func b_display_upgrades() -> void:
	
	var UP1 = $"../CanvasLayer/UI/UP1"
	var UP2 = $"../CanvasLayer/UI/UP2"
	var UP3 = $"../CanvasLayer/UI/UP3"
	
	for x in range (3):
		var curUP
		if (x == 0): curUP = UP1
		elif (x == 1): curUP = UP2
		elif (x == 2): curUP = UP3
		
		if len(b_list) >= x+1:
			if b_list[x] == 0: # REVOLVER
				if currentTurn%6 == 0:
					curUP.texture=load("res://Assets/rev6.png")
				elif currentTurn%6 == 1:
					curUP.texture=load("res://Assets/rev1.png")
				elif currentTurn%6 == 2:
					curUP.texture=load("res://Assets/rev2.png")
				elif currentTurn%6 == 3:
					curUP.texture=load("res://Assets/rev3.png")
				elif currentTurn%6 == 4:
					curUP.texture=load("res://Assets/rev4.png")
				elif currentTurn%6 == 5:
					curUP.texture=load("res://Assets/rev5.png")
			elif b_list[x] == 1:
				curUP.texture=load("res://Assets/guillotine.png")
			elif b_list[x] == 2:
				curUP.texture=load("res://Assets/crown.png")
			elif b_list[x] == 3: #SWORD
				if currentTurn%3 == 0:
					curUP.texture=load("res://Assets/sword2.png")
				elif currentTurn%3 == 1:
					curUP.texture=load("res://Assets/sword3.png")
				elif currentTurn%3 == 2:
					curUP.texture=load("res://Assets/sword1.png")
			elif b_list[x] == 4:
				curUP.texture=load("res://Assets/tower.png")
			elif b_list[x] == 5:
				curUP.texture=load("res://Assets/shield.png")
			elif b_list[x] == 6:
				curUP.texture=load("res://Assets/factory.png")
			elif b_list[x] == 7:
				curUP.texture=load("res://Assets/ship.png")
			elif b_list[x] == 8: #ARTY
				if currentTurn%12 == 0:
					curUP.texture=load("res://Assets/arty10.png")
				elif currentTurn%12 == 1:
					curUP.texture=load("res://Assets/arty11.png")
				elif currentTurn%12 == 2:
					curUP.texture=load("res://Assets/arty12.png")
				elif currentTurn%12 == 3:
					curUP.texture=load("res://Assets/arty1.png")
				elif currentTurn%12 == 4:
					curUP.texture=load("res://Assets/arty2.png")
				elif currentTurn%12 == 5:
					curUP.texture=load("res://Assets/arty3.png")
				elif currentTurn%12 == 6:
					curUP.texture=load("res://Assets/arty4.png")
				elif currentTurn%12 == 7:
					curUP.texture=load("res://Assets/arty5.png")
				elif currentTurn%12 == 8:
					curUP.texture=load("res://Assets/arty6.png")
				elif currentTurn%12 == 9:
					curUP.texture=load("res://Assets/arty7.png")
				elif currentTurn%12 == 10:
					curUP.texture=load("res://Assets/arty8.png")
				elif currentTurn%12 == 11:
					curUP.texture=load("res://Assets/arty9.png")
		else:
			curUP.texture=load("res://Assets/blankUpgrade.png")

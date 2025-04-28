echo = console.log

# NOTE: this example uses the chess.js library:
# https:#github.com/jhlywa/chess.js

board = null

boardDiv = document.getElementById('board')

game = new Chess()

$status = $ '#status' # jquery används inuti chessBoard
$fen = $ '#fen'
$pgn = $ '#pgn'

FROM = '#baca44' # '#f6f669'
TO   = '#baca44'

onDragStart = (source, piece, position, orientation) ->
	# if game.game_over() then return false
	# if game.turn() == 'w' and piece.search(/^b/) != -1 then false
	# if game.turn() == 'b' and piece.search(/^w/) != -1 then false
	# true
	
onDrop = (source, target) ->
	move = game.move
		from: source
		to: target
		promotion: 'q' # NOTE: always promote to a queen for example simplicity
	
	# illegal move
	if move == null then return 'snapback'

	updateStatus()

# update the board position after the piece snap
# for castling, en passant, pawn promotion
# onSnapEnd = -> board.position game.fen()

onSnapEnd = ->
  clearHighlights()
  fen = game.fen()
  board.position(fen)

  # Hämta senaste drag från Chess-historik
  moves = game.history({ verbose: true })
  if moves.length > 0
    lastMove = moves[moves.length - 1]
    highlightSquare(lastMove.from, FROM )
    highlightSquare(lastMove.to, TO)


clearHighlights = ->
  squares = boardDiv.querySelectorAll('[data-square]')
  for square in squares
    square.style.background = ''

highlightSquare = (square, color = '#a9a9a9') ->
  el = boardDiv.querySelector("[data-square='#{square}']")
  if el
    el.style.background = color

updateStatus = ->
	status = ''
	moveColor = 'White'
	if game.turn() == 'b' then moveColor = 'Black'
	if game.in_checkmate() then status = 'Game over, ' + moveColor + ' is in checkmate.'
	else if game.in_draw() then status = 'Game over, drawn position'
	else 
		status = moveColor + ' to move'
		if game.in_check() then status += ', ' + moveColor + ' is in check'

	$status.html status
	$fen.html game.fen()
	$pgn.html game.pgn()

config = 
	draggable: true
	position: 'start'
	onDragStart: onDragStart
	onDrop: onDrop
	onSnapEnd: onSnapEnd

board = Chessboard 'board', config

updateStatus()
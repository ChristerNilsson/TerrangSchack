VERSION = 71

START_POINT = lat : 59.2702, lon : 18.1303 # Kaninparken

SIZE_PIXEL = 0 # En schackrutas storlek i pixlar
SIZE_METER = 0 # En schackrutas storlek i meter
FACTOR = 1
RADIUS_METER = 0 # meter. Maxavstånd mellan spelaren och target
RADIUS_PIXEL = 0

TIME = [90,30] # base in minutes, increment in seconds
R = 6371e3  # Jordens radie i meter

BEARINGLIST ='01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36'.split ' '
DISTLIST = '2 4 6 8 10 12 14 16 18 20 25 30 35 40 45 50 60 70 80 90 100 120 140 160 180 200 250 300 350 400 450 500 600 700 800 900 1000 1200 1400 1600 1800 2000 2500 3000 3500 4000 4500 5000 6000 7000 8000 9000'.split ' '

#################

LETTERS = 'abcdefgh'
DIGITS = '87654321'

PIECES = {}

chessWrapper = null

targets = []
target = ""

messages = []
sounds = {}
started = false

matrix = {} # WGS84
grid_meter = {}
grid_pixel = {}

echo = console.log
range = _.range

watchID = null
gpsCount = 0

boardDiv = document.getElementById('board')

game = new Chess()

$status = $ '#status' # jquery används inuti chessBoard
$fen = $ '#fen'
$pgn = $ '#pgn'

FROM = '#baca44' # '#f6f669'
TO   = '#baca44'

dump = (msg) ->
	messages.unshift msg # nyaste överst
	if messages.length > 20 then messages.pop() # äldsta droppas

assert = (a,b) -> if a != b then echo 'assert',a,b

closestDistance = (m) =>
	bestDist = 999999
	bestValue = 0
	for d in DISTLIST
		if abs(m-d) < bestDist
			bestDist = abs m-d
			bestValue = d
	bestValue

sayDist = (m) -> # m är en distans, eventuellt i DISTLIST
	dump.store ""
	dump.store "sayDistance #{m} #{JSON.stringify distanceQ}"
	m = closestDistance m
	console.log m,'started'
	distanceSounds[m].play()
	# distanceSounds[m].onended () => console.log m, "ended"

sayDistance = (a,b) -> # a is newer (meter)
	# if a border is crossed, produce a distance
	dump.store "D #{round a,1} #{round b,1}"
	a = round a
	b = round b
	if b == -1 then return a
	for d in DISTLIST
		d = parseInt d
		if a == d and b != d then return d
		if (a-d) * (b-d) < 0 then return d
	""

decreaseQueue = ->
	console.log 'decreaseQueue',bearingQ,distanceQ
	if bearingQ.length == 0
		if distanceQ.length == 0
			return
		else
			console.log 'distance',distanceQ
			msg = _.last distanceQ # latest
			distanceQ.clear() # ignore the rest
			#arr = msg.split ' '
			if general.DISTANCE or msg < LIMIT
				distance = msg
				#errors.push "distance #{msg}"
				if distanceSaid != distance then sayDist distance
				distanceSaid = distance
	else
		console.log 'bearing',bearingQ
		msg = _.last bearingQ # latest
		#errors.push "bearing #{msg}"
		bearingQ.clear() # ignore the rest
		if msg in BEARINGLIST
			bearingSounds[msg].play()


increaseQueue = (p) ->

	# if crossHair == null then return

	# [trgLon,trgLat] = b2w.convert crossHair[0],crossHair[1]

	# a = LatLon p.coords.latitude, p.coords.longitude # newest
	# b = LatLon gpsLat, gpsLon
	# c = LatLon trgLat, trgLon # target
	
	# distac = a.distanceTo c # meters
	# distbc = b.distanceTo c
	# distance = (distac - distbc)/DIST

	bearingac = a.bearingTo c
	#bearingbc = b.bearingTo c
	if distac >= LIMIT then bearing.update bearingac # sayBearing bearingac,bearingbc else ""

	sDistance = sayDistance distac,distbc
	if sDistance != "" then distanceQ.push sDistance # Vi kan inte säga godtyckligt avstånd numera

	if abs(distance) >= 0.5 # update only if DIST detected. Otherwise some beeps will be lost.
		gpsLat = round p.coords.latitude,6
		gpsLon = round p.coords.longitude,6

wp = (p) =>
	#sounds.soundDown.play()
	gpsCount += 1
	matrix.p.lat = p.coords.latitude
	matrix.p.lon = p.coords.longitude
	grid_meter.p = makePoint matrix.s, matrix.p
	grid_pixel.p = [grid_meter.p[0] * FACTOR, grid_meter.p[1] * FACTOR]
	dump "#{gpsCount} #{round bearingBetween matrix.p, matrix[target]}° #{target} #{round distanceBetween(matrix.p, matrix[target])}m #{round p.coords.latitude,6} #{round p.coords.longitude,6}" 

	# om man är inom RADIUS meter från målet, byt mål
	if target == '' then return
	if RADIUS_METER < distanceBetween matrix.p, matrix[target] then return
	if targets.length == 0
		target = ''
		return
	sounds.soundDown.play()
	target = targets.shift()

wperr = (err) -> dump "Fel: #{err.message}"

# window.touchStarted = () ->
# 	echo mouseX, mouseY
# 	if mouseY > 8 * SIZE_PIXEL
# 		if not started
# 			userStartAudio()
# 			startTracking()
# 			started = true
# 		sounds.soundDown.play()
# 	else
# 		letter = LETTERS[round mouseX / SIZE_PIXEL - 0.5]
# 		digit  =  DIGITS[round mouseY / SIZE_PIXEL - 0.5]
# 		echo letter + digit
# 		chessWrapper.clickSquare letter + digit

# 	return false

startTracking = ->

	if not navigator.geolocation
		dump "Geolocation stöds inte i din webbläsare."
		return

	dump "Begär platsdata..."

	watchID = navigator.geolocation.watchPosition wp, wperr,
		enableHighAccuracy: true 
		timeout: 5000 
		maximumAge: 1000

distanceBetween = (p,q) ->
	lat1 = p.lat
	lon1 = p.lon
	lat2 = q.lat
	lon2 = q.lon
	φ1 = lat1 * Math.PI / 180
	φ2 = lat2 * Math.PI / 180
	Δφ = (lat2 - lat1) * Math.PI / 180
	Δλ = (lon2 - lon1) * Math.PI / 180
	a = Math.sin(Δφ / 2) ** 2 + Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) ** 2
	c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
	R * c  # avstånd i meter

bearingBetween = (p,q) ->
	lat1 = p.lat
	lon1 = p.lon
	lat2 = q.lat
	lon2 = q.lon
	φ1 = lat1 * Math.PI / 180
	φ2 = lat2 * Math.PI / 180
	Δλ = (lon2 - lon1) * Math.PI / 180
	y = Math.sin(Δλ) * Math.cos(φ2)
	x = Math.cos(φ1) * Math.sin(φ2) - Math.sin(φ1) * Math.cos(φ2) * Math.cos(Δλ)
	θ = Math.atan2(y, x)
	(θ * 180 / Math.PI + 360) % 360  # bäring i grader

deltaXYBetweenPoints = (p,q) ->
	lat1 = p.lat
	lon1 = p.lon
	lat2 = q.lat
	lon2 = q.lon
	φ1 = lat1 * Math.PI / 180
	φ2 = lat2 * Math.PI / 180
	Δφ = (lat2 - lat1) * Math.PI / 180
	Δλ = (lon2 - lon1) * Math.PI / 180
	dx = R * Δλ * Math.cos((φ1 + φ2) / 2)  # östlig skillnad
	dy = R * Δφ                            # nordlig skillnad
	[dx,-dy] # i meter

makePoint = (p,q) -> deltaXYBetweenPoints p, q

destinationPoint = (lat, lon, distance, bearing) -> 
	φ1 = lat * Math.PI / 180
	λ1 = lon * Math.PI / 180
	θ = bearing * Math.PI / 180
	δ = distance / R

	φ2 = Math.asin(Math.sin(φ1) * Math.cos(δ) + Math.cos(φ1) * Math.sin(δ) * Math.cos(θ))
	λ2 = λ1 + Math.atan2(Math.sin(θ) * Math.sin(δ) * Math.cos(φ1), Math.cos(δ) - Math.sin(φ1) * Math.sin(φ2))

	lat: φ2 * 180 / Math.PI
	lon: λ2 * 180 / Math.PI

initSounds = ->
	sounds = {}
	for name in "soundDown soundUp".split ' '
		sound = loadSound "sounds/#{name}.wav"
		sound.setVolume 1.0
		sound.pan 0
		sounds[name] = sound

# window.preload = ->
# 	initSounds()
# 	for piece in "KQRBNP"
# 		PIECES["B#{piece}"] = loadImage "./pieces/B#{piece}.svg"
# 		PIECES["W#{piece}"] = loadImage "./pieces/W#{piece}.svg"

window.setup = ->

	SIZE_PIXEL = window.windowWidth/8 # En schackrutas storlek i pixlar
	SIZE_METER = 10 # En schackrutas storlek i meter
	FACTOR = SIZE_PIXEL / SIZE_METER
	RADIUS_METER = 0.25 * SIZE_METER # meter. Maxavstånd mellan spelaren och target
	RADIUS_PIXEL = 0.25 * SIZE_PIXEL

	d = window.windowWidth - 2
	[x1,y1] = [0.5*d, 0.5*d]
	[x2,y2] = [3*SIZE_PIXEL, 8*SIZE_PIXEL]
	drawSvgLine x1,y1,x2,y2,'black',2
	drawSvgCircle x1,y1, RADIUS_PIXEL, 'yellow'
	drawSvgCircle x2,y2, RADIUS_PIXEL, 'red'

# window.setup = ->
# 	createCanvas windowWidth-5, windowHeight-5, document.getElementById "canvas"

# 	rectMode CENTER

# 	grid_meter.s = [3.5*SIZE_METER, 3.5*SIZE_METER] # origo, samlingspunkt
# 	grid_pixel.s = [3.5*SIZE_PIXEL, 3.5*SIZE_PIXEL] # origo, samlingspunkt

# 	grid_meter.p = [0.5*SIZE_METER, 0.5*SIZE_METER] # origo, samlingspunkt
# 	grid_pixel.p = [0.5*SIZE_PIXEL, 0.5*SIZE_PIXEL] # origo, samlingspunkt

# 	textAlign CENTER,CENTER
# 	textSize 0.04 * height
# 	noFill()
# 	frameRate 2

# 	matrix.s = START_POINT 
# 	arr = (destinationPoint matrix.s.lat, matrix.s.lon, i * SIZE_METER, 90 for i in [0...8])

# 	for i in range 8
# 		for j in range 8
# 			key = "#{LETTERS[i]}#{DIGITS[j]}"
# 			matrix[key] = destinationPoint arr[i].lat, arr[i].lon, j * SIZE_METER, 180
# 			grid_pixel[key] = [i * SIZE_PIXEL, j * SIZE_PIXEL]
# 			grid_meter[key] = [i * SIZE_METER, j * SIZE_METER]

# 	targets = _.keys matrix
# 	targets = 's a1 a8 h1 h8 p'.split ' '
# 	# targets = _.shuffle targets
# 	echo targets
# 	target = targets.shift()

# 	# NW hörnet
# 	lat = (matrix.a8.lat + matrix.b7.lat) / 2
# 	lon = (matrix.a8.lon + matrix.b7.lon) / 2
# 	matrix.p = {lat, lon}
# 	# grid_pixel.p = [0.5*SIZE_PIXEL, 0.5*SIZE_PIXEL]
# 	# grid_meter.p = [grid_pixel.p[0] / FACTOR, grid_pixel.p[1] / FACTOR]

# 	dump "V:#{VERSION} S:#{SIZE_METER}m R:#{RADIUS_METER}m #{START_POINT.lat} #{START_POINT.lon}"  

# 	echo 'matrix',matrix
# 	echo 'grid_meter',grid_meter
# 	echo 'grid_pixel',grid_pixel

# 	# assert 224, round distanceBetween matrix.c1, matrix.d3
# 	# assert  27, round bearingBetween matrix.c1, matrix.d3
# 	# assert  90, round bearingBetween matrix.c3, matrix.d3
# 	# assert 108, round bearingBetween matrix.a4, matrix.d3
# 	# assert 214, round bearingBetween matrix.c4, matrix.a1
# 	# assert 297, round bearingBetween matrix.d2, matrix.b3

# window.draw = ->
# 	background 0
# 	OX = (width - 7*SIZE_PIXEL) / 2 # offset x
# 	OY = 2*RADIUS_PIXEL # offset y

# 	keys = Object.keys(grid_pixel).sort()
# 	for key in keys
# 		[x,y] = grid_pixel[key]
# 		stroke 'white'
# 		if key == target then stroke 'red'
# 		if key == 'p' then stroke 'yellow'
# 		if key in [target, 'p'] 
# 			noFill()
# 			strokeWeight 2
# 			circle OX + x, OY + y, 2*RADIUS_PIXEL
# 		else
# 			letter = LETTERS.indexOf key[0]
# 			digit = DIGITS.indexOf key[1]
# 			fill if (letter+digit) % 2 == 0 then 'gray' else 'lightgray'
# 			if chessWrapper.state.from == LETTERS[letter] + DIGITS[digit]
# 				fill 'green'
# 			noStroke()
# 			rect OX + x, OY + y, 4*RADIUS_PIXEL

# 	stroke 'black'
# 	[px,py] = grid_pixel.p
# 	[tx,ty] = grid_pixel[target]
# 	line OX + px, OY + py, OX + tx, OY + ty

# 	noStroke()
# 	push()
# 	fill '#444'
# 	textSize 0.02 * height
# 	for i in range 8
# 		text LETTERS[i], 10 + i*SIZE_PIXEL, 55 + 7 * SIZE_PIXEL # letters
# 		text DIGITS[i],  width-8,           10 + (i+0.043)*SIZE_PIXEL # digits
# 	pop()

# 	push()
# 	fill 'yellow'
# 	textSize 2*0.03 * height
# 	textAlign LEFT
# 	text round(bearingBetween(matrix.p, matrix[target])) + '°', 0, 8.5 * SIZE_PIXEL
# 	textAlign CENTER
# 	text target, 0.5 * width, 8.5 * SIZE_PIXEL
# 	textAlign RIGHT
# 	text round(distanceBetween(matrix.p, matrix[target])) + 'm', width, 8.5 * SIZE_PIXEL
# 	pop()

# 	push()
# 	fill '#777'
# 	textAlign LEFT
# 	textSize 0.034 * height
# 	for i in range messages.length
# 		text messages[i], 0, 9.3 * SIZE_PIXEL + i * 0.04 * height
# 	pop()

# 	letters = "RNBQKBNR"
# 	for i in range 8
# 		image PIECES['B'+letters[i]], i*SIZE_PIXEL, 0*SIZE_PIXEL, SIZE_PIXEL, SIZE_PIXEL
# 		image PIECES['BP'],           i*SIZE_PIXEL, 1*SIZE_PIXEL, SIZE_PIXEL, SIZE_PIXEL
# 		image PIECES['WP'],           i*SIZE_PIXEL, 6*SIZE_PIXEL, SIZE_PIXEL, SIZE_PIXEL
# 		image PIECES['W'+letters[i]], i*SIZE_PIXEL, 7*SIZE_PIXEL, SIZE_PIXEL, SIZE_PIXEL

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

# Rita en cirkel i SVG på absolut koordinat (x, y)
drawSvgCircle = (x, y, radius = 10, color = 'red') ->
  svg = document.getElementById('overlay')
  circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle')
  circle.setAttribute('cx', x)
  circle.setAttribute('cy', y)
  circle.setAttribute('r', radius)
  circle.setAttribute('fill', color)
  svg.appendChild(circle)

# Rita en linje från (x1, y1) till (x2, y2)
drawSvgLine = (x1, y1, x2, y2, color = 'blue', width = 4) ->
  svg = document.getElementById('overlay')
  line = document.createElementNS('http://www.w3.org/2000/svg', 'line')
  line.setAttribute('x1', x1)
  line.setAttribute('y1', y1)
  line.setAttribute('x2', x2)
  line.setAttribute('y2', y2)
  line.setAttribute('stroke', color)
  line.setAttribute('stroke-width', width)
  line.setAttribute('stroke-linecap', 'round')
  svg.appendChild(line)

class ChessWrapper
	constructor: () ->
		@chess = new Chess()

		moves = @chess.moves verbose: true
		echo moves.map (m) -> "#{m.from}#{m.to}"

		@state =
			from: null
			to: null
			fromReached: false
			toReached: false
			centerReached: false

	# highlightFrom : () ->
	# highlightTo : () ->

	clickSquare : (square) ->
		if not @state.from
			@state.from = square
			# @highlightFrom square
		else if not @state.to
			@state.to = square
			if @validateMove @state.from, @state.to
				# @highlightTo square
				console.log "Drag godkänt, vänta på fysiska besök"
			else
				console.log "Ogiltigt drag, börjar om"
				# @resetState()

	validateMove : (from, to) ->
		moves = @chess.moves square: from, verbose: true
		moves.some (m) -> m.to is to

	resetState : ->
		@state =
			from: null
			to: null
			fromReached: false
			toReached: false
			centerReached: false
		@clearHighlights()

	gpsPositionReached : (squareName) ->
		if squareName is @state.from and not @state.fromReached
			@state.fromReached = true
			console.log "Från-ruta besökt"
		else if squareName is @state.to and @state.fromReached and not @state.toReached
			@state.toReached = true
			console.log "Till-ruta besökt"
		else if squareName is "center" and @state.toReached and not @state.centerReached
			@state.centerReached = true
			console.log "Centrumrutan besökt"
			@completeMove()

	completeMove : ->
		@chess.move from: @state.from, to: @state.to
		updateBoard()
		@toggleClock()
		@resetState()

	toggleClock : ->
		console.log "Schackklocka växlas!"

# board = Chessboard 'board','start'
# echo board

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
  echo 'onSnapEnd'
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

config = 
	draggable: true
	position: 'start'
	onDragStart: onDragStart
	onDrop: onDrop
	onSnapEnd: onSnapEnd

board = Chessboard 'board', config

echo board

getOverlaySize = (element) ->
  elem = document.getElementById(element)
  echo elem
  rect = elem.getBoundingClientRect()
  echo rect
  rect

getOverlaySize 'board'
getOverlaySize 'overlay'


$('#startBtn').on 'click', board.start
$('#clearBtn').on 'click', board.clear

# chessWrapper = new ChessWrapper
# echo chessWrapper

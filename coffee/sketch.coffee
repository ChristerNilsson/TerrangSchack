VERSION = 101

START_POINT = lat : 59.27, lon : 18.13 # Kaninparken. Brädets mittpunkt
SIZE_METER = 10 # En schackrutas storlek i meter

# Dessa beräknas i setup.
SIZE_PIXEL = 0 # En schackrutas storlek i pixlar
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

targets = [] # t ex ["e2","e4","zenter"] from to zenter square
target = "zenter"

messages = []
sounds = {}
started = false

wgs = {} # WGS84 {lat,lon}
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

# visar vilket drag som utförts.
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
	# sounds.soundDown.play()
	gpsCount += 1
	if not wgs.p then wgs.p = {}
	wgs.p.lat = p.coords.latitude
	wgs.p.lon = p.coords.longitude
	grid_meter.p = makePoint wgs.origin, wgs.p
	grid_pixel.p = [grid_meter.p[0] * FACTOR, grid_meter.p[1] * FACTOR]
	dump "#{gpsCount} • #{round bearingBetween wgs.p, wgs[target]}° • #{target} • #{round distanceBetween(wgs.p, wgs[target])}m" # • #{round p.coords.latitude,6} • #{round p.coords.longitude,6}" 
	
	# om man är inom RADIUS meter från målet, byt mål
	if target == '' then return
	if RADIUS_METER < distanceBetween wgs.p, wgs[target] then return
	if targets.length == 0
		target = ''
		clearOverlay()
		return
	sounds.soundDown.play()
	target = targets.shift()

wperr = (err) -> dump "Fel: #{err.message}"

startTracking = ->

	if not navigator.geolocation
		dump "Geolocation stöds inte i din webbläsare."
		return

	# dump "GPS startad"

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

window.touchStarted = () ->
	# dump 'touchStarted'
	if started then return false
	messages = []
	userStartAudio()
	startTracking()
	started = true
	sounds.soundDown.play()
	return false 

window.preload = ->
	initSounds()

window.setup = ->
	h = window.windowHeight - window.windowWidth

	SIZE_PIXEL = round 976/8 # En schackrutas storlek i pixlar. integer!
	createCanvas window.windowWidth-20, 700, document.getElementById "canvas"

	FACTOR = SIZE_PIXEL / SIZE_METER
	RADIUS_METER = 0.25 * SIZE_METER # meter. Maxavstånd mellan spelaren och target
	RADIUS_PIXEL = 0.25 * SIZE_PIXEL

	dump "SIZE_PIXEL #{SIZE_PIXEL}"
	dump "FACTOR #{FACTOR}"

	wgs.origin = destinationPoint START_POINT.lat, START_POINT.lon, sqrt(2) * 4 * SIZE_METER, 315
	grid_meter.origin = [0,0]
	grid_pixel.origin = [0,0]

	grid_meter.zenter = [4*SIZE_METER, 4*SIZE_METER] # samlingspunkt, brädets mittpunkt
	grid_pixel.zenter = [4*SIZE_PIXEL, 4*SIZE_PIXEL] # samlingspunkt, brädets mittpunkt

	frameRate 30

	wgs.zenter = START_POINT
	arr = (destinationPoint wgs.zenter.lat, wgs.zenter.lon, (i-3.5) * SIZE_METER, 90 for i in [0...8])

	for i in range 8
		for j in range 8
			key = "#{LETTERS[i]}#{DIGITS[j]}"
			wgs[key] = destinationPoint arr[i].lat, arr[i].lon, (j-3.5) * SIZE_METER, 180
			grid_pixel[key] = [(i+0.5) * SIZE_PIXEL, (j+0.5) * SIZE_PIXEL]
			grid_meter[key] = [(i+0.5) * SIZE_METER, (j+0.5) * SIZE_METER]


	echo 'wgs',wgs
	echo 'grid_meter',grid_meter
	echo 'grid_pixel',grid_pixel

	targets = []
	target = "zenter"

	dump "V:#{VERSION} S:#{SIZE_METER}m R:#{RADIUS_METER}m #{START_POINT.lat} #{START_POINT.lon}"  
	dump "#{width} x #{height} #{SIZE_PIXEL}"
	dump 'Klicka här för att starta!'

	# assert 224, round distanceBetween wgs.c1, wgs.d3
	# assert  27, round bearingBetween wgs.c1, wgs.d3
	# assert  90, round bearingBetween wgs.c3, wgs.d3
	# assert 108, round bearingBetween wgs.a4, wgs.d3
	# assert 214, round bearingBetween wgs.c4, wgs.a1
	# assert 297, round bearingBetween wgs.d2, wgs.b3

testPattern = ->
	# clearOverlay()
	for i in range 9
		for j in range 9
			x = i * SIZE_PIXEL
			y = j * SIZE_PIXEL
			drawSvgLine x,y-8,x,y+8,'black',1
			drawSvgLine x-8,y,x+8,y,'black',1

window.draw = ->
	background 'black'

	push()
	textSize 0.4 * SIZE_PIXEL
	textAlign CENTER,TOP
	fill 'white'
	for i in range messages.length
		text messages[i], 0.5 * width, (i+2.5) * 0.4 * SIZE_PIXEL
	pop()

	if target == "" or not wgs.p or not wgs[target] then return

	fill 255
	push()
	textSize 0.8 * SIZE_PIXEL
	fill 'yellow'
	textAlign LEFT,CENTER
	text round(bearingBetween(wgs.p, wgs[target])) + '°', 0.01*width, 0.55 * SIZE_PIXEL
	textAlign CENTER
	text target, 0.5 * width, 0.55 * SIZE_PIXEL
	textAlign RIGHT
	text round(distanceBetween(wgs.p, wgs[target])) + 'm', 0.99*width, 0.55 * SIZE_PIXEL
	pop()

	showTarget target,"p"

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

showTarget = (p,q) ->
	[x1,y1] = grid_pixel[target]
	[x2,y2] = grid_pixel.p
	# dump "#{target} #{round x1} #{round y1} #{round x2} #{round y2}"
	clearOverlay()
	drawSvgLine x1,y1,x2,y2,'black',2
	drawSvgCircle x1,y1, RADIUS_PIXEL, 'yellow'
	drawSvgCircle x2,y2, RADIUS_PIXEL, 'red'

	x = x1
	y = y1
	d = RADIUS_PIXEL
	drawSvgLine x,y-d,x,y+d,'black',1
	drawSvgLine x-d,y,x+d,y,'black',1

clearOverlay = ->
  svg = document.getElementById('overlay')
  while svg.firstChild
    svg.removeChild(svg.firstChild)

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

# onDragStart = (source, piece, position, orientation) ->
# 	# if game.game_over() then return false
# 	# if game.turn() == 'w' and piece.search(/^b/) != -1 then false
# 	# if game.turn() == 'b' and piece.search(/^w/) != -1 then false
# 	# true
	
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
  dump "#{lastMove.from}-#{lastMove.to}"

  targets = [lastMove.from, lastMove.to, "zenter"]
  target = targets.shift()
  echo target,targets

clearHighlights = ->
  squares = boardDiv.querySelectorAll('[data-square]')
  for square in squares
    square.style.background = ''

highlightSquare = (square, color = '#a9a9a9') ->
  el = boardDiv.querySelector("[data-square='#{square}']")
  if el
    el.style.background = color

config = 
	draggable: false
	position: 'start'
	# onDragStart: onDragStart
	# onDrop: onDrop
	# onSnapEnd: onSnapEnd

board = Chessboard 'board', config

getOverlaySize = (element) ->
  elem = document.getElementById(element)
  elem.getBoundingClientRect()

#$('#startBtn').on 'click', board.start
#$('#clearBtn').on 'click', () ->
#	clearOverlay()
#	target = targets.shift()

selectedSquare = null

# boardDiv = document.getElementById('board')


# boardDiv.addEventListener('click', (event) => {
#   const el = event.target.closest('.square-55d63');
#   if (!el) return;
#   const square = el.getAttribute('data-square');
#   if (square) handleInput(square);
# });



handleClick = (event) ->
#   dump 'handleClick'
  clickTarget = event.target.closest '.square-55d63'

#   clickTarget = event.target
  echo 'clickTarget',clickTarget

  return unless clickTarget.classList.contains 'square-55d63'

  clickSquare = clickTarget.getAttribute 'data-square'
  echo 'clickSquare',clickSquare

  if selectedSquare
    # Försök göra draget
    move = game.move
      from: selectedSquare
      to: clickSquare
      promotion: 'q'
    
    if move
      board.position game.fen()
    #   board.flip()
      clearHighlights()
      clearOverlay()
      highlightSquare move.from, '#baca44'
      highlightSquare move.to, '#baca44'
      dump "#{move.from}-#{move.to} #{target} #{targets}"


      targets = [move.from, move.to, "zenter"]
      target = targets.shift()

    else
      dump "Ogiltigt drag"

    selectedSquare = null
  else
    selectedSquare = clickSquare
    clearHighlights()
    clearOverlay()
    highlightSquare clickSquare, '#baca44'

  echo 'selectedSquare',selectedSquare

boardDiv.addEventListener 'click', handleClick
boardDiv.addEventListener 'touchstart', handleClick

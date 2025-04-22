VERSION = 38

START_POINT = lat: 59.271667, lon: 18.151778 # knixen på kraftledningen NO Brotorp
SIZE_PIXEL = 200 # En schackrutas storlek i pixlar
SIZE_METER = 50 # En schackrutas storlek i meter
FACTOR = SIZE_PIXEL / SIZE_METER

RADIUS = 2 # meter. Maxavstånd mellan spelaren och target

FILES = 'efgh' # De 16 rutor man har hand om
RANKS = '4321'

R = 6371e3  # Jordens radie i meter

targets = []
target = ""

messages = []
sounds = {}
started = false

matrix = {} # WGS84
grid_meter = {} # meter
grid_pixel = {} # pixel
grid_meter.s = [0,0] # origo, samlingspunkt
grid_pixel.s = [0,0] # origo, samlingspunkt

echo = console.log
range = _.range

dump = (msg) ->
	messages.unshift msg # nyaste överst
	if messages.length > 20 then messages.pop() # äldsta droppas

assert = (a,b) -> if a != b then echo 'assert',a,b

watchID = null
gpsCount = 0

wp = (p) =>
	#sounds.soundDown.play()
	gpsCount += 1
	matrix.p.lat = p.coords.latitude
	matrix.p.lon = p.coords.longitude
	grid_meter.p = makePoint matrix.s, matrix.p
	grid_pixel.p = [grid_meter.p[0] * FACTOR, grid_meter.p[1] * FACTOR]
	dump "#{gpsCount} #{round bearingBetween matrix.p, matrix[target]}° #{target} #{round distanceBetween(matrix.p, matrix[target]),1}m #{round p.coords.latitude,6} #{round p.coords.longitude,6}" 

	# om man är inom RADIUS meter från målet, byt mål
	if target == '' then return
	if RADIUS < distanceBetween matrix.p, matrix[target] then return
	if targets.length == 0
		target = ''
		return
	sounds.soundDown.play()
	target = targets.shift()

wperr = (err) -> dump "Fel: #{err.message}"

window.touchStarted = ->
	if not started
		userStartAudio()
		startTracking()
		started = true
	sounds.soundDown.play()
	return false

startTracking = ->

	if not navigator.geolocation
		dump "Geolocation stöds inte i din webbläsare."
		return

	dump "Begär platsdata..."

	watchID = navigator.geolocation.watchPosition wp, wperr,
		enableHighAccuracy: true 
		timeout: 5000 
		maximumAge: 1000

# document.querySelector('#startBtn').addEventListener 'click', startTracking

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
	[dx,dy] # i meter

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

window.preload = ->
	initSounds()

window.setup = ->
	createCanvas windowWidth-5, windowHeight-5, document.getElementById "canvas"
	textAlign CENTER,CENTER
	textSize 0.3 * SIZE_PIXEL
	noStroke()
	frameRate 2

	# sounds.soundUp.play()

	matrix.s = START_POINT 
	arr = (destinationPoint matrix.s.lat, matrix.s.lon, (i+0.5) * SIZE_METER, 90 for i in [0...4])
	# echo arr

	for i in [0...4]
		for j in [0...4]
			key = "#{FILES[i]}#{RANKS[j]}"
			matrix[key] = destinationPoint arr[i].lat, arr[i].lon, (j+0.5) * SIZE_METER, 180
			grid_pixel[key] = [(i+0.5) * SIZE_PIXEL, (j+0.5) * SIZE_PIXEL]
			grid_meter[key] = [(i+0.5) * SIZE_METER, (j+0.5) * SIZE_METER]

	targets = _.keys matrix
	targets = 'h1 g1 f1 e1 e2 f2 g2 h2 h3 g3 f3 e3 e4 f4 g4 h4 s p'.split ' '
	# targets = _.shuffle targets
	echo targets
	target = targets.shift()

	# kvadrantens mittpunkt
	lat = (matrix.f3.lat + matrix.g2.lat) / 2
	lon = (matrix.f3.lon + matrix.g2.lon) / 2
	matrix.p = {lat, lon}
	grid_pixel.p = [2*SIZE_PIXEL,-2*SIZE_PIXEL]
	grid_meter.p = [grid_pixel.p[0] / FACTOR, grid_pixel.p[1] / FACTOR]

	dump 'Version: ' + VERSION

	echo 'matrix',matrix
	echo 'grid_meter',grid_meter
	echo 'grid_pixel',grid_pixel

	# assert 224, round distanceBetween matrix.c1, matrix.d3
	# assert  27, round bearingBetween matrix.c1, matrix.d3
	# assert  90, round bearingBetween matrix.c3, matrix.d3
	# assert 108, round bearingBetween matrix.a4, matrix.d3
	# assert 214, round bearingBetween matrix.c4, matrix.a1
	# assert 297, round bearingBetween matrix.d2, matrix.b3

window.draw = ->
	background 0
	fill 255
	# scale 2
	SP2 = SIZE_PIXEL/2
	stroke 255
	[px,py] = grid_pixel.p
	[tx,ty] = grid_pixel[target]
	line 10 + px, 10 - py, 10 + tx, 10 + ty
	noStroke()

	for key of grid_pixel
		[x,y] = grid_pixel[key]
		fill 'white'
		if key == target then fill 'red'
		if key == 'p'
			fill 'yellow'
			circle 10 + x, 10 - y, 0.1 * SP2
		else
			# text key, 50+x, 50+y
			circle 10 + x, 10 + y, 0.1 * SP2

	fill 'green'
	for i in [0...4]
		text FILES[i], 10 + SP2 + i*SIZE_PIXEL, 10 + 0.25 * SIZE_PIXEL
		text RANKS[i], 10 + SP2/2,              10 + SP2 + i*SIZE_PIXEL

	text round(bearingBetween(matrix.p, matrix[target])) + '°',10+0.5*SIZE_PIXEL,3.9*SIZE_PIXEL
	text target, 10+2*SIZE_PIXEL, 3.9*SIZE_PIXEL
	text round(distanceBetween(matrix.p, matrix[target])) + 'm',10+3.5*SIZE_PIXEL,3.9*SIZE_PIXEL

	push()
	textAlign "left"
	textSize 0.2 * SIZE_PIXEL
	for i in range messages.length
		text messages[i], 0.1*SIZE_PIXEL, 4.2*SIZE_PIXEL + i*0.2 * SIZE_PIXEL
	pop()








# class Player
# 	constructor : (@name, @tx=4*SIZE, @ty=4*SIZE) ->
# 		@speed = SPEED
# 		@pos = createVector 4*SIZE,4*SIZE
# 		@target = new Square createVector @tx, @ty
# 		@home = @target
# 		@squares = [] # lista med Square som ej påbörjats
# 		@trail = []
# 		@n = 0
# 		@distance = 0
# 		@assists = 0

# 	closest : ->
# 		if @squares.length == 0 then return null
# 		bestDist = 99999
# 		bestSq = @squares[0]
# 		for square in @squares
# 			d = p5.Vector.dist square.pos, @pos
# 			if d < bestDist
# 				bestDist = d
# 				bestSq = square
# 		bestSq

# 	add : (sq) ->
# 		@squares.push sq
# 		@target = @closest()

# 	drawTail : ->
# 		if @n % (10/SPEED) == 0 then @trail.push createVector @pos.x, @pos.y
# 		@n += 1
# 		if @trail.length > MAXTRAIL then @trail.shift()
# 		stroke 'black'
# 		for i in [0...@trail.length]
# 			size = map i, 0, @trail.length - 1, 5,15
# 			noFill()
# 			ellipse @trail[i].x, @trail[i].y, size, size

# 	draw : () ->
# 		target = @target.pos
# 		dx = target.x - @pos.x
# 		dy = target.y - @pos.y
# 		d = sqrt dx*dx+dy*dy

# 		stroke 'black'

# 		# if @name in 'ABCD'
# 		line target.x, target.y, @pos.x, @pos.y

# 		step = p5.Vector.sub(target, @pos).setMag min @speed, d
# 		if d < @speed # target nådd
# 			if not @target.done
# 				@target.done = true
# 				@target.carrier = @name

# 				# Skicka draget om både start.done och slut.done
# 				for key of games
# 					g = games[key]
# 					if g.move and g.move.start.done and g.move.stopp.done						
# 						duration = (15/SPEED * (performance.now() - g.move.start.time)/1000)

# 						if g.index % 2 == 0 then g.duration += duration
# 						if g.move.start.carrier == g.move.stopp.carrier
# 							carriers = g.move.start.carrier
# 						else 
# 							carriers = g.move.start.carrier + g.move.stopp.carrier

# 						if g.move.start.carrier in 'ABCD'
# 							# echo 'assists: ',g.move.start.carrier,g.move.stopp.carrier
# 							players[g.move.start.carrier].assists += 1
# 							players[g.move.stopp.carrier].assists += 1
# 							# echo g.name, g.move.uci, @name, g.move.start.carrier + g.move.stopp.carrier

# 						g.chess.move { from: g.move.uci.slice(0, 2), to: g.move.uci.slice(2, 4) }

# 						td = document.getElementById("SEL#{g.name}")
# 						td.innerHTML += "#{g.san_moves[g.chess.history().length-1]} by #{carriers} (#{duration.toFixed()} s)<br>"

# 						document.getElementById("board#{g.name}").innerHTML = shrink g.chess.ascii()
# 						updateInfo g.name, @

# 						g.queue.push g.move
# 						g.move = null
# 						if g.initMove() == false
# 							stoppTime = Date.now()
# 							# echo 'done', (stoppTime-startTime)/1000

# 			@squares = _.filter @squares, (sq) -> sq.done == false

# 			# hämta närmaste uppdrag om sådant finns
# 			if @squares.length > 0
# 				@target = @closest()
# 				d = p5.Vector.dist @pos,@target.pos
# 				@distance += d

# 		@pos.add step

# 		for square in @squares
# 			if @name in 'ABCD'
# 				fill 'red'
# 			else
# 				fill 'black'
# 			circle square.pos.x, square.pos.y, 10

# 		# if @name in 'ABCD'
# 		@drawTail()
# 		if @name in 'ABCD' then fill 'yellow' else fill 'black'
# 		strokeWeight 1
# 		circle @pos.x,@pos.y,0.4*SIZE
# 		if @name in 'ABCD' then fill 'black' else fill 'yellow'
# 		noStroke()
# 		# fill 'black'
# 		text @name, @pos.x, @pos.y

# uci2pos = (uci) -> # t ex e2e4 => [[225,75],[225,175]]
# 	startx = uci[0]
# 	starty = uci[1]
# 	stoppx = uci[2]
# 	stoppy = uci[3]
# 	result = []
# 	x = FILES.indexOf startx
# 	y = 7 - RANKS.indexOf starty
# 	result.push createVector SIZE/2 + SIZE*x, SIZE/2 + SIZE*y
# 	x = FILES.indexOf stoppx
# 	y = 7 - RANKS.indexOf stoppy
# 	result.push createVector SIZE/2 + SIZE*x, SIZE/2 + SIZE*y
# 	result

# class Game
# 	constructor : (@name, pgn, @link) ->
# 		@chess = new Chess()
# 		@chess.load_pgn pgn
# 		@san_moves = @chess.history() # [Nf3, ...]
# 		@uci_moves = (move.from + move.to for move in @chess.history({ verbose: true })) # [g1f3, ...]
# 		@move = null
# 		@queue = []
# 		@duration = 0
# 		@chess.reset()
# 		@index = -1
# 		document.getElementById("link#{@name}").innerHTML = "<a href=\"#{@link}\" target=\"_blank\">Link</a>"

# 	initMove : ->
# 		if @index >= @uci_moves.length - 1 then return false
# 		@index += 1
# 		if @move != null 
# 			#echo 'too quick!'
# 			return false
# 		@move = new Move @uci_moves[@index], @name

# 		start = @move.uci.slice 0,2
# 		stopp = @move.uci.slice 2,4

# 		antal = 'ABCD'.indexOf @name
# 		for i in [0...antal] 
# 			start = rotate start
# 			stopp = rotate stopp

# 		if @index % 2 == 0
# 			a = "1234"
# 			b = "5678"
# 			# Dela ut start och stopp till rätt spelare beroende på kvadrant
# 			if start[0] in "abcd" and start[1] in a then players.A.add @move.start
# 			if start[0] in "efgh" and start[1] in a then players.B.add @move.start
# 			if start[0] in "abcd" and start[1] in b then players.C.add @move.start
# 			if start[0] in "efgh" and start[1] in b then players.D.add @move.start

# 			if stopp[0] in "abcd" and stopp[1] in a then players.A.add @move.stopp
# 			if stopp[0] in "efgh" and stopp[1] in a then players.B.add @move.stopp
# 			if stopp[0] in "abcd" and stopp[1] in b then players.C.add @move.stopp
# 			if stopp[0] in "efgh" and stopp[1] in b then players.D.add @move.stopp

# 		else
# 			a = "1234"
# 			b = "5678"
# 			# Hantera motståndaren
# 			# Dela ut start och stopp till rätt spelare beroende på kvadrant
# 			if start[0] in "abcd" and start[1] in a then players.G.add @move.start
# 			if start[0] in "abcd" and start[1] in b then players.E.add @move.start
# 			if start[0] in "efgh" and start[1] in a then players.H.add @move.start
# 			if start[0] in "efgh" and start[1] in b then players.F.add @move.start

# 			if stopp[0] in "abcd" and stopp[1] in a then players.G.add @move.stopp
# 			if stopp[0] in "abcd" and stopp[1] in b then players.E.add @move.stopp
# 			if stopp[0] in "efgh" and stopp[1] in a then players.H.add @move.stopp
# 			if stopp[0] in "efgh" and stopp[1] in b then players.F.add @move.stopp
# 		true

# class Square 
# 	constructor : (@pos, @uci="", @carrier="") -> # Vector
# 		@done = false
# 		@time = performance.now()
	
# # rotate = (sq) -> FILES[8-sq[1]] + String 1 + FILES.indexOf sq[0]
# # echo "g3" == rotate "c2"
# # echo "h1" == rotate "a1"
# # echo "h8" == rotate rotate "a1"
# # echo "a8" == rotate rotate rotate "a1"
# # echo "a1" == rotate rotate rotate rotate "a1"

# # coordinates = (sq) ->
# # 	x = FILES.indexOf sq[0]
# # 	y = RANKS.indexOf sq[1]
# # 	[x, 7-y]
# # echo _.isEqual [4,4], coordinates "e4"
# # echo _.isEqual [0,7], coordinates "a1"

# # toVector = ([x,y]) ->
# # 	createVector SIZE/2 + SIZE*x, SIZE/2 + SIZE*y
# # echo toVector [3,4]

# class Move
# 	constructor : (@uci, @name) -> # e2e4, B
# 		antal = "ABCD".indexOf @name
# 		start = @uci.slice 0,2
# 		stopp = @uci.slice 2,4
# 		for i in [0...antal]
# 			start = rotate start
# 			stopp = rotate stopp
# 		start = toVector coordinates start
# 		stopp = toVector coordinates stopp
# 		@pos = [start, stopp]
# 		@start = new Square start, @uci
# 		@stopp = new Square stopp, @uci

VERSION = 66

# START_POINT = lat: 59.271667, lon: 18.151778 # knixen på kraftledningen NO Brotorp
# START_POINT = lat : 59.266338, lon : 18.131969 # Brandparken
START_POINT = lat : 59.270294, lon : 18.130309 # Kaninparken

SIZE_PIXEL = 100 # En schackrutas storlek i pixlar
SIZE_METER = 10 # En schackrutas storlek i meter
FACTOR = SIZE_PIXEL / SIZE_METER
RADIUS_METER = 0.25 * SIZE_METER # meter. Maxavstånd mellan spelaren och target
RADIUS_PIXEL = 0.25 * SIZE_PIXEL
TIME = [90,30] # base in minutes, increment in seconds
R = 6371e3  # Jordens radie i meter

BEARINGLIST ='01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36'.split ' '
DISTLIST = '2 4 6 8 10 12 14 16 18 20 25 30 35 40 45 50 60 70 80 90 100 120 140 160 180 200 250 300 350 400 450 500 600 700 800 900 1000 1200 1400 1600 1800 2000 2500 3000 3500 4000 4500 5000 6000 7000 8000 9000'.split ' '

#################

FILES = 'abcdefgh'
RANKS = '87654321'

targets = []
target = ""

messages = []
sounds = {}
started = false

matrix = {} # WGS84
grid_meter = {}
grid_pixel = {}
grid_meter.s = [3.5*SIZE_METER, 3.5*SIZE_METER] # origo, samlingspunkt
grid_pixel.s = [3.5*SIZE_PIXEL, 3.5*SIZE_PIXEL] # origo, samlingspunkt

grid_meter.p = [0.5*SIZE_METER, 0.5*SIZE_METER] # origo, samlingspunkt
grid_pixel.p = [0.5*SIZE_PIXEL, 0.5*SIZE_PIXEL] # origo, samlingspunkt


echo = console.log
range = _.range

dump = (msg) ->
	messages.unshift msg # nyaste överst
	if messages.length > 20 then messages.pop() # äldsta droppas

assert = (a,b) -> if a != b then echo 'assert',a,b

watchID = null
gpsCount = 0


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
	dump "#{gpsCount} #{round bearingBetween matrix.p, matrix[target]}° #{target} #{round distanceBetween(matrix.p, matrix[target])}m #{round p.coords.latitude,6} #{round p.coords.longitude,6} #{round p.coords.accuracy, 1}" 

	# om man är inom RADIUS meter från målet, byt mål
	if target == '' then return
	if RADIUS_METER < distanceBetween matrix.p, matrix[target] then return
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

# locationUpdate = (p) ->
# 	reason = 0
# 	try
# 		pLat = round p.coords.latitude,6
# 		pLon = round p.coords.longitude,6
# 		# if storage.trail.length == 0
# 		# 	gpsLat = pLat
# 		# 	gpsLon = pLon
# 		# messages[5] = gpsCount++
# 		decreaseQueue()
# 		# reason = 1
# 		increaseQueue p # meters
# 		# reason = 2
# 		# uppdatera pLat, pLon
# 		# reason = 3
# 	catch error
# 		dump error
# 		dump reason

window.preload = ->
	initSounds()

window.setup = ->
	createCanvas windowWidth-5, windowHeight-5, document.getElementById "canvas"
	textAlign CENTER,CENTER
	textSize 2*0.02 * height
	noFill()
	frameRate 2

	matrix.s = START_POINT 
	arr = (destinationPoint matrix.s.lat, matrix.s.lon, i * SIZE_METER, 90 for i in [0...8])

	for i in [0...8]
		for j in [0...8]
			key = "#{FILES[i]}#{RANKS[j]}"
			matrix[key] = destinationPoint arr[i].lat, arr[i].lon, j * SIZE_METER, 180
			grid_pixel[key] = [i * SIZE_PIXEL, j * SIZE_PIXEL]
			grid_meter[key] = [i * SIZE_METER, j * SIZE_METER]

	targets = _.keys matrix
	targets = 's a1 a8 h1 h8 p'.split ' '
	# targets = _.shuffle targets
	echo targets
	target = targets.shift()

	# NW hörnet
	lat = (matrix.a8.lat + matrix.b7.lat) / 2
	lon = (matrix.a8.lon + matrix.b7.lon) / 2
	matrix.p = {lat, lon}
	# grid_pixel.p = [0.5*SIZE_PIXEL, 0.5*SIZE_PIXEL]
	# grid_meter.p = [grid_pixel.p[0] / FACTOR, grid_pixel.p[1] / FACTOR]

	dump "V:#{VERSION} S:#{SIZE_METER}m R:#{RADIUS_METER}m #{START_POINT.lat} #{START_POINT.lon}"  

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
	OX = (width - 7*SIZE_PIXEL - 2*RADIUS_PIXEL)2 #10 # offset
	OY = 2*RADIUS_PIXEL
	background 0
	# noFill() # 255
	SP2 = SIZE_PIXEL/2

	stroke 'white'
	strokeWeight 2

	[px,py] = grid_pixel.p
	[tx,ty] = grid_pixel[target]
	line OX + px, OY + py, OX + tx, OY + ty
	# noStroke()

	for key of grid_pixel
		[x,y] = grid_pixel[key]
		# noFill()
		stroke 'white'
		if key == target then stroke 'red'
		if key == 'p'
			stroke 'yellow'
			circle OX + x, OY + y, 2*RADIUS_PIXEL
		else
			circle OX + x, OY + y, 2*RADIUS_PIXEL

	# strokeWeight 1
	noStroke()
	push()
	fill '#777'
	textSize 0.025 * height
	for i in [0...8]
		text FILES[i], OX + i*SIZE_PIXEL, OY + 7 * SIZE_PIXEL # letters
		if i < 7
			text RANKS[i], OX,            OY + (i+0.043)*SIZE_PIXEL # digits
	pop()

	push()
	fill 'yellow'
	textSize 2*0.03 * height
	textAlign 'left'
	text round(bearingBetween(matrix.p, matrix[target])) + '°', 0, 8.2*SIZE_PIXEL
	textAlign 'center'
	text target, 0.5*width, 8.2*SIZE_PIXEL
	textAlign 'right'
	text round(distanceBetween(matrix.p, matrix[target])) + 'm', width, 8.2*SIZE_PIXEL
	pop()

	push()
	fill '#777'
	textAlign "left"
	textSize 0.036 * height
	for i in range messages.length
		text messages[i], 0.0*SIZE_PIXEL, 9*SIZE_PIXEL + i * 0.04 * height
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

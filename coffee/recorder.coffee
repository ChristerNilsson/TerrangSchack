points = []
watchId = null

startRecording = ->
	if navigator.geolocation
		watchId = navigator.geolocation.watchPosition recordPoint, showError,
			enableHighAccuracy: true
			maximumAge: 0
			timeout: 5000
	else
		alert "Geolocation is not supported."

stopRecording = ->
	if watchId?
		navigator.geolocation.clearWatch watchId
		watchId = null
		saveData()

recordPoint = (position) ->
	point =
		latitude: position.coords.latitude
		longitude: position.coords.longitude
		accuracy: position.coords.accuracy
		altitude: position.coords.altitude
		altitudeAccuracy: position.coords.altitudeAccuracy
		heading: position.coords.heading
		speed: position.coords.speed
		timestamp: position.timestamp
	
	points.push point

	document.getElementById('output').textContent = "#{points.length}\n" + JSON.stringify(point, null, 2)

	if points.length >= 300
		stopRecording()

showError = (error) ->
	console.error "Geolocation error: #{error.message}"

saveData = ->
	blob = new Blob([JSON.stringify(points, null, 2)], {type: "application/json"})
	url = URL.createObjectURL(blob)
	link = document.createElement("a")
	link.href = url
	link.download = "gps_data.json"
	link.click()

document.getElementById('start').addEventListener 'click', startRecording
document.getElementById('stop').addEventListener 'click', stopRecording

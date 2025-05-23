// Generated by CoffeeScript 2.7.0
var echo, points, recordPoint, saveData, showError, startRecording, stopRecording, watchId;

echo = console.log;

points = [];

watchId = null;

startRecording = function() {
  if (navigator.geolocation) {
    return watchId = navigator.geolocation.watchPosition(recordPoint, showError, {
      enableHighAccuracy: true,
      maximumAge: 0,
      timeout: 5000
    });
  } else {
    return alert("Geolocation is not supported.");
  }
};

stopRecording = function() {
  if (watchId != null) {
    navigator.geolocation.clearWatch(watchId);
    watchId = null;
    return saveData();
  }
};

recordPoint = function(position) {
  var point;
  point = {
    latitude: position.coords.latitude,
    longitude: position.coords.longitude,
    accuracy: position.coords.accuracy,
    altitude: position.coords.altitude,
    altitudeAccuracy: position.coords.altitudeAccuracy,
    heading: position.coords.heading,
    speed: position.coords.speed,
    timestamp: position.timestamp
  };
  points.push(point);
  document.getElementById('output').textContent = `${points.length}\n` + JSON.stringify(point, null, 2);
  if (points.length >= 300) {
    return stopRecording();
  }
};

showError = function(error) {
  return console.error(`Geolocation error: ${error.message}`);
};

saveData = function() {
  var blob, link, url;
  blob = new Blob([JSON.stringify(points, null, 2)], {
    type: "application/json"
  });
  url = URL.createObjectURL(blob);
  link = document.createElement("a");
  link.href = url;
  link.download = "gps_data.json";
  return link.click();
};

document.getElementById('start').addEventListener('click', startRecording);

document.getElementById('stop').addEventListener('click', stopRecording);

//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoicmVjb3JkZXIuanMiLCJzb3VyY2VSb290IjoiLi5cXCIsInNvdXJjZXMiOlsiY29mZmVlXFxyZWNvcmRlci5jb2ZmZWUiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IjtBQUFBLElBQUEsSUFBQSxFQUFBLE1BQUEsRUFBQSxXQUFBLEVBQUEsUUFBQSxFQUFBLFNBQUEsRUFBQSxjQUFBLEVBQUEsYUFBQSxFQUFBOztBQUFBLElBQUEsR0FBTyxPQUFPLENBQUM7O0FBRWYsTUFBQSxHQUFTOztBQUNULE9BQUEsR0FBVTs7QUFFVixjQUFBLEdBQWlCLFFBQUEsQ0FBQSxDQUFBO0VBQ2hCLElBQUcsU0FBUyxDQUFDLFdBQWI7V0FDQyxPQUFBLEdBQVUsU0FBUyxDQUFDLFdBQVcsQ0FBQyxhQUF0QixDQUFvQyxXQUFwQyxFQUFpRCxTQUFqRCxFQUNUO01BQUEsa0JBQUEsRUFBb0IsSUFBcEI7TUFDQSxVQUFBLEVBQVksQ0FEWjtNQUVBLE9BQUEsRUFBUztJQUZULENBRFMsRUFEWDtHQUFBLE1BQUE7V0FNQyxLQUFBLENBQU0sK0JBQU4sRUFORDs7QUFEZ0I7O0FBU2pCLGFBQUEsR0FBZ0IsUUFBQSxDQUFBLENBQUE7RUFDZixJQUFHLGVBQUg7SUFDQyxTQUFTLENBQUMsV0FBVyxDQUFDLFVBQXRCLENBQWlDLE9BQWpDO0lBQ0EsT0FBQSxHQUFVO1dBQ1YsUUFBQSxDQUFBLEVBSEQ7O0FBRGU7O0FBTWhCLFdBQUEsR0FBYyxRQUFBLENBQUMsUUFBRCxDQUFBO0FBQ2QsTUFBQTtFQUFDLEtBQUEsR0FDQztJQUFBLFFBQUEsRUFBVSxRQUFRLENBQUMsTUFBTSxDQUFDLFFBQTFCO0lBQ0EsU0FBQSxFQUFXLFFBQVEsQ0FBQyxNQUFNLENBQUMsU0FEM0I7SUFFQSxRQUFBLEVBQVUsUUFBUSxDQUFDLE1BQU0sQ0FBQyxRQUYxQjtJQUdBLFFBQUEsRUFBVSxRQUFRLENBQUMsTUFBTSxDQUFDLFFBSDFCO0lBSUEsZ0JBQUEsRUFBa0IsUUFBUSxDQUFDLE1BQU0sQ0FBQyxnQkFKbEM7SUFLQSxPQUFBLEVBQVMsUUFBUSxDQUFDLE1BQU0sQ0FBQyxPQUx6QjtJQU1BLEtBQUEsRUFBTyxRQUFRLENBQUMsTUFBTSxDQUFDLEtBTnZCO0lBT0EsU0FBQSxFQUFXLFFBQVEsQ0FBQztFQVBwQjtFQVNELE1BQU0sQ0FBQyxJQUFQLENBQVksS0FBWjtFQUVBLFFBQVEsQ0FBQyxjQUFULENBQXdCLFFBQXhCLENBQWlDLENBQUMsV0FBbEMsR0FBZ0QsQ0FBQSxDQUFBLENBQUcsTUFBTSxDQUFDLE1BQVYsQ0FBQSxFQUFBLENBQUEsR0FBdUIsSUFBSSxDQUFDLFNBQUwsQ0FBZSxLQUFmLEVBQXNCLElBQXRCLEVBQTRCLENBQTVCO0VBRXZFLElBQUcsTUFBTSxDQUFDLE1BQVAsSUFBaUIsR0FBcEI7V0FBNkIsYUFBQSxDQUFBLEVBQTdCOztBQWZhOztBQWlCZCxTQUFBLEdBQVksUUFBQSxDQUFDLEtBQUQsQ0FBQTtTQUFXLE9BQU8sQ0FBQyxLQUFSLENBQWMsQ0FBQSxtQkFBQSxDQUFBLENBQXNCLEtBQUssQ0FBQyxPQUE1QixDQUFBLENBQWQ7QUFBWDs7QUFFWixRQUFBLEdBQVcsUUFBQSxDQUFBLENBQUE7QUFDWCxNQUFBLElBQUEsRUFBQSxJQUFBLEVBQUE7RUFBQyxJQUFBLEdBQU8sSUFBSSxJQUFKLENBQVMsQ0FBQyxJQUFJLENBQUMsU0FBTCxDQUFlLE1BQWYsRUFBdUIsSUFBdkIsRUFBNkIsQ0FBN0IsQ0FBRCxDQUFULEVBQTJDO0lBQUMsSUFBQSxFQUFNO0VBQVAsQ0FBM0M7RUFDUCxHQUFBLEdBQU0sR0FBRyxDQUFDLGVBQUosQ0FBb0IsSUFBcEI7RUFDTixJQUFBLEdBQU8sUUFBUSxDQUFDLGFBQVQsQ0FBdUIsR0FBdkI7RUFDUCxJQUFJLENBQUMsSUFBTCxHQUFZO0VBQ1osSUFBSSxDQUFDLFFBQUwsR0FBZ0I7U0FDaEIsSUFBSSxDQUFDLEtBQUwsQ0FBQTtBQU5VOztBQVFYLFFBQVEsQ0FBQyxjQUFULENBQXdCLE9BQXhCLENBQWdDLENBQUMsZ0JBQWpDLENBQWtELE9BQWxELEVBQTJELGNBQTNEOztBQUNBLFFBQVEsQ0FBQyxjQUFULENBQXdCLE1BQXhCLENBQStCLENBQUMsZ0JBQWhDLENBQWlELE9BQWpELEVBQTBELGFBQTFEIiwic291cmNlc0NvbnRlbnQiOlsiZWNobyA9IGNvbnNvbGUubG9nIFxyXG5cclxucG9pbnRzID0gW11cclxud2F0Y2hJZCA9IG51bGxcclxuXHJcbnN0YXJ0UmVjb3JkaW5nID0gLT5cclxuXHRpZiBuYXZpZ2F0b3IuZ2VvbG9jYXRpb25cclxuXHRcdHdhdGNoSWQgPSBuYXZpZ2F0b3IuZ2VvbG9jYXRpb24ud2F0Y2hQb3NpdGlvbiByZWNvcmRQb2ludCwgc2hvd0Vycm9yLFxyXG5cdFx0XHRlbmFibGVIaWdoQWNjdXJhY3k6IHRydWVcclxuXHRcdFx0bWF4aW11bUFnZTogMFxyXG5cdFx0XHR0aW1lb3V0OiA1MDAwXHJcblx0ZWxzZVxyXG5cdFx0YWxlcnQgXCJHZW9sb2NhdGlvbiBpcyBub3Qgc3VwcG9ydGVkLlwiXHJcblxyXG5zdG9wUmVjb3JkaW5nID0gLT5cclxuXHRpZiB3YXRjaElkP1xyXG5cdFx0bmF2aWdhdG9yLmdlb2xvY2F0aW9uLmNsZWFyV2F0Y2ggd2F0Y2hJZFxyXG5cdFx0d2F0Y2hJZCA9IG51bGxcclxuXHRcdHNhdmVEYXRhKClcclxuXHJcbnJlY29yZFBvaW50ID0gKHBvc2l0aW9uKSAtPlxyXG5cdHBvaW50ID1cclxuXHRcdGxhdGl0dWRlOiBwb3NpdGlvbi5jb29yZHMubGF0aXR1ZGVcclxuXHRcdGxvbmdpdHVkZTogcG9zaXRpb24uY29vcmRzLmxvbmdpdHVkZVxyXG5cdFx0YWNjdXJhY3k6IHBvc2l0aW9uLmNvb3Jkcy5hY2N1cmFjeVxyXG5cdFx0YWx0aXR1ZGU6IHBvc2l0aW9uLmNvb3Jkcy5hbHRpdHVkZVxyXG5cdFx0YWx0aXR1ZGVBY2N1cmFjeTogcG9zaXRpb24uY29vcmRzLmFsdGl0dWRlQWNjdXJhY3lcclxuXHRcdGhlYWRpbmc6IHBvc2l0aW9uLmNvb3Jkcy5oZWFkaW5nXHJcblx0XHRzcGVlZDogcG9zaXRpb24uY29vcmRzLnNwZWVkXHJcblx0XHR0aW1lc3RhbXA6IHBvc2l0aW9uLnRpbWVzdGFtcFxyXG5cdFxyXG5cdHBvaW50cy5wdXNoIHBvaW50XHJcblxyXG5cdGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKCdvdXRwdXQnKS50ZXh0Q29udGVudCA9IFwiI3twb2ludHMubGVuZ3RofVxcblwiICsgSlNPTi5zdHJpbmdpZnkgcG9pbnQsIG51bGwsIDJcclxuXHJcblx0aWYgcG9pbnRzLmxlbmd0aCA+PSAzMDAgdGhlbiBzdG9wUmVjb3JkaW5nKClcclxuXHJcbnNob3dFcnJvciA9IChlcnJvcikgLT4gY29uc29sZS5lcnJvciBcIkdlb2xvY2F0aW9uIGVycm9yOiAje2Vycm9yLm1lc3NhZ2V9XCJcclxuXHJcbnNhdmVEYXRhID0gLT5cclxuXHRibG9iID0gbmV3IEJsb2IgW0pTT04uc3RyaW5naWZ5IHBvaW50cywgbnVsbCwgMl0sIHt0eXBlOiBcImFwcGxpY2F0aW9uL2pzb25cIn1cclxuXHR1cmwgPSBVUkwuY3JlYXRlT2JqZWN0VVJMIGJsb2JcclxuXHRsaW5rID0gZG9jdW1lbnQuY3JlYXRlRWxlbWVudCBcImFcIlxyXG5cdGxpbmsuaHJlZiA9IHVybFxyXG5cdGxpbmsuZG93bmxvYWQgPSBcImdwc19kYXRhLmpzb25cIlxyXG5cdGxpbmsuY2xpY2soKVxyXG5cclxuZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ3N0YXJ0JykuYWRkRXZlbnRMaXN0ZW5lciAnY2xpY2snLCBzdGFydFJlY29yZGluZ1xyXG5kb2N1bWVudC5nZXRFbGVtZW50QnlJZCgnc3RvcCcpLmFkZEV2ZW50TGlzdGVuZXIgJ2NsaWNrJywgc3RvcFJlY29yZGluZ1xyXG4iXX0=
//# sourceURL=c:\github\TerrangSchack\coffee\recorder.coffee
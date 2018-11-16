"strict";

let lineWidth = 2;
let lineColor = '#ff0000';
let lineOpacity = 0.5;
let geoSteps = 100;
let markers = [];

$(document).ready(function() {
  let points = [];
  $("li.airport").each(function(index, li) {
    let lat = $(li).attr("x-latitude");
    let lng = $(li).attr("x-longitude");

    points.push([lat,lng]);
  });

  let map = L.map("flightmap").setView([0,0], 8);
  map.fitBounds(points);

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: 'map data © OpenStreetMap contributors',
    minZoom: 1,
    MaxZoom: 18
  }).addTo(map);

  points = {};
  $("li.route").each(function(index, li) {
    let depiata = $(li).attr("x-depart");
    let arriata = $(li).attr("x-arrive");
    let dep = $("li.airport#" + depiata)[0];
    let arr = $("li.airport#" + arriata)[0];

    let slatlng = L.latLng($(dep).attr("x-latitude"), $(dep).attr("x-longitude"));
    let elatlng = L.latLng($(arr).attr("x-latitude"), $(arr).attr("x-longitude"));

    if (!(depiata in points)) {
      createPoint(map, slatlng.lat, slatlng.lng, depiata, depiata + ": " + $(dep).html());
      points[depiata] = 1;
    }
    if (!(arriata in points)) {
      createPoint(map, elatlng.lat, elatlng.lng, arriata, arriata + ": " + $(arr).html());
      points[arriata] = 1;
    }
    createLine(map, slatlng, elatlng, lineColor, lineWidth, lineOpacity);
  });

  markers = []; // Remove the route points; they never get removed

  map.on('click', function(e) {
    onClick(map, e);
  });
});

function createPoint(map, lat, lng, id, title) {
  let icon = L.MakiMarkers.icon({icon: "marker", color: "#aaaaff", size: "s"});
  let marker = L.marker([lat, lng], { "icon": icon });
  marker.bindPopup(title).openPopup();
  markers.push(marker);
  return marker.addTo(map);
}

function createLine(map, slatlng, elatlng, color, width, opacity) {
  let opts = {
    weight: width,
    opacity: opacity,
    color: color,
    steps: geoSteps
  };

  return L.geodesic([[slatlng, elatlng]], opts).addTo(map);
}

function onClick(map, event) {
  $("#near").html("<p>Searching for airports...</p>");

  $.ajax({
    "type": "GET",
    "dataType": "json",
    "url": "/near",
    "timeout": 5000,
    "data": {"lat": event.latlng.lat, "lng": event.latlng.lng},
    "success": function(data,status) { showAirports(map, data); }
  });
};

function showAirports(map, data) {
  if (data.length != 1) {
    airp = data.length + " airports:";
  } else {
    airp = "1 airport:";
  }

  for (marker of markers) {
    map.removeLayer(marker);
  }
  markers = [];

  list = "<p>Found " + airp + "</p>";
  list += "<table border=0 cellpadding=0 cellspacing=0>";

  for (var pos = 0, len = data.length; pos < len; pos++) {
    list += "<tr>";
    list += "<td><code style='font-size:120%; font-weight:bold;'>"
            + data[pos].code + "</code>&#160;</td>";
    list += "<td>" + data[pos].name + "&#160;</td>";
    list += "<td>(" + data[pos].dist + " miles)</td>";
    list += "</tr>";

    createPoint(map, data[pos].lat, data[pos].lng, data[pos].code, data[pos].name);
  }

  list += "</table>";
  $("#near").html(list);
}

/* -*- JavaScript -*-

Plot flight maps with Google Maps API V3.
You must setup the globals first:

  var mapDiv, SFO, IAD;
  mapDiv = document.getElementById('flightmap');
  SFO = new Airport(37.6189994812012, -122.375, "SFO", "");
  IAD = new Airport(38.94449997, -77.45580292, "IAD", "");
  flights.push(new Flight(SFO,IAD));
  Plot();

It could be prettier, I'm sure.
*/

// Globals.

var mapDiv;
var map;
var flights = [];
var markers = [];
var lines = [];

var lineWidth = 1;
var lineColor = '#ff0000';

function Plot() {
    // Calculate the optimal size and center for the map
    var bounds = new google.maps.LatLngBounds();
    for (var i = 0; i < flights.length; ++i ) {
	var p = new google.maps.LatLng(flights[i].depart.lat, flights[i].depart.long);
	bounds.extend(p);
	p = new google.maps.LatLng(flights[i].arrive.lat, flights[i].arrive.long);
	bounds.extend(p);
    }

    var latlng = new google.maps.LatLng(bounds.getCenter().lat(), bounds.getCenter().lng());
    var mapopts = {
        zoom: 4,
        center: latlng,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
    };
    // disableDefaultUI: true

    map = new google.maps.Map(mapDiv, mapopts);
    map.fitBounds(bounds);

    if ($("#travelmapclickable").size() > 0) {
        google.maps.event.addListener(map, "click", mapClick);
    }

    // Now place the current markers and lines.
    for ( var i = 0; i < flights.length; ++i ) {
	var depart = flights[i].depart;
	var arrive = flights[i].arrive;

	createPoint(map, depart.lat, depart.long, depart.iata);
	createPoint(map, arrive.lat, arrive.long, arrive.iata);

        createLine(map, depart.latlng, arrive.latlng, lineColor, lineWidth);
    }
}

function mapClick(event) {
    $("#near").html("<p>Searching for airports...</p>");
    $.ajax({
        "type": "GET",
        "dataType": "json",
        "url": "/near",
        "timeout": 5000,
        "data": {"lat": event.latLng.lat(), "lng": event.latLng.lng()},
        "success": function(data,status) { showAirports(data); }
    });
}

function showAirports(data) {
    var airp, list, marker, latlng;

    // Remove any existing markers
    for ( var i = 0; i < markers.length; ++i ) {
	markers[i].setMap(null);
    }
    markers = [];

    if (data.length != 1) {
        airp = data.length + " airports:";
    } else {
        airp = "1 airport:";
    }

    list = "<p>Found " + airp + "</p>";
    list += "<table border=0 cellpadding=0 cellspacing=0>";

    for (var pos = 0, len = data.length; pos < len; pos++) {
        list += "<tr>";
        list += "<td><code style='font-size:120%; font-weight:bold;'>" + data[pos].code + "</code>&#160;</td>";
        list += "<td>" + data[pos].name + "&#160;</td>";
        list += "<td>(" + data[pos].dist + " miles)</td>";
        list += "</tr>";

        latlng = new google.maps.LatLng(data[pos].lat, data[pos].lng)
        marker = new google.maps.Marker({
            position: latlng,
            map: map,
            icon: "http://www.google.com/intl/en_us/mapfiles/ms/micons/blue-dot.png",
            title: data[pos].code
        });
        markers.push(marker);
    }

    list += "</table>";
    $("#near").html(list)
}

function Airport(lat, long, iata, uri) {
    this.lat = lat;
    this.long = long;
    this.latlng = new google.maps.LatLng(lat, long);
    this.iata = iata;
}

function Flight(depart, arrive) {
    this.depart = depart;
    this.arrive = arrive;
}

function createPoint(map, lat, lng, title) {
    var latlng = new google.maps.LatLng(lat, lng);
    var marker = new google.maps.Marker({
        position: latlng,
        map: map,
        icon: "/img/x.png",
        title: title
    });
}

function createLine(map, slatlng, elatlng, color, width) {
    var coords = [ slatlng, elatlng ];
    var line = new google.maps.Polyline({
        path: coords,
        strokeColor: color,
        strokeWidth: width,
        strokeWeight: 1,
        geodesic: true
    });
    line.setMap(map);
}

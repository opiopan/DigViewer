//
//  GPSMapView.js
//  DigViewer
//
//  Created by opiopan on 2014/03/30.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

var map = null;
var latlng = null;
var zoomLevel = 10;
var defLatLng = new google.maps.LatLng(0, 0);
var marker = null;

function initialize() {
    var mapOptions = {
        center: defLatLng,
        zoom: 1,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        panControl: false,
        zoomControl: true,
        mapTypeControl: true,
        scaleControl: true,
        streetViewControl: true,
        overviewMapControl: true
    };
    if (latlng){
        mapOptions.center = latlng;
        mapOptions.zoom = zoomLevel;
    }
    map = new google.maps.Map(document.getElementById("map_canvas"),mapOptions);
}

function setMarker(latitude, longitude) {
    if (!latlng){
        map.setZoom(zoomLevel);
    }
    latlng = new google.maps.LatLng(latitude, longitude);
    if (marker){
        marker.setMap(null);
    }
    marker = new google.maps.Marker({
                                    position: latlng,
                                    map: map
                                    });
    map.setCenter(latlng);
}

function resetMarker() {
    if (latlng){
        zoomLevel = map.getZoom();
        latlng = null;
        map.setZoom(1);
    }
    if (marker){
        marker.setMap(null);
        marker = null;
    }
}

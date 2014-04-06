//
//  GPSMapView.js
//  DigViewer
//
//  Created by opiopan on 2014/03/30.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

var map = null;
var imageLocation = null;
var zoomLevel = 10;
var imageVector = null;
var imageHeading = null;
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
    if (imageLocation){
        mapOptions.center = imageLocation;
        mapOptions.zoom = zoomLevel;
    }
    map = new google.maps.Map(document.getElementById("map_canvas"),mapOptions);
    google.maps.event.addListener(map, "bounds_changed", function(){setHeading();});
    google.maps.event.addListener(map, "zoom_changed", function(){setHeading();});
    window.bridge.reflectGpsInfo();
}

function setMarker(latitude, longitude, heading) {
    if (map){
        if (!imageLocation){
            map.setZoom(zoomLevel);
        }
        imageLocation = new google.maps.LatLng(latitude, longitude);
        if (marker){
            marker.setMap(null);
        }
        marker = new google.maps.Marker({
                                        position: imageLocation,
                                        map: map
                                        });
        map.setCenter(imageLocation);
        imageHeading = heading;
        setHeading();
    }else{
        imageLocation = new google.maps.LatLng(latitude, longitude);
        imageHeading = heading;
    }
}

function resetMarker() {
    if (imageLocation){
        zoomLevel = map.getZoom();
        imageLocation = null;
        map.setZoom(1);
        map.setCenter(defLatLng);
    }
    if (marker){
        marker.setMap(null);
        marker = null;
    }
    imageHeading = null;
    setHeading();
}

function setHeading() {
    if (imageVector){
        imageVector.setMap(null);
        imageVector = null;
    }
    if (imageHeading){
        to = google.maps.geometry.spherical.computeOffset(imageLocation, headingLength(), imageHeading);
        var color = "#FF0000";
        var opacity = 0.7;
        var headArrow = {
            path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW,
            fillOpacity: opacity,
            fillColor: color,
            strokeColor: color,
            strokeOpacity: opacity
            };
        var icon_symbol =  [{icon: headArrow, offset: '100%'}];
        var vectorOpt = {
            path: [imageLocation, to],
            icons: icon_symbol,
            strokeColor: color,
            strokeOpacity: opacity,
            strokeWeight: 3
        };
        imageVector = new google.maps.Polyline(vectorOpt);
        imageVector.setMap(map);
    }
}

function headingLength() {
    var bounds = map.getBounds();
    if (bounds){
        var northEast = bounds.getNorthEast();
        var southWest = bounds.getSouthWest();
        var northWest = new google.maps.LatLng(northEast.lat(), southWest.lng());
        var width = google.maps.geometry.spherical.computeDistanceBetween(northEast, northWest);
        var height = google.maps.geometry.spherical.computeDistanceBetween(southWest, northWest);
        var ratio = 0.4;
        if (height > width){
            return width * ratio;
        }else{
            return height * ratio;
        }
    }else{
        return 0;
    }
}